#!/usr/bin/env python
import argparse
import configparser
import os

from pathlib import Path
from typing import Dict

import cocotb
import cocotb.handle
import cocotb.runner
import cocotb.wavedrom

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))


def read_ini(path):
    # type: (Union[List[str], str]) -> configparser.SafeConfigParser
    app_ini = configparser.ConfigParser()
    app_ini.read(path)
    return app_ini


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('module')
    return parser.parse_args()


async def initialise_dut(dut):
    signals_dict = get_signals_dict(dut)
    for signal_name in signals_dict.keys():
        if signals_dict[signal_name]['type'] == 'bit_mux':
            getattr(dut, '{}'.format(signals_dict[signal_name]['name'])).value = 0
        elif 'bit_out' in signals_dict[signal_name]['type']:
            pass  # ignore outputs
        else:
            wstb = getattr(dut, '{}_WSTB'.format(signal_name), None)
            if wstb is not None:
                wstb.value = 0

            getattr(dut, signal_name).value = 0



def get_timing_ini(module):
    ini_path = Path(SCRIPT_DIR).parent.parent / 'modules' / module / '{}.timing.ini'.format(module)
    return read_ini(str(ini_path.resolve()))


def get_block_ini(module):
    ini_path = Path(SCRIPT_DIR).parent.parent / 'modules' / module / '{}.block.ini'.format(module)
    return read_ini(str(ini_path.resolve()))



def assign(dut, name, val):
    # TODO: maybe use the block ini information to not assume? more generally, refactor and clean this file
    signal = getattr(dut, '{}_i'.format(name), None)
    if signal is not None:
        signal.value = val
        return

    getattr(dut, name).value = val
    wstb  = getattr(dut, '{}_wstb'.format(name), None)
    if wstb is not None:
        wstb.value = 1


def parse_assignments(assignments):
    result = {}
    for assignment in assignments.split(','):
        signal_name, val = assignment.split('=')
        signal_name, val = signal_name.strip(), int(val)
        result[signal_name] = val
    return result


def do_assignments(dut, assignments, wstb_to_reset):
    if wstb_to_reset:
        for wstb_name in wstb_to_reset:
            getattr(dut, wstb_name).value = 0
    wstb_to_reset = []
    for signal_name, val in parse_assignments(assignments).items():
        assign(dut, signal_name, val)
        wstb_name = '{}_wstb'.format(signal_name)
        if hasattr(dut, wstb_name):
            wstb_to_reset.append(wstb_name)
    return wstb_to_reset

    
def check_conditions(dut, conditions: Dict[str, int], loud=False):
    for signal_name, val in conditions.items():
        assert getattr(dut, '{}_o'.format(signal_name)).value == val, "Signal {} != {}, time = {} ns".format(signal_name, val, cocotb.utils.get_sim_time("ns"))
        if loud:
            dut._log.info(f"Check passed: Signal {signal_name} = {val}, time = {cocotb.utils.get_sim_time("ns")} ns")


def get_signals(dut):
    return [getattr(dut, signal_name) for signal_name in dir(dut) 
            if isinstance(getattr(dut, signal_name), cocotb.handle.ModifiableObject) and not signal_name.startswith('_')] 


def get_signals_dict(dut):
    # Get a mapping between signal names in INI file and VHDL file, and store signal type.
    signals_dict = {}
    ini = get_block_ini(dut._name)
    expected_signal_names = ini.sections()
    for signal_name in expected_signal_names:
        if 'type' in ini[signal_name]:
            signals_dict[signal_name] = {'type': ini[signal_name]['type']} 
            if signals_dict[signal_name]['type'] == 'bit_mux':
                signals_dict[signal_name]["name"] = '{}_i'.format(signal_name.lower())
            elif signals_dict[signal_name]['type'] == 'bit_out':
                signals_dict[signal_name]['name'] = '{}_o'.format(signal_name.lower())
            else:
                signals_dict[signal_name]['name'] = signal_name
    return signals_dict


def log_signals(dut, signals_dict = None):
    if signals_dict is None:
        signals_dict = get_signals_dict(dut)
    for signal_name in signals_dict:
        dut._log.info(f"Signal {signal_name} ({signals_dict[signal_name]['name']}) = {getattr(dut, signals_dict[signal_name]['name']).value}.")
    print()


async def section_timing_test(dut, timing_ini, test_name, loud=False):
    with cocotb.wavedrom.trace(*get_signals(dut), clk=dut.clk_i) as trace:   
        cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start(start_high=False))
        ticks = 0
        await initialise_dut(dut)
        await RisingEdge(dut.clk_i)
        conditions = {}    
        wstb = [] 
        for ts_str, line in timing_ini.items(test_name):
            ts = int(ts_str)
            parts = line.split('->')
            assignments = parts[0]
            if len(parts) > 1:
                conditions[ts + 1] = parts[1] 

            # Tick until time specicifed in INI. 
            # Assign values to signals where needed. Check conditions from previous line where needed.
            while ticks < ts:
                await RisingEdge(dut.clk_i)
                ticks += 1
                if ticks in conditions.keys() and ticks == ts:
                    wstb = do_assignments(dut, assignments, wstb)
                    await ReadOnly()
                    check_conditions(dut, parse_assignments(conditions[ticks]), loud=loud)
                elif ticks in conditions.keys():
                    await ReadOnly()
                    check_conditions(dut, parse_assignments(conditions[ticks]), loud=loud)
                elif ticks == ts:
                    wstb = do_assignments(dut, assignments, wstb)
                
        # Check any final conditions
        await RisingEdge(dut.clk_i)
        ticks += 1
        if ticks in conditions.keys():
            await ReadOnly()
            check_conditions(dut, parse_assignments(conditions[ticks]), loud=loud)
            await RisingEdge(dut.clk_i)
            ticks += 1

        with open(f'{test_name.replace(" ", "_")}_wavedrom.json', 'w') as fhandle:
                fhandle.write(trace.dumpj())


@cocotb.test()
async def module_timing_test(dut):
    module = dut._name
    timing_ini = get_timing_ini(module)
    test_name = None
    for section in timing_ini.sections():
        if section.strip() != '.':
            test_name = section
            await section_timing_test(dut, timing_ini, test_name, loud=True)
            # TODO: Add functionality to run all the tests
        
        


def get_module_hdl_files(module):
    module_dir = Path(SCRIPT_DIR).parent.parent / 'modules' / module
    return list((module_dir / 'hdl').glob('*.vhd'))


def test_module():
    args = get_args()
    sim = cocotb.runner.get_runner('ghdl')
    sim.build(sources=get_module_hdl_files(args.module), hdl_toplevel=args.module, build_args=['--std=08'])
    sim.test(hdl_toplevel=args.module, test_module='cocotb_timing_test_runner', test_args=['--std=08'])


if __name__ == "__main__":
    test_module()
#!/usr/bin/env python
import argparse
import configparser
import os
import logging

from pathlib import Path
from typing import Dict

import cocotb
import cocotb.handle
import cocotb.runner
import cocotb.wavedrom
import cocotb.binary

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
    parser.add_argument('test_name', nargs='?', default='all')
    parser.add_argument('-l', action='store_true')
    return parser.parse_args()


async def initialise_dut(dut):
    signals_dict = get_signals_info(dut)
    for signal_name in signals_dict.keys():
        dut_signal_name = signals_dict[signal_name]['name']
        if signals_dict[signal_name]['type'] == 'bit_mux':
            getattr(dut, '{}'.format(dut_signal_name)).value = 0
        elif signals_dict[signal_name]['type'].endswith('_out'):
            pass  # ignore outputs
        else:
            wstb = getattr(dut, '{}_WSTB'.format(signal_name), None)
            if wstb is not None:
                wstb.value = 0
            getattr(dut, signal_name).value = 0


def get_timing_ini(module):
    ini_path = (Path(SCRIPT_DIR).parent.parent / 'modules' / module /
                '{}.timing.ini'.format(module))
    return read_ini(str(ini_path.resolve()))


def get_block_ini(module):
    ini_path = Path(SCRIPT_DIR).parent.parent / 'modules' / module / \
        '{}.block.ini'.format(module)
    return read_ini(str(ini_path.resolve()))


def assign(dut, name, val):
    getattr(dut, name).value = val


def parse_assignments(assignments):
    result = {}
    for assignment in assignments.split(','):
        signal_name, val = assignment.split('=')
        signal_name, val = signal_name.strip(), int(val)
        result[signal_name] = val
    return result


def do_assignments(dut, assignments):
    for signal_name, val in assignments.items():
        assign(dut, signal_name, val)


def check_conditions(dut, conditions: Dict[str, int], loud=False):
    for signal_name, val in conditions.items():
        sim_val = getattr(dut, signal_name).value
        assert sim_val == val, 'Signal {} = {}, expecting {}. Time = {} ns'\
            .format(signal_name, sim_val, val, cocotb.utils.get_sim_time("ns"))
        if loud:
            dut._log.info(f'Check passed: Signal {signal_name} = {val}, \
                          time = {cocotb.utils.get_sim_time("ns")} ns')


def get_signals(dut):
    return [getattr(dut, signal_name) for signal_name in dir(dut)
            if isinstance(getattr(dut, signal_name),
                          cocotb.handle.ModifiableObject)
            and not signal_name.startswith('_')]


def get_signals_info(dut):
    # Get a mapping between signal names in INI file and VHDL file,
    # and store signal type.
    signals_dict = {}
    ini = get_block_ini(dut._name)
    expected_signal_names = ini.sections()
    for signal_name in expected_signal_names:
        if 'type' in ini[signal_name]:
            signals_dict[signal_name] = {'type': ini[signal_name]['type']}
            if signals_dict[signal_name]['type'] == 'bit_mux':
                signals_dict[signal_name]["name"] = '{}_i'.format(
                    signal_name.lower())
            elif signals_dict[signal_name]['type'].endswith('_out'):
                signals_dict[signal_name]['name'] = '{}_o'.format(
                    signal_name.lower())
            else:
                signals_dict[signal_name]['name'] = signal_name

        if ini[signal_name].get('wstb', False):
            signals_dict[signal_name]['wstb_name'] = '{}_wstb'.format(
                signal_name.lower())
    return signals_dict


def log_signals(dut, signals_dict=None):
    if signals_dict is None:
        signals_dict = get_signals_info(dut)
    for signal_name in signals_dict:
        dut._log.debug(f'''Signal {signal_name} ({signals_dict[signal_name]
                       ["name"]}) = {getattr(dut, signals_dict[signal_name]
                                             ["name"]).value}.''')
    print()


async def section_timing_test(dut, timing_ini, test_name, loud=False):
    conditions_schedule = {}
    assignments_schedule = {}
    last_ts = 0
    signals_info = get_signals_info(dut)
    for ts_str, line in timing_ini.items(test_name):
        ts = int(ts_str)
        for i in (ts, ts + 1):
            assignments_schedule.setdefault(i, {})
            conditions_schedule.setdefault(i, {})

        last_ts = max(last_ts, ts + 1)
        parts = line.split('->')
        for sig_name, val in parse_assignments(parts[0]).items():
            name = signals_info.get(sig_name)['name']
            assignments_schedule[ts][name] = val
            wstb_name = signals_info.get(sig_name).get('wstb_name', None)
            if wstb_name is not None:
                assignments_schedule[ts][wstb_name] = 1
                assignments_schedule[ts + 1].update({wstb_name: 0})

        if len(parts) > 1:
            conditions_schedule[ts + 1] = {}
            for sig_name, val in parse_assignments(parts[1]).items():
                name = signals_info.get(sig_name)['name']
                conditions_schedule[ts + 1][name] = val

    with cocotb.wavedrom.trace(*get_signals(dut), clk=dut.clk_i) as trace:
        clkedge = RisingEdge(dut.clk_i)
        cocotb.start_soon(Clock(
            dut.clk_i, 1, units="ns").start(start_high=False))
        ts = 0
        await initialise_dut(dut)
        await clkedge
        conditions = {}
        while ts <= last_ts:
            do_assignments(dut, assignments_schedule.get(ts, {}))
            conditions.update(conditions_schedule.get(ts, {}))
            await ReadOnly()
            check_conditions(dut, conditions)
            await clkedge
            ts += 1

        with open(f'{test_name.replace(" ", "_")}_wavedrom.json', 'w') as fhandle:
            fhandle.write(trace.dumpj())


@cocotb.test()
async def module_timing_test(dut):
    test_name = os.getenv('test_name', 'default')
    loud = True if (os.getenv("loud, default")) == "True" else False
    module = dut._name
    timing_ini = get_timing_ini(module)
    # test_name = None
    # for section in timing_ini.sections():
    if test_name.strip() != '.':
        await section_timing_test(dut, timing_ini, test_name, loud)
        # TODO: Add functionality to run all the tests


def get_module_hdl_files(module):
    module_dir = Path(SCRIPT_DIR).parent.parent / 'modules' / module
    return list((module_dir / 'hdl').glob('*.vhd'))


def test_module():
    args = get_args()
    logging.basicConfig(level=logging.DEBUG)
    loud = args.l
    timing_ini = get_timing_ini(args.module)
    sections = [args.test_name] if args.test_name != 'all' else timing_ini.sections()
    sim = cocotb.runner.get_runner('ghdl')
    sim.build(sources=get_module_hdl_files(args.module),
              hdl_toplevel=args.module,
              build_args=['--std=08'])
    # Path(f'sim_build/{args.module}/json').mkdir(parents=True, exist_ok=True)
    for section in sections:
        if section.strip() != '.':
            test_name = section
            vcd_filename = '{}-{}.vcd'.format(args.module, test_name.replace(' ', '_'))
            print()
            print('Test: "{}" in module {}.\n'.format(test_name, args.module))
            sim.test(hdl_toplevel=args.module,
                     test_module='cocotb_timing_test_runner',
                     test_args=['--std=08'],
                     plusargs=['--vcd={}'.format(vcd_filename)],
                     extra_env={'test_name': test_name, 'loud': str(loud)})


if __name__ == "__main__":
    test_module()

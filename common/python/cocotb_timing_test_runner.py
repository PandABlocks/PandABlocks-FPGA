#!/usr/bin/env python
import argparse
import configparser
import os
import logging
import shutil
import time

from pathlib import Path
from typing import Dict, List

import cocotb
import cocotb.handle
import cocotb.runner
import cocotb.wavedrom
import cocotb.binary

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly


SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


def read_ini(path: List[str] | str) -> configparser.ConfigParser:
    app_ini = configparser.ConfigParser()
    app_ini.read(path)
    return app_ini


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('module')
    parser.add_argument('test_name', nargs='?', default=None)
    return parser.parse_args()


def is_input_signal(signals_info, signal_name):
    return not (signals_info[signal_name]['type'].endswith('_out')
                or 'read' in signals_info[signal_name]['type'])


async def initialise_dut(dut):
    signals_info = get_signals_info(dut)
    for signal_name in signals_info.keys():
        dut_signal_name = signals_info[signal_name]['name']
        if is_input_signal(signals_info, signal_name):
            getattr(dut, '{}'.format(dut_signal_name)).value = 0
            wstb_name = signals_info[signal_name].get('wstb_name', '')
            if wstb_name:
                getattr(dut, wstb_name).value = 0


def get_timing_ini(module):
    ini_path = (MODULES_PATH / module / '{}.timing.ini'.format(module))
    return read_ini(str(ini_path.resolve()))


def get_block_ini(module):
    ini_path = MODULES_PATH / module / '{}.block.ini'.format(module)
    return read_ini(str(ini_path.resolve()))


def assign(dut, name, val):
    getattr(dut, name).value = val


def parse_assignments(assignments):
    result = {}
    for assignment in assignments.split(','):
        if assignment.strip() == '':
            continue
        signal_name, val = assignment.split('=')
        signal_name = signal_name.strip()
        if val.startswith('0x') or val.startswith('0X'):
            val = int(val[2:], 16)
        else:
            val = int(val)
        result[signal_name] = val
    return result


def do_assignments(dut, assignments):
    for signal_name, val in assignments.items():
        assign(dut, signal_name, val)


def check_conditions(dut, conditions: Dict[str, int]):
    for signal_name, val in conditions.items():
        if val < 0:
            sim_val = getattr(dut, signal_name).value.signed_integer
        else:
            sim_val = getattr(dut, signal_name).value

        assert sim_val == val, 'Signal {} = {}, expecting {}. Time = {} ns'\
            .format(signal_name, sim_val, val, cocotb.utils.get_sim_time("ns"))


def get_signals(dut):
    return [getattr(dut, signal_name) for signal_name in dir(dut)
            if isinstance(getattr(dut, signal_name),
                          cocotb.handle.ModifiableObject)
            and not signal_name.startswith('_')]


def get_signals_info(dut):
    # Get a mapping between signal names in INI file and VHDL file,
    # and store signal type.
    signals_info = {}
    ini = get_block_ini(dut._name)
    expected_signal_names = ini.sections()
    for signal_name in expected_signal_names:
        if 'type' in ini[signal_name]:
            _type = ini[signal_name]['type'].strip()
            suffixes = []
            if _type == 'time':
                suffixes = ['_L', '_H']
            elif _type == 'table short':
                suffixes = ['_START', '_DATA', '_LENGTH']
            if suffixes:
                for suffix in suffixes:
                    new_signal_name = f'{signal_name}{suffix}'
                    signals_info[new_signal_name] = {}
                    signals_info[new_signal_name].update(ini[signal_name])
                    signals_info[new_signal_name]['name'] = new_signal_name
                    if ini[signal_name].get('wstb', False):
                        signals_info[new_signal_name]['wstb_name'] = \
                            '{}_wstb'.format(new_signal_name.lower())
            else:
                signals_info[signal_name] = {}
                signals_info[signal_name].update(ini[signal_name])

                if _type.endswith('_mux'):
                    signals_info[signal_name]['name'] = '{}_i'.format(
                        signal_name.lower())
                elif _type.endswith('_out'):
                    signals_info[signal_name]['name'] = '{}_o'.format(
                        signal_name.lower())
                else:
                    signals_info[signal_name]['name'] = signal_name

                if ini[signal_name].get('wstb', False):
                    signals_info[signal_name]['wstb_name'] = '{}_wstb'.format(
                        signal_name.lower())
    return signals_info


async def section_timing_test(dut, timing_ini, test_name):
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
        wavedrom_filename = f'{test_name.replace(" ", "_")}_wavedrom.json'
        try:
            while ts <= last_ts:
                do_assignments(dut, assignments_schedule.get(ts, {}))
                conditions.update(conditions_schedule.get(ts, {}))
                await ReadOnly()
                check_conditions(dut, conditions)
                await clkedge
                ts += 1
        except AssertionError as error:
            with open(wavedrom_filename, 'w') as fhandle:
                fhandle.write(trace.dumpj())
            raise error
        else:
            with open(wavedrom_filename, 'w') as fhandle:
                fhandle.write(trace.dumpj())


@cocotb.test()
async def module_timing_test(dut):
    test_name = os.getenv('test_name', 'default')
    module = dut._name
    timing_ini = get_timing_ini(module)
    if test_name.strip() != '.':
        await section_timing_test(dut, timing_ini, test_name)


def get_module_build_args(module):
    module_dir_path = MODULES_PATH / module
    g = {'TOP_PATH': TOP_PATH}
    code = open(str(module_dir_path / 'test_config.py')).read()
    exec(code, g)
    g.get('EXTRA_BUILD_ARGS', [])
    extra_args = g.get('EXTRA_BUILD_ARGS', [])
    return extra_args


def get_module_hdl_files(module):
    module_dir_path = MODULES_PATH / module
    g = {'TOP_PATH': TOP_PATH}
    code = open(str(module_dir_path / 'test_config.py')).read()
    exec(code, g)
    g.get('EXTRA_HDL_FILES', [])
    extra_files = list(g.get('EXTRA_HDL_FILES', []))
    extra_files_2 = []
    for my_file in extra_files:
        if str(my_file).endswith('.vhd'):
            extra_files_2.append(my_file)
        else:
            extra_files_2 = extra_files_2 + list(my_file.glob('**/*.vhd'))
    result = extra_files_2 + list((module_dir_path / 'hdl').glob('*.vhd'))
    print('Gathering the following VHDL files:')
    for my_file in result:
        print(my_file)
    print()
    return result


def print_results(module, passed, failed, time=None):
    print('\nModule: {}'.format(module))
    if len(passed) + len(failed) == 0:
        print('\033[0;33m' + 'No tests ran.' + '\033[0m')
    else:
        percentage = round(len(passed) / (len(passed) + len(failed)) * 100)
        print('{}/{} tests passed ({}%).'.format(
            len(passed), len(passed) + len(failed), percentage))
        if time:
            print('Time taken = {}s.'.format(time))
        if failed:
            print('\033[0;31m' + 'Failed tests:' + '\x1b[0m', end=' ')
            print(*[test + (', ' if i < len(failed) - 1 else '.')
                    for i, test in enumerate(failed)])
        else:
            print('\033[92m' + 'ALL PASSED' + '\x1b[0m')


def summarise_results(results):
    failed = [module for module in results if results[module][1]]
    passed = [module for module in results if not results[module][1]]
    total_passed, total_failed = 0, 0
    for module in results:
        total_passed += len(results[module][0])
        total_failed += len(results[module][1])
    total = total_passed + total_failed
    print('\nSummary:\n')
    if total == 0:
        print('\033[1;33m' + 'No tests ran.' + '\033[0m')
    else:
        print('{}/{} modules passed ({}%).'.format(
            len(passed), len(results.keys()),
            round(len(passed) / len(results.keys()) * 100)))
        print('{}/{} tests passed ({}%).'.format(
            total_passed, total, round(total_passed / total * 100)))
        if failed:
            print('\033[0;31m' + '\033[1m' + 'Failed modules:' +
                  '\x1b[0m', end=' ')
            print(*[module + (', ' if i < len(failed) - 1 else '.')
                    for i, module in enumerate(failed)])
        else:
            print('\033[92m' + '\033[1m' + 'ALL MODULES PASSED' + '\x1b[0m')


def test_module(module, test_name=None):
    # args = get_args()
    logging.basicConfig(level=logging.DEBUG)
    timing_ini = get_timing_ini(module)
    if not Path(MODULES_PATH / module).is_dir():
        raise FileNotFoundError('No such directory: \'{}\''.format(
            Path(MODULES_PATH / module)))
    if test_name:
        if test_name in timing_ini.sections():
            sections = [test_name]
        else:
            print('No test called "{}" in {} INI timing file.'
                  .format(test_name, module)
                  .center(shutil.get_terminal_size().columns))
            return [], []
    else:
        sections = timing_ini.sections()
    sim = cocotb.runner.get_runner('ghdl')
    build_dir = f'sim_build_{module}'
    build_args = ['--std=08'] + get_module_build_args(module)
    sim.build(sources=get_module_hdl_files(module),
              build_dir=build_dir,
              hdl_toplevel=module,
              build_args=build_args)

    passed, failed = [], []

    for section in sections:
        if section.strip() != '.':
            test_name = section
            vcd_filename = '{}.vcd'.format(test_name.replace(' ', '_'))
            print()
            print('Test: "{}" in module {}.\n'.format(test_name, module))
            sim.test(hdl_toplevel=module,
                     test_module='cocotb_timing_test_runner',
                     build_dir=build_dir,
                     test_args=['--std=08'],
                     plusargs=['--vcd={}'.format(vcd_filename)],
                     extra_env={'test_name': test_name})
            xml_path = cocotb.runner.get_abs_path(f'{build_dir}/results.xml')
            results = cocotb.runner.get_results(xml_path)
            if results == (1, 0):
                # ran 1 test, 0 failed
                passed.append(test_name)
            elif results == (1, 1):
                # ran 1 test, 1 failed
                failed.append(test_name)
            else:
                raise ValueError(f'Results unclear: {results}')
    return passed, failed


def get_cocotb_testable_modules():
    modules = MODULES_PATH.glob('*/test_config.py')
    return list(module.parent.name for module in modules)


def run_tests():
    t_time_0 = time.time()
    args = get_args()
    if args.module.lower() == 'all':
        tests = get_cocotb_testable_modules()
    else:
        tests = [args.module]

    results = {}
    times = {}
    for module in tests:
        t0 = time.time()
        module = module.strip('\n')
        results[module] = [[], []]
        # [[passed], [failed]]
        print()
        print('* Testing module \033[1m{}\033[0m *'.format(module.strip("\n"))
              .center(shutil.get_terminal_size().columns))
        print('---------------------------------------------------'
              .center(shutil.get_terminal_size().columns))
        results[module][0], results[module][1] = \
            test_module(module, args.test_name)
        t1 = time.time()
        times[module] = round(t1 - t0, 2)
    print('___________________________________________________')
    print('\nResults:')
    for module in results:
        print_results(module, results[module][0], results[module][1],
                      times[module])
    print('___________________________________________________')
    summarise_results(results)
    t_time_1 = time.time()
    print('\nTime taken: {}s.'.format(round(t_time_1 - t_time_0, 2)))
    print('___________________________________________________\n')
    logging.basicConfig(level=logging.DEBUG)


def get_ip(module=None):
    if not module:
        modules = os.listdir(MODULES_PATH)
    else:
        modules = [module]
    ip = {}
    for module in modules:
        ini = get_block_ini(module)
        if not ini.sections():
            print('\033[1m' + f'No block INI file found in {module}!'
                  + '\033[0m')
            continue
        info = []
        if '.' in ini.keys():
            info = ini['.']
        spaces = ' ' + '-' * (16 - len(module)) + ' '
        if 'ip' in info:
            print('IP needed for module ' + '\033[1m' + module + '\033[0m:' +
                  spaces + '\033[0;33m' + info['ip'] + '\033[0m:')
            ip[module] = info['ip']
        else:
            print('IP needed for module ' + '\033[1m' + module
                  + '\033[0m:' + spaces + 'None found')
            ip[module] = None
    return ip


if __name__ == "__main__":
    args = get_args()
    if args.module.lower() == 'ip':
        ip = get_ip(args.test_name)
    else:
        run_tests()
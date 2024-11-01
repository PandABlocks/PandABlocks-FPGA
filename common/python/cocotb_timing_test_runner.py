#!/usr/bin/env python
import argparse
import configparser
import os
import logging
import shutil
import time
import coverage

from pathlib import Path
from typing import Dict, List

import cocotb
import cocotb.handle
import cocotb.runner
import cocotb.wavedrom
import cocotb.binary

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

from dma_driver import DMADriver


SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('module')
    parser.add_argument('test_name', nargs='?', default=None)
    parser.add_argument('--sim', default='ghdl')
    return parser.parse_args()


def read_ini(path: List[str] | str) -> configparser.ConfigParser:
    """Read INI file and return its contents.

    Args:
        path: Path to INI file.
    Returns:
        ConfigParser object containing INI file.
    """
    app_ini = configparser.ConfigParser()
    app_ini.read(path)
    return app_ini


def get_timing_ini(module):
    """Get a module's timing INI file.

    Args:
        module: Name of module.
    Returns:
        Contents of timing INI.
    """
    ini_path = (MODULES_PATH / module / '{}.timing.ini'.format(module))
    return read_ini(str(ini_path.resolve()))


def get_block_ini(module):
    """Get a module's block INI file.

    Args:
        module: Name of module.
    Returns:
        Contents of block INI.
    """
    ini_path = MODULES_PATH / module / '{}.block.ini'.format(module)
    return read_ini(str(ini_path.resolve()))


def is_input_signal(signals_info, signal_name):
    """Check if a signal is an input signal based on it's type.

    Args:
        signals_info: Dictionary containing information about signals.
        signal_name: Name of signal.
    Returns:
        True if signal is an input signal, otherwise False.
    """
    return not ('_out' in signals_info[signal_name]['type']
                or 'read' in signals_info[signal_name]['type']
                or 'valid_data' in signals_info[signal_name]['type'])


async def initialise_dut(dut, signals_info):
    """Initialise input signals to 0.
    Args:
        dut: cocotb dut object.
        signals_info: Dictionary containing information about signals.
    """
    for signal_name in signals_info.keys():
        dut_signal_name = signals_info[signal_name]['name']
        if is_input_signal(signals_info, signal_name):
            getattr(dut, '{}'.format(dut_signal_name)).value = 0
            wstb_name = signals_info[signal_name].get('wstb_name', '')
            if wstb_name:
                getattr(dut, wstb_name).value = 0


def parse_assignments(assignments):
    """Get assignements (or conditions) for a certain tick,
    from timing INI file format.

    Args:
        assignements: Assignments as written in timing INI file.
    Returns:
        Dictionary of assignments (or conditions).
    """
    result = {}
    for assignment in assignments.split(','):
        if assignment.strip() == '':
            continue
        signal_name, val = assignment.split('=')
        signal_name = signal_name.strip()
        if val.startswith('0x') or val.startswith('0X'):
            val = int(val[2:], 16)
        elif val.startswith('-0x') or val.startswith('-0X'):
            val = int(val[0] + val[3:], 16)
        else:
            val = int(val)
        result[signal_name] = val
    return result


def assign_bus(dut, name, val, index=None, bus_bits=None):
    # Unused
    lsb, msb = index * bus_bits, (index + 1) * bus_bits - 1
    getattr(dut, name)[lsb:msb].value = val


def assign(dut, name, val):
    """Assign value to a signal.

    Args:
        dut: cocotb dut object.
        name: Name of signal being assigned.
        val: Value being assigned to signal.
    """
    getattr(dut, name).value = val


def do_assignments(dut, assignments, signals_info):
    """Assign values to input signals.

    Args:
        dut: cocotb dut object.
        assignments: Dictionary of signals and values to assign to them.
        signals_info: Dictionary containing information about signals.
    """
    for signal_name, val in assignments.items():
        if '[' in signal_name:  # partial assignent to bus
            index = int(signal_name.split('[')[1][:-1])
            signal_name = signal_name.split('[')[0]
            n_bits = signals_info[get_ini_signal_name(
                signal_name, signals_info)]['bits']
            val = get_bus_value(getattr(dut, signal_name).value,
                                n_bits, val, index)
        assign(dut, signal_name, val)


def check_conditions(dut, conditions: Dict[str, int], ts):
    """Check value of output signals.

    Args:
        dut: cocotb dut object.
        conditions: Dictionary of signals and their expected values.
        ts: Current tick.
    """
    for signal_name, val in conditions.items():
        if val < 0:
            sim_val = getattr(dut, signal_name).value.signed_integer
        else:
            sim_val = getattr(dut, signal_name).value
        assert sim_val == val, 'Signal {} = {}, expecting {}. Ticks = {}'\
            .format(signal_name, sim_val, val, ts)


def update_conditions(conditions, conditions_to_update, signals_info):
    """Update dictionary of conditions with any needed for the current tick.
    Other than for signals of type 'valid_data', old conditions are propogated
    to the next tick, unless they are overwritten by a new condition.

    Args:
        conditions: Dictionary of conditions for the previous tick.
        conditions_to_update: Dictionary of conditions for current tick.
        signals_info: Dictionary containing information about signals.
    """
    for signal in dict(conditions).keys():
        ini_signal_name = get_ini_signal_name(signal, signals_info)
        if signals_info[ini_signal_name]['type'] == 'valid_data':
            conditions.pop(signal)
    conditions.update(conditions_to_update)
    return conditions


def get_signals(dut):
    """Get the names of signals in the dut.

    Args:
        dut: cocotb dut object.
    Returns:
        List of signal names.
    """
    return [getattr(dut, signal_name) for signal_name in dir(dut)
            if isinstance(getattr(dut, signal_name),
                          cocotb.handle.ModifiableObject)
            and not signal_name.startswith('_')]


def get_schedules(timing_ini, signals_info, test_name):
    """Get schedules for assignements and conditions for a test.

    Args:
        timing_ini: INI file containing timing tests.
        signals_info: Dictionary containing information about signals.
        test_name: Name of current test.
    Returns:
        Two dictionaries containing a schedule for assignments and conditions
        respectively for a certain test.
    """
    conditions_schedule, assignments_schedule = {}, {}
    for ts_str, line in timing_ini.items(test_name):
        ts = int(ts_str)
        for i in (ts, ts + 1):
            assignments_schedule.setdefault(i, {})
            conditions_schedule.setdefault(i, {})
        parts = line.split('->')
        for sig_name, val in parse_assignments(parts[0]).items():
            index = f'[{sig_name.split("[")[1]}' if '[' in sig_name else ''
            sig_name = sig_name[:len(sig_name) - len(index)]
            name = signals_info.get(sig_name)['name']
            assignments_schedule[ts][name + index] = val
            wstb_name = signals_info.get(sig_name).get('wstb_name')
            if wstb_name is not None:
                assignments_schedule[ts][wstb_name] = 1
                assignments_schedule[ts + 1].update({wstb_name: 0})

        if len(parts) > 1:
            conditions_schedule[ts + 1] = {}
            for sig_name, val in parse_assignments(parts[1]).items():
                name = signals_info.get(sig_name)['name']
                conditions_schedule[ts + 1][name] = val
    return assignments_schedule, conditions_schedule


def get_signals_info(block_ini):
    """Get information about signals from a module's block INI file, including
    a mapping between signal names in the INI files and VHDL files.

    Args:
        block_ini: INI file containing signals information.
    Returns:
        Dictionary containing signals information.
    """
    signals_info = {}
    expected_signal_names = [name for name in block_ini.sections()
                             if name != '.']
    for signal_name in expected_signal_names:
        if 'type' in block_ini[signal_name]:
            _type = block_ini[signal_name]['type'].strip()
            suffixes = []
            if _type == 'time':
                suffixes = ['_L', '_H']
            elif _type == 'table short':
                suffixes = ['_START', '_DATA', '_LENGTH']
            elif _type == 'table':
                suffixes = ['_ADDRESS', '_LENGTH']
            if suffixes:
                for suffix in suffixes:
                    new_signal_name = f'{signal_name}{suffix}'
                    signals_info[new_signal_name] = {}
                    signals_info[new_signal_name].update(
                        block_ini[signal_name])
                    signals_info[new_signal_name]['name'] = new_signal_name
                    if block_ini[signal_name].get('wstb', False):
                        signals_info[new_signal_name]['wstb_name'] = \
                            '{}_wstb'.format(new_signal_name.lower())
            else:
                signals_info[signal_name] = {}
                signals_info[signal_name].update(block_ini[signal_name])

                if _type.endswith('_mux'):
                    signals_info[signal_name]['name'] = '{}_i'.format(
                        signal_name.lower())
                elif _type.endswith('_out'):
                    signals_info[signal_name]['name'] = '{}_o'.format(
                        signal_name.lower())
                else:
                    signals_info[signal_name]['name'] = signal_name

                if block_ini[signal_name].get('wstb', False):
                    signals_info[signal_name]['wstb_name'] = '{}_wstb'.format(
                        signal_name.lower())
    return signals_info


def get_ini_signal_name(name, signals_info):
    """Get signal name as seen in the INI files from the VHDL signal name.

    Args:
        name: VHDL signal name.
    Returns:
        Signal name as it appears in the INI files.
    """
    for key, info in signals_info.items():
        if info['name'] == name:
            return key
    return None


def check_signals_info(signals_info):
    """Check there are no duplicate signal names in signals_info dictionary.

    Args:
        signals_info: Dictionary containing information about signals.
    """
    signal_names = []
    for signal_info in signals_info.values():
        if signal_info['name'] in signal_names:
            raise ValueError(
                'Duplicate signal names in signals info dictionary.')
        else:
            signal_names.append(signal_info['name'])


def block_has_dma(block_ini):
    """Check if module requires a dma to work.

    Args:
        block_ini: INI file containing signals information about a module.
    """
    return block_ini['.'].get('type', '') == 'dma'


def block_is_pcap(block_ini):
    """Check if module is pcap.

    Args:
        block_ini: INI file containing signals information about a module.
    """
    return block_ini['.'].get('type') == 'pcap'


def get_bus_value(current_value, n_bits, value, index):
    """When doing a partial assignent to a bus, get the value we need to
    assign to the entire bus. This is needed as partial assignment appears to
    not be supported.

    Args:
        current value: Current value of bus signal.
        n_bits: Number of bits each index refers to.
        value: Value we are attemping to assign to part of the bus.
        index: Bus index at which we are attempting to assign.
    Returns:
        Value to assign to an entire bus to assign the intended value to the
        correct index, while keeping all other indexes unchanged.
    """
    val_copy = value
    capacity = 2**n_bits
    if value < 0:
        value += capacity
    if value < 0 or value >= capacity:
        raise ValueError(f'Value {val_copy} too large in magnitude for ' +
                         f'{n_bits} bit allocation on bus.')
    value_at_index = ((capacity - 1) << n_bits*index) & current_value
    new_value_at_index = value << n_bits*index
    return current_value - value_at_index + new_value_at_index


def get_extra_signals_info(module):
    """Get extra signals information from a module's test config file.

    Args:
        module: Name of module.
    Returns:
        Dictionary containing extra signals information.
    """
    module_dir_path = MODULES_PATH / module
    g = {'TOP_PATH': TOP_PATH}
    code = open(str(module_dir_path / 'test_config.py')).read()
    exec(code, g)
    extra_signals_info = g.get('EXTRA_SIGNALS_INFO', {})
    return extra_signals_info


def get_module_build_args(module):
    """Get simulation build arguments from a module's test config file.

    Args:
        module: Name of module.
    Returns:
        List of extra build arguments.
    """
    module_dir_path = MODULES_PATH / module
    g = {'TOP_PATH': TOP_PATH}
    code = open(str(module_dir_path / 'test_config.py')).read()
    exec(code, g)
    extra_args = g.get('EXTRA_BUILD_ARGS', [])
    return extra_args


def order_hdl_files(hdl_files, build_dir, top_level):
    command = f'vhdeps dump {top_level} -o {TOP_PATH / build_dir / "order"}'
    for file in hdl_files:
        command += f' --include={str(file)}'
    os.system(command)
    try:
        with open(TOP_PATH / build_dir / 'order') as order:
            ordered_hdl_files = [line.strip().split(' ')[-1] for line in order.readlines()]
    except FileNotFoundError as error:
        print(f'Likely that the following command failed:\n{command}')
        print('HDL FILES HAVE NOT BEEN PUT INTO COMPILATION ORDER!')
        return hdl_files
    return ordered_hdl_files


def get_module_hdl_files(module, top_level, build_dir):
    """Get HDL files needed to simulate a module from its test config file.

    Args:
        module: Name of module.
    Returns:
        List of paths to the HDL files.
    """
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
    result = order_hdl_files(result, build_dir, top_level)
    print('Gathering the following VHDL files:')
    for my_file in result:
        print(my_file)
    print()
    return result


def get_module_top_level(module):
    """Get top level entity from a module's test config file.
    If none is found, assume top level entity is the same as the module name.

    Args:
        module: Name of module.
    Returns:
        Name of top level entity.
    """
    module_dir_path = MODULES_PATH / module
    g = {'TOP_PATH': TOP_PATH}
    code = open(str(module_dir_path / 'test_config.py')).read()
    exec(code, g)
    top_level = g.get('TOP_LEVEL', None)
    if top_level:
        return top_level
    return module


def print_results(module, passed, failed, time=None):
    """Format and print results from a module's tests.

    Args:
        module: Name of module.
        passed: List of the names of tests that passed.
        failed: List of the names of tests that failed.
        time: Time taken to run the tests.
    """
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
    """Format and print summary of results from a test run.

    Args:
        Results: Dictionary of all results from a test run.
    """
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


async def simulate(dut, assignments_schedule, conditions_schedule, signals_info):
    last_ts = max(max(assignments_schedule.keys()),
                  max(conditions_schedule.keys()))
    clkedge = RisingEdge(dut.clk_i)
    cocotb.start_soon(Clock(
        dut.clk_i, 1, units="ns").start(start_high=False))
    ts = 0
    await initialise_dut(dut, signals_info)
    await clkedge
    conditions = {}
    
    while ts <= last_ts:
        do_assignments(dut, assignments_schedule.get(ts, {}),
                        signals_info)
        update_conditions(conditions, conditions_schedule.get(ts, {}),
                            signals_info)
        await ReadOnly()
        check_conditions(dut, conditions, ts)
        await clkedge
        ts += 1


async def section_timing_test(dut, module, test_name, block_ini, timing_ini, simulator):
    """Perform one test.

    Args:
        dut: cocotb dut object.
        module: Name of module we are testing.
        test_name: Name of test we are applying to the module.
        block_ini: INI file containing information about the module's signals.
        timing_ini: INI file containing timing tests.
    """
    if block_has_dma(block_ini):
        dma_driver = DMADriver(dut, module)

    signals_info = get_signals_info(block_ini)
    signals_info.update(get_extra_signals_info(module))
    check_signals_info(signals_info)

    assignments_schedule, conditions_schedule = \
        get_schedules(timing_ini, signals_info, test_name)

    if simulator == 'nvc' and module in ['pcap', 'pcomp', 'pgen', 'seq']:
        await simulate(dut, assignments_schedule, conditions_schedule, signals_info)
    else:
        with cocotb.wavedrom.trace(*get_signals(dut), clk=dut.clk_i) as trace:
            wavedrom_filename = '{}_wavedrom.json'.format(
            test_name.replace(" ", "_").replace("/", "_"))
            try:
                await simulate(dut, assignments_schedule, conditions_schedule, signals_info)
            except AssertionError as error:
                with open(wavedrom_filename, 'w') as fhandle:
                    fhandle.write(trace.dumpj())
                raise error
            else:
                with open(wavedrom_filename, 'w') as fhandle:
                    fhandle.write(trace.dumpj())


@cocotb.test()
async def module_timing_test(dut):
    """Function with cocotb test decorator that cocotb calls to run tests.

    Args:
        dut: cocotb dut object.
    """
    module = os.getenv('module', 'default')
    test_name = os.getenv('test_name', 'default')
    simulator = os.getenv('simulator', 'default')
    block_ini = get_block_ini(module)
    timing_ini = get_timing_ini(module)
    if test_name.strip() != '.':
        await section_timing_test(
            dut, module, test_name, block_ini, timing_ini, simulator)


def get_simulator_build_args(simulator, module):
    if simulator == 'ghdl':
        return ['--std=08', '-fsynopsys', '-Wno-hide']
    elif simulator == 'nvc':
        return ['--std=2008']


def get_test_args(simulator, build_args, test_name):
    test_name = test_name.replace(' ', '_').replace('/', '_')
    if simulator == 'ghdl':
        return build_args
    elif simulator == 'nvc':
        return [ '--ieee-warnings=off', f'--wave={test_name}.vcd']


def get_plus_args(simulator, test_name):
    test_name = test_name.replace(' ', '_').replace('/', '_')
    vcd_filename = f'{test_name}.vcd'
    if simulator == 'ghdl':
        return [f'--vcd={vcd_filename}']
    elif simulator == 'vcd':
        return []
    return []


def test_module(module, test_name=None, simulator='ghdl'):
    """Run tests for a module.

    Args:
        module: Name of module.
        test_name: Name of specific test to run. If not specified, all tests
            for that module will be run.
    Returns:
        Lists of tests that passed and failed respectively.
    """
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
    sim = cocotb.runner.get_runner(simulator)
    build_dir = f'sim_build_{module}'
    build_args = get_simulator_build_args(simulator, module)
    build_args += get_module_build_args(module)
    top_level = get_module_top_level(module)
    sim.build(sources=get_module_hdl_files(module, top_level, build_dir),
              build_dir=build_dir,
              hdl_toplevel=top_level,
              build_args=build_args,
              clean=True)
    passed, failed = [], []

    for section in sections:
        if section.strip() != '.':
            test_name = section
            vcd_filename = '{}.vcd'.format(
                test_name.replace(' ', '_').replace('/', '_'))
            print()
            print('Test: "{}" in module {}.\n'.format(test_name, module))
            xml_path = sim.test(hdl_toplevel=top_level,
                                test_module='cocotb_timing_test_runner',
                                build_dir=build_dir,
                                test_args=get_test_args(simulator, build_args, test_name),
                                plusargs=get_plus_args(simulator, test_name),
                                extra_env={'module': module,
                                           'test_name': test_name,
                                           'simulator': simulator,
                                           'coverage': 'True'})
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
    """Get list of modules that contain a test config file.

    Returns:
        List of names of testable modules.
    """
    modules = MODULES_PATH.glob('*/test_config.py')
    return list(module.parent.name for module in modules)


def run_tests():
    """Perform test run.
    """
    t_time_0 = time.time()
    args = get_args()
    if args.module.lower() == 'all':
        modules = get_cocotb_testable_modules()
    else:
        modules = args.module.split(',')
    simulator = args.sim
    results = {}
    times = {}
    for module in modules:
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
            test_module(module, test_name=args.test_name, simulator=simulator)
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
    print(f'Simulator: {simulator}\n')


def get_ip(module=None, quiet=True):
    if not module:
        modules = os.listdir(MODULES_PATH)
    else:
        modules = [module]
    ip = {}
    for module in modules:
        ini = get_block_ini(module)
        if not ini.sections():
            if not quiet:
                print('\033[1m' + f'No block INI file found in {module}!'
                      + '\033[0m')
            continue
        info = []
        if '.' in ini.keys():
            info = ini['.']
        spaces = ' ' + '-' * (16 - len(module)) + ' '
        if 'ip' in info:
            ip[module] = info['ip']
            if not quiet:
                print('IP needed for module \033[1m' + module + '\033[0m:' +
                      spaces + '\033[0;33m' + info['ip'] + '\033[0m')
        else:
            ip[module] = None
            if not quiet:
                print('IP needed for module ' + '\033[1m' + module
                      + '\033[0m:' + spaces + 'None found')
    return ip


def check_timing_ini(module=None, quiet=True):
    if not module:
        modules = os.listdir(MODULES_PATH)
    else:
        modules = [module]
    has_timing_ini = {}
    for module in modules:
        ini = get_timing_ini(module)
        if not ini.sections():
            has_timing_ini[module] = False
            if not quiet:
                print('\033[0;33m' +
                      f'No timing INI file found in - \033[1m{module}\033[0m')
        else:
            has_timing_ini[module] = True
            if not quiet:
                print(f'Timing ini file found in ---- \033[1m{module}\033[0m')
    return has_timing_ini


def get_some_info():
    ini_and_ip = []
    ini_no_ip = []
    no_ini = []
    has_timing_ini = check_timing_ini()
    has_ip = get_ip()
    for module in has_timing_ini.keys():
        if has_timing_ini[module]:
            if has_ip[module]:
                ini_and_ip.append(module)
            else:
                ini_no_ip.append(module)
        else:
            no_ini.append(module)
    print('\nModules with no timing INI:')
    for i, module in enumerate(no_ini):
        print(f'{i + 1}. {module}')
    print('\nModules with timing INI and IP:')
    for i, module in enumerate(ini_and_ip):
        print(f'{i + 1}. {module}')
    print('\nModules with timing INI and no IP:')
    for i, module in enumerate(ini_no_ip):
        print(f'{i + 1}. {module}')


def main():
    args = get_args()
    if args.module.lower() == 'ip':
        get_ip(args.test_name, quiet=False)
    elif args.module.lower() == 'ini':
        check_timing_ini(quiet=False)
    elif args.module.lower() == 'info':
        get_some_info()
    else:
        run_tests()


if __name__ == "__main__":
    main()

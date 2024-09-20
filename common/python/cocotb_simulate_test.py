#!/usr/bin/env python
import configparser
import os
import logging
import csv
import pandas as pd

from pathlib import Path
from typing import Dict, List

import cocotb
import cocotb.handle

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

from dma_driver import DMADriver

logger = logging.getLogger(__name__)

SCRIPT_DIR_PATH = Path(__file__).parent.resolve()
TOP_PATH = SCRIPT_DIR_PATH.parent.parent
MODULES_PATH = TOP_PATH / 'modules'


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


def get_timing_inis(module):
    """Get a module's timing ini files.

    Args:
        module: Name of module.
    Returns:
        Dictionary of filepath: file contents for any timing.ini files in the
        module directory.
    """
    ini_paths = (MODULES_PATH / module).glob('*.timing.ini')
    return {str(path): read_ini(str(path.resolve())) for path in ini_paths}


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


def assign_bus(dut, name, val, index, n_bits):
    # Unused
    lsb, msb = index * n_bits, (index + 1) * n_bits - 1
    getattr(dut, name).value[msb:lsb] = val


def assign(dut, name, val):
    """Assign value to a signal.

    Args:
        dut: cocotb dut object.
        name: Name of signal being assigned.
        val: Value being assigned to signal.
    """
    getattr(dut, name).set(val)


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
            val = get_bus_value(int(getattr(dut, signal_name).value),
                                n_bits, val, index)
        assign(dut, signal_name, val)


def check_conditions(dut, conditions: Dict[str, int], ts):
    """Check value of output signals.

    Args:
        dut: cocotb dut object.
        conditions: Dictionary of signals and their expected values.
        ts: Current tick.
    """
    errors = []
    values = {}
    for signal_name, val in conditions.items():
        if val < 0:
            sim_val = getattr(dut, signal_name).value.signed_integer
        else:
            sim_val = getattr(dut, signal_name).value
        values[signal_name] = (int(val), int(sim_val))
        if sim_val != val:
            error = 'Signal {} = {}, expecting {}. Ticks = {}'\
            .format(signal_name, sim_val, val, ts)
            dut._log.error(error)
            errors.append(error)
    return errors, values



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
        signals_info: Dictionary containing information about signals.
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


def get_extra_signals_info(module, panda_build_dir):
    """Get extra signals information from a module's test config file.

    Args:
        module: Name of module.
        panda_build_dir: Path to autogenerated HDL files
    Returns:
        Dictionary containing extra signals information.
    """
    test_config_path = MODULES_PATH / module / 'test_config.py'
    if test_config_path.exists():
        g = {'TOP_PATH': TOP_PATH,
            'BUILD_PATH': Path(panda_build_dir)}
        with open(str(test_config_path)) as file:
            code = file.read()
        exec(code, g)
        extra_signals_info = g.get('EXTRA_SIGNALS_INFO', {})
        return extra_signals_info
    return {}


async def simulate(dut, assignments_schedule, conditions_schedule,
                   signals_info, collect):
    """Run the simulation according to the schedule found in timing ini.
    
    Args:
        dut: cocotb dut object.
        assignments_schedule: Schedule for signal assignments.
        conditions_schedule: Schedule for checking conditions.
        signals_info: Dictionary containing information about signals.
        collect: Collect signals expected and actual values when True.
    Returns:
        Dictionaries containing signal values and timing errors.
    """
    last_ts = max(max(assignments_schedule.keys()),
                  max(conditions_schedule.keys()))
    clkedge = RisingEdge(dut.clk_i)
    cocotb.start_soon(Clock(
        dut.clk_i, 1, units="ns").start(start_high=False))
    ts = 0
    await initialise_dut(dut, signals_info)
    await clkedge
    conditions = {}
    timing_errors = {}
    values = {}
    while ts <= last_ts:
        do_assignments(dut, assignments_schedule.get(ts, {}),
                       signals_info)
        update_conditions(conditions, conditions_schedule.get(ts, {}),
                          signals_info)
        await ReadOnly()
        errors, values[ts] = check_conditions(dut, conditions, ts)
        if errors:
            timing_errors[ts] = errors
        await clkedge
        ts += 1
    return values, timing_errors


def collect_values(values, test_name):
    """Saves collected signal values to csv and html.
    
    Args:
        values: Dictionary of signal values to save.
        test_name: Name of test.
    """
    filename = f'{test_name.replace(' ', '_').replace('/', '_')}_values'
    values_df = pd.DataFrame(values)
    values_df = values_df.transpose()
    values_df.index.name = 'tick'
    values_df.to_csv(f'{Path.cwd()}/{filename}.csv', index=True)
    values_df.to_html(f'{Path.cwd()}/{filename}.html')


async def section_timing_test(dut, module, test_name, block_ini, timing_ini,
                              panda_build_dir, collect=True):
    """Perform one test.

    Args:
        dut: cocotb dut object.
        module: Name of module we are testing.
        test_name: Name of test we are applying to the module.
        block_ini: INI file containing information about the module's signals.
        timing_ini: INI file containing timing tests.
        collect: Collect signals expected and actual values when True.
    """
    if block_has_dma(block_ini):
        dma_driver = DMADriver(dut, module)

    signals_info = get_signals_info(block_ini)
    signals_info.update(get_extra_signals_info(module, panda_build_dir))
    check_signals_info(signals_info)

    assignments_schedule, conditions_schedule = \
        get_schedules(timing_ini, signals_info, test_name)

    values, timing_errors = await simulate(dut, assignments_schedule,
                                   conditions_schedule, signals_info,
                                   collect)

    if timing_errors:
        filename = f'{test_name.replace(' ', '_').replace('/', '_')}_errors.csv'
        with open(filename, mode='w', newline='', encoding='utf-8') as file:
            writer = csv.writer(file)
            for tick, messages in timing_errors.items():
                for message in messages:
                    writer.writerow([tick, message])
        dut._log.info(f'Errors written to {filename}')
    if collect:
        collect_values(values, test_name)

    assert not timing_errors, 'Timing errors found, see above.'


@cocotb.test()
async def module_timing_test(dut):
    """Function with cocotb test decorator that cocotb calls to run tests.

    Args:
        dut: cocotb dut object.
    """
    module = os.getenv('module')
    test_name = os.getenv('test_name')
    simulator = os.getenv('simulator')
    sim_build_dir = os.getenv('sim_build_dir')
    panda_build_dir = os.getenv('panda_build_dir')
    timing_ini_path = os.getenv('timing_ini_path')
    collect = True if os.getenv('collect') == 'True' else False
    block_ini = get_block_ini(module)
    timing_inis = get_timing_inis(module)
    timing_ini = timing_inis[timing_ini_path]
    if test_name.strip() != '.':
        await section_timing_test(
            dut, module, test_name, block_ini, timing_ini, panda_build_dir,
            collect)
#!/usr/bin/env python
import sys

from cocotb_tools.runner import get_runner
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent.resolve()))
from cocotb_timing_test_runner import order_hdl_files


def get_top():
    current = Path(__file__).parent.resolve()
    while not (current / '.git').exists():
        current = current.parent

    return current


def run_testtarget(test_module, fpga_path,  build_path, dump_waveform=False):
    autogen_path = build_path / 'apps' / 'testtarget' / 'autogen'
    sources = order_hdl_files(get_dependencies(fpga_path, autogen_path),
                              build_path,
                              'testtarget_top')
    runner = get_runner('nvc')
    runner.build(sources=sources,
                 build_args=[
                     '--std=2008',
                 ],
                 build_dir=f'{str(build_path)}/sim_{test_module}',
                 hdl_toplevel='testtarget_top',
                 always=True,
                 clean=True,
                 )
    runner.test(hdl_toplevel='testtarget_top',
                test_args=[
                    '--ieee-warnings=off',
                ] + ([
                    '--wave=wave.fst',
                    '--dump-arrays',
                ] if dump_waveform else []),
                extra_env={
                    'FPGA_PATH': str(fpga_path),
                    'AUTOGEN_PATH': str(autogen_path),
                },
                test_module=test_module)


def get_dependencies(fpga_path, autogen_path):
    sources = \
        [
            fpga_path / 'common' / 'hdl' / 'defines' / name for name in
                ('top_defines.vhd', 'support.vhd', 'operator.vhd')
        ] + \
        [
            fpga_path / 'common' / 'hdl' / name for name in
                ('reg_top.vhd', 'reg.vhd', 'axi_lite_slave.vhd',
                 'axi_read_master.vhd', 'delay_line.vhd', 'bitmux.vhd',
                 'posmux.vhd', 'spbram.vhd', 'fifo.vhd')
        ] + \
        list(fpga_path.glob('common/hdl/table_read_engine*.vhd')) + \
        list(autogen_path.glob('hdl/*.vhd')) + \
        list(fpga_path.glob('modules/pcap/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/bits/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/calc/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/clock/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/counter/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/div/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/filter/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/lut/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/pcomp/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/pulse/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/seq/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/pgen/hdl/*.vhd')) + \
        list(fpga_path.glob('modules/srgate/hdl/*.vhd')) + \
        list(fpga_path.glob('targets/testtarget/hdl/*.vhd'))

    for s in sources:
        if not s.exists():
            raise FileNotFoundError(f'Required source file not found: {s}')

    return sources

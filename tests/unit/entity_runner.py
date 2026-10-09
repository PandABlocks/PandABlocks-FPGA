from pathlib import Path

from cocotb_tools.runner import get_runner

from cocotb_timing_test_runner import order_hdl_files

TOP = Path(__file__).parents[2]


def run_entity_test(test_module, toplevel, sources, build_dir,
                    parameters=None, waves=False):
    """Simulate a single VHDL entity with NVC and run the cocotb tests in
    test_module against it.

    Args:
        test_module: Name of the Python module holding the cocotb tests.
        toplevel: Name of the VHDL entity under test.
        sources: VHDL files needed by the entity, relative to the repo root.
        build_dir: Base build directory, each test builds in its own subdir.
        parameters: Generics to set on the entity.
        waves: Dump a wave.fst waveform in the test build directory.
    """
    sim_build_dir = Path(build_dir) / f'unit_{test_module}'
    sources = [TOP / source for source in sources]
    for source in sources:
        if not source.exists():
            raise FileNotFoundError(f'Required source file not found: {source}')

    runner = get_runner('nvc')
    runner.build(sources=order_hdl_files(sources, sim_build_dir, toplevel),
                 build_args=['--std=2008'],
                 build_dir=sim_build_dir,
                 hdl_toplevel=toplevel,
                 always=True,
                 clean=True,
                 )
    runner.test(hdl_toplevel=toplevel,
                test_module=test_module,
                parameters=parameters or {},
                test_args=['--ieee-warnings=off'] +
                (['--wave=wave.fst', '--dump-arrays'] if waves else []),
                )

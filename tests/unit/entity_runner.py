import shutil
import subprocess
from pathlib import Path

from cocotb_tools.runner import get_runner

from cocotb_timing_test_runner import order_hdl_files

TOP = Path(__file__).parents[2]


def _check_sources(sources):
    sources = [TOP / source for source in sources]
    for source in sources:
        if not source.exists():
            raise FileNotFoundError(f'Required source file not found: {source}')
    return sources


def run_entity_test(test_module, toplevel, sources, build_dir,
                    parameters=None, waves=False, libraries=None):
    """Simulate a single VHDL entity with NVC and run the cocotb tests in
    test_module against it.

    Args:
        test_module: Name of the Python module holding the cocotb tests.
        toplevel: Name of the VHDL entity under test.
        sources: VHDL files needed by the entity, relative to the repo root.
        build_dir: Base build directory, each test builds in its own subdir.
        parameters: Generics to set on the entity.
        waves: Dump a wave.fst waveform in the test build directory.
        libraries: Extra VHDL libraries the sources use, as a dict of library
            name to its source files relative to the repo root, for example
            simulation stand-ins for Xilinx primitives in a unisim library.
    """
    sim_build_dir = Path(build_dir) / f'unit_{test_module}'
    sources = _check_sources(sources)
    libraries = {name: _check_sources(files)
                 for name, files in (libraries or {}).items()}

    # Start from a clean build directory, the extra libraries have to be
    # compiled into it before the runner builds the sources
    if sim_build_dir.exists():
        shutil.rmtree(sim_build_dir)
    sim_build_dir.mkdir(parents=True)
    for name, files in libraries.items():
        subprocess.run(
            ['nvc', '--std=2008', '-L', str(sim_build_dir),
             f'--work={name}:{sim_build_dir / name}', '-a']
            + [str(source) for source in files], check=True)

    runner = get_runner('nvc')
    # IEEE warnings about metavalues before reset are noise, nvc only
    # honours the option as a global one, which build_args are
    runner.build(sources=order_hdl_files(sources, sim_build_dir, toplevel,
                                         libraries),
                 build_args=['--std=2008', '--ieee-warnings=off'],
                 build_dir=sim_build_dir,
                 hdl_toplevel=toplevel,
                 always=True,
                 clean=False,
                 )
    runner.test(hdl_toplevel=toplevel,
                test_module=test_module,
                parameters=parameters or {},
                test_args=['--wave=wave.fst', '--dump-arrays'] if waves else [],
                )

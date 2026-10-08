import sys
from pathlib import Path

import pytest

# The harness lives with the testtarget infrastructure (shared with sim_server).
# cocotb forwards sys.path to the simulator via PYTHONPATH, so the test modules
# can import it there too.
TESTTARGET_DIR = Path(__file__).parents[2] / 'common' / 'python' / 'testtarget'
sys.path.insert(1, str(TESTTARGET_DIR.resolve()))


def pytest_addoption(parser):
    parser.addoption("--build-dir", action="store")


@pytest.fixture(scope="module")
def build_dir(request):
    return request.config.getoption("--build-dir")

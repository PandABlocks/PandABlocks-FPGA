import pytest

def pytest_addoption(parser):
    parser.addoption("--sim", action="store", default="nvc")
    parser.addoption("--panda-build-dir", action="store", default="/build")
    parser.addoption("--skip", action="store", default="")
    parser.addoption("--collect", action="store_true")

@pytest.fixture(scope="module")
def sim(request):
    return request.config.getoption("--sim")

@pytest.fixture(scope="module")
def panda_build_dir(request):
    return request.config.getoption("--panda-build-dir")

@pytest.fixture(scope="module")
def skip(request):
    return request.config.getoption("--skip")

@pytest.fixture(scope="module")
def collect(request):
    return request.config.getoption("--collect")

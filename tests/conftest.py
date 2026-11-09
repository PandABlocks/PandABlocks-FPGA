import pytest


def pytest_addoption(parser):
    parser.addoption("--build-dir", action="store")


@pytest.fixture(scope="module")
def build_dir(request):
    return request.config.getoption("--build-dir")

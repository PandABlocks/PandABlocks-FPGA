import os
import shutil
import unittest
from common.python.generate_app import AppGenerator


TEST_DATA = os.path.join(os.path.dirname(__file__), "test_data_calc_extensions")


class TestCalcApp(unittest.TestCase):
    maxDiff = None
    app_build_dir = None

    @classmethod
    def setUpClass(cls):
        here = os.path.dirname(__file__)
        path= "tests/python/test_data_calc_extensions"
        app = os.path.join(here, "test_data_calc_extensions", "calc_extension.app.ini")
        cls.app_build_dir = "/tmp/test_app_calc_extensions_build_dir"
        if os.path.exists(cls.app_build_dir):
            shutil.rmtree(cls.app_build_dir)
        cls.expected_dir = os.path.join(here, "test_data_calc_extensions", "app-expected")
        AppGenerator(app, cls.app_build_dir, testPath=path)

    @classmethod
    def tearDownClass(cls):
        if os.path.exists(cls.app_build_dir):
            shutil.rmtree(cls.app_build_dir)

    def assertGeneratedEqual(self, *path):
        with open(os.path.join(self.expected_dir, *path)) as f:
            expected = f.read()
        with open(os.path.join(self.app_build_dir, *path)) as f:
            actual = f.read()
        self.assertMultiLineEqual(expected, actual)

    def test_description(self):
        self.assertGeneratedEqual("config_d", "description")

    def test_config(self):
        self.assertGeneratedEqual("config_d", "config")

    def test_registers(self):
        self.assertGeneratedEqual("config_d", "registers")


if __name__ == '__main__':
    unittest.main()

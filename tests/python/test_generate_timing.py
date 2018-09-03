import os
import shutil
import unittest
from common.python.generate_hdl_timing import HdlTimingGenerator


class TestGenerateTiming(unittest.TestCase):
    maxDiff = None
    build_dir = None

    @classmethod
    def setUpClass(cls):
        here = os.path.dirname(__file__)
        timing = os.path.join(here, "test_data", "test.timing.ini")
        cls.build_dir = "/tmp/test_timing_build_dir"
        cls.expected_dir = os.path.join(here, "test_data", "timing-expected")
        HdlTimingGenerator(cls.build_dir, [timing])

    @classmethod
    def tearDownClass(cls):
        if os.path.exists(cls.build_dir):
            shutil.rmtree(cls.build_dir)

    def assertGeneratedEqual(self, *path):
        with open(os.path.join(self.expected_dir, *path)) as f:
            expected = f.read()
        with open(os.path.join(self.build_dir, *path)) as f:
            actual = f.read()
        self.assertMultiLineEqual(expected, actual)

    def test_first_timings(self):
        self.assertGeneratedEqual("timing001", "1testblockexpected.csv")

    def test_first_bench(self):
        self.assertGeneratedEqual("timing001", "hdl_timing.v")

    def test_second_timings(self):
        self.assertGeneratedEqual("timing002", "2testblockexpected.csv")

    def test_second_bench(self):
        self.assertGeneratedEqual("timing002", "hdl_timing.v")


if __name__ == '__main__':
    unittest.main()
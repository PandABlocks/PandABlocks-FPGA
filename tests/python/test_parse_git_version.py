import unittest
from common.python.parse_git_version import parse_git_version


class TestParseGitVersion(unittest.TestCase):
    def test_clean_value(self):
        self.assertEqual("00000300",
                         parse_git_version("0.3"))

    def test_dirty_value(self):
        self.assertEqual("00000300",
                         parse_git_version("0.3-dirty"))

    def test_clean_value_with_changes(self):
        self.assertEqual("0b000100",
                         parse_git_version("0.1-11-g5539563"))

    def test_dirty_value_with_changes(self):
        self.assertEqual("0b000100",
                         parse_git_version("0.1-11-g5539563-dirty"))

    def test_bad_value(self):
        with self.assertRaises(AssertionError):
            parse_git_version("loads_of_junk")


if __name__ == '__main__':
    unittest.main()

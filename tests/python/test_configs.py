import unittest

from common.python.configs import BlockConfig, FieldConfig


class TestConfigs(unittest.TestCase):
    def test_bad_block_name(self):
        with self.assertRaises(AssertionError) as cm:
            BlockConfig("LUT3", 1, True, None, None)
        self.assertEqual("Expected BLOCK_NAME with no trailing numbers, got 'LUT3'",
                         str(cm.exception))

    def test_bad_field_name(self):
        with self.assertRaises(AssertionError) as cm:
            FieldConfig("bad_field", 1, "param", "")
        self.assertEqual("Expected FIELD_NAME, got 'bad_field'",
                         str(cm.exception))

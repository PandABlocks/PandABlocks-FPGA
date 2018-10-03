import unittest

from common.python.configs import BlockConfig, FieldConfig, ParamEnumFieldConfig


class TestConfigs(unittest.TestCase):
    def test_bad_block_name(self):
        with self.assertRaises(AssertionError) as cm:
            BlockConfig("LUT3", 1, None)
        self.assertEqual("Expected BLOCK_NAME with no numbers, got 'LUT3'",
                         str(cm.exception))

    def test_bad_field_name(self):
        with self.assertRaises(AssertionError) as cm:
            FieldConfig("bad_field", 1, "param", "")
        self.assertEqual("Expected FIELD_NAME, got 'bad_field'",
                         str(cm.exception))

    # The restrictions on the param enum descriptions are no longer in place

#    def test_bad_enum(self):
#        extras = {
#            "0": "Bad Value"
#        }
#        f = ParamEnumFieldConfig("BADENUM", 1, "param enum", "", **extras)
#        with self.assertRaises(AssertionError) as cm:
#            list(f.extra_config_lines())
#        self.assertEqual("Expected enum_value, got 'Bad Value'",
#                         str(cm.exception))

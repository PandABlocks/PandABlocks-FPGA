import os
import shutil
import unittest
from common.python.generate_app import AppGenerator

expected_description = """LUT\tLookup table
\tFUNC\tInput func
\tA\tSource of the value of A for calculation
\tB\tSource of the value of B for calculation
\tC\tSource of the value of C for calculation
\tD\tSource of the value of D for calculation
\tE\tSource of the value of E for calculation
\tINPA\tInput A
\tINPB\tInput B
\tINPC\tInput C
\tINPD\tInput D
\tINPE\tInput E
\tOUT\tLookup table output

"""

expected_config = """*METADATA
    DESIGN      string
    LAYOUT      multiline
    EXPORTS     multiline

LUT[8]
\tFUNC\tparam\tlut
\tA\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tB\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tC\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tD\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tE\tparam\tenum
\t\t0\tInput Value
\t\t1\tRising Edge
\t\t2\tFalling Edge
\t\t3\tEither Edge
\tINPA\tbit_mux
\tINPB\tbit_mux
\tINPC\tbit_mux
\tINPD\tbit_mux
\tINPE\tbit_mux
\tOUT\tbit_out

"""

expected_registers = """# This special register block is not present in the config file and contains
# fixed register definitions used in the hardware interface.
# Alas, because hardware access occurs during the processing of this file, it
# is necessary to place this section at the start!
*REG        0
    #
    # FPGA Version and Build Identification Values
    #
    FPGA_VERSION            0
    FPGA_BUILD              1
    USER_VERSION            2
    # Bit bus readout registers: first write to BIT_READ_RST to capture a
    # snapshot of the bit bus and its changes, then read BIT_READ_VALUE 8 times
    # to read out bit bus values and change flags.
    BIT_READ_RST            3
    BIT_READ_VALUE          4

    # Position bus readout registers: first write to POS_READ_RST to snapshot
    # the position bus and the change set, then read POS_READ_VALUE 32 times to
    # read out the positions, and finally read the change set from
    # POS_READ_CHANGES.
    POS_READ_RST            5
    POS_READ_VALUE          6
    POS_READ_CHANGES        7

    # The capture set is written by first writing to PCAP_START_WRITE and then
    # writing the required changes to PCAP_WRITE
    PCAP_START_WRITE        8
    PCAP_WRITE              9

    # Position capture control
    PCAP_ARM                13
    PCAP_DISARM             14

    # This array of registers is used to program data delays on the capture bus
    PCAP_DATA_DELAY         32 .. 63


# These registers are used by the kernel driver to read the data capture stream.
# This block is not used by the server, but is here for documentation and other
# automated tools.
*DRV        1
    # This register is used to reset DMA engine.
    PCAP_DMA_RESET          0
    # This register is used to initialise DMA engine with first set of
    # addresses.
    PCAP_DMA_START          1
    # The physical address of each DMA block is written to this register.
    PCAP_DMA_ADDR           2
    # This register configures the maximum interval between capture interrupts
    PCAP_TIMEOUT            3
    # Interrupt status and acknowledge
    PCAP_IRQ_STATUS         4
    # DMA block size in bytes
    PCAP_BLOCK_SIZE         6

LUT\t2
\tFUNC\t0
\tA\t1
\tB\t2
\tC\t3
\tD\t4
\tE\t5
\tINPA\t6 7
\tINPB\t8 9
\tINPC\t10 11
\tINPD\t12 13
\tINPE\t14 15
\tOUT\t0 1 2 3 4 5 6 7

"""


class TestGenerateApp(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        app = os.path.join(os.path.dirname(__file__), "only-lut.ini")
        self.app_build_dir = "/tmp/test_app_build_dir"
        self.config_dir = os.path.join(self.app_build_dir, "config_d")
        AppGenerator(app, self.app_build_dir)

    def tearDown(self):
        if os.path.exists(self.app_build_dir):
            shutil.rmtree(self.app_build_dir)

    def test_lut_description(self):
        with open(os.path.join(self.config_dir, "descriptions")) as f:
            actual = f.read()
        self.assertMultiLineEqual(actual, expected_description)

    def test_lut_config(self):
        with open(os.path.join(self.config_dir, "config")) as f:
            actual = f.read()
        self.assertMultiLineEqual(actual, expected_config)

    def test_lut_register(self):
        with open(os.path.join(self.config_dir, "registers")) as f:
            actual = f.read()
        self.assertMultiLineEqual(actual, expected_registers)


if __name__ == '__main__':
    unittest.main()
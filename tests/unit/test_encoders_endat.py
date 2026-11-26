"""EnDat through the encoders entity of the PandABox encoder blocks, over a
model of the daughter card data transceivers in
tests/unit/encoders_endat_loopback.vhd: the INENC master looped back to the
OUTENC slave on a control card, and the INENC sniffer listening to an external
master and encoder on a monitor card."""

from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from entity_runner import run_entity_test

# A 1MHz EnDat clock and 100us frames at the 125MHz FPGA clock, which leaves
# room for the recovery time of the slave after a frame
CLK_PERIOD = 125
FRAME_PERIOD = 12500
# The master gives up on an answer after 1ms
TCAL_TIMEOUT = 125000
# Period of the external master's clock in ns
EXT_PERIOD = 128

PROTOCOL_ENDAT = 3
# Control daughter card reading back EnDat as the protocol of both encoders
DCARD_CONTROL = 0x00030302
DCARD_MONITOR = DCARD_CONTROL & ~0xE | (3 << 1)

HEALTH_OK = 0
HEALTH_TIMEOUT = 2
HEALTH_ERROR_BIT = 4
# OUTENC unused on a monitor card
OUTENC_HEALTH_UNUSED = 3

# Encoder send position value
MODE_COMMAND = [0, 0, 0, 1, 1, 1]

SOURCES = [
    'tests/unit/encoders_endat_loopback.vhd',
    'common/hdl/defines/top_defines.vhd',
    'common/hdl/defines/support.vhd',
    'common/hdl/encoders/encoders.vhd',
    'common/hdl/encoders/endat_master.vhd',
    'common/hdl/encoders/endat_slave.vhd',
    'common/hdl/encoders/endat_sniffer.vhd',
    'common/hdl/encoders/endat_crc.vhd',
    'common/hdl/encoders/biss_master.vhd',
    'common/hdl/encoders/biss_slave.vhd',
    'common/hdl/encoders/biss_sniffer.vhd',
    'common/hdl/encoders/biss_crc.vhd',
    'common/hdl/encoders/biss_clock_gen.vhd',
    'common/hdl/encoders/ssi_master.vhd',
    'common/hdl/encoders/ssi_slave.vhd',
    'common/hdl/encoders/ssi_sniffer.vhd',
    'common/hdl/encoders/ssi_error_detect.vhd',
    'common/hdl/ssi_clock_gen.vhd',
    'common/hdl/serial_link_detect.vhd',
    'common/hdl/shifter_in.vhd',
    'common/hdl/prescaler.vhd',
    'common/hdl/prescaler_pos.vhd',
    'common/hdl/qenc.vhd',
    'common/hdl/qencoder.vhd',
    'common/hdl/qdec.vhd',
    'common/hdl/qdecoder.vhd',
    'common/hdl/delay_filter.vhd',
    'common/hdl/iobuf_registered.vhd',
]
# Stand-in for the Xilinx IOBUF
LIBRARIES = {'unisim': ['tests/unit/unisim_sim.vhd']}


def endat_crc(bits):
    """CRC-5 x^5 + x^3 + x + 1, preset to ones, complemented remainder"""
    crc = 0x1F
    for bit in bits:
        inv = bit ^ (crc >> 4)
        crc = ((crc << 1) & 0x1F) ^ (0b01011 if inv else 0)
    return ~crc & 0x1F


class ExternalBus:
    """Model of an external EnDat master and its encoder on the bus a
    monitor card listens to. The clock idles high, data changes after the
    rising edges and is read on the falling edges. The encoder sends F1 low
    for an error, the default F1_ERROR_VALUE of the EnDat entities."""

    def __init__(self, dut, bits, position=0, tcal=3, tm_ns=1000,
                 gap_ns=3000):
        self.dut = dut
        self.bits = bits
        self.position = position
        self.tcal = tcal
        self.tm_ns = tm_ns
        self.gap_ns = gap_ns
        self.error = False
        self.dut.ext_drive_i.value = 1
        self.dut.ext_sck_i.value = 1
        self.dut.ext_dat_i.value = 0

    async def clocks(self, values):
        """One clock period per value, the value is driven on the data line
        after the rising edge. The clock is left high."""
        for value in values:
            self.dut.ext_sck_i.value = 0
            await Timer(EXT_PERIOD // 2, 'ns')
            self.dut.ext_sck_i.value = 1
            self.dut.ext_dat_i.value = value
            await Timer(EXT_PERIOD // 2, 'ns')

    async def position_frame(self):
        """A complete position request answered by the encoder"""
        payload = [0 if self.error else 1] + [
            (self.position >> i) & 1 for i in range(self.bits)]
        crc = endat_crc(payload)
        answer = [1] + payload + [(crc >> i) & 1 for i in range(4, -1, -1)]
        # One clock to latch, the six mode bits, the master releases the
        # line, the encoder holds it low for tcal and answers, one more
        # clock to read the last CRC bit, then the encoder holds the line
        # high for the recovery time and low again
        await self.clocks([0] + MODE_COMMAND + [0] + [0] * self.tcal +
                          answer + [1])
        await Timer(self.tm_ns, 'ns')
        self.dut.ext_dat_i.value = 0
        await Timer(self.gap_ns, 'ns')


def start_clock(dut):
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())


async def setup(dut, bits, position=0, outenc_protocol=PROTOCOL_ENDAT,
                dcard_mode=DCARD_CONTROL):
    """Reset with INENC as an EnDat master and OUTENC as an EnDat slave"""
    dut.reset_i.value = 1
    dut.INENC_PROTOCOL.value = PROTOCOL_ENDAT
    dut.INENC_ENCODING.value = 0
    dut.CLK_PERIOD.value = CLK_PERIOD
    dut.FRAME_PERIOD.value = FRAME_PERIOD
    dut.DELAY_COMP.value = 0
    dut.INENC_BITS.value = bits
    dut.OUTENC_PROTOCOL.value = outenc_protocol
    dut.OUTENC_BITS.value = bits
    dut.GENERATOR_ERROR.value = 0
    dut.posn_i.value = position
    dut.DCARD_MODE.value = dcard_mode
    dut.cable_i.value = 1
    dut.ext_drive_i.value = 0
    dut.ext_sck_i.value = 1
    dut.ext_dat_i.value = 0
    await ClockCycles(dut.clk_i, 8)
    dut.reset_i.value = 0


async def watch_line(dut):
    """Fail if the data line is ever driven from both ends, once the pads
    have settled after the start of the simulation"""
    await ClockCycles(dut.clk_i, 2)
    while True:
        await RisingEdge(dut.clk_i)
        assert str(dut.data_line_o.value) in ('0', '1', 'Z'), \
            'Data line driven from both ends'


def link_up(dut):
    return str(dut.STATUS_o.value)[-1] == '1'


def check_health(dut, health, outenc_health=HEALTH_OK):
    assert dut.INENC_HEALTH_o.value.to_unsigned() == health
    assert link_up(dut) == (health == HEALTH_OK)
    assert dut.HOMED_o.value.to_unsigned() == 1
    assert dut.OUTENC_HEALTH_o.value.to_unsigned() == outenc_health


async def read_positions(dut, bits):
    await setup(dut, bits)
    mask = (1 << bits) - 1
    for position in [0, 1, 1 << (bits - 1), mask, 0x5A5A5A5A & mask]:
        dut.posn_i.value = position
        # The slave latches the position at the start of a frame, allow for
        # the frame that may be in flight
        await ClockCycles(dut.clk_i, 2 * FRAME_PERIOD)
        assert dut.posn_o.value.to_unsigned() == position
        check_health(dut, HEALTH_OK)


@cocotb.test(timeout_time=5, timeout_unit='ms')
async def endat_position_read(dut):
    start_clock(dut)
    watcher = cocotb.start_soon(watch_line(dut))
    for bits in [13, 24, 32]:
        await read_positions(dut, bits)
    watcher.cancel()


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_error_bit(dut):
    start_clock(dut)
    watcher = cocotb.start_soon(watch_line(dut))
    await setup(dut, 24, position=1234)
    await ClockCycles(dut.clk_i, 2 * FRAME_PERIOD)
    assert dut.posn_o.value.to_unsigned() == 1234
    check_health(dut, HEALTH_OK)
    # The slave reports an error, the position is not updated
    dut.GENERATOR_ERROR.value = 1
    dut.posn_i.value = 4321
    await ClockCycles(dut.clk_i, 2 * FRAME_PERIOD)
    assert dut.posn_o.value.to_unsigned() == 1234
    check_health(dut, HEALTH_ERROR_BIT)
    dut.GENERATOR_ERROR.value = 0
    await ClockCycles(dut.clk_i, 2 * FRAME_PERIOD)
    assert dut.posn_o.value.to_unsigned() == 4321
    check_health(dut, HEALTH_OK)
    watcher.cancel()


@cocotb.test(timeout_time=4, timeout_unit='ms')
async def endat_no_encoder(dut):
    start_clock(dut)
    watcher = cocotb.start_soon(watch_line(dut))
    await setup(dut, 24, position=1234)
    await ClockCycles(dut.clk_i, 2 * FRAME_PERIOD)
    assert dut.posn_o.value.to_unsigned() == 1234
    check_health(dut, HEALTH_OK)
    # The encoder is unplugged. A frame in flight times out waiting for the
    # answer, then the master's transceiver reads the undriven line as high,
    # so the master never sees the line go low and does not start a frame,
    # which it reports as a timeout at the next frame pulse.
    dut.cable_i.value = 0
    await ClockCycles(dut.clk_i, TCAL_TIMEOUT + 2 * FRAME_PERIOD)
    assert dut.INENC_HEALTH_o.value.to_unsigned() == HEALTH_TIMEOUT
    assert not link_up(dut)
    for _ in range(FRAME_PERIOD):
        await RisingEdge(dut.clk_i)
        assert str(dut.data_line_o.value) == 'Z'
        assert str(dut.clk_line_o.value) == '1'
    # The encoder is back and holds the line low, the master reads it
    dut.cable_i.value = 1
    dut.posn_i.value = 4321
    await ClockCycles(dut.clk_i, 3 * FRAME_PERIOD)
    assert dut.posn_o.value.to_unsigned() == 4321
    check_health(dut, HEALTH_OK)
    watcher.cancel()


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_monitor_card_does_not_drive(dut):
    start_clock(dut)
    # On a monitor card the master and slave stay off the line, which is
    # left released, and the sniffer sees no frames
    await setup(dut, 24, position=1234, dcard_mode=DCARD_MONITOR)
    for _ in range(2 * FRAME_PERIOD):
        await RisingEdge(dut.clk_i)
        assert str(dut.data_line_o.value) == 'Z'
    assert dut.INENC_HEALTH_o.value.to_unsigned() == HEALTH_TIMEOUT
    assert not link_up(dut)
    assert dut.OUTENC_HEALTH_o.value.to_unsigned() == OUTENC_HEALTH_UNUSED


@cocotb.test(timeout_time=2, timeout_unit='ms')
async def endat_monitor_card_sniffs(dut):
    start_clock(dut)
    # On a monitor card the sniffer decodes the frames between an external
    # master and its encoder
    await setup(dut, 24, dcard_mode=DCARD_MONITOR)
    bus = ExternalBus(dut, 24, position=0x123456)
    # Let the input filters settle on the idle levels of the bus
    await ClockCycles(dut.clk_i, 16)
    await bus.position_frame()
    assert dut.posn_o.value.to_unsigned() == 0x123456
    check_health(dut, HEALTH_OK, OUTENC_HEALTH_UNUSED)
    bus.position = 0x654321
    await bus.position_frame()
    assert dut.posn_o.value.to_unsigned() == 0x654321
    check_health(dut, HEALTH_OK, OUTENC_HEALTH_UNUSED)
    # The encoder reports an error. A monitor card ignores the error bit,
    # the master at the other end of the bus deals with it, and still
    # decodes the position.
    bus.error = True
    bus.position = 0x111111
    await bus.position_frame()
    assert dut.posn_o.value.to_unsigned() == 0x111111
    check_health(dut, HEALTH_OK, OUTENC_HEALTH_UNUSED)
    bus.error = False
    bus.position = 0x222222
    await bus.position_frame()
    assert dut.posn_o.value.to_unsigned() == 0x222222
    check_health(dut, HEALTH_OK, OUTENC_HEALTH_UNUSED)


def test_encoders_endat(build_dir):
    # Bus widths of the testtarget app, from make autogen
    top_defines_gen = Path(build_dir) / 'apps/testtarget/autogen/hdl/top_defines_gen.vhd'
    run_entity_test(
        'test_encoders_endat', 'encoders_endat_loopback',
        SOURCES + [str(top_defines_gen)], build_dir, libraries=LIBRARIES)

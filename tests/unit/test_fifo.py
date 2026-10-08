import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from entity_runner import run_entity_test

FIFO_BITS = 5
DATA_WIDTH = 8
# The memory holds 2**FIFO_BITS words, plus one more in the output register
CAPACITY = 2**FIFO_BITS + 1


async def setup(dut):
    """Start the clock and reset the FIFO.  The DUT is shared by all tests in
    this module, so each test must start from a clean state."""
    dut.write_valid_i.value = 0
    dut.write_data_i.value = 0
    dut.read_ready_i.value = 0
    dut.reset_fifo_i.value = 1
    cocotb.start_soon(Clock(dut.clk_i, 8, 'ns').start())
    # Inputs are driven and outputs sampled on falling edges, so a handshake
    # seen there completes on the following rising edge
    await FallingEdge(dut.clk_i)
    dut.reset_fifo_i.value = 0
    await ClockCycles(dut.clk_i, 2, rising=False)


async def write(dut, values):
    for value in values:
        dut.write_data_i.value = value
        dut.write_valid_i.value = 1
        while True:
            accepted = dut.write_ready_o.value == 1
            await FallingEdge(dut.clk_i)
            if accepted:
                break
    dut.write_valid_i.value = 0


async def read(dut, count):
    values = []
    dut.read_ready_i.value = 1
    while len(values) < count:
        if dut.read_valid_o.value == 1:
            values.append(dut.read_data_o.value.to_unsigned())
        await FallingEdge(dut.clk_i)
    dut.read_ready_i.value = 0
    return values


@cocotb.test(timeout_time=10, timeout_unit='us')
async def fifo_preserves_order(dut):
    await setup(dut)
    values = [(i * 37) % 2**DATA_WIDTH for i in range(10)]
    await write(dut, values)
    await FallingEdge(dut.clk_i)
    assert dut.fifo_depth_o.value.to_unsigned() == len(values)

    assert await read(dut, len(values)) == values
    await FallingEdge(dut.clk_i)
    assert dut.fifo_depth_o.value.to_unsigned() == 0
    assert dut.read_valid_o.value == 0


@cocotb.test(timeout_time=10, timeout_unit='us')
async def fifo_full_blocks_writes(dut):
    await setup(dut)
    dut.write_valid_i.value = 1
    accepted = 0
    for _ in range(2 * CAPACITY):
        dut.write_data_i.value = accepted
        if dut.write_ready_o.value == 1:
            accepted += 1
        await FallingEdge(dut.clk_i)
    dut.write_valid_i.value = 0

    assert accepted == CAPACITY
    assert dut.write_ready_o.value == 0
    assert dut.fifo_depth_o.value.to_unsigned() == CAPACITY
    assert await read(dut, CAPACITY) == list(range(CAPACITY))


@cocotb.test(timeout_time=10, timeout_unit='us')
async def fifo_reset_empties(dut):
    await setup(dut)
    await write(dut, range(5))
    dut.reset_fifo_i.value = 1
    await FallingEdge(dut.clk_i)
    dut.reset_fifo_i.value = 0
    await ClockCycles(dut.clk_i, 2, rising=False)

    assert dut.fifo_depth_o.value.to_unsigned() == 0
    assert dut.read_valid_o.value == 0
    assert dut.write_ready_o.value == 1


def test_fifo(build_dir):
    run_entity_test(
        'test_fifo', 'fifo',
        ['common/hdl/fifo.vhd', 'common/hdl/defines/support.vhd'],
        build_dir,
        parameters={'FIFO_BITS': FIFO_BITS, 'DATA_WIDTH': DATA_WIDTH})

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;
use work.support.all;

entity lvdsout_zynqmp_top is
port (
    -- Clocks and Resets
    clk_i : in std_logic;
    clk_4x_i : in std_logic;
    reset_i : in std_logic;
    calibration_ready_i : in std_logic;
    -- Memory Bus Interface
    read_strobe_i : in std_logic;
    read_address_i : in std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o : out std_logic_vector(31 downto 0);
    read_ack_o : out std_logic;
    write_strobe_i : in std_logic;
    write_address_i : in std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i : in std_logic_vector(31 downto 0);
    write_ack_o : out std_logic;
    -- System Bus
    bit_bus_i : in std_logic_vector(BBUSW-1 downto 0);
    -- LVDS I/O
    pad_o : out std_logic_vector(LVDSOUT_NUM-1 downto 0)
);
end;

architecture rtl of lvdsout_zynqmp_top is
    signal read_strobe : std_logic_vector(LVDSOUT_NUM-1 downto 0);
    signal read_data : std32_array(LVDSOUT_NUM-1 downto 0);
    signal write_strobe : std_logic_vector(LVDSOUT_NUM-1 downto 0);
    signal read_ack : std_logic_vector(LVDSOUT_NUM-1 downto 0);
    signal write_ack : std_logic_vector(LVDSOUT_NUM-1 downto 0);
    signal oct_delay : std32_array(LVDSOUT_NUM-1 downto 0);
    signal fine_delay : std32_array(LVDSOUT_NUM-1 downto 0);
    signal fine_delay_wstb : std_logic_vector(LVDSOUT_NUM-1 downto 0);
    signal fine_delay_compensated : std32_array(LVDSOUT_NUM-1 downto 0);
    signal val : std_logic_vector(LVDSOUT_NUM-1 downto 0);
begin
    -- Acknowledgement to AXI Lite interface
    write_ack_o <= or_reduce(write_ack);
    read_ack_o <= or_reduce(read_ack);
    read_data_o <= read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

    -- lvdsout_zynqmp Block
    LVDSOUT_ZYNQMP_GEN : for I in 0 to (LVDSOUT_NUM-1) generate
        -- Sub-module address decoding
        read_strobe(I) <=
            compute_block_strobe(read_address_i, I) and read_strobe_i;
        write_strobe(I) <=
            compute_block_strobe(write_address_i, I) and write_strobe_i;
        -- Control System Interface
        lvdsout_zynqmp_ctrl_inst : entity work.lvdsout_zynqmp_ctrl
        port map (
            clk_i => clk_i,
            reset_i => reset_i,
            bit_bus_i => bit_bus_i,
            pos_bus_i => (others => (others => '0')),
            val_from_bus => val(I),
            OCT_DELAY  => oct_delay(I),
            FINE_DELAY => fine_delay(I),
            FINE_DELAY_WSTB => fine_delay_wstb(I),
            FINE_DELAY_COMPENSATED => fine_delay_compensated(I),
            -- Memory Bus Interface
            read_strobe_i => read_strobe(I),
            read_address_i => read_address_i(BLK_AW-1 downto 0),
            read_data_o => read_data(I),
            read_ack_o => read_ack(I),
            write_strobe_i => write_strobe(I),
            write_address_i => write_address_i(BLK_AW-1 downto 0),
            write_data_i => write_data_i,
            write_ack_o => write_ack(I)
        );
        lvdsout_zynqmp_block : entity work.lvdsout_zynqmp_block
        port map (
            -- Clock and Reset
            clk_i => clk_i,
            clk_4x_i => clk_4x_i,
            reset_i => reset_i,
            calibration_ready_i => calibration_ready_i,
            -- Registers
            OCT_DELAY  => oct_delay(I),
            FINE_DELAY => fine_delay(I),
            FINE_DELAY_WSTB => fine_delay_wstb(I),
            FINE_DELAY_COMPENSATED => fine_delay_compensated(I),
            -- Block inputs
            val => val(I),
            -- Block outputs
            pad_o => pad_o(I)
        );
    end generate;
end;

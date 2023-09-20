-- AUTOGENERATED
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.addr_defines.all;
use work.top_defines.all;

entity interval_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Block Parameters
    BOTTOM              : out std_logic_vector(31 downto 0);
    BOTTOM_wstb         : out std_logic;
    TOP                 : out std_logic_vector(31 downto 0);
    TOP_wstb            : out std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic
);
end interval_ctrl;

architecture rtl of interval_ctrl is


-- Register interface common

signal read_addr        : natural range 0 to (2**read_address_i'length - 1);
signal write_addr       : natural range 0 to (2**write_address_i'length - 1);

begin

    -- Sub-module address decoding
    read_addr <= to_integer(unsigned(read_address_i));
    write_addr <= to_integer(unsigned(write_address_i));

    read_ack_delay : entity work.delay_line
    generic map (DW => 1)
    port map (
        clk_i       => clk_i,
        data_i(0)   => read_strobe_i,
        data_o(0)   => read_ack_o,
        DELAY_i       => RD_ADDR2ACK
    );

    -- Control System Register Interface
    REG_WRITE : process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- Zero all the write strobe arrays, we set them below
            BOTTOM_wstb <= '0';
            TOP_wstb <= '0';
            if (write_strobe_i = '1') then
                -- Set the specific write strobe that has come in
                case write_addr is
                    when INTERVAL_BOTTOM_addr =>
                        BOTTOM <= write_data_i;
                        BOTTOM_wstb <= '1';
                    when INTERVAL_TOP_addr =>
                        TOP <= write_data_i;
                        TOP_wstb <= '1';
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    --
    -- Status Register Read     // NOT dealt with yet!      -- Need MUX for read_data(I)
                                                            -- find examples that actually have register reads...
                                                            -- Current implementation taken from old panda_block_ctrl_template
    --
    REG_READ : process(clk_i)
    begin
        if rising_edge(clk_i) then
            case (read_addr) is
                when others =>
                    read_data_o <= (others => '0');
            end case;
        end if;
    end process;

    --
    -- Instantiate Delay Blocks for Bit and Position Bus Fields
    --

end rtl;

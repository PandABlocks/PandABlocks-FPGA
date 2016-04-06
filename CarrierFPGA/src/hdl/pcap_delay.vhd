--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Read configuration registers, and apply 0-31 delay taps to
--                System Bus bits and Position Bus fields.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity pcap_delay is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Inputs and Outputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    extbus_i            : in  std32_array(ENC_NUM-1 downto 0);
    enable_i            : in  std_logic;
    capture_i           : in  std_logic;
    frame_i             : in  std_logic;
    sysbus_o            : out sysbus_t;
    posbus_o            : out posbus_t;
    extbus_o            : out std32_array(ENC_NUM-1 downto 0);
    enable_o            : out std_logic;
    capture_o           : out std_logic;
    frame_o             : out std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0)
);
end pcap_delay;

architecture rtl of pcap_delay is

signal mem_addr : natural range 0 to (2**mem_addr_i'length - 1);

signal data_delay_array : std32_array(31 downto 0);
signal bit_delay_array  : std32_array(3 downto 0);

begin

mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Gather DELAY values for System Bus and Position Bus Fields
--
BIT_DELAY_WRITE : process(clk_i) begin

if rising_edge(clk_i) then
    if (reset_i = '1') then
        bit_delay_array <= (others => (others => '0'));
    else
        FOR I IN REG_PCAP_BIT_DELAY_0 to REG_PCAP_BIT_DELAY_3 LOOP
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = I) then
                    bit_delay_array(I-REG_PCAP_BIT_DELAY_0) <= mem_dat_i;
                end if;
            end if;
        END LOOP;
    end if;
end if;

end process;

DATA_DELAY_WRITE : process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            data_delay_array <= (others => (others => '0'));
        else
            FOR I IN REG_PCAP_DATA_DELAY_0 to REG_PCAP_DATA_DELAY_31 LOOP
                if (mem_cs_i = '1' and mem_wstb_i = '1') then
                    -- Input Select Control Registers
                    if (mem_addr = I) then
                        data_delay_array(I-REG_PCAP_DATA_DELAY_0) <= mem_dat_i;
                    end if;
                end if;
            END LOOP;
        end if;
    end if;
end process;

--
-- Apply Delays To System Bus,
--
BIT_DELAY_GEN : FOR I IN 0 TO 3 GENERATE

bit_delay_inst : entity work.delay_line
port map (
    clk_i       => clk_i,
    data_i      => sysbus_i(32*I+31 downto 32*I),
    data_o      => sysbus_o(32*I+31 downto 32*I),
    DELAY       => bit_delay_array(I)(4 downto 0)
);

END GENERATE;

--
-- Apply Delays To Position Fields,
--
POS_DELAY_GEN : FOR I IN 0 TO 31 GENERATE

data_delay_inst : entity work.delay_line
port map (
    clk_i       => clk_i,
    data_i      => posbus_i(I),
    data_o      => posbus_o(I),
    DELAY       => data_delay_array(I)(4 downto 0)
);

END GENERATE;

EXT_DELAY_GEN : FOR I IN REG_PCAP_DATA_DELAY_1 TO REG_PCAP_DATA_DELAY_4 GENERATE

ext_delay_inst : entity work.delay_line
port map (
    clk_i       => clk_i,
    data_i      => extbus_i(I-REG_PCAP_DATA_DELAY_1),
    data_o      => extbus_o(I-REG_PCAP_DATA_DELAY_1),
    DELAY       => data_delay_array(I-REG_PCAP_DATA_DELAY_1+1)(4 downto 0)
);

END GENERATE;

--
-- Delay Enable/Frame/Capture signals to line-up with *_DLY=0
--
process(clk_i) begin
    if rising_edge(clk_i) then
        enable_o <= enable_i;
        frame_o <= frame_i;
        capture_o <= capture_i;
    end if;
end process;

end rtl;

--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Read requested fields from position bus and feed them serially
--                to the dma engine
--
--                Capture mask for requested fields are stored in a BRAM that is
--                read sequentially, and output value is used as select to the
--                multiplexer for position field array
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity pcap_buffer is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Configuration Registers
    START_WRITE         : in  std_logic;
    WRITE               : in  std_logic_vector(31 downto 0);
    WRITE_WSTB          : in  std_logic;
    -- Block inputs
    fatpipe_i           : in  std32_array(63 downto 0);
    capture_i           : in  std_logic;
    -- Output pulses
    pcap_dat_o          : out std_logic_vector(31 downto 0);
    pcap_dat_valid_o    : out std_logic;
    error_o             : out std_logic
);
end pcap_buffer;

architecture rtl of pcap_buffer is

signal ongoing_capture  : std_logic;
signal capture_data_lt  : std32_array(63 downto 0);
signal mask_length      : unsigned(5 downto 0) := "000000";
signal mask_addra       : unsigned(5 downto 0) := "000000";
signal mask_addrb       : unsigned(5 downto 0);
signal mask_doutb       : std_logic_vector(31 downto 0);
signal capture          : std_logic;

begin

--------------------------------------------------------------------------
-- Position Bus capture mask is implemented using a Block RAM to
-- achieve minimum dead time between capture triggers.
-- Data is pushed into the buffer sequentially followed by reset.
--------------------------------------------------------------------------
mask_spbram : entity work.spbram
generic map (
    AW          => 6,
    DW          => 32
)
port map (
    addra       => std_logic_vector(mask_addra),
    addrb       => std_logic_vector(mask_addrb),
    clka        => clk_i,
    clkb        => clk_i,
    dina        => WRITE,
    doutb       => mask_doutb,
    wea         => WRITE_WSTB
);

--------------------------------------------------------------------------
-- Fill mask buffer with field indices sequentially, and latch buffer len
--------------------------------------------------------------------------
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (START_WRITE = '1') then
            mask_addra <= (others => '0');
        elsif (WRITE_WSTB = '1') then
            mask_addra <= mask_addra + 1;
        end if;

        -- User must complete filling the mask before enabling the
        -- block.
        mask_length <= mask_addra;
    end if;
end process;

--------------------------------------------------------------------------
-- Start reading capture index sequentially following the capture trigger.
-- An ongoing_capture flag is produced to be used for graceful finish by
-- the DMA engine.
--------------------------------------------------------------------------
capture <= capture_i or ongoing_capture;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            capture_data_lt <= (others => (others => '0'));
            ongoing_capture <= '0';
            mask_addrb <= (others => '0');
            error_o <= '0';
            pcap_dat_valid_o <= '0';
        else
            -- Latch all capture fields on rising edge of capture
            if (capture_i = '1' and mask_addrb = 0) then
                capture_data_lt <= fatpipe_i;
            end if;

            -- Ongoing flag runs while mask buffer is read through
            -- Do not produce ongoing pulse if len = 1
            if (mask_addrb = mask_length - 1) then
                ongoing_capture <= '0';
            elsif (capture_i = '1' and mask_addrb = 0) then
                ongoing_capture <= '1';
            end if;

            -- Counter is active follwing capture and rolls over
            if (capture = '1') then
                if (mask_addrb = mask_length - 1) then
                    mask_addrb <= (others => '0');
                else
                    mask_addrb <= mask_addrb + 1;
                end if;
            else
                mask_addrb <= (others => '0');
            end if;

            pcap_dat_valid_o <= capture;

            -- Flag an error on consecutive captures, it is latched until
            -- next pcap start (via reset port)
            if (ongoing_capture = '1' and mask_addrb <= mask_length - 1) then
                error_o <= capture_i;
            end if;
        end if;
    end if;
end process;

-- Generate pcap data and write strobe.
pcap_dat_o <= capture_data_lt(to_integer(mask_doutb));

end rtl;


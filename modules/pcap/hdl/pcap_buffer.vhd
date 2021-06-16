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
--                trig mask for requested fields are stored in a BRAM that is
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
    mode_ts_bits_i      : in  t_mode_ts_bits;
    --
    trig_i              : in  std_logic;
    -- Output pulses
    pcap_dat_o          : out std_logic_vector(31 downto 0);
    pcap_dat_valid_o    : out std_logic;
    error_o             : out std_logic
);
end pcap_buffer;

architecture rtl of pcap_buffer is


constant c_bits0           : std_logic_vector(3 downto 0) := "0111"; -- 7
constant c_bits1           : std_logic_vector(3 downto 0) := "1000"; -- 8
constant c_bits2           : std_logic_vector(3 downto 0) := "1001"; -- 9
constant c_bits3           : std_logic_vector(3 downto 0) := "1010"; --10

signal ongoing_trig        : std_logic;
signal mask_length         : unsigned(5 downto 0) := "000000";
signal mask_addra          : unsigned(5 downto 0) := "000000";
signal mask_addrb          : unsigned(5 downto 0);
signal mask_doutb          : std_logic_vector(31 downto 0);
signal trig_dly            : std_logic;
signal ongoing_trig_dly    : std_logic;


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

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            ongoing_trig <= '0';
            mask_addrb <= (others => '0');
            error_o <= '0';
            pcap_dat_valid_o <= '0';
            trig_dly  <= '0';
            ongoing_trig_dly <= '0';
        else

            -- Ongoing flag runs while mask buffer is read through
            -- Do not produce ongoing pulse if len = 1
            if (mask_addrb = mask_length - 1) then
                ongoing_trig <= '0';
            elsif (trig_i = '1' and mask_addrb = 0) then
                ongoing_trig <= '1';
            end if;

            if (trig_i = '1' or ongoing_trig = '1') then
                if (mask_addrb = mask_length - 1) then
                    mask_addrb <= (others => '0');
                else
                    mask_addrb <= mask_addrb + 1;
                end if;
            end if;

            trig_dly <= trig_i;
            ongoing_trig_dly <= ongoing_trig;
            pcap_dat_valid_o <= trig_dly or ongoing_trig_dly;

            -- Flag an error on consecutive captures, it is latched until
            -- next pcap start (via reset port)
            if (ongoing_trig = '1' and mask_addrb <= mask_length - 1) then
                error_o <= trig_i;
            end if;
        end if;
    end if;
end process;

------------------------------------------------------------------------------

--            -----------------------------------------
--            | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
--            -----------------------------------------
-- 0x240        1 | 0   0   1   0   0 | 0   0   0   0       -- TimeStamp Capture
-- 0x50         0 | 0   0   1   0   1 | 0   0   0   0       --  5 Mode 0 (Value)
-- 0xB1         0 | 0   1   0   1   1 | 0   0   0   1       -- 11 Mode 1 (Difference)
-- 0x32         0 | 0   0   0   1   1 | 0   0   1   0       --  3 Mode 2 (Sum Lo)
-- 0x22         0 | 0   0   0   1   0 | 0   0   1   0       --  2 Mode 2 (Sum Lo)
-- 0x23         0 | 0   0   0   1   0 | 0   0   1   1       --  2 Mode 3 (Sum Hi)
-- 0x92         0 | 0   1   0   0   1 | 0   0   1   0       --  9 Mode 2 Shift
-- 0x84         0 | 0   1   0   0   0 | 0   1   0   0       --  8 Mode 4 (Min)
-- 0x45         0 | 0   0   1   0   0 | 0   1   0   1       --  4 Mode 5 (Max)
-- 0x260        1 | 0   0   1   1   0 | 0   0   0   0       -- Number of Samples
-- 0x200        1 | 0   0   0   0   0 | 0   0   0   0       -- TimeStamp Start
-- 0x220        1 | 0   0   0   1   0 | 0   0   0   0       -- TimeStamp End
-- 0x240        1 | 0   0   1   0   0 | 0   0   0   0       -- TimeStamp Capture
-- 0x270        1 | 0   0   1   1   1 | 0   0   0   0       -- Bits Bus 0
-- 0x280        1 | 0   1   0   0   0 | 0   0   0   0       -- Bits Bus 1
-- 0x290        1 | 0   1   0   0   1 | 0   0   0   0       -- Bits Bus 2
-- 0x2A0        1 | 0   1   0   1   0 | 0   0   0   0       -- Bits Bus 3
-- 0x11                 0 \ 0   0   0   0   1 | 0   0   0   1       --  1 Mode 1 (Difference)
-- 0x12                 0 \ 0   0   0   0   1 \ 0   0   1   0       --  1 MOde 2 (Sum Lo)

--            -----------------------------------------     -----------------
--            | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |     | 3 | 2 | 1 | 0 |
--            -----------------------------------------     -----------------
--              0 | 0   0   0   0   0 | 0   0   0   0         0   1   0   1   -- POS 0  0x000 - 0x005
--              0 | 0   0   0   0   1 | 0   0   0   0         0   1   0   1   -- POS 1  0x010 - 0x015
--
--              0 | 1   1   1   1   0 | 0   0   0   0         0   1   0   1   -- POS 30 0x1E0 - 0x0F5
--              0 | 1   1   1   1   1 | 0   0   0   0         0   1   0   1   -- POS 31 0x1F0 - 0x1F5


-- TimeStamp Start      LSB  0X200
-- TimeStamp Start      MSB  0X210
-- TimeStamp End        LSB  0X220
-- TimeStamp End        MSB  0X230
-- Capture Time         LSB  0x240
-- Capture Time         MSB  0x250
-- Number of Samples         0x260
--

   ----------------------------------------------------
-- | 11 | 10 |  9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
   ----------------------------------------------------
-- | 0  | 0  | ES |      EXT/POS      |     MODE      |
   ----------------------------------------------------
-- Bit  9 = 1 EXTENSION BUS active, 7 - 4 = EXT(11 off)
-- Bit  9 = 0 POSITION BUS active,  7 - 4 = POS(32 off) and MODE(6 off)



-- Modes0,1,2,3,4 and 5 * 32 =  192
-- TimeStamp Start                                2
-- TimeStamp End                                  2
-- TimeStamp Capture                      2
-- Sample Count                                   1
-- Bit Bus 0                                      1
-- Bit Bus 1                                      1
-- Bit Bus 2                                      1
-- Bit Bus 3                                      1
-- Total                                                203
ps_mode_bus: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Position Bus
        if mask_doutb(9) = '0' then
            -- 32 difference mode groups loop through all of them to see which one is active
            lp: for i in PBUSW-1 downto 0 loop
                if (to_integer(unsigned(mask_doutb(8 downto 4)))) = i then
                    -- 6 modes loop through all of them to see which one is active
                    lp_mode: for j in 5 downto 0 loop
                        if (to_integer(unsigned(mask_doutb(3 downto 0)))) = j then
                            pcap_dat_o <= mode_ts_bits_i.mode(i)(j);
                        end if;
                    end loop lp_mode;
                 end if;
            end loop lp;
        -- Extension Bus Selected
        elsif mask_doutb(9) = '1' then
            -- Ext Bus (BITS0, BITS1, BITS2 and BITS3)
            -- Bit Bus 0
            if mask_doutb(7 downto 4) = c_bits0 then
                pcap_dat_o <= mode_ts_bits_i.bits(0);
            -- Bit Bus 1
            elsif mask_doutb(7 downto 4) = c_bits1 then
                pcap_dat_o <= mode_ts_bits_i.bits(1);
            -- Bit Bus 2
            elsif mask_doutb(7 downto 4) = c_bits2 then
                pcap_dat_o <= mode_ts_bits_i.bits(2);
            -- Bit Bus 3
            elsif mask_doutb(7 downto 4) = c_bits3 then
                pcap_dat_o <= mode_ts_bits_i.bits(3);
            -- TS Start x2, TS End x2, TS Capture x2 and Samples
            else
                lp_ext_bus: for i in 6 downto 0 loop
                    if (to_integer(unsigned(mask_doutb(7 downto 4)))) = i then
                        pcap_dat_o <= mode_ts_bits_i.ts(i);
                    end if;
                end loop lp_ext_bus;
            end if;
        end if;
    end if;
end process ps_mode_bus;



end rtl;


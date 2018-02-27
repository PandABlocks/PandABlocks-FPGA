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
    mode_ts_bits        : in  t_mode_ts_bits;
    capture_i           : in  std_logic;
    -- Output pulses
    pcap_dat_o          : out std_logic_vector(31 downto 0);
    pcap_dat_valid_o    : out std_logic;
    error_o             : out std_logic
);
end pcap_buffer;

architecture rtl of pcap_buffer is


constant c_bits0        : std_logic_vector(3 downto 0) := "0111"; -- 7
constant c_bits1        : std_logic_vector(3 downto 0) := "1000"; -- 8
constant c_bits2        : std_logic_vector(3 downto 0) := "1001"; -- 9
constant c_bits3        : std_logic_vector(3 downto 0) := "1010"; --10

constant c_first_eight  : std_logic_vector(1 downto 0) := "00";
constant c_second_eight : std_logic_vector(1 downto 0) := "01";
constant c_third_eight  : std_logic_vector(1 downto 0) := "10";
constant c_fourth_eight : std_logic_vector(1 downto 0) := "11";   

signal mode_bus0        : std_logic_vector(31 downto 0);
signal mode_bus1        : std_logic_vector(31 downto 0);
signal mode_bus2        : std_logic_vector(31 downto 0);
signal mode_bus3        : std_logic_vector(31 downto 0); 
signal ext_bus          : std_logic_vector(31 downto 0);
signal ongoing_capture  : std_logic;
signal capture_data_lt  : t_mode_ts_bits;
signal mask_length      : unsigned(5 downto 0) := "000000";
signal mask_addra       : unsigned(5 downto 0) := "000000";
signal mask_addrb       : unsigned(5 downto 0);
signal mask_doutb       : std_logic_vector(31 downto 0);
signal capture          : std_logic;
signal capture_dly      : std_logic;
signal capture_dly2     : std_logic;

signal test             : natural :=0;
signal test_integer     : natural;

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
            capture_data_lt.mode <= (others => (others => (others => '0')));
            capture_data_lt.ts <= (others => (others => '0'));
            capture_data_lt.bits <= (others => (others => '0'));
            ongoing_capture <= '0';
            mask_addrb <= (others => '0');
            error_o <= '0';
            pcap_dat_valid_o <= '0';
            capture_dly  <= '0';
            capture_dly2 <= '0';
        else
            -- Latch all capture fields on rising edge of capture
            if (capture_i = '1' and mask_addrb = 0) then
                capture_data_lt <= mode_ts_bits;                                   
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

--            pcap_dat_valid_o <= capture;
            capture_dly <= capture;
            capture_dly2 <= capture_dly;
            pcap_dat_valid_o <= capture_dly2;

            -- Flag an error on consecutive captures, it is latched until
            -- next pcap start (via reset port)
            if (ongoing_capture = '1' and mask_addrb <= mask_length - 1) then
                error_o <= capture_i;
            end if;
        end if;
    end if;
end process;


   -------------------------------------------------------------
-- | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
   -------------------------------------------------------------
-- | 0| 0| 0 | ES |  0 |      EXT/POS      |       MODE        |
   -------------------------------------------------------------
-- Bit  9 = 1 EXTENSION BUS active, 7 - 4 = EXT(11 off)   
-- Bit  9 = 0 POSITION BUS active,  7 - 4 = POS(32 off) and MODE(6 off)
 

-- Ext bus
-- Bits0, Bits1, Bits2, Bits3, TS Start x2, TS End x2, TS Capture x2 and Samples
ps_ext_bus: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Extension Bus Selected 
        if mask_doutb(9) = '1' then
            -- Ext Bus (BITS0, BITS1, BITS2 and BITS3)
            if mask_doutb(7 downto 4) = c_bits0 then
                ext_bus <= capture_data_lt.bits(0);
            elsif mask_doutb(7 downto 4) = c_bits1 then
                ext_bus <= capture_data_lt.bits(1);
            elsif mask_doutb(7 downto 4) = c_bits2 then
                ext_bus <= capture_data_lt.bits(2);
            elsif mask_doutb(7 downto 4) = c_bits3 then        
                ext_bus <= capture_data_lt.bits(3);
            -- TS Start x2, TS End x2, TS Capture x2 and Samples    
            else
                ext_bus <= capture_data_lt.ts(to_integer(mask_doutb(6 downto 4)));    
            end if;
        end if;    
    end if;
end process ps_ext_bus;


-- Modes0,1,2,3,4 and 5 * 32 
ps_mode_bus: process(clk_i)
begin
    if rising_edge(clk_i) then            
        -- Position Bus
        if mask_doutb(9) = '0' then 
            test <= 0;
            -- cap_frame 7 downto 0
            if mask_doutb(8 downto 7) = c_first_eight then
                test <= 1;
                -- 7 downto 0                
                mode_bus0 <= capture_data_lt.mode(to_integer(mask_doutb(6 downto 4)))(to_integer(mask_doutb(3 downto 0)));                
            end if;
            -- cap_frame 15 downto 8       
            if mask_doutb(8 downto 7) = c_second_eight then
                -- 15 downto 8
                mode_bus1 <= capture_data_lt.mode(to_integer(mask_doutb(6 downto 4)))(to_integer(mask_doutb(3 downto 0)));
            end if;
            -- cap_frame 23 downto 16
            if mask_doutb(8 downto 7) = c_third_eight then 
                -- 23 downto 16
                mode_bus2 <= capture_data_lt.mode(to_integer(mask_doutb(6 downto 4)))(to_integer(mask_doutb(3 downto 0)));
            end if;
            -- cap_frame 31 downto 24
            if mask_doutb(8 downto 7) = c_fourth_eight then
                -- 31 downto 24
                mode_bus3 <= capture_data_lt.mode(to_integer(mask_doutb(6 downto 4)))(to_integer(mask_doutb(3 downto 0)));
            end if;                                    
        end if;
    end if;
end process ps_mode_bus;        


-- Second mux to ease timing
-- Ext Bus 
-- Input 0 MOde bus 0
-- Input 1 Mode bus 1
-- Input 2 Mode bus 2
-- Input 3 Mode bus 3     
ps_fatpipes: process(clk_i)
begin
    if rising_edge(clk_i) then
        if mask_doutb(9) = '1' then
            pcap_dat_o <= ext_bus;
        else
            if mask_doutb(8 downto 7) = "00" then
                pcap_dat_o <= mode_bus0;
            elsif mask_doutb(8 downto 7) = "01" then
                pcap_dat_o <= mode_bus1;
            elsif mask_doutb(8 downto 7) = "10" then
                pcap_dat_o <= mode_bus2;
            elsif mask_doutb(8 downto 7) = "11" then
                pcap_dat_o <= mode_bus3;
            end if;
        end if;                         
    end if;
end process ps_fatpipes;
    


end rtl;


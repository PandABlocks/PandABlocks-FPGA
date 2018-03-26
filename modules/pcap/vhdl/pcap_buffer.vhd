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
    -- 
    capture_i           : in  std_logic;
    gate_i              : in  std_logic;
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
signal mask_length      : unsigned(5 downto 0) := "000000";
signal mask_addra       : unsigned(5 downto 0) := "000000";
signal mask_addrb       : unsigned(5 downto 0);
signal mask_doutb       : std_logic_vector(31 downto 0);
signal mask_doutb_del   : std_logic_vector(31 downto 0);
signal capture          : std_logic;
signal capture_dly      : std_logic_vector(2 downto 0);


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
--capture <= capture_i or ongoing_capture;                                  -- HERE CODE CHANGED
capture <= capture_i;

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
--            capture_data_lt.mode <= (others => (others => (others => '0')));
--            capture_data_lt.ts <= (others => (others => '0'));
--            capture_data_lt.bits <= (others => (others => '0'));
            ongoing_capture <= '0';
            mask_addrb <= (others => '0');
            error_o <= '0';
            pcap_dat_valid_o <= '0';
            capture_dly  <= (others => '0');
        else

            -- Ongoing flag runs while mask buffer is read through
            -- Do not produce ongoing pulse if len = 1
            if (mask_addrb = mask_length - 1) then
                ongoing_capture <= '0';
            elsif (capture_i = '1' and mask_addrb = 0) then
                ongoing_capture <= '1';
            end if;

            -- Counter is active follwing capture and rolls over
----            if (capture = '1') then
-----------------------------------------------------------------------------------------------
            mask_doutb_del <= mask_doutb;
----            if (capture_dly(2) = '1') then                                     --- HERE                         
--            if (capture_dly(2) = '1' or (capture_dly(1) = '1' and ongoing_capture = '1')) then                                                              
            if (capture_i = '1' or (capture_dly(0) = '1' and ongoing_capture = '1')) then                                                              
-----------------------------------------------------------------------------------------------
                if (mask_addrb = mask_length - 1) then
                    mask_addrb <= (others => '0');
                else
                    mask_addrb <= mask_addrb + 1;
                end if;
--            else
--                mask_addrb <= (others => '0');
            end if;

            capture_dly <= capture_dly(1 downto 0) & capture;
            pcap_dat_valid_o <= capture_dly(2);

            -- Flag an error on consecutive captures, it is latched until
            -- next pcap start (via reset port)
            if (ongoing_capture = '1' and mask_addrb <= mask_length - 1) then
                error_o <= capture_i;
            end if;
        end if;
    end if;
end process;

------------------------------------------------------------------------------
-- TimeStamp            0x240                                     
-- Mode 0               0x50
-- Mode 1               0xB1
-- Mode 2               0x32
-- Mode 3               0x22 / 0x23 SHIFT 0x92 / 0x260
-- Mode 4               0x84
-- Mode 5               0x45
-- Number of Samples    0x260
-- TimeStamp Start      0x200 / 0x220 / 0x240
-- Bits bus             0x270 / 0x280 / 0x290 / 0x2A0
-- Trigers              0x11 / 0x12

--            -----------------------------------------                  
--            | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
--            -----------------------------------------  
-- 0x240        1 | 0   0   1   0   0 | 0   0   0   0       -- TimeStamp Capture            
-- 0x50         0 | 0   0   1   0   1 | 0   0   0   0       -- Mode 0(Value)        
-- 0xB1         0 | 0   1   0   1   1 | 0   0   0   1       -- Mode 1(Difference)       
-- 0x32         0 | 0   0   0   1   1 | 0   0   1   0       -- Mode 2(Sum Lo)           
-- 0x22         0 | 0   0   0   1   0 | 0   0   1   0       -- Mode 2(Sum Lo)       
-- 0x23         0 | 0   0   0   1   0 | 0   0   1   1       -- Mode 3(Sum Hi)       
-- 0x92         0 | 0   1   0   0   1 | 0   0   1   0       -- Mode 2  Shift                     
-- 0x84         0 | 0   1   0   0   0 | 0   1   0   0       -- Mode 4(Min)          
-- 0x45         0 | 0   0   1   0   0 | 0   1   0   1       -- Mode 5(Max)          
-- 0x260        1 | 0   0   1   1   0 | 0   0   0   0       -- Number of Samples    
-- 0x200        1 | 0   0   0   0   0 | 0   0   0   0       -- TimeStamp Start      
-- 0x220        1 | 0   0   0   1   0 | 0   0   0   0       -- TimeStamp End        
-- 0x240        1 | 0   0   1   0   0 | 0   0   0   0       -- TimeStamp Capture      
-- 0x270        1 | 0   0   1   1   1 | 0   0   0   0       -- Bits Bus             
-- 0x280        1 | 0   1   0   0   0 | 0   0   0   0       -- Bits Bus                 
-- 0x290        1 | 0   1   0   0   1 | 0   0   0   0       -- Bits Bus             
-- 0x2A0        1 | 0   1   0   1   0 | 0   0   0   0       -- Bits Bus                 

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
 

-- Ext bus
-- Bits0, Bits1, Bits2, Bits3, TS Start x2, TS End x2, TS Capture x2 and Samples
ps_ext_bus: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Extension Bus Selected 
        if mask_doutb(9) = '1' then
            -- Ext Bus (BITS0, BITS1, BITS2 and BITS3)
            if mask_doutb(7 downto 4) = c_bits0 then                
                ext_bus <= mode_ts_bits.bits(0);
            elsif mask_doutb(7 downto 4) = c_bits1 then
                ext_bus <= mode_ts_bits.bits(1);
            elsif mask_doutb(7 downto 4) = c_bits2 then
                ext_bus <= mode_ts_bits.bits(2);
            elsif mask_doutb(7 downto 4) = c_bits3 then        
                ext_bus <= mode_ts_bits.bits(3);
            -- TS Start x2, TS End x2, TS Capture x2 and Samples    
            else
                lp_ext_bus: for i in 6 downto 0 loop
                    if (to_integer(unsigned(mask_doutb(7 downto 4)))) = i then
                        ext_bus <= mode_ts_bits.ts(i);    
                    end if;
                end loop lp_ext_bus;
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
            -- cap_frame 7 downto 0
            if mask_doutb(8 downto 7) = c_first_eight then
                -- 7 downto 0                
                lp_first : for i in 7 downto 0 loop
                    if (to_integer(unsigned(mask_doutb(6 downto 4)))) = i then
                        lp_mode7 : for j in 5 downto 0 loop                
                            if (to_integer(unsigned(mask_doutb(3 downto 0)))) = j then
                                -- 7 downto 0
                                mode_bus0 <= mode_ts_bits.mode(i)(j); 
                            end if;
                        end loop lp_mode7;
                    end if;
                end loop lp_first;                                    
            end if;
            -- cap_frame 15 downto 8       
            if mask_doutb(8 downto 7) = c_second_eight then
                -- 15 downto 8
                lp_second : for k in 7 downto 0 loop
                    if (to_integer(unsigned(mask_doutb(6 downto 4)))) = k then
                        lp_mode14 : for l in 5 downto 0 loop
                            if (to_integer(unsigned(mask_doutb(3 downto 0)))) = l then
                                -- 15 downto 8
                                mode_bus1 <= mode_ts_bits.mode(8+k)(l);
                            end if;
                        end loop lp_mode14;    
                    end if;
                end loop lp_second;
            end if;
            -- cap_frame 23 downto 16
            if mask_doutb(8 downto 7) = c_third_eight then 
                -- 23 downto 16
                lp_third : for n in 7 downto 0 loop
                    if (to_integer(unsigned(mask_doutb(6 downto 4)))) = n then
                        lp_mode21 : for m in 5 downto 0 loop
                            if (to_integer(unsigned(mask_doutb(3 downto 0)))) = m then
                                -- 23 downto 16
                                mode_bus2 <= mode_ts_bits.mode(16+n)(m);
                            end if;
                        end loop lp_mode21;
                    end if;
                end loop lp_third;                
            end if;
            -- cap_frame 31 downto 24
            if mask_doutb(8 downto 7) = c_fourth_eight then
                -- 31 downto 24
                lp_fourth : for o in 7 downto 0 loop
                    if (to_integer(unsigned(mask_doutb(6 downto 4)))) = o then
                        lp_mode32 : for p in 5 downto 0 loop
                            if (to_integer(unsigned(mask_doutb(3 downto 0)))) = p then 
                                -- 31 downto 24
                                mode_bus3 <= mode_ts_bits.mode(24+o)(p);
                            end if;
                        end loop lp_mode32;
                    end if;
                end loop lp_fourth;                
            end if;                                    
        end if;
    end if;
end process ps_mode_bus;        


-- Second mux to ease timing
-- Ext Bus 
-- Input 0 MOde bus 0 mode bus (7 downto 0)
-- Input 1 Mode bus 1 mode bus (15 downto 8)
-- Input 2 Mode bus 2 mode bus (23 downto 16)
-- Input 3 Mode bus 3 mode bus (31 downto 24)    
ps_fatpipes: process(clk_i)
begin
    if rising_edge(clk_i) then
        if mask_doutb_del(9) = '1' then
            pcap_dat_o <= ext_bus;
        else
            if mask_doutb_del(8 downto 7) = "00" then
                pcap_dat_o <= mode_bus0;
            elsif mask_doutb_del(8 downto 7) = "01" then
                pcap_dat_o <= mode_bus1;
            elsif mask_doutb_del(8 downto 7) = "10" then
                pcap_dat_o <= mode_bus2;
            elsif mask_doutb_del(8 downto 7) = "11" then
                pcap_dat_o <= mode_bus3;
            end if;
        end if;                         
    end if;
end process ps_fatpipes;
    


end rtl;


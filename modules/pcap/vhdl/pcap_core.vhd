--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Position Capture Core module handles core functionalities:
--                  * Arming of the block,
--                  * Frame/Capture handling,
--                  * Buffered output.
--                  * Error generation.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.operator.all;

entity pcap_core is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block registers
    ARM                 : in  std_logic;
    DISARM              : in  std_logic;
    START_WRITE         : in  std_logic;
    WRITE               : in  std_logic_vector(31 downto 0);
    WRITE_WSTB          : in  std_logic;
    CAPTURE_EDGE        : in  std_logic_vector(1 downto 0);
    SHIFT_SUM           : in  std_logic_vector(5 downto 0);
    health              : out std_logic_vector(31 downto 0);
    -- Block inputs
    enable_i            : in  std_logic;
    capture_i           : in  std_logic;
    gate_i              : in  std_logic;
    dma_error_i         : in  std_logic;
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Block outputs
    pcap_dat_o          : out std_logic_vector(31 downto 0);
    pcap_dat_valid_o    : out std_logic;
    pcap_done_o         : out std_logic;
    pcap_actv_o         : out std_logic;
    pcap_status_o       : out std_logic_vector(1 downto 0)
);
end pcap_core;

architecture rtl of pcap_core is


signal capture_prev     : std_logic;
signal gate             : std_logic;
signal pcap_reset       : std_logic;
signal capture          : std_logic;
signal capture_rise     : std_logic;
signal capture_fall     : std_logic; 

signal timestamp        : std_logic_vector(63 downto 0);
signal capture_pulse    : std_logic;
signal mode_ts_bits     : t_mode_ts_bits;
signal pcap_buffer_error: std_logic;
--signal pcap_frame_error : std_logic;
signal pcap_error       : std_logic;
signal pcap_status      : std_logic_vector(1 downto 0);
signal pcap_dat_valid   : std_logic;
signal pcap_armed       : std_logic;
--signal pcap_start       : std_logic;


begin

-- Assign outputs
pcap_dat_valid_o <= pcap_dat_valid;
pcap_status_o <= pcap_status;
pcap_actv_o <= pcap_armed;

--------------------------------------------------------------------------
-- These errors signals termination of PCAP operation
--------------------------------------------------------------------------
--pcap_error <= pcap_buffer_error or pcap_frame_error;
pcap_error <= pcap_buffer_error;

--------------------------------------------------------------------------
-- Arm/Disarm/Enable Control Logic
--------------------------------------------------------------------------
pcap_arming : entity work.pcap_arming
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    ARM                 => ARM,
    DISARM              => DISARM,
    enable_i            => enable_i,
    pcap_error_i        => pcap_error,
    dma_error_i         => dma_error_i,
    ongoing_capture_i   => pcap_dat_valid,
    pcap_armed_o        => pcap_armed,
    pcap_done_o         => pcap_done_o,
    timestamp_o         => timestamp,
    pcap_status_o       => pcap_status
);


ps_prev: process(clk_i)                                      
begin                                                               
    if rising_edge(clk_i) then                      
        capture_prev <= capture_i;                  
    end if;                                                         
end process ps_prev;                                                


capture_rise <= not capture_prev and capture_i;
capture_fall <= capture_prev and not capture_i;

-- Handle the trigger 
capture <= capture_rise when (capture_rise = '1' and (CAPTURE_EDGE = "00" or CAPTURE_EDGE = "10")) else
           capture_fall when (capture_fall = '1' and (CAPTURE_EDGE = "01" or CAPTURE_EDGE = "10")) else
           '0';  


gate <= pcap_armed and gate_i;

-- Keep sub-block under reset when pcap is not armed
pcap_reset <= reset_i or not pcap_armed;


--------------------------------------------------------------------------
-- Encoder and ADC Position Data Processing
--------------------------------------------------------------------------
pcap_frame : entity work.pcap_frame
port map (
    clk_i               => clk_i,
--    reset_i             => pcap_reset,
    reset_i             => reset_i,    

    SHIft_SUM           => SHIFT_SUM,    
    
    posbus_i            => posbus_i,
    sysbus_i            => sysbus_i,
    enable_i            => enable_i,
    gate_i              => gate,
    capture_i           => capture,
    timestamp_i         => timestamp,

    capture_o           => capture_pulse,
    mode_ts_bits        => mode_ts_bits
--    error_o             => pcap_frame_error
);

--------------------------------------------------------------------------
-- Pcap Mask Buffer
--------------------------------------------------------------------------
pcap_buffer : entity work.pcap_buffer
port map (
    clk_i               => clk_i,
--    reset_i             => pcap_reset,
    reset_i             => reset_i,
--    reset_mem           => reset_i,
    -- Configuration Registers
    START_WRITE         => START_WRITE,    
    WRITE               => WRITE,
    WRITE_WSTB          => WRITE_WSTB,
    -- Block inputs
    mode_ts_bits        => mode_ts_bits,
    --
    capture_i           => capture,
    gate_i              => gate_i,
    -- Output pulses
    pcap_dat_o          => pcap_dat_o,
    pcap_dat_valid_o    => pcap_dat_valid,
    error_o             => pcap_buffer_error
);

health(31 downto 2) <= (others => '0');
health(1 downto 0) <= pcap_status(1 downto 0);

end rtl;

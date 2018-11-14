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
    TRIG_EDGE           : in  std_logic_vector(1 downto 0);
    SHIFT_SUM           : in  std_logic_vector(5 downto 0);
    HEALTH              : out std_logic_vector(31 downto 0);
    -- Block inputs
    enable_i            : in  std_logic;
    trig_i              : in  std_logic;
    gate_i              : in  std_logic;
    dma_error_i         : in  std_logic;
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Block outputs
    pcap_dat_o          : out std_logic_vector(31 downto 0);
    pcap_dat_valid_o    : out std_logic;
    pcap_done_o         : out std_logic;
    pcap_actv_o         : out std_logic;
    pcap_status_o       : out std_logic_vector(2 downto 0)
);
end pcap_core;

architecture rtl of pcap_core is


constant c_cap_to_close : std_logic_vector(1 downto 0) := "01";
constant c_dma_full		: std_logic_vector(1 downto 0) := "10"; 
constant c_health_ok	: std_logic_vector(1 downto 0) := "00";	

signal gate             : std_logic;
signal pcap_reset       : std_logic;
signal timestamp        : std_logic_vector(63 downto 0);
signal trig_pulse       : std_logic;
signal mode_ts_bits     : t_mode_ts_bits;
signal pcap_buffer_error: std_logic;
signal pcap_error       : std_logic;
signal pcap_status      : std_logic_vector(2 downto 0);
signal pcap_dat_valid   : std_logic;
signal pcap_armed       : std_logic;
signal trig_en          : std_logic;


begin

-- Assign outputs
pcap_dat_valid_o <= pcap_dat_valid;
pcap_status_o <= pcap_status;
pcap_actv_o <= pcap_armed;

--------------------------------------------------------------------------
-- This error signal causes the termination of PCAP operation
--------------------------------------------------------------------------
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
    ongoing_trig_i      => pcap_dat_valid,
    pcap_armed_o        => pcap_armed,
    pcap_done_o         => pcap_done_o,
    timestamp_o         => timestamp,
    pcap_status_o       => pcap_status
);


-- Gate the gate with the pcap_armed and ARM signals
gate <= (ARM or pcap_armed) and gate_i and enable_i;

-- Keep sub-block under reset when pcap is not armed
pcap_reset <= reset_i or not pcap_armed;

-- Enable the trigger only when the enable is set
trig_en <= trig_i and enable_i;

--------------------------------------------------------------------------
-- Encoder and ADC Position Data Processing
--------------------------------------------------------------------------
pcap_frame : entity work.pcap_frame
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,    
	-- Register control
    SHIft_SUM           => SHIFT_SUM,    
	TRIG_EDGE		    => TRIG_EDGE,
    -- 
    posbus_i            => posbus_i,
    sysbus_i            => sysbus_i,
    enable_i            => enable_i,
    gate_i              => gate,
    trig_i              => trig_en,
    timestamp_i         => timestamp,
	--
    trig_o              => trig_pulse,
    mode_ts_bits_o      => mode_ts_bits
);

--------------------------------------------------------------------------
-- Pcap Mask Buffer
--------------------------------------------------------------------------
pcap_buffer : entity work.pcap_buffer
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Configuration Registers
    START_WRITE         => START_WRITE,    
    WRITE               => WRITE,
    WRITE_WSTB          => WRITE_WSTB,
    -- Block inputs
    mode_ts_bits_i      => mode_ts_bits,
    --
    trig_i              => trig_pulse,
    -- Output pulses
    pcap_dat_o          => pcap_dat_o,
    pcap_dat_valid_o    => pcap_dat_valid,
    error_o             => pcap_buffer_error
);

HEALTH(31 downto 2) <= (others => '0');
HEALTH(1 downto 0) <= c_cap_to_close when pcap_status(1) = '1' else
					  c_dma_full when pcap_status(2) = '1' else
					  c_health_ok;	 


end rtl;

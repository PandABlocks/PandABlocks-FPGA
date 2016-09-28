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
    FRAMING_MASK        : in  std_logic_vector(31 downto 0);
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MODE        : in  std_logic_vector(31 downto 0);
    FRAME_NUM           : in  std_logic_vector(31 downto 0);
    ERR_STATUS          : out std_logic_vector(31 downto 0);
    -- Block inputs
    enable_i            : in  std_logic;
    capture_i           : in  std_logic;
    frame_i             : in  std_logic;
    dma_full_i          : in  std_logic;
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

signal frame            : std_logic;
signal capture          : std_logic;
signal frames_completed	: std_logic;

signal timestamp        : std_logic_vector(63 downto 0);
signal capture_pulse    : std_logic;
signal capture_data     : std32_array(63 downto 0);
signal pcap_buffer_error: std_logic;
signal pcap_frame_error : std_logic;
signal pcap_error       : std_logic;

signal pcap_status      : std_logic_vector(2 downto 0);
signal pcap_dat_valid   : std_logic;

signal pcap_armed       : std_logic;
signal pcap_enabled     : std_logic;

begin

pcap_dat_valid_o <= pcap_dat_valid;
pcap_status_o <= pcap_status;
pcap_actv_o <= pcap_armed;

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
	frames_completed_i	=> frames_completed,
    pcap_error_i        => pcap_error,
    dma_error_i         => dma_full_i,
    ongoing_capture_i   => pcap_dat_valid,
    pcap_armed_o        => pcap_armed,
    pcap_enabled_o      => pcap_enabled,
    pcap_done_o         => pcap_done_o,
    timestamp_o         => timestamp,
    pcap_status_o       => pcap_status
);

-- Mask capture and frame signals only when core is active (armed)
capture <= capture_i and pcap_armed;
frame <= frame_i and pcap_armed;

--------------------------------------------------------------------------
-- Encoder and ADC Position Data Processing
--------------------------------------------------------------------------
pcap_frame : entity work.pcap_frame
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    FRAMING_MASK        => FRAMING_MASK,
    FRAMING_ENABLE      => FRAMING_ENABLE,
    FRAMING_MODE        => FRAMING_MODE,
	FRAME_NUM			=> FRAME_NUM, 

    posbus_i            => posbus_i,
    sysbus_i            => sysbus_i,

    enable_i            => pcap_enabled,
    frame_i             => frame,
    capture_i           => capture,
    timestamp_i         => timestamp,
    capture_o           => capture_pulse,
	frames_completed_o	=> frames_completed,
	posn_o              => capture_data,
    error_o             => pcap_frame_error
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
    enable_i            => pcap_enabled,
    fatpipe_i           => capture_data,
    capture_i           => capture_pulse,
    -- Output pulses
    pcap_dat_o          => pcap_dat_o,
    pcap_dat_valid_o    => pcap_dat_valid,
    error_o             => pcap_buffer_error
);

--------------------------------------------------------------------------
-- These errors signals termination of PCAP operation.
--------------------------------------------------------------------------
pcap_error <= pcap_buffer_error or pcap_frame_error;

ERR_STATUS(31 downto 3) <= (others => '0');
ERR_STATUS(2 downto 0) <= pcap_status;

end rtl;

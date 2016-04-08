-----------------------------------------------------------------------------
--  Project      : Diamond PandA SSI Encoder Splitter
--  Filename     : ssi_master.vhd
--  Purpose      : Absolute encoder SSI Master
--
--  Author       : Dr. Isa Servan Uzun
-----------------------------------------------------------------------------
--  Copyright (c) 2012 Diamond Light Source Ltd.
--  All rights reserved.
-----------------------------------------------------------------------------
--  Module Description: Master SSI module continuously reads from Absolute
--  encoders acting as slaves. N clock cycles are generated, and on falling edge
--  of each clock, data input is latched and shifted into N-bit register.
-----------------------------------------------------------------------------
--  Limitations & Assumptions:
-----------------------------------------------------------------------------
--  Known Errors: This design is still under test. Please send any bug
--reports to isa.uzun@diamond.ac.uk
-----------------------------------------------------------------------------
--  TO DO List:
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ssi_master is
port (
    -- Global system and reset interface
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Block Parameters
    BITS            : in  std_logic_vector(7 downto 0);
    CLK_PERIOD      : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD    : in  std_logic_vector(31 downto 0);
    -- Block Inputs and Outputs
    ssi_sck_o       : out std_logic;
    ssi_dat_i       : in  std_logic;
    posn_o          : out std_logic_vector(31 downto 0);
    posn_valid_o    : out std_logic
);
end entity;

architecture rtl of ssi_master is

signal frame_pulse          : std_logic;
signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal shift_enable         : std_logic;
signal shift_clock          : std_logic;
signal shift_data           : std_logic;

begin

-- Connect outputs
ssi_sck_o <= serial_clock;

-- Generate Internal SSI Frame from system clock
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => FRAME_PERIOD,
    pulse_o     => frame_pulse
);

clock_train_inst : entity work.ssi_clock_gen
generic map (
    DEAD_PERIOD     => (10000/8)    -- 10us
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    N               => BITS,
    CLK_PERIOD      => CLK_PERIOD,
    start_i         => frame_pulse,
    clock_pulse_o   => serial_clock,
    active_o        => shift_enable,
    busy_o          => open
);

-- SSI Master FSM
ssi_fsm_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        if reset_i = '1' then
            serial_clock_prev <= '0';
        else
            serial_clock_prev <= serial_clock;
        end if;
    end if;
end process;

-- Shift source synchronous data on the Falling egde of clock.
shift_clock <= not serial_clock and serial_clock_prev;
shift_data <= ssi_dat_i;

shifter_in_inst : entity work.shifter_in
generic map (
    DW              => 32
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    enable_i        => shift_enable,
    clock_i         => shift_clock,
    data_i          => shift_data,
    data_o          => posn_o,
    data_valid_o    => posn_valid_o
);

end rtl;


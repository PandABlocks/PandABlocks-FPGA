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
    ENCODING        : in  std_logic_vector(1 downto 0);
    BITS            : in  std_logic_vector(7 downto 0);
    CLK_PERIOD      : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD    : in  std_logic_vector(31 downto 0);
    -- Block Inputs and Outputs
    ssi_sck_o       : out std_logic;
    ssi_dat_i       : in  std_logic;
    posn_o          : out std_logic_vector(31 downto 0);
    posn_valid_o    : out std_logic;
    ssi_frame_o     : out std_logic
);
end entity;

architecture rtl of ssi_master is

signal frame_pulse          : std_logic;
signal serial_clock         : std_logic;
signal serial_clock_prev    : std_logic;
signal shift_enable_prev    : std_logic;
signal shift_enable         : std_logic;
signal shift_clock          : std_logic;
signal shift_data           : std_logic;
signal shift_in             : std_logic_vector(31 downto 0);
signal ssi_frame            : std_logic;

-- Shift length in integer
signal intBITS              : natural range 0 to 2**BITS'length-1;

begin

-- Connect outputs
ssi_sck_o <= serial_clock;
ssi_frame_o <= ssi_frame;

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
            shift_enable_prev <= '0';
            ssi_frame <= '0';
        else
            serial_clock_prev <= serial_clock;
            shift_enable_prev <= shift_enable;   
            -- Check for initial falling edge of serial clock for start of frame
            if shift_clock = '1' and ssi_frame = '0' then
                ssi_frame <= '1';
            -- check for falling edge of shift_enable to reset ssi_frame
            elsif shift_enable = '0' and shift_enable_prev = '1' then
                ssi_frame <= '0';
            end if; 
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
    ENCODING        => ENCODING,
    enable_i        => shift_enable,
    clock_i         => shift_clock,
    data_i          => shift_data,
    data_o          => shift_in,
    data_valid_o    => posn_valid_o
);

--------------------------------------------------------------------------
-- Dynamic bit length require sign extention logic
--------------------------------------------------------------------------
intBITS <= to_integer(unsigned(BITS));

process(clk_i)
begin
    if rising_edge(clk_i) then
        FOR I IN shift_in'range LOOP
            -- Have to handle 0-bit configuration. Horrible indeed.
            if (intBITS = 0) then
                posn_o(I) <= '0';
            else
            -- Sign bit or not depending on BITS parameter.
                if (I < intBITS) then
                    posn_o(I) <= shift_in(I);
                else
                    posn_o(I) <= shift_in(intBITS-1);
                end if;
            end if;
        END LOOP;
    end if;
end process;

end rtl;


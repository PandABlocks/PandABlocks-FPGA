-----------------------------------------------------------------------------
--  Project      : Diamond PandA SSI Encoder Splitter
--  Filename     : max14900_ctrl.vhd
--  Purpose      : Absolute encoder SSI Master
--
--  Author       : Dr. Isa Servan Uzun
-----------------------------------------------------------------------------
--  Copyright (c) 2012 Diamond Light Source Ltd.
--  All rights reserved.
-----------------------------------------------------------------------------
--  Module Description: MAX14900 SPI control interface.
--                      Configuration data write and status read are performed
--                      on the same cycle at 1ms continuously.
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity max14900_ctrl is
generic (
    SIM             : boolean := false
);
port (
    -- Global system and reset interface
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -- Block Inputs and Outputs
    csn_o           : out std_logic;
    sclk_o          : out std_logic;
    miso_i          : in  std_logic;
    mosi_o          : out std_logic;
    config_i        : in  std_logic_vector(15 downto 0);
    status_o        : out std_logic_vector(15 downto 0)
);
end entity;

architecture rtl of max14900_ctrl is

--
constant usec           : natural := 1000;
constant msec           : natural := 1000 * usec;

-- Shift length in integer
constant DW            : natural := 16;

signal SPI_PERIOD       : std_logic_vector(31 downto 0);
signal SCLK_PERIOD      : std_logic_vector(31 downto 0);

signal spi_update       : std_logic;
signal sclk             : std_logic;
signal sclk_prev        : std_logic;
signal sclk_fall        : std_logic;
signal sclk_rise        : std_logic;
signal shift_enable     : std_logic;
signal shiftreg         : std_logic_vector(DW-1 downto 0);

begin

-- Set SPI data transmission rate from master to slave
SPI_PERIOD <= std_logic_vector(to_unsigned(1000 * usec / 8, 32)) when
                (SIM = false) else
                    std_logic_vector(to_unsigned(100 * usec / 8, 32));

-- Set SPI clock to 1MHz.
SCLK_PERIOD <= std_logic_vector(to_unsigned(1 * usec / 8, 32));

-- Connect outputs
csn_o <= not shift_enable;
sclk_o <= sclk;

-- Update Configuration and Read Status every 100ms
frame_presc : entity work.prescaler_pos
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,
    PERIOD      => SPI_PERIOD,
    pulse_o     => spi_update
);

-- Generate SCLK output from master to slave for 16 ticks
clock_train_inst : entity work.max14900_sclk_gen
generic map (
    N               => 16
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    CLK_PERIOD      => SCLK_PERIOD,
    start_i         => spi_update,
    clock_pulse_o   => sclk,
    active_o        => shift_enable,
    busy_o          => open
);

ssi_fsm_gen : process(clk_i)
begin
    if rising_edge(clk_i) then
        sclk_prev <= sclk;
    end if;
end process;

-- Shift data in and out on clock edges
sclk_rise <= sclk and not sclk_prev;
sclk_fall <= not sclk and sclk_prev;

--
-- On SPI update pulse, latch previous status data and shift in new value
--
process (clk_i)
begin
    if (rising_edge(clk_i)) then
        -- Latch previous data output and clear shift register.
        if (spi_update = '1') then
            status_o <= shiftreg;
            shiftreg <= config_i;
        -- Shift data when enabled.
        elsif (shift_enable = '1' and sclk_fall = '1') then
            shiftreg <= shiftreg(DW-2 downto 0) & miso_i;
        end if;
    end if;
end process;

mosi_o <= shiftreg(DW-1);

end rtl;


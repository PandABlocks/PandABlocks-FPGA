----------------------------------------------------------------------------
--  Project      : Diamond Diamond FOFB Communication Controller
--  Filename     : syncdata.vhd
--  Purpose      : Data mux synchroniser for data lines
--  Author       : Isa S. Uzun
----------------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: Data mux synchroniser for data line. ctrl_i control line
--  should toggle everytime dat_i is changed.
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity syncdata is
    generic (
        DW          : in  integer := 32
    );
    port (
        clk_i       : in  std_logic;
        clk_o       : in  std_logic;
        dat_i       : in  std_logic_vector(DW-1 downto 0);
        val_i       : in  std_logic;
        dat_o       : out std_logic_vector(DW-1 downto 0) := (others => '0');
        val_o       : out std_logic
    );
end syncdata;

architecture rtl of syncdata is

signal val_synced   : std_logic := '0';

begin

p2p_inst : entity work.pulse2pulse
port map (
    in_clk       => clk_i,
    out_clk      => clk_o,
    rst          => '0',
    pulsein      => val_i,
    inbusy       => open,
    pulseout     => val_synced
);

-- Wait until ctrl_i control line settled, then
-- capture dat_i
process(clk_o)
begin
    if rising_edge(clk_o) then
        val_o <= '0';
        if (val_synced = '1') then
            val_o <= '1';
            dat_o <= dat_i;
        end if;
    end if;
end process;

end rtl;

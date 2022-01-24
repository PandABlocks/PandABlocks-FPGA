--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Module name    : pcap_bus_delay.vhd
-- Purpose        : block parameters and block inputs pipeline registers
--                  needed to meet timing constraints
--
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : NO
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------


---------------------------
-- Libraries Declaration --
---------------------------
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.top_defines.all; -- bit_bus_t, pos_bus_t

------------------------
-- Entity Declaration --
------------------------
entity pcap_bus_delay is
port (
    clk_i         : in  std_logic;
    -- Block parameters inputs
    TRIG_EDGE_i   : in  std_logic_vector(1 downto 0);
    SHIFT_SUM_i   : in  std_logic_vector(5 downto 0);
    -- Block inputs
    enable_i      : in  std_logic;
    trig_i        : in  std_logic;
    gate_i        : in  std_logic;
    bit_bus_i     : in  bit_bus_t;    -- std_logic_vector(BBUSW-1 downto 0); BBUSW = 128
    pos_bus_i     : in  pos_bus_t;    -- std32_array(PBUSW-1 downto 0);  PBUSW = 18 to 30
    -- Block parameters outputs
    TRIG_EDGE_o   : out std_logic_vector(1 downto 0);
    SHIFT_SUM_o   : out std_logic_vector(5 downto 0);
    -- Block outputs
    enable_o      : out std_logic;
    trig_o        : out std_logic;
    gate_o        : out std_logic;
    bit_bus_o     : out bit_bus_t;
    pos_bus_o     : out pos_bus_t
);
end pcap_bus_delay;


------------------------------
-- Architecture Declaration --
------------------------------
architecture rtl of pcap_bus_delay is

-- bit_bus is std_logic_vector(BBUSW-1 downto 0); BBUSW = 128
-- pos_bus is std32_array(PBUSW-1 downto 0);  PBUSW = 18 to 30

-- Block inputs pipeline registers
signal enable_r1      : std_logic;
signal trig_r1        : std_logic;
signal gate_r1        : std_logic;
signal bit_bus_r1     : bit_bus_t;
signal pos_bus_r1     : pos_bus_t;

-- Block parameters pipeline registers
signal TRIG_EDGE_r1   : std_logic_vector(1 downto 0);
signal SHIFT_SUM_r1   : std_logic_vector(5 downto 0);


-----------------------
-- Beginning of Code --
-----------------------
begin

  reg_proc : process(clk_i)
  begin
      if rising_edge(clk_i) then
          -- Block parameters pipeline registers
          TRIG_EDGE_r1  <= TRIG_EDGE_i;
          SHIFT_SUM_r1  <= SHIFT_SUM_i;
          -- Block inputs pipeline registers
          enable_r1     <= enable_i;
          trig_r1       <= trig_i;
          gate_r1       <= gate_i;
          bit_bus_r1    <= bit_bus_i;
          pos_bus_r1    <= pos_bus_i;
      end if;
  end process;

  -- assign block parameters outputs
  TRIG_EDGE_o  <= TRIG_EDGE_r1;
  SHIFT_SUM_o  <= SHIFT_SUM_r1;

  -- assign block outputs
  enable_o      <= enable_r1;
  trig_o        <= trig_r1;
  gate_o        <= gate_r1;
  bit_bus_o     <= bit_bus_r1;
  pos_bus_o     <= pos_bus_r1;


end rtl;


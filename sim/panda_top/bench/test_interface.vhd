library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;

-- Package Declaration
package test_interface is

function vectorise (s: std_logic) return std_logic_vector;

procedure writeNowToScreen (text_string : in string);

procedure writeNowWithDataToScreen (
    text_string     : in string;
    decValue        : in integer
);

procedure writeHexToScreen (
  text_string       : in string;
  hexValue          : in std_logic_vector
);

procedure writeDecToScreen (
  text_string       : in string;
  decValue          : in integer
);

procedure FINISH;

procedure FINISH_FAILURE;

procedure PROC_CLK_EAT  (
    clock_count     : in integer;
    signal trn_clk  : in std_logic
);

procedure BLK_WRITE  (
    signal mem_clk       : in  std_logic;
    signal mem_addr      : out std_logic_vector(BLK_AW-1 downto 0);
    signal mem_dat       : out std_logic_vector(31 downto 0);
    signal mem_cs        : out std_logic;
    signal mem_wstb      : out std_logic;
    addr                 : std_logic_vector(BLK_AW-1 downto 0);
    val                  : integer
);

end package test_interface;

-- Package Body
package body test_interface is

procedure writeNowToScreen (
    text_string                 : in string
) is
    variable L      : line;
begin
    write (L, String'("[ "));
    write (L, now);
    write (L, String'(" ] : "));
    write (L, text_string);
    writeline (output, L);
end writeNowToScreen;

procedure writeNowWithDataToScreen (
    text_string     : in string;
    decValue        : in integer
) is
    variable L      : line;
begin
    write (L, String'("[ "));
    write (L, now);
    write (L, String'("] : "));
    write (L, text_string);
    write(L, decValue);
    writeline (output, L);
end writeNowWithDataToScreen;

procedure writeHexToScreen (
    text_string   : in string;
    hexValue      : in std_logic_vector
) is
    variable L      : line;
begin
    write (L, text_string);
    hwrite(L, hexValue);
    writeline (output, L);
end writeHexToScreen;


procedure writeDecToScreen (
    text_string     : in string;
    decValue        : in integer
) is
    variable L      : line;
begin
    write (L, text_string);
    write(L, decValue);
    writeline (output, L);
end writeDecToScreen;


procedure FINISH is
    variable  L : line;
begin
    assert (false)
        report "Simulation Stopped."
        severity failure;
end FINISH;

procedure FINISH_FAILURE is
    variable  L : line;
begin
    assert (false)
        report "Simulation Ended With 1 or more failures"
        severity failure;
end FINISH_FAILURE;

function vectorise (s: std_logic ) return std_logic_vector is
    variable v: std_logic_vector(0 downto 0);
begin
    v(0) := s;
    return v;
end vectorise;

procedure PROC_CLK_EAT  (
    clock_count             : in integer;
    signal trn_clk          : in std_logic
) is
    variable i  : integer;
begin
    for i in 0 to (clock_count - 1) loop
        wait until (trn_clk'event and trn_clk = '1');
    end loop;
end PROC_CLK_EAT;

procedure BLK_WRITE (
    signal mem_clk       : in  std_logic;
    signal mem_addr      : out std_logic_vector(BLK_AW-1 downto 0);
    signal mem_dat       : out std_logic_vector(31 downto 0);
    signal mem_cs        : out std_logic;
    signal mem_wstb      : out std_logic;
    addr                 : std_logic_vector(BLK_AW-1 downto 0);
    val                  : integer
) is
begin
    mem_addr <= addr;
    mem_dat <= std_logic_vector(to_signed(val, 32));
    mem_wstb <= '1';
    mem_cs <= '1';
    PROC_CLK_EAT (1, mem_clk);
    mem_addr <= (others => '0');
    mem_dat <= (others => '0');
    mem_wstb <= '0';
    mem_cs <= '0';
    PROC_CLK_EAT (1, mem_clk);
end BLK_WRITE;

end package body;

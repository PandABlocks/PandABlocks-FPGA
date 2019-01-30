--------------------------------------------------------------------------------
--  File:       lut.vhd
--  Desc:       5-Input LUT.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lut is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    inpa_i              : in  std_logic;
    inpb_i              : in  std_logic;
    inpc_i              : in  std_logic;
    inpd_i              : in  std_logic;
    inpe_i              : in  std_logic;
    out_o               : out std_logic;
    -- 0 = Value of inp, 1 = Pulse on rising edge of inp
    -- 2 = Pulse on falling edge of inp, 3 = Pulse on either edge
    TYPEA               : in  std_logic_vector(31 downto 0);
    TYPEB               : in  std_logic_vector(31 downto 0);
    TYPEC               : in  std_logic_vector(31 downto 0);
    TYPED               : in  std_logic_vector(31 downto 0);
    TYPEE               : in  std_logic_vector(31 downto 0);
    -- Block Parameters
    FUNC                : in  std_logic_vector(31 downto 0)
);
end lut;

architecture rtl of lut is

constant c_value_of_inp : std_logic_vector(1 downto 0) := "00";
constant c_rising_inp   : std_logic_vector(1 downto 0) := "01";
constant c_falling_inp  : std_logic_vector(1 downto 0) := "10";
constant c_either_inp   : std_logic_vector(1 downto 0) := "11";

type t_ABCDE is array(4 downto 0) of std_logic_vector(1 downto 0);

signal ABCDE           : t_ABCDE;
signal index           : unsigned(4 downto 0);
signal inp             : std_logic_vector(4 downto 0);
signal inp_dly         : std_logic_vector(4 downto 0);
signal rising_inp      : std_logic_vector(4 downto 0);
signal falling_inp     : std_logic_vector(4 downto 0);


begin

-- Get the inp into an array
inp <= inpa_i & inpb_i & inpc_i & inpd_i & inpe_i;

-- Register the inpa_i & inpb_i & inpc_i & inpd_i & inpe_i
process(clk_i)
begin
    if rising_edge(clk_i) then
        inp_dly <= inp;
    end if;
end process;

-- Generate rising edge and falling edge
ps_rising_falling: process(inp_dly, inp)
begin
    lp_inp : for i in 4 downto 0 loop
        -- Rising edge
        if inp_dly(i) = '0' and inp(i) = '1' then
            rising_inp(i) <= '1';
        else
            rising_inp(i) <= '0';
        end if;
        -- Falling edge
        if inp_dly(i) = '1' and inp(i) = '0' then
            falling_inp(i) <= '1';
        else
            falling_inp(i) <= '0';
        end if;
    end loop lp_inp;
end process ps_rising_falling;


-- Get A, B, C, D, E into an array
ABCDE(4) <= TYPEA(1 downto 0);
ABCDE(3) <= TYPEB(1 downto 0);
ABCDE(2) <= TYPEC(1 downto 0);
ABCDE(1) <= TYPED(1 downto 0);
ABCDE(0) <= TYPEE(1 downto 0);


-- Assembe index to function
-- 1. index-inp
-- 2. index-risingg inp
-- 3. index-falling inp
-- 4. index-rising or falling inps
gen_index: for i in 4 downto 0 generate
    index(i) <= inp(i) when ABCDE(i) = c_value_of_inp else
            rising_inp(i) when ABCDE(i) = c_rising_inp else
            falling_inp(i) when ABCDE(i) = c_falling_inp else
            rising_inp(i) or falling_inp(i) when ABCDE(i) = c_either_inp else
            '0';
end generate gen_index;


-- Assign output
process(clk_i)
begin
    if rising_edge(clk_i) then
        out_o <= FUNC(to_integer(index));
    end if;
end process;

end rtl;


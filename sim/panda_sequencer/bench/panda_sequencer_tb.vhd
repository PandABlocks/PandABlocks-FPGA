LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;
use work.test_interface.all;

use std.textio.all;

ENTITY panda_sequencer_tb IS
END panda_sequencer_tb;

ARCHITECTURE behavior OF panda_sequencer_tb IS

--Inputs
signal clk                  : std_logic := '0';
signal reset                : std_logic := '1';

--Outputs
signal pulse                : std_logic_vector(5 downto 0);
signal act                  : std_logic;
signal length               : integer;

file table                  : text open read_mode is "table.dat";

signal gate                 : std_logic := '0';
signal inpa                 : std_logic := '0';
signal inpb                 : std_logic := '0';
signal inpc                 : std_logic := '0';
signal inpd                 : std_logic := '0';
signal outa                 : std_logic;
signal outb                 : std_logic;
signal outc                 : std_logic;
signal outd                 : std_logic;
signal oute                 : std_logic;
signal outf                 : std_logic;
signal active               : std_logic;

signal FORCE_GATE           : std_logic := '0';
signal PRESCALE             : std_logic_vector(31 downto 0);
signal SOFT_GATE            : std_logic := '0';
signal TABLE_PUSH_START     : std_logic := '0';
signal TABLE_PUSH_DATA      : std_logic_vector(31 downto 0);
signal TABLE_PUSH_WSTB      : std_logic := '0';
signal TABLE_REPEAT         : std_logic_vector(31 downto 0);
signal TABLE_LENGTH         : std_logic_vector(15 downto 0);
signal CUR_FRAME            : std_logic_vector(31 downto 0);
signal CUR_FCYCLES          : std_logic_vector(31 downto 0);
signal CUR_TCYCLE           : std_logic_vector(31 downto 0);
signal CUR_STATE            : std_logic_vector(31 downto 0);

signal start                : std_logic;

BEGIN

clk <= not clk after 4 ns;
reset <= '0' after 1 us;
inpa <= not inpa after 1 us;

uut: entity work.panda_sequencer
port map (
    -- Clock and Reset
    clk_i               => clk,
    -- Block Input and Outputs
    gate_i              => gate,
    inpa_i              => inpa,
    inpb_i              => inpb,
    inpc_i              => inpc,
    inpd_i              => inpd,
    outa_o              => outa,
    outb_o              => outb,
    outc_o              => outc,
    outd_o              => outd,
    oute_o              => oute,
    outf_o              => outf,
    active_o            => active,
    -- Block Parameters
    FORCE_GATE          => FORCE_GATE,
    PRESCALE            => PRESCALE,
    SOFT_GATE           => SOFT_GATE,
    TABLE_PUSH_START    => TABLE_PUSH_START,
    TABLE_PUSH_DATA     => TABLE_PUSH_DATA,
    TABLE_PUSH_WSTB     => TABLE_PUSH_WSTB,
    TABLE_REPEAT        => TABLE_REPEAT,
    TABLE_LENGTH        => TABLE_LENGTH,
    CUR_FRAME           => CUR_FRAME,
    CUR_FCYCLES         => CUR_FCYCLES,
    CUR_TCYCLE          => CUR_TCYCLE,
    CUR_STATE           => CUR_STATE
);

-- Stimulus process
stim_proc: process
    variable inputline  : line;
    variable data       : integer;
begin
    start <= '0';
    PRESCALE <= X"0000_0002";
    TABLE_PUSH_START <= '0';
    TABLE_PUSH_DATA <= (others => '0');
    TABLE_PUSH_WSTB <= '0';
    TABLE_REPEAT <= X"0000_0005";
    TABLE_LENGTH <= (others => '0');

    length <= 0;
    PROC_CLK_EAT(125, clk);

    TABLE_PUSH_START <= '1';
    PROC_CLK_EAT(1, clk);
    TABLE_PUSH_START <= '0';
    PROC_CLK_EAT(125, clk);

    while (not(endfile(table))) loop
        readline(table, inputline);
        read(inputline, data);
        TABLE_PUSH_DATA <= std_logic_vector(to_unsigned(data, 32));
        TABLE_PUSH_WSTB <= '1';
        PROC_CLK_EAT(1, clk);
        TABLE_PUSH_DATA <= (others => '0');
        TABLE_PUSH_WSTB <= '0';
        PROC_CLK_EAT(1, clk);
        length <= length + 1;
    end loop;

    PROC_CLK_EAT(125, clk);
    TABLE_LENGTH <= std_logic_vector(to_unsigned(length, 16));
    PROC_CLK_EAT(125, clk);
    start <= '1';
    PROC_CLK_EAT(1, clk);
    start <= '0';
    wait;
end process;

-- Generate Gate
--
process
begin
    gate <= '0';
    PROC_CLK_EAT(50*125, clk);
    gate <= '1';
    PROC_CLK_EAT(25*125, clk);
    gate <= '0';
    PROC_CLK_EAT(100*125, clk);
    gate <= '1';
    wait;
end process;

--process(clk)
--begin
--    if rising_edge(clk) then
--        if (start = '1') then
--            gate <= '1';
--        elsif (active = '0') then
--            gate <= '0';
--        end if;
--    end if;
--end process;


end;

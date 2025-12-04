--------------------------------------------------------------------------------
--  PandA Motion Project - 2024
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--      MaxIV Laboratory, Lund, Sweden
--
--------------------------------------------------------------------------------
--
--  Description : Sine wave generator
--  latest rev  : feb 7 2024
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity singen is
port (
    -- Clock and Reset
    clk_i                 : in  std_logic;
    ENABLE_i              : in  std_logic;
    -- Block Input and Outputs
    amplitude             : in  std_logic_vector(31 downto 0); -- sfix32_En30
    frequency             : in  std_logic_vector(31 downto 0); -- sfix32_En31
    out_o                 : out std_logic_vector(31 downto 0)  -- sfix32_En31
    );
end singen;


architecture rtl of singen is

    -- account for DDS pipelining
    constant WAIT_STATES   : natural := 13;
    constant WAIT_CNTR_MAX : natural := 15;
    
    signal singen_clr      : std_logic := '1';
    signal singen_res_n    : std_logic := '0';
    signal singen_ce_out   : std_logic;
    signal wait_cntr       : natural range 0 to WAIT_CNTR_MAX :=0;
    signal singen_out      : std_logic_vector(31 downto 0);

    component singenmc_0
        port
            (
            rational_freq : in  std_logic_vector(31 downto 0);
            ampl          : in  std_logic_vector(31 downto 0);
            reset_n       : in  std_logic_vector(0 downto 0);
            clk           : in  std_logic;
            clr           : in  std_logic;
            sine_out      : out std_logic_vector(31 downto 0);
            ce_out        : out std_logic_vector(0 downto 0)
            );
    end component;

begin

    the_singen: singenmc_0
        port map
            (
            rational_freq  => frequency,
            ampl           => amplitude,
            reset_n(0)     => singen_res_n,
            clk            => clk_i,
            clr            => singen_clr,
            sine_out       => singen_out,
            ce_out(0)      => singen_ce_out
            );
    
    reset_process : process (clk_i, ENABLE_i)
    begin
        if rising_edge(clk_i) then
            if ENABLE_i = '0' then
                singen_res_n    <= '0';
                if (singen_clr = '0') and (wait_cntr=WAIT_STATES) then
                    singen_clr <= '1';
                else
                    singen_clr <= singen_clr;
                end if;
            else
                singen_clr  <= '0';
                if (singen_res_n = '0') and (singen_ce_out = '1') then
                    singen_res_n <= '1';
                else
                    singen_res_n <= singen_res_n;
                end if;
            end if;
        end if;
    end process reset_process;


    wait_process : process (clk_i)
    begin
        if rising_edge(clk_i) then
            if ENABLE_i = '1' then
                wait_cntr <= 0;
            else
                if (singen_clr = '0') and (singen_ce_out = '1') then
                    wait_cntr <= wait_cntr +1;
                else
                    wait_cntr <= wait_cntr;
                end if;
            end if;            
        end if;    
    end process wait_process;


    -- first DDS sine lookup table value could be not exactly zero;
    -- just output a solid 0 when disabled
    out_process : process (clk_i)
    begin
        if rising_edge(clk_i) then
            if ENABLE_i = '1' then
                out_o <= singen_out;
            else
                out_o <= "00000000000000000000000000000000";
            end if;            
        end if;    
    end process out_process;
    
end;

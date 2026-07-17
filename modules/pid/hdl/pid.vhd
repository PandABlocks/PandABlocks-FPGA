--------------------------------------------------------------------------------
--  PandA Motion Project - 2024
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--      MaxIV Laboratory, Lund, Sweden
--
--------------------------------------------------------------------------------
--
--  Description : PID controller; 
--                       - developed with model composer
--                       - floating point
--                       - fixed sampling frequency=1 MHz
--
--  latest rev  : feb 2 2024
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pid is
port (
    -- Clock and Reset
    clk_i                 : in  std_logic;
    ENABLE_i              : in  std_logic;
    -- Block Input and Outputs
    cmd_i                 : in  std_logic_vector(31 downto 0); -- sfix32_En31
    meas_i                : in  std_logic_vector(31 downto 0); -- sfix32_En31
    thresh                : in  std_logic_vector(31 downto 0); -- sfix32_En30
    anti_int_wndp_rat_g   : in  std_logic_vector(31 downto 0); -- sfix32_En30
    max_out               : in  std_logic_vector(31 downto 0); -- sfix32_En30
    out_o                 : out std_logic_vector(31 downto 0); -- sfix32_En31
    -- internal gains
    reserved_gp           : in  std_logic_vector(31 downto 0); -- ufix32_En24 - note: UNSIGNED
    reserved_gi           : in  std_logic_vector(31 downto 0); -- ufix32_En25 - note: UNSIGNED
    reserved_g1d          : in  std_logic_vector(31 downto 0); -- ufix32_En32 - note: UNSIGNED
    reserved_g2d          : in  std_logic_vector(31 downto 0); -- ufix32_En07 - note: UNSIGNED
    -- boolean
    sample_clk_i          : in  std_logic;
    inv_cmd               : in  std_logic_vector(31 downto 0);
    inv_meas              : in  std_logic_vector(31 downto 0);
    deriv_on_procvar      : in  std_logic_vector(31 downto 0)
    );
end pid;


architecture rtl of pid is

    constant WAIT_STATES   : natural := 4;
    
    signal pid_clkdiv_clr  : std_logic := '1';
    signal pid_res         : std_logic := '1';
    signal pid_ce_in       : std_logic;
    signal pid_ce_out, pid_ce_out_prev : std_logic;
    signal sample_clk_prev : std_logic;
    signal wait_cntr       : natural range 0 to WAIT_STATES :=0;

    component pidmc_0
        port
            (
            aiw_g       : in  std_logic_vector(31 downto 0);
            ce          : in  std_logic_vector(0 DOWNTO 0);
            g1d         : in  std_logic_vector(31 downto 0);
            g2d         : in  std_logic_vector(31 downto 0);
            gi          : in  std_logic_vector(31 downto 0);
            pv_deriv    : in  std_logic_vector(0 downto 0);
            command_in  : in  std_logic_vector(31 downto 0);
            inv_command : in  std_logic_vector(0 downto 0);
            inv_meas    : in  std_logic_vector(0 downto 0);
            kp          : in  std_logic_vector(30 downto 0);
            meas_in     : in  std_logic_vector(31 downto 0);
            res         : in  std_logic_vector(0 downto 0);
            sat_limit   : in  std_logic_vector(31 downto 0);
            thr_in      : in  std_logic_vector(31 downto 0);
            clk         : in  std_logic;
            clr         : in  std_logic;
            ce_out      : out std_logic_vector(0 downto 0);
            control_out : out std_logic_vector(31 downto 0)
            );
    end component;


begin
    
    the_pid: pidmc_0
        port map
            (
            aiw_g          => anti_int_wndp_rat_g,
            ce(0)          => pid_ce_in,
            g1d            => reserved_g1d,
            g2d            => reserved_g2d,
            gi             => reserved_gi,
            pv_deriv(0)    => deriv_on_procvar(0),
            command_in     => cmd_i,
            inv_command(0) => inv_cmd(0),
            inv_meas(0)    => inv_meas(0),
            res(0)         => pid_res,
            kp             => reserved_gp(30 downto 0),
            meas_in        => meas_i,
            sat_limit      => max_out,
            thr_in         => thresh,
            clk            => clk_i,
            clr            => pid_clkdiv_clr,
            ce_out(0)      => pid_ce_out,
            control_out    => out_o
            );

    -- pipes to detect edges
    pipes: process (clk_i)
    begin
        if rising_edge(clk_i) then
            sample_clk_prev <= sample_clk_i;
            pid_ce_out_prev <= pid_ce_out;
        end if;
    end process pipes;
    
    -- synchronize reset to the PID internal 1 MHz clock (== ce_out pulse)
    reset_process : process (clk_i, ENABLE_i)
    begin
        if rising_edge(clk_i) then
            if ENABLE_i = '0' then
                pid_res         <= '1';
                if (pid_clkdiv_clr = '0') and (wait_cntr=WAIT_STATES) then
                    pid_clkdiv_clr <= '1';
                else
                    pid_clkdiv_clr <= pid_clkdiv_clr;
                end if;
            else
                pid_clkdiv_clr  <= '0';
                pid_res <= '0';
            end if;
        end if;
    end process reset_process;

    -- wait until the reset propagates through the PID and produces a 0 output
    wait_process : process (clk_i)
    begin
        if rising_edge(clk_i) then
            if ENABLE_i = '1' then
                wait_cntr <= 0;
            else
                if (pid_clkdiv_clr = '0') and (pid_ce_out = '1') and (wait_cntr/=WAIT_STATES) then
                    wait_cntr <= wait_cntr +1;
                else
                    wait_cntr <= wait_cntr;
                end if;
            end if;            
        end if;    
    end process wait_process;

    -- synchronize external sampling clock to the PID internal 1 MHz clock (== ce_out pulse)
    -- and supply it as CE_in to the PID IP
    extfs_process : process (clk_i, sample_clk_i)
    begin
        if rising_edge(clk_i) then
            if((sample_clk_i = '1') and (sample_clk_prev='0')) then
                pid_ce_in <= '1';
            elsif((pid_ce_out = '1') and (pid_ce_out_prev='0')) then
                pid_ce_in <= '0';
            else
                pid_ce_in <= pid_ce_in;
            end if;
        end if;
    end process extfs_process;

end rtl;

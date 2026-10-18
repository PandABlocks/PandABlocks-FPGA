--------------------------------------------------------------------------------
--  PandA Motion Project
--      Diamond Light Source, Oxford, UK
--------------------------------------------------------------------------------
--
--  Description : Test wrapper connecting endat_master to endat_slave over a
--                model of the half duplex data line, for the cocotb loopback
--                test. The line has a propagation delay of CABLE_DELAY clk_i
--                cycles each way. Each end drives a weak low when its output
--                is disabled, so the line reads low when neither end drives
--                it and both ends driving at once shows up as X.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity endat_loopback is
generic (
    TCAL_TIMEOUT    : natural := 125000;
    START_DELAY     : natural := 250;
    TCAL_CLOCKS     : natural := 2;
    RECOVERY        : natural := 1250;
    -- Propagation delay of the line in clk_i cycles, each way
    CABLE_DELAY     : natural := 0
);
port (
    clk_i : in  std_logic;
    reset_i : in  std_logic;
    slave_reset_i : in  std_logic;
    -- Master parameters
    BITS : in  std_logic_vector(5 downto 0);
    CLK_PERIOD : in  std_logic_vector(31 downto 0);
    FRAME_PERIOD : in  std_logic_vector(31 downto 0);
    DELAY_COMP : in  std_logic_vector(15 downto 0);
    -- Slave parameters and position
    GENERATOR_ERROR : in  std_logic;
    posn_i : in  std_logic_vector(31 downto 0);
    -- Master outputs
    link_up_o : out std_logic;
    health_o : out std_logic_vector(31 downto 0);
    posn_o : out std_logic_vector(31 downto 0);
    posn_valid_o : out std_logic;
    -- Slave outputs
    slave_health_o : out std_logic_vector(31 downto 0)
);
end;

architecture rtl of endat_loopback is

-- Master end of the line
signal m_sck : std_logic;
signal m_dat : std_logic;
signal m_oe : std_logic;
signal m_drive : std_logic;
signal m_line : std_logic;
signal m_dat_in : std_logic;

-- Slave end of the line
signal s_sck : std_logic;
signal s_dat : std_logic;
signal s_oe : std_logic;
signal s_drive : std_logic;
signal s_line : std_logic;
signal s_dat_in : std_logic;

-- Drives after the propagation delay
signal sck_dly : std_logic;
signal m_drive_dly : std_logic;
signal s_drive_dly : std_logic;

begin

-- What each end puts on the line, a weak low when not driving
m_drive <= m_dat when m_oe else 'L';
s_drive <= s_dat when s_oe else 'L';

-- The line at each end is the local drive resolved with the far end's
-- drive after the propagation delay
m_line <= m_drive;
m_line <= s_drive_dly;
s_line <= s_drive;
s_line <= m_drive_dly;
m_dat_in <= to_X01(m_line);
s_dat_in <= to_X01(s_line);

gen_direct: if CABLE_DELAY = 0 generate
    sck_dly <= m_sck;
    m_drive_dly <= m_drive;
    s_drive_dly <= s_drive;
end generate;

gen_delay: if CABLE_DELAY > 0 generate
    signal sck_sr : std_logic_vector(1 to CABLE_DELAY) := (others => '1');
    signal m_drive_sr : std_logic_vector(1 to CABLE_DELAY) := (others => 'L');
    signal s_drive_sr : std_logic_vector(1 to CABLE_DELAY) := (others => 'L');
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            sck_sr(1) <= m_sck;
            m_drive_sr(1) <= m_drive;
            s_drive_sr(1) <= s_drive;
            for i in 2 to CABLE_DELAY loop
                sck_sr(i) <= sck_sr(i-1);
                m_drive_sr(i) <= m_drive_sr(i-1);
                s_drive_sr(i) <= s_drive_sr(i-1);
            end loop;
        end if;
    end process;
    sck_dly <= sck_sr(CABLE_DELAY);
    m_drive_dly <= m_drive_sr(CABLE_DELAY);
    s_drive_dly <= s_drive_sr(CABLE_DELAY);
end generate;

s_sck <= sck_dly;

master_inst : entity work.endat_master
generic map (
    TCAL_TIMEOUT    => TCAL_TIMEOUT,
    START_DELAY     => START_DELAY
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    CLK_PERIOD      => CLK_PERIOD,
    FRAME_PERIOD    => FRAME_PERIOD,
    DELAY_COMP      => DELAY_COMP,
    link_up_o       => link_up_o,
    health_o        => health_o,
    endat_sck_o     => m_sck,
    endat_dat_i     => m_dat_in,
    endat_dat_o     => m_dat,
    endat_dat_oe_o  => m_oe,
    posn_o          => posn_o,
    posn_valid_o    => posn_valid_o
);

slave_inst : entity work.endat_slave
generic map (
    TCAL_CLOCKS     => TCAL_CLOCKS,
    RECOVERY        => RECOVERY
)
port map (
    clk_i           => clk_i,
    reset_i         => reset_i or slave_reset_i,
    BITS            => BITS,
    GENERATOR_ERROR => GENERATOR_ERROR,
    health_o        => slave_health_o,
    posn_i          => posn_i,
    endat_sck_i     => s_sck,
    endat_dat_i     => s_dat_in,
    endat_dat_o     => s_dat,
    endat_dat_oe_o  => s_oe
);

end;

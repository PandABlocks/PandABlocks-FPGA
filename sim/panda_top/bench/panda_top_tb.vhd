LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.test_interface.all;

ENTITY panda_top_tb IS
END panda_top_tb;

ARCHITECTURE behavior OF panda_top_tb IS 

--Inputs
signal enc0_ctrl_pad_i : std_logic_vector(3 downto 0) := (others => '0');

--BiDirs
signal DDR_addr         : std_logic_vector(14 downto 0);
signal DDR_ba           : std_logic_vector(2 downto 0);
signal DDR_cas_n        : std_logic;
signal DDR_ck_n         : std_logic;
signal DDR_ck_p         : std_logic;
signal DDR_cke          : std_logic;
signal DDR_cs_n         : std_logic;
signal DDR_dm           : std_logic_vector(3 downto 0);
signal DDR_dq           : std_logic_vector(31 downto 0);
signal DDR_dqs_n        : std_logic_vector(3 downto 0);
signal DDR_dqs_p        : std_logic_vector(3 downto 0);
signal DDR_odt          : std_logic;
signal DDR_ras_n        : std_logic;
signal DDR_reset_n      : std_logic;
signal DDR_we_n         : std_logic;
signal FIXED_IO_ddr_vrn : std_logic;
signal FIXED_IO_ddr_vrp : std_logic;
signal FIXED_IO_mio     : std_logic_vector(53 downto 0);
signal FIXED_IO_ps_clk  : std_logic;
signal FIXED_IO_ps_porb : std_logic;
signal FIXED_IO_ps_srstb: std_logic;
signal Am0_pad_io       : std_logic_vector(0 downto 0);
signal Bm0_pad_io       : std_logic_vector(0 downto 0);
signal Zm0_pad_io       : std_logic_vector(0 downto 0);
signal As0_pad_io       : std_logic_vector(0 downto 0);
signal Bs0_pad_io       : std_logic_vector(0 downto 0);
signal Zs0_pad_io       : std_logic_vector(0 downto 0);

--Outputs
signal enc0_ctrl_pad_o  : std_logic_vector(11 downto 0);
signal leds             : std_logic_vector(1 downto 0);
signal clk              : std_logic := '1';

signal A_IN_P           : std_logic;
signal B_IN_P           : std_logic;
signal Z_IN_P           : std_logic := '0';
signal CLK_OUT_P        : std_logic;
signal DATA_IN_P        : std_logic := '0';

signal A_OUT_P          : std_logic;
signal B_OUT_P          : std_logic;
signal Z_OUT_P          : std_logic;
signal CLK_IN_P         : std_logic := '0';
signal DATA_OUT_P       : std_logic;

signal inputs           : unsigned(15 downto 0) := X"0000";

signal ttlin_pad        : std_logic_vector(5 downto 0);
signal lvdsin_pad       : std_logic_vector(1 downto 0);


-- #of Burst per Host Block. Each AXI3 burst has 16 strobes.
constant TLP_SIZE       : integer := 128;

-- Host Block Size. Each TLP has 16 x 4 bytes.
constant BLOCK_SIZE     : integer := TLP_SIZE * 64; -- 8KByte

begin

clk <= not clk after 4 ns;

ttlin_pad <= std_logic_vector(inputs(13 downto 8));
lvdsin_pad <= std_logic_vector(inputs(15 downto 14));

-- Instantiate the Unit Under Test (UUT)
uut: entity work.panda_top
PORT MAP (
    DDR_addr            => DDR_addr,
    DDR_ba              => DDR_ba,
    DDR_cas_n           => DDR_cas_n,
    DDR_ck_n            => DDR_ck_n,
    DDR_ck_p            => DDR_ck_p,
    DDR_cke             => DDR_cke,
    DDR_cs_n            => DDR_cs_n,
    DDR_dm              => DDR_dm,
    DDR_dq              => DDR_dq,
    DDR_dqs_n           => DDR_dqs_n,
    DDR_dqs_p           => DDR_dqs_p,
    DDR_odt             => DDR_odt,
    DDR_ras_n           => DDR_ras_n,
    DDR_reset_n         => DDR_reset_n,
    DDR_we_n            => DDR_we_n,
    FIXED_IO_ddr_vrn    => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp    => FIXED_IO_ddr_vrp,
    FIXED_IO_mio        => FIXED_IO_mio,
    FIXED_IO_ps_clk     => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb    => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb   => FIXED_IO_ps_srstb,
    Am0_pad_io          => Am0_pad_io,
    Bm0_pad_io          => Bm0_pad_io,
    Zm0_pad_io          => Zm0_pad_io,
    As0_pad_io          => As0_pad_io,
    Bs0_pad_io          => Bs0_pad_io,
    Zs0_pad_io          => Zs0_pad_io,
    enc0_ctrl_pad_i     => enc0_ctrl_pad_i,
    enc0_ctrl_pad_o     => enc0_ctrl_pad_o,
    ttlin_pad_i         => ttlin_pad,
    lvdsin_pad_i        => lvdsin_pad,
    ttlout_pad_o        => open,
    lvdsout_pad_o       => open,
    leds                => leds
);

daughter_card_model_inst : entity work.daughter_card_model
port map (
    -- Front Panel via DB15
    A_IN_P      => A_IN_P,
    B_IN_P      => B_IN_P,
    Z_IN_P      => Z_IN_P,
    CLK_OUT_P   => CLK_OUT_P,
    DATA_IN_P   => DATA_IN_P,

    A_OUT_P     => A_OUT_P,
    B_OUT_P     => B_OUT_P,
    Z_OUT_P     => Z_OUT_P,
    CLK_IN_P    => CLK_IN_P,
    DATA_OUT_P  => DATA_OUT_P,

    A_IN        => Am0_pad_io(0),
    B_IN        => Bm0_pad_io(0),
    Z_IN        => Zm0_pad_io(0),
    A_OUT       => As0_pad_io(0),
    B_OUT       => Bs0_pad_io(0),
    Z_OUT       => Zs0_pad_io(0),

    CTRL_IN     => enc0_ctrl_pad_o,
    CTRL_OUT    => enc0_ctrl_pad_i
);

incr_encoder_model_inst : entity work.incr_encoder_model
port map (
    CLK         => clk,
    A_OUT       => open, --A_IN_P,
    B_OUT       => open  --B_IN_P
);

A_IN_P <= A_OUT_P;
B_IN_P <= B_OUT_P;

-- Loopback on SSI
CLK_IN_P <= CLK_OUT_P;
DATA_IN_P <= DATA_OUT_P;


-- Simple counter to emulate TTL inputs
process(clk)
begin
    if rising_edge(clk) then
        inputs <= inputs + 1;
    end if;
end process;


end;

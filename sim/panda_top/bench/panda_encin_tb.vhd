LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

library work;
use work.test_interface.all;
use work.addr_defines.all;

ENTITY panda_encin_tb IS
END panda_encin_tb;

ARCHITECTURE behavior OF panda_encin_tb IS 

--Inputs
signal clk : std_logic := '0';
signal reset : std_logic := '1';
signal mem_cs : std_logic := '0';
signal mem_wstb : std_logic := '0';
signal mem_addr : std_logic_vector(3 downto 0) := (others => '0');
signal mem_dat : std_logic_vector(31 downto 0) := (others => '0');
signal a_i : std_logic := '0';
signal b_i : std_logic := '0';
signal z_i : std_logic := '0';
signal mdat_i : std_logic := '0';
signal mclk_o : std_logic;
signal mdat_o : std_logic;
signal posn_o : std_logic_vector(31 downto 0);
signal posn_valid_o : std_logic;
signal iobuf_ctrl_o : std_logic_vector(2 downto 0);

signal enc_dat      : std_logic_vector(23 downto 0);
signal enc_val      : std_logic;

BEGIN

clk <= not clk after 4ns;
reset <= '0' after 1 us;

uut: entity work.panda_encin
PORT MAP (
    clk_i           => clk,
    reset_i         => reset,
    mem_cs_i        => mem_cs,
    mem_wstb_i      => mem_wstb,
    mem_addr_i      => mem_addr,
    mem_dat_i       => mem_dat,
    a_i             => a_i,
    b_i             => b_i,
    z_i             => z_i,
    mclk_o          => mclk_o,
    mdat_i          => mdat_i,
    mdat_o          => mdat_o,
    posn_o          => posn_o,
    posn_valid_o    => posn_valid_o,
    iobuf_ctrl_o    => iobuf_ctrl_o
);


-- Stimulus process
stim_proc: process
begin
    wait for 10 us;

    BLK_WRITE (clk, mem_addr, mem_dat, mem_cs, mem_wstb, ENCIN_PROT_ADDR, 1);
    BLK_WRITE (clk, mem_addr, mem_dat, mem_cs, mem_wstb, ENCIN_BITS_ADDR, 24);
--    BLK_WRITE (clk, mem_addr, mem_dat, mem_cs, mem_wstb, ENCIN_FRM_SRC_ADDR, 1);
--    BLK_WRITE (clk, mem_addr, mem_dat, mem_cs, mem_wstb, ENCIN_FRM_VAL_ADDR, 3);

    PROC_CLK_EAT(25000, clk);

    FINISH;

end process;

panda_ssislv_inst : entity work.panda_ssislv
port map (
    clk_i           => clk,
    reset_i         => reset,
    ssi_sck_i       => mclk_o,
    ssi_dat_o       => mdat_i,
    enc_dat_i       => enc_dat,
    enc_val_i       => enc_val
);

-- Stimulus process
test_proc: process
begin
    enc_val <= '0';
    enc_dat <= (others => '0');
    wait until falling_edge(reset);
    PROC_CLK_EAT(10, clk);
    enc_val <= '1';
    enc_dat <= X"123456";
    PROC_CLK_EAT(1, clk);
    enc_val <= '0';

--    for I in 0 to 100 loop
--        wait until rising_edge(enc_val_rb);
--        PROC_CLK_EAT(1, clk);
--        enc_val <= '1';
--        enc_dat <= enc_dat(22 downto 0) & enc_dat(23);
--        PROC_CLK_EAT(1, clk);
--        enc_val <= '0';
--    end loop;

    wait;
end process;

end;

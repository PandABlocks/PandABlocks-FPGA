library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.txt_util.all;
use work.std_logic_textio.all;
use work.test_interface.all;

entity panda_ps is
  port (
    DDR_addr            : inout STD_LOGIC_VECTOR(14 downto 0):=(others => '0');
    DDR_ba              : inout STD_LOGIC_VECTOR(2  downto 0):=(others => '0');
    DDR_cas_n           : inout STD_LOGIC := '0';
    DDR_ck_n            : inout STD_LOGIC := '0';
    DDR_ck_p            : inout STD_LOGIC := '0';
    DDR_cke             : inout STD_LOGIC := '0';
    DDR_cs_n            : inout STD_LOGIC := '0';
    DDR_dm              : inout STD_LOGIC_VECTOR (3  downto 0):=(others=>'0');
    DDR_dq              : inout STD_LOGIC_VECTOR (31 downto 0):=(others=>'0');
    DDR_dqs_n           : inout STD_LOGIC_VECTOR (3  downto 0):=(others=>'0');
    DDR_dqs_p           : inout STD_LOGIC_VECTOR (3  downto 0):=(others=>'0');
    DDR_odt             : inout STD_LOGIC := '0';
    DDR_ras_n           : inout STD_LOGIC := '0';
    DDR_reset_n         : inout STD_LOGIC := '0';
    DDR_we_n            : inout STD_LOGIC := '0';

    FIXED_IO_ddr_vrn    : inout STD_LOGIC := '0';
    FIXED_IO_ddr_vrp    : inout STD_LOGIC := '0';
    FIXED_IO_mio        : inout STD_LOGIC_VECTOR(53 downto 0):=(others=>'0');
    FIXED_IO_ps_clk     : inout STD_LOGIC := '0';
    FIXED_IO_ps_porb    : inout STD_LOGIC := '0';
    FIXED_IO_ps_srstb   : inout STD_LOGIC := '0';
    IRQ_F2P             : in STD_LOGIC := '0';

    FCLK_CLK0           : out STD_LOGIC;
    FCLK_LEDS           : out STD_LOGIC_VECTOR (31 downto 0);
    FCLK_RESET0_N       : out STD_LOGIC;

    M00_AXI_araddr      : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_arprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_arready     : in STD_LOGIC;
    M00_AXI_arvalid     : out STD_LOGIC;
    M00_AXI_awaddr      : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_awprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M00_AXI_awready     : in STD_LOGIC;
    M00_AXI_awvalid     : out STD_LOGIC;
    M00_AXI_bready      : out STD_LOGIC;
    M00_AXI_bresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_bvalid      : in STD_LOGIC;
    M00_AXI_rdata       : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_rready      : out STD_LOGIC;
    M00_AXI_rresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M00_AXI_rvalid      : in STD_LOGIC;
    M00_AXI_wdata       : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M00_AXI_wready      : in STD_LOGIC;
    M00_AXI_wstrb       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M00_AXI_wvalid      : out STD_LOGIC;
    M01_AXI_araddr      : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M01_AXI_arprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M01_AXI_arready     : in STD_LOGIC;
    M01_AXI_arvalid     : out STD_LOGIC;
    M01_AXI_awaddr      : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M01_AXI_awprot      : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M01_AXI_awready     : in STD_LOGIC;
    M01_AXI_awvalid     : out STD_LOGIC;
    M01_AXI_bready      : out STD_LOGIC;
    M01_AXI_bresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M01_AXI_bvalid      : in STD_LOGIC;
    M01_AXI_rdata       : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M01_AXI_rready      : out STD_LOGIC;
    M01_AXI_rresp       : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M01_AXI_rvalid      : in STD_LOGIC;
    M01_AXI_wdata       : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M01_AXI_wready      : in STD_LOGIC;
    M01_AXI_wstrb       : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M01_AXI_wvalid      : out STD_LOGIC
);
end panda_ps;

architecture model of panda_ps is

signal clk100           : std_logic := '0';
signal resetn           : std_logic := '0';


begin

-- Clock and Reset
FCLK_CLK0 <= clk100;
FCLK_RESET0_N <= resetn;

clk100 <= not clk100 after 5 ns;
resetn <= '1' after 1 us;

-- Unused IO
FCLK_LEDS <= (others => '0');

--
process
    file CMD_SCRIPT         : text;
    variable textline       : line;
    variable command        : string(1 to 80);
    variable char1          : string(1 to 1);
    variable WaitDelay      : integer := 0;
    variable axi_addr       : std_logic_vector(31 downto 0);
    variable axi_data       : std_logic_vector(31 downto 0);

    -- AXI Write Procedure
    procedure AXI_WRITE (
        addr : in std_logic_vector(31 downto 0);
        data : in std_logic_vector(31 downto 0)
    ) is
    begin
        PROC_CLK_EAT(1, clk100);
        -- Address
        M00_AXI_awaddr <= addr;
        M00_AXI_awvalid <= '1';
        -- Data
        M00_AXI_wdata <= data;
        M00_AXI_wstrb <= "1111";
        M00_AXI_wvalid <= '1';
        PROC_CLK_EAT(1, clk100);
        M00_AXI_awvalid <= '0';
        M00_AXI_wstrb <= "0000";
        M00_AXI_wvalid <= '0';
        PROC_CLK_EAT(10, clk100);
        REPORT "CMD Write: ADDR 0x" & hstr(addr) & 
            " DATA " & str(to_integer(unsigned(data)));
    end procedure AXI_WRITE;

begin
    M00_AXI_araddr     <= (others => '0');
    M00_AXI_arprot     <= (others => '0');
    M00_AXI_arvalid    <= '0';
    M00_AXI_awaddr      <= (others => '0');
    M00_AXI_awprot      <= (others => '0');
    M00_AXI_awvalid     <= '0';
    M00_AXI_bready      <= '1';
    M00_AXI_rready      <= '0';
    M00_AXI_wdata       <= (others => '0');
    M00_AXI_wstrb       <= (others => '0');
    M00_AXI_wvalid      <= '0';
    M01_AXI_araddr      <= (others => '0');
    M01_AXI_arprot      <= (others => '0');
    M01_AXI_arvalid     <= '0';
    M01_AXI_awaddr      <= (others => '0');
    M01_AXI_awprot      <= (others => '0');
    M01_AXI_awvalid     <= '0';
    M01_AXI_bready      <= '0';
    M01_AXI_rready      <= '0';
    M01_AXI_wdata       <= (others => '0');
    M01_AXI_wstrb       <= (others => '0');
    M01_AXI_wvalid      <= '0';


    file_open(CMD_SCRIPT, "command.dat", read_mode);

    while not endfile(CMD_SCRIPT) loop

        -- Skip empty lines
        readline(CMD_SCRIPT, textline);
            next when textline'length = 0;

        -- Reset command string
        for I in 1 to command'length loop
            command(I to I) := " ";
        end loop;

        -- Read command
        for I in 1 to command'length loop
            exit when I > textline'length;
            read(textline, command(I to I));

            -- Comment
            if (command(1 to 1) = ";") then
                read(textline, command(1 to textline'length));
                REPORT(command) SEVERITY warning;
                exit;
            end if;

            -- WAIT Command
            if (command(1 to 4) = "WAIT") then
                char1 := " ";
                while (char1 /= "=") loop
                    read(textline, char1);
                end loop;
                read(textline, WaitDelay);
                REPORT("Wait for " & str(WaitDelay) & " us");
                for i in 1 to WaitDelay loop
                    wait for 1 us;
                end loop;
                exit;
            end if;

            -- Register Write Command
            if (command(1 to 7) = "REG_SET") then
                -- Collect address
                char1 := " ";
                while (char1 /= "x") loop
                    read(textline, char1);
                end loop;
                hread(textline, axi_addr);
                -- Collect data
                char1 := " ";
                while (char1 /= "x") loop
                    read(textline, char1);
                end loop;
                hread(textline, axi_data);
                -- Write
                axi_write(axi_addr, axi_data);
                exit;
            end if;
        end loop;

    end loop;

    file_close(CMD_SCRIPT);

    REPORT "Test ended." severity warning;
    wait;
end process;



end model;




































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































--------------------------------------------------------------------------------
-- Top-level VHDL wrapper for a block
-- This is responsible for creating 8 instances of a LUT Block
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;


entity lut_wrapper is
generic (
    NUM : natural := 8
);
port (
    -- Clocks and Resets
    clk_i               : in  std_logic := '0';
    reset_i             : in  std_logic := '0';

    -- Bus inputs
    -- TODO: rename to bit_bus_i
    bit_bus_i           : in  sysbus_t := (others => '0');
    pos_bus_i           : in  posbus_t := (others => (others => '0'));

    -- Bus outputs
    OUT_o  : out std_logic_vector(NUM-1 downto 0);

    -- Memory Interface
    read_strobe_i       : in  std_logic := '0';
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0) := (others => '0');
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic := '0';
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0) := (others => '0');
    write_data_i        : in  std_logic_vector(31 downto 0) := (others => '0');
    write_ack_o         : out std_logic
);
end lut_wrapper;

architecture rtl of lut_wrapper is


-- Register addresses, current values and strobes, an array of these for NUM
-- Blocks

constant INPA_addr : natural := 0;
signal INPA        : std32_array(NUM-1 downto 0);
signal INPA_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPA_dly_addr : natural := 1;
signal INPA_dly        : std32_array(NUM-1 downto 0);
signal INPA_dly_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPB_addr : natural := 2;
signal INPB        : std32_array(NUM-1 downto 0);
signal INPB_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPB_dly_addr : natural := 3;
signal INPB_dly        : std32_array(NUM-1 downto 0);
signal INPB_dly_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPC_addr : natural := 4;
signal INPC        : std32_array(NUM-1 downto 0);
signal INPC_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPC_dly_addr : natural := 5;
signal INPC_dly        : std32_array(NUM-1 downto 0);
signal INPC_dly_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPD_addr : natural := 6;
signal INPD        : std32_array(NUM-1 downto 0);
signal INPD_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPD_dly_addr : natural := 7;
signal INPD_dly        : std32_array(NUM-1 downto 0);
signal INPD_dly_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPE_addr : natural := 8;
signal INPE        : std32_array(NUM-1 downto 0);
signal INPE_wstb   : std_logic_vector(NUM-1 downto 0);

constant INPE_dly_addr : natural := 9;
signal INPE_dly        : std32_array(NUM-1 downto 0);
signal INPE_dly_wstb   : std_logic_vector(NUM-1 downto 0);

constant A_addr : natural := 10;
signal A        : std32_array(NUM-1 downto 0);
signal A_wstb   : std_logic_vector(NUM-1 downto 0);

constant B_addr : natural := 11;
signal B        : std32_array(NUM-1 downto 0);
signal B_wstb   : std_logic_vector(NUM-1 downto 0);

constant C_addr : natural := 12;
signal C        : std32_array(NUM-1 downto 0);
signal C_wstb   : std_logic_vector(NUM-1 downto 0);

constant D_addr : natural := 13;
signal D        : std32_array(NUM-1 downto 0);
signal D_wstb   : std_logic_vector(NUM-1 downto 0);

constant E_addr : natural := 14;
signal E        : std32_array(NUM-1 downto 0);
signal E_wstb   : std_logic_vector(NUM-1 downto 0);

constant FUNC_addr : natural := 15;
signal FUNC        : std32_array(NUM-1 downto 0);
signal FUNC_wstb   : std_logic_vector(NUM-1 downto 0);


-- Current values for bit muxes

signal INPA_from_bus : std_logic_vector(NUM-1 downto 0);
signal INPB_from_bus : std_logic_vector(NUM-1 downto 0);
signal INPC_from_bus : std_logic_vector(NUM-1 downto 0);
signal INPD_from_bus : std_logic_vector(NUM-1 downto 0);
signal INPE_from_bus : std_logic_vector(NUM-1 downto 0);


-- Register interface common

signal read_strobe      : std_logic_vector(NUM-1 downto 0);
signal read_data        : std32_array(NUM-1 downto 0);
signal write_strobe     : std_logic_vector(NUM-1 downto 0);
signal read_addr        : natural range 0 to (2**read_address_i'length - 1);
signal write_addr       : natural range 0 to (2**write_address_i'length - 1);


begin

    -- Acknowledgement to AXI Lite interface
    write_ack_o <= '1';

    read_ack_delay : entity work.delay_line
    generic map (DW => 1)
    port map (
        clk_i       => clk_i,
        data_i(0)   => read_strobe_i,
        data_o(0)   => read_ack_o,
        DELAY       => RD_ADDR2ACK
    );

    -- Generate NUM instances of the blocks
    GEN : FOR I IN 0 TO (NUM-1) GENERATE

        -- Sub-module address decoding
        read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
        write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;
        read_addr <= to_integer(unsigned(read_address_i(BLK_AW-1 downto 0)));
        write_addr <= to_integer(unsigned(write_address_i(BLK_AW-1 downto 0)));

        -- Control System Register Interface
        REG_WRITE : process(clk_i)
        begin
            if rising_edge(clk_i) then
                -- Zero all the write strobe arrays, we set them below
                INPA_wstb(I) <= '0';
                INPA_dly_wstb(I) <= '0';
                INPB_wstb(I) <= '0';
                INPB_dly_wstb(I) <= '0';
                INPC_wstb(I) <= '0';
                INPC_dly_wstb(I) <= '0';
                INPD_wstb(I) <= '0';
                INPD_dly_wstb(I) <= '0';
                INPE_wstb(I) <= '0';
                INPE_dly_wstb(I) <= '0';
                A_wstb(I) <= '0';
                B_wstb(I) <= '0';
                C_wstb(I) <= '0';
                D_wstb(I) <= '0';
                E_wstb(I) <= '0';
                FUNC_wstb(I) <= '0';
                if (write_strobe(I) = '1') then
                    -- Set the specific write strobe that has come in
                    case write_addr is
                        when INPA_addr =>
                            INPA(I) <= write_data_i;
                            INPA_wstb(I) <= '1';
                        when INPA_dly_addr =>
                            INPA_dly(I) <= write_data_i;
                            INPA_dly_wstb(I) <= '1';
                        when INPB_addr =>
                            INPB(I) <= write_data_i;
                            INPB_wstb(I) <= '1';
                        when INPB_dly_addr =>
                            INPB_dly(I) <= write_data_i;
                            INPB_dly_wstb(I) <= '1';
                        when INPC_addr =>
                            INPC(I) <= write_data_i;
                            INPC_wstb(I) <= '1';
                        when INPC_dly_addr =>
                            INPC_dly(I) <= write_data_i;
                            INPC_dly_wstb(I) <= '1';
                        when INPD_addr =>
                            INPD(I) <= write_data_i;
                            INPD_wstb(I) <= '1';
                        when INPD_dly_addr =>
                            INPD_dly(I) <= write_data_i;
                            INPD_dly_wstb(I) <= '1';
                        when INPE_addr =>
                            INPE(I) <= write_data_i;
                            INPE_wstb(I) <= '1';
                        when INPE_dly_addr =>
                            INPE_dly(I) <= write_data_i;
                            INPE_dly_wstb(I) <= '1';
                        when A_addr =>
                            A(I) <= write_data_i;
                            A_wstb(I) <= '1';
                        when B_addr =>
                            B(I) <= write_data_i;
                            B_wstb(I) <= '1';
                        when C_addr =>
                            C(I) <= write_data_i;
                            C_wstb(I) <= '1';
                        when D_addr =>
                            D(I) <= write_data_i;
                            D_wstb(I) <= '1';
                        when E_addr =>
                            E(I) <= write_data_i;
                            E_wstb(I) <= '1';
                        when FUNC_addr =>
                            FUNC(I) <= write_data_i;
                            FUNC_wstb(I) <= '1';
                        when others =>
                            null;
                    end case;
                end if;
            end if;
        end process;

        --
        -- Status Register Read     // NOT dealt with yet!      -- Need MUX for read_data(I)
                                                                -- find examples that actually have register reads...
        --
        REG_READ : process(clk_i)
        begin
            if rising_edge(clk_i) then
                case (read_addr) is
                    when others =>
                        read_data(I) <= (others => '0');
                end case;
            end if;
        end process;

        -- Instantiate Delay Blocks for Bit and Position Bus Fields
        bitmux_INPA : entity work.bitmux
        port map (
            clk_i       => clk_i,
            sysbus_i    => bit_bus_i,
            bit_o       => INPA_from_bus(I),
            bitmux_sel  => INPA(I),
            bit_dly     => INPA_DLY(I)
        );

        bitmux_INPB : entity work.bitmux
        port map (
            clk_i       => clk_i,
            sysbus_i    => bit_bus_i,
            bit_o       => INPB_from_bus(I),
            bitmux_sel  => INPB(I),
            bit_dly     => INPB_DLY(I)
        );

        bitmux_INPC : entity work.bitmux
        port map (
            clk_i       => clk_i,
            sysbus_i    => bit_bus_i,
            bit_o       => INPC_from_bus(I),
            bitmux_sel  => INPC(I),
            bit_dly     => INPC_DLY(I)
        );

        bitmux_INPD : entity work.bitmux
        port map (
            clk_i       => clk_i,
            sysbus_i    => bit_bus_i,
            bit_o       => INPD_from_bus(I),
            bitmux_sel  => INPD(I),
            bit_dly     => INPD_DLY(I)
        );

        bitmux_INPE : entity work.bitmux
        port map (
            clk_i       => clk_i,
            sysbus_i    => bit_bus_i,
            bit_o       => INPE_from_bus(I),
            bitmux_sel  => INPE(I),
            bit_dly     => INPE_DLY(I)
        );



        -- Connect to the actual logic entity
        lut : entity work.lut
        port map (
            INPA_i => INPA_from_bus(I),
            INPB_i => INPB_from_bus(I),
            INPC_i => INPC_from_bus(I),
            INPD_i => INPD_from_bus(I),
            INPE_i => INPE_from_bus(I),
            FUNC => FUNC(I),
            A => A(I)(1 downto 0),
            B => B(I)(1 downto 0),
            C => C(I)(1 downto 0),
            D => D(I)(1 downto 0),
            E => E(I)(1 downto 0),
            OUT_o => OUT_o(I),
            clk_i => clk_i
        );

    END GENERATE;

end rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;
use work.slow_defines.all;

entity outenc_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    As0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    conn_o              : out   std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Outputs
    slow_tlp_o          : out slow_packet;
    -- Position data value
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t
);
end outenc_top;

architecture rtl of outenc_top is

--
-- Return Daughter Card control value.
--
function ASSIGN_DATA (mem_dat_i : std_logic_vector) return std_logic_vector is
begin
    case (mem_dat_i(2 downto 0)) is
        when "000"  => -- INC
            return ZEROS(24) & X"07";
        when "001"  => -- SSI
            return ZEROS(24) & X"28";
        when "010"  => -- EnDat
            return ZEROS(24) & X"10";
        when "011"  => -- BiSS
            return ZEROS(24) & X"18";
        when "100"  => -- Pass
            return ZEROS(24) & X"07";
        when others =>
            return TO_SVECTOR(0, 32);
    end case;
end ASSIGN_DATA;

--
-- Return slow controller address value.
--
function ASSIGN_ADDR (mem_addr_i : std_logic_vector) return std_logic_vector is
begin
    case mem_addr_i(PAGE_AW-1 downto BLK_AW) is
        when "0000"  => -- INC
            return TO_SVECTOR(OUTENC1_PROTOCOL, PAGE_AW);
        when "0001"  => -- SSI
            return TO_SVECTOR(OUTENC2_PROTOCOL, PAGE_AW);
        when "0010"  => -- EnDat
            return TO_SVECTOR(OUTENC3_PROTOCOL, PAGE_AW);
        when "0011"  => -- BiSS
            return TO_SVECTOR(OUTENC4_PROTOCOL, PAGE_AW);
        when others =>
            return TO_SVECTOR(0, PAGE_AW);
    end case;
end ASSIGN_ADDR;

signal mem_blk_cs           : std_logic_vector(ENC_NUM-1 downto 0);

signal iobuf_ctrl           : iobuf_ctrl_array(ENC_NUM-1 downto 0);
signal enc_mode             : encmode_array(ENC_NUM-1 downto 0);

signal As0_ipad, As0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Bs0_ipad, Bs0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Zs0_ipad, Zs0_opad   : std_logic_vector(ENC_NUM-1 downto 0);

signal ao,bo, zo            : std_logic_vector(ENC_NUM-1 downto 0);
signal sclk                 : std_logic_vector(ENC_NUM-1 downto 0);
signal sdato                : std_logic_vector(ENC_NUM-1 downto 0);
signal sdati                : std_logic_vector(ENC_NUM-1 downto 0);
signal sdat_dir             : std_logic_vector(ENC_NUM-1 downto 0);
signal slow_tlp             : slow_packet_array(ENC_NUM-1 downto 0);

signal mem_read_data        : std32_array(ENC_NUM-1 downto 0);

begin

-- Unused signals.
sdati <= "0000";

-- Multiplex read data among multiple instantiations of the block.
mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate ENCOUT Blocks :
--  There are ENC_NUM amount of encoders on the board
--
ENCOUT_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

--
-- Encoder I/O Control :
--  On-chip IOBUF primitives needs dynamic control based on protocol
--
IOBUF_As0 : IOBUF port map (
I=>As0_opad(I), O=>As0_ipad(I), T=>iobuf_ctrl(I)(2), IO=>As0_pad_io(I));

IOBUF_Bs0 : IOBUF port map (
I=>Bs0_opad(I), O=>Bs0_ipad(I), T=>iobuf_ctrl(I)(1), IO=>Bs0_pad_io(I));

IOBUF_Zs0 : IOBUF port map (
I=>Zs0_opad(I), O=>Zs0_ipad(I), T=>iobuf_ctrl(I)(0), IO=>Zs0_pad_io(I));

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

-- Encoder output multiplexing should monitor selected protocol
-- "000" : Incremental
-- "001" : SSI
-- "010" : Endat
-- "011" : BiSS
-- "100" : Pass Through
As0_opad(I) <= ao(I) when (enc_mode(I)(1 downto 0) = "00") else sdato(I);
Bs0_opad(I) <= bo(I);
Zs0_opad(I) <= zo(I) when (enc_mode(I)(1 downto 0) = "00") else sdat_dir(I);

sclk(I) <= Bs0_ipad(I);

outenc_block_inst : entity work.outenc_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Interface
    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_read_data(I),
    -- Encoder I/O Pads
    a_o                 => ao(I),
    b_o                 => bo(I),
    z_o                 => zo(I),
    conn_o              => conn_o(I),
    sclk_i              => sclk(I),
    sdat_i              => sdati(I),
    sdat_o              => sdato(I),
    sdat_dir_o          => sdat_dir(I),
    -- Position Bus Input
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    -- CS Interface
    enc_mode_o          => enc_mode(I),
    iobuf_ctrl_o        => iobuf_ctrl(I)
);

END GENERATE;

--
-- Issue a Write command to Slow Controller when a write is detected on
-- PROTOCOL register
--
SLOW_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            slow_tlp_o.strobe <= '0';
            slow_tlp_o.address <= (others => '0');
            slow_tlp_o.data <= (others => '0');
        else
            -- Single clock cycle strobe
            slow_tlp_o.strobe <= '0';
            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                if (mem_addr_i(BLK_AW-1 downto 0) = TO_SVECTOR(OUTENC_PROTOCOL, BLK_AW)) then
                    slow_tlp_o.strobe <= '1';
                    slow_tlp_o.data <= ASSIGN_DATA(mem_dat_i);
                    slow_tlp_o.address <= ASSIGN_ADDR(mem_addr_i);
                end if;
           end if;
        end if;
    end if;
end process;

end rtl;


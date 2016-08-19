--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Encoder Daughter Card IO interface handling signal
--                multiplexing
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity dcard_interface is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder I/O Pads
    Am0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    As0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    -- Configuration registers
    INPROT              : in  std3_array(ENC_NUM-1 downto 0);
    OUTPROT             : in  std3_array(ENC_NUM-1 downto 0);
    -- Block Input/Outputs
    A_IN                : out std_logic_vector(ENC_NUM-1 downto 0);
    B_IN                : out std_logic_vector(ENC_NUM-1 downto 0);
    Z_IN                : out std_logic_vector(ENC_NUM-1 downto 0);
    A_OUT               : in  std_logic_vector(ENC_NUM-1 downto 0);
    B_OUT               : in  std_logic_vector(ENC_NUM-1 downto 0);
    Z_OUT               : in  std_logic_vector(ENC_NUM-1 downto 0);
    CLK_OUT             : in  std_logic_vector(ENC_NUM-1 downto 0);
    DATA_IN             : out std_logic_vector(ENC_NUM-1 downto 0);
    CLK_IN              : out std_logic_vector(ENC_NUM-1 downto 0);
    DATA_OUT            : in  std_logic_vector(ENC_NUM-1 downto 0)
);
end dcard_interface;

architecture rtl of dcard_interface is

signal Am0_ipad, Am0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Bm0_ipad, Bm0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Zm0_ipad, Zm0_opad   : std_logic_vector(ENC_NUM-1 downto 0);

signal As0_ipad, As0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Bs0_ipad, Bs0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Zs0_ipad, Zs0_opad   : std_logic_vector(ENC_NUM-1 downto 0);

signal inenc_dir            : std_logic_vector(ENC_NUM-1 downto 0);
signal outenc_dir           : std_logic_vector(ENC_NUM-1 downto 0);
signal inenc_ctrl           : std3_array(ENC_NUM-1 downto 0);
signal outenc_ctrl          : std3_array(ENC_NUM-1 downto 0);

begin

-- Unused Nets.
inenc_dir <= "0000";
outenc_dir <= "0000";
Am0_opad <= "0000";
Zm0_opad <= "0000";

--
--  On-chip IOBUF control for INENC Blocks :
--
INENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            inenc_ctrl(I) <= "111";
        else
            case (INPROT(I)) is
                when "000"  =>                              -- INC
                    inenc_ctrl(I) <= "111";
                when "001"  =>                              -- SSI
                    inenc_ctrl(I) <= "101";
                when "010"  =>                              -- BiSS-C
                    inenc_ctrl(I) <= "101";
                when "011"  =>                              -- EnDat
                    inenc_ctrl(I) <= inenc_dir(I) & "00";
                when others =>
                    inenc_ctrl(I) <= "111";
            end case;
        end if;
    end if;
end process;

-- Physical IOBUF instantiations controlled with PROTOCOL
IOBUF_Am0 : IOBUF port map (
I=>Am0_opad(I), O=>Am0_ipad(I), T=>inenc_ctrl(I)(2), IO=>Am0_pad_io(I));

IOBUF_Bm0 : IOBUF port map (
I=>Bm0_opad(I), O=>Bm0_ipad(I), T=>inenc_ctrl(I)(1), IO=>Bm0_pad_io(I));

IOBUF_Zm0 : IOBUF port map (
I=>Zm0_opad(I), O=>Zm0_ipad(I), T=>inenc_ctrl(I)(0), IO=>Zm0_pad_io(I));

-- Interface to Input Encoder Block.
Bm0_opad(I) <= CLK_OUT(I);

a_filt : entity work.delay_filter port map(
    clk_i => clk_i, reset_i => reset_i,
        pulse_i => Am0_ipad(I), filt_o => A_IN(I));

b_filt : entity work.delay_filter port map(
    clk_i => clk_i, reset_i => reset_i,
        pulse_i => Bm0_ipad(I), filt_o => B_IN(I));

z_filt : entity work.delay_filter port map(
    clk_i => clk_i, reset_i => reset_i,
        pulse_i => Zm0_ipad(I), filt_o => Z_IN(I));

din_filt : entity work.delay_filter port map(
    clk_i => clk_i, reset_i => reset_i,
        pulse_i => Am0_ipad(I), filt_o => DATA_IN(I));

END GENERATE;

--
--  On-chip IOBUF control for OUTENC Blocks :
--
OUTENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

--
-- Setup IOBUF Control Values :
--  Due to Encoder I/O multiplexing on device pins, on-chip
--  IOBUFs have to be configured according to protocol selected.
IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            outenc_ctrl(I) <= "000";
        else
            case (OUTPROT(I)) is
                when "000"  =>                        -- INC
                    outenc_ctrl(I) <= "000";
                when "001"  =>                        -- SSI
                    outenc_ctrl(I) <= "011";
                when "010"  =>                        -- EnDat
                    outenc_ctrl(I) <= outenc_dir(I) & "10";
                when "011"  =>                        -- BiSS
                    outenc_ctrl(I) <= outenc_dir(I) & "10";
                when "100"  =>                        -- Pass-Through
                    outenc_ctrl(I) <= "000";
                when others =>
                    outenc_ctrl(I) <= "000";
            end case;
        end if;
    end if;
end process;

IOBUF_As0 : IOBUF port map (
I=>As0_opad(I), O=>As0_ipad(I), T=>outenc_ctrl(I)(2), IO=>As0_pad_io(I));

IOBUF_Bs0 : IOBUF port map (
I=>Bs0_opad(I), O=>Bs0_ipad(I), T=>outenc_ctrl(I)(1), IO=>Bs0_pad_io(I));

IOBUF_Zs0 : IOBUF port map (
I=>Zs0_opad(I), O=>Zs0_ipad(I), T=>outenc_ctrl(I)(0), IO=>Zs0_pad_io(I));

-- A output is shared between incremental and absolute data lines.
As0_opad(I) <= A_OUT(I) when (OUTPROT(I)(1 downto 0) = "00") else DATA_OUT(I);
Bs0_opad(I) <= B_OUT(I);
Zs0_opad(I) <= Z_OUT(I);

din_filt : entity work.delay_filter port map(
    clk_i => clk_i, reset_i => reset_i,
        pulse_i => Bs0_ipad(I), filt_o => CLK_IN(I));

END GENERATE;

end rtl;


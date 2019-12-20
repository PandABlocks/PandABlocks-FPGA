--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Incremental Encoder Input interface module.
--                Implements an up/down counter around a 4x Quadrature decoder
--                block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity qdec is
port (
    -- Clock and reset signals
    clk_i               : in  std_logic;
--    reset_i             : in  std_logic;
    LINKUP_INCR         : in  std_logic_vector(31 downto 0);
    --Quadrature A,B and Z input
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    --Position data
    RST_ON_Z            : in  std_logic_vector(31 downto 0);
    SETP                : in  std_logic_vector(31 downto 0);
    SETP_WSTB           : in  std_logic;
    HOMED               : out std_logic_vector(31 downto 0);
    out_o               : out std_logic_vector(31 downto 0)
);
end qdec;

architecture rtl of qdec is

signal reset            : std_logic := '0';
signal quad_trans       : std_logic;
signal quad_dir         : std_logic;
signal quad_reset       : std_logic;
signal quad_count       : std_logic_vector(31 downto 0) := (others => '0');
signal z_old            : std_logic;

begin

HOMED(31 downto 1)<=(others =>'0');

-- Quadrature Decoder instantiation
qdecoder_inst : entity work.qdecoder
port map (
    clk                 => clk_i,
    reset               => reset,
    a_i                 => a_i,
    b_i                 => b_i,
    quad_reset_o        => quad_reset,
    quad_trans_o        => quad_trans,
    quad_dir_o          => quad_dir
);

-- Position counter
-- User can initialise the counter
-- Index can be used to reset the counter
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset = '1') then
            HOMED(0) <= '0';
        else
            if (LINKUP_INCR(0) = '0') then
                HOMED(0) <= '0';
            elsif (RST_ON_Z(0) = '1' and z_i = '1') then
                quad_count <= (others => '0');
                HOMED(0) <= '1';
            elsif (SETP_WSTB = '1') then
                quad_count <= SETP;
                HOMED(0) <= '1';
            elsif (quad_trans = '1') then
                if (quad_reset = '1') then
                    -- Reset is aligned to quad_trans, and reset value
                    -- depends on the wheel direction
                    if (quad_dir = '0') then
                        quad_count <= (others => '0');
                    else
                        quad_count <= (31=>'0', others => '0');
                    end if;
                else
                    if (quad_dir = '0') then
                        quad_count <= quad_count + 1;
                    else
                        quad_count <= quad_count - 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

out_o <= quad_count;

end rtl;

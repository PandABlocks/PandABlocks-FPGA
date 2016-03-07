--------------------------------------------------------------------------------
--  File:       quadin.vhd
--  Desc:       Incremental Encoder Input interface module. Implements an up/down
--              counter around a 4x Quadrature decoder block.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity quadin is
port (
    -- Clock and reset signals
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    --Quadrature A,B and Z input
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    --Position data
    rst_z_i             : in  std_logic;
    setp_val_i          : in  std_logic_vector(31 downto 0);
    setp_wstb_i         : in  std_logic;
    posn_o              : out std_logic_vector(31 downto 0)
);
end quadin;

architecture rtl of quadin is

signal quad_trans       : std_logic;
signal quad_dir         : std_logic;
signal quad_reset       : std_logic;
signal quad_count       : std_logic_vector(31 downto 0) := (others => '0');
signal z_old            : std_logic;

begin

-- Quadrature Decoder instantiation
qdec_inst : entity work.qdec
port map (
    clk                 => clk_i,
    reset               => reset_i,
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
        if (reset_i = '1') then
            quad_count <= (others => '0');
        else
            if (rst_z_i = '1' and z_i = '1') then
                quad_count <= (others => '0');
            elsif (setp_wstb_i = '1') then
                quad_count <= setp_val_i;
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

posn_o <= quad_count;

end rtl;

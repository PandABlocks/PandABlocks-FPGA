library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity outenc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Encoder inputs from Bitbus
    a_i                 : in  std_logic;
    b_i                 : in  std_logic;
    z_i                 : in  std_logic;
    conn_i              : in  std_logic;
    posn_i              : in  std_logic_vector(31 downto 0);
    enable_i            : in  std_logic;
    -- Encoder I/O Pads
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    z_o                 : out std_logic;
    conn_o              : out std_logic;
    sclk_i              : in  std_logic;
    sdat_i              : in  std_logic;
    sdat_o              : out std_logic;
    sdat_dir_o          : out std_logic;
    -- Block parameters
    PROTOCOL            : in  std_logic_vector(2 downto 0);
    BITS                : in  std_logic_vector(7 downto 0);
    QPERIOD             : in  std_logic_vector(31 downto 0);
    QPERIOD_WSTB        : in  std_logic;
    QSTATE              : out std_logic_vector(31 downto 0);
    -- Status interface
    enc_mode_o          : out encmode_t;
    iobuf_ctrl_o        : out std_logic_vector(2 downto 0)
);
end entity;

architecture rtl of outenc is

signal quad_a           : std_logic;
signal quad_b           : std_logic;

signal sdat_dir         : std_logic;

begin

-- Unused signals.
sdat_dir <= '0';

-- Status information to upper-level
enc_mode_o <= PROTOCOL;
sdat_dir_o <= sdat_dir;

-- Assign outputs
a_o <= a_i when (PROTOCOL = "100") else quad_a;
b_o <= b_i when (PROTOCOL = "100") else quad_b;
z_o <= z_i when (PROTOCOL = "100") else '0';

conn_o <= conn_i;

--
-- Setup IOBUF Control Values :
--  Due to Encoder I/O multiplexing on device pins, on-chip
--  IOBUFs have to be configured according to protocol selected.
IOBUF_CTRL : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            iobuf_ctrl_o <= "000";
        else
            case (PROTOCOL) is
                when "000"  =>                        -- INC
                    iobuf_ctrl_o <= "000";
                when "001"  =>                        -- SSI
                    iobuf_ctrl_o <= "011";
                when "010"  =>                        -- EnDat
                    iobuf_ctrl_o <= sdat_dir & "10";
                when "011"  =>                        -- BiSS
                    iobuf_ctrl_o <= sdat_dir & "10";
                when "100"  =>                        -- Pass-Through
                    iobuf_ctrl_o <= "000";
                when others =>
                    iobuf_ctrl_o <= "000";
            end case;
        end if;
    end if;
end process;

--
-- INCREMENTAL OUT
--
qenc_inst : entity work.qenc
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    QPERIOD         => QPERIOD,
    QPERIOD_WSTB    => QPERIOD_WSTB,
    QSTATE          => QSTATE,
    enable_i        => enable_i,
    posn_i          => posn_i,
    a_o             => quad_a,
    b_o             => quad_b
);

--
-- SSI SLAVE
--
ssislv_inst : entity work.ssislv
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,
    BITS            => BITS,
    posn_i          => posn_i,
    ssi_sck_i       => sclk_i,
    ssi_dat_o       => sdat_o
);

end rtl;


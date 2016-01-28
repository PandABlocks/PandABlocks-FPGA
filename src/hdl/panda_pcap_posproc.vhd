--------------------------------------------------------------------------------
--  File:       panda_pcap_posproc.vhd
--  Desc:       Position field processing (not ADC fields).
--
--              Although the data path is fixed to 64-bits, it will be trimmed
--              accordingly when ext_i is not connected.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcap_posproc is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block input and outputs.
    posn_i              : in  std_logic_vector(31 downto 0);
    extn_i              : in  std_logic_vector(31 downto 0);
    frame_i             : in  std_logic;
    capture_i           : in  std_logic;
    posn_o              : out std_logic_vector(31 downto 0);
    extn_o              : out std_logic_vector(31 downto 0);
    -- Block register
    FRAMING_ENABLE      : in  std_logic;
    FRAMING_MODE        : in  std_logic
);
end panda_pcap_posproc;

architecture rtl of panda_pcap_posproc is

signal posin            : std_logic_vector(63 downto 0);
signal posout           : std_logic_vector(63 downto 0);
signal posn_prev        : std_logic_vector(63 downto 0);
signal posn_delta       : signed(63 downto 0);
signal posn_sum         : signed(63 downto 0);

begin

posin <= extn_i & posn_i;

posn_o <= posout(31 downto 0);
extn_o <= posout(63 downto 32);

-- Calculate Delta and Sum from Frame-to-Frame
posn_delta <= signed(posin) - signed(posn_prev);
posn_sum <= signed(posin) + signed(posn_prev);

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            posn_prev <= (others => '0');
            posout <= (others => '0');
        else
            -- Output new POSN on frame input.
            if (FRAMING_ENABLE = '1') then
                if (frame_i = '1') then
                    posn_prev <= posin;

                    -- Output POSN data based on FRAME_MODE flag.
                    if (FRAMING_MODE = '0') then
                        posout <= std_logic_vector(posn_delta);
                    else
                        posout <= '0'& std_logic_vector(posn_sum(63 downto 1));
                    end if;
                end if;
            -- Else output instantaneous value.
            else
                posout <= posin;
            end if;
        end if;
    end if;
end process;

end rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_reg is
port (
    -- Clock and Reset
    clk_i                   : in  std_logic;
    reset_i                 : in  std_logic;
    -- Block register interface
    BIT_READ_RST            : in  std_logic;
    BIT_READ_RSTB           : in  std_logic;
    BIT_READ_VALUE          : out std_logic_vector(31 downto 0);
    POS_READ_RST            : in  std_logic;
    POS_READ_RSTB           : in  std_logic;
    POS_READ_VALUE          : out std_logic_vector(31 downto 0);
    POS_READ_CHANGES        : out std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    sysbus_i                : in  sysbus_t;
    posbus_i                : in  posbus_t
);
end panda_reg;

architecture rtl of panda_reg is

type bit16_array is array(natural range <>) of std_logic_vector(15 downto 0);

signal sbus                 : bit16_array(7 downto 0);
signal sbus_prev            : bit16_array(7 downto 0);
signal sbus_latched         : bit16_array(7 downto 0);
signal index                : unsigned(2 downto 0);
signal sbus_change          : bit16_array(7 downto 0);
signal sbus_change_latched  : bit16_array(7 downto 0);

signal pbus                 : posbus_t;
signal pbus_prev            : posbus_t;
signal pbus_latched         : posbus_t;
signal p_index              : unsigned(4 downto 0);
signal pbus_change          : std_logic_vector(31 downto 0);
signal pbus_change_latched  : std_logic_vector(31 downto 0);

begin

--
-- POSITION BUS Readback
--

--
-- System Bus is un-packed into an array of 16-bit words, so that on a
-- current value and changed flags can be read at the same strobe.
-- Read data is packed as:
-- mem_dat_o[31:16] = N*SysBus[15:0]
-- mem_dat_o[15: 0] = N*Changed[15:0]
--
process(sysbus_i)
begin
    for I in 0 to 7 loop
        sbus(I) <= sysbus_i(I*16+15 downto I*16);
    end loop;
end process;

--
-- Keep track of incoming BIT_READ_* write and read strobes to generate
-- change clear flag, index for the current 16-bit word and data out
-- strobe.

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            index <= (others => '0');
            sbus_change <= (others => (others => '0'));
            sbus_change_latched <= (others => (others => '0'));
            sbus_latched <= (others => (others => '0'));
        else
            -- Latch System Bus and Change Registers
            if (BIT_READ_RST = '1') then
                sbus_latched <= sbus;
                sbus_change_latched <= sbus_change;
            end if;

            -- 16-read strobes will read all system bus and changed flags.
            if (BIT_READ_RST = '1') then
                index <= (others => '0');
            elsif (BIT_READ_RSTB = '1') then
                index <= index + 1;
            end if;

            -- Change register is cleared on read, and it keeps track of changes
            -- on the system bus.
            sbus_prev <= sbus;
            for I in 0 to 7 loop
                -- Reset/Clear to current change status rather than 0.
                if (BIT_READ_RST = '1') then
                    sbus_change(I) <= sbus(I) xor sbus_prev(I);
                else
                    sbus_change(I) <= (sbus(I) xor sbus_prev(I)) or sbus_change(I);
                end if;
            end loop;
        end if;
    end if;
end process;

-- Packed read data output.
BIT_READ_VALUE <= sbus_latched(to_integer(index)) & sbus_change_latched(to_integer(index));

--
-- POSITION BUS Readback
--
POS_READ_VALUE <= pbus_latched(to_integer(p_index));
POS_READ_CHANGES <= pbus_change_latched;

pbus <= posbus_i;

process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            p_index <= (others => '0');
            pbus_change <= (others => '0');
            pbus_latched <= (others => (others => '0'));
            pbus_change_latched <= (others => '0');
        else
            -- Latch Position Bus and Change Registers
            if (POS_READ_RST = '1') then
                pbus_latched <= posbus_i;
                pbus_change_latched <= pbus_change;
            end if;

            -- 32-read strobes will read all position bus fields.
            if (POS_READ_RST = '1') then
                p_index <= (others => '0');
            elsif (POS_READ_RSTB = '1') then
                p_index <= p_index + 1;
            end if;

            pbus_prev <= pbus;
            for I in 0 to 31 loop
                -- Reset/Clear to current change status rather than 0.
                if (POS_READ_RST = '1') then
                    pbus_change(I) <= COMP(pbus(I), pbus_prev(I));
                else
                    pbus_change(I) <= COMP(pbus(I), pbus_prev(I)) or pbus_change(I);
                end if;
            end loop;
        end if;
    end if;
end process;

end rtl;


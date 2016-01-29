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
    POS_READ_VALUE          : out std_logic_vector(31 downto 0);
    POS_READ_CHANGES        : out std_logic_vector(31 downto 0);
    -- Encoder I/O Pads
    sysbus_i                : in  sysbus_t;
    posbus_i                : in  posbus_t
);
end panda_reg;

architecture rtl of panda_reg is

type bit16_array is array(natural range <>) of std_logic_vector(15 downto 0);

signal sbus               : bit16_array(7 downto 0);
signal sbus_prev            : bit16_array(7 downto 0);
signal sbus_change          : bit16_array(7 downto 0);
signal sbus_change_clear    : std_logic_vector(7 downto 0);

signal index                : unsigned(2 downto 0):= "000";

begin

POS_READ_VALUE <= (others => '0');
POS_READ_CHANGES <= (others => '0');

--
-- System Bus is un-packed into an array of 16-bit words, so that on a
-- single 32-bit Read Strobe, following fields can be read simultaneously.
-- mem_dat_o[31:16] = N*SysBus[15:0]
-- mem_dat_o[15: 0] = N*Changed[15:0]
process(sysbus_i)
begin
    for I in 0 to 7 loop
        sbus(I) <= sysbus_i(I*16+15 downto I*16);
    end loop;
end process;

-- Keep track of incoming BIT_READ_* write and read strobes to generate
-- change clear flag, index for the current 16-bit word and data out
-- strobe.
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            sbus_change_clear <= (others => '0');
            index <= (others => '0');
        else
            -- Clear and Read Strobe is a single clock flag
            sbus_change_clear <= (others => '0');

            if (BIT_READ_RST = '1') then
                index <= (others => '0');
            elsif (BIT_READ_RSTB = '1') then
                index <= index + 1;
                sbus_change_clear(to_integer(index)) <= '1';
            end if;
        end if;
    end if;
end process;

BIT_READ_VALUE <= sbus_prev(to_integer(index)) & sbus_change(to_integer(index));

--
-- Change register is cleared on read, and it keeps track of changes on the
-- system bus.
process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            sbus_prev <= (others => (others => '0'));
            sbus_change <= (others => (others => '0'));
        else
            sbus_prev <= sbus;
            for I in 0 to 7 loop
                -- Reset/Clear to current change status rather than 0.
                if (sbus_change_clear(I) = '1') then
                    sbus_change(I) <= sbus(I) xor sbus_prev(I);
                else
                    sbus_change(I) <= (sbus(I) xor sbus_prev(I)) or sbus_change(I);
                end if;
            end loop;
        end if;
    end if;
end process;

end rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_for_clock is
    port (
        clk_i : in std_logic;
        enable_i : in std_logic;
        low_i : in std_logic_vector(31 downto 0);
        auto_reload_i : in std_logic_vector(31 downto 0);
        out_o : out std_logic := '1'
    );
end;

architecture rtl of timer_for_clock is
    signal counter : unsigned(31 downto 0) := (others => '0');
begin
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if enable_i then
                if counter = 0 then
                    counter <= unsigned(auto_reload_i);
                else
                    counter <= counter - 1;
                end if;
                if counter = 0 then
                    out_o <= '1';
                elsif counter = unsigned(low_i) then
                    out_o <= '0';
                end if;
            else
                counter <= (others => '0');
                out_o <= '0';
            end if;
        end if;
    end process;
end;

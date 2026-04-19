library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prescaled_timer is
    port (
        clk_i : in std_logic;
        enable_i : in std_logic;
        prescaler_rollover_i : in std_logic_vector(31 downto 0);
        timer_rollover_i : in std_logic_vector(31 downto 0);
        expired_o : out std_logic
    );
end;

architecture rtl of prescaled_timer is
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal precounter : unsigned(31 downto 0) := (others => '0');
    signal counter_rolled : std_logic := '0';
    signal precounter_rolled : std_logic := '0';
begin
    precounter_rolled <=
        '1' when precounter = unsigned(prescaler_rollover_i) else '0';
    counter_rolled <=
        '1' when counter = unsigned(timer_rollover_i) else '0';
    expired_o <= precounter_rolled and counter_rolled and enable_i;
    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if enable_i then
                if precounter_rolled then
                    precounter <= (others => '0');
                    if counter_rolled then
                        counter <= (others => '0');
                    else
                        counter <= counter + 1;
                    end if;
                else
                    precounter <= precounter + 1;
                end if;
            else
                counter <= (others => '0');
                precounter <= (others => '0');
            end if;
        end if;
    end process;
end;

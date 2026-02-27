library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity idelayctrl_autoreset is
    port (
        -- Should be connected to the same clock as the idelayctrl
        clk_i : in std_logic;
        rdy_i : in std_logic;
        idelayctrl_reset_o : out std_logic := '1'
    );
end;

architecture rtl of idelayctrl_autoreset is
    constant RESET_WAIT : natural := 63;
    signal reset_cnt  : unsigned(5 downto 0) := (others => '0');
    signal idelayctrl_reset : std_logic := '0';
    type state_t is (RESETTING, WAIT_READY, MONITOR_READY);
    signal state : state_t := RESETTING;
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            case state is
                when RESETTING =>
                    if reset_cnt = RESET_WAIT then
                        state <= WAIT_READY;
                        idelayctrl_reset <= '0';
                        reset_cnt <= (others => '0');
                    else
                        reset_cnt <= reset_cnt + 1;
                        idelayctrl_reset <= '1';
                    end if;
                when WAIT_READY =>
                    if rdy_i then
                        state <= MONITOR_READY;
                    end if;
                when MONITOR_READY =>
                    if not rdy_i then
                        state <= RESETTING;
                        reset_cnt <= (others => '0');
                    end if;
                when others =>
                    state <= RESETTING;
            end case;
            idelayctrl_reset_o <= idelayctrl_reset;
        end if;
    end process;
end;

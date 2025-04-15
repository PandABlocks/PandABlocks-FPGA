library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity table_read_engine_client_length_manager is
    port (
        clk_i : in  std_logic;
        abort_i : in  std_logic;
        address_i : in  std_logic_vector(31 downto 0);
        length_i : in  std_logic_vector(31 downto 0);
        length_wstb_i : in  std_logic;
        address_o : out std_logic_vector(31 downto 0) := (others => '0');
        length_o : out std_logic_vector(31 downto 0) := (others => '0');
        more_o : out std_logic;
        length_taken_i : in std_logic;
        length_zero_event_o : out std_logic;
        completed_o : out std_logic := '0';
        repeat_i : in std_logic_vector(31 downto 0);
        overflow_error_o : out std_logic := '0';
        became_ready_event_o : out std_logic := '0';
        transfer_busy_i : in std_logic;
        transfer_start_o : out std_logic := '0'
    );
end;

architecture rtl of table_read_engine_client_length_manager is
    type state_t is (NO_ADDRESS, WAIT_LENGTH_TAKEN, WAIT_DMA, DONE);
    signal state : state_t := NO_ADDRESS;
    signal length : std_logic_vector(31 downto 0) := (others => '0');
    signal length_taken_reg : std_logic := '1';
    signal length_taken : std_logic := '0';
    signal repeat_count : unsigned(31 downto 0) := to_unsigned(1, 32);
    constant MORE_FLAG_INDEX : positive := 31;
begin
    length_taken <= length_taken_reg or length_taken_i;
    length_zero_event_o <= '1' when length_wstb_i = '1' and
                                    length_i = x"00000000" else
                           '0';
    address_o <= address_i;

    process (clk_i)
    begin
        if rising_edge(clk_i) then
            if length_zero_event_o then
                state <= NO_ADDRESS;
                -- first time through we don't need to wait for last length
                -- being taken
                length_taken_reg <= '1';
                completed_o <= '0';
            elsif abort_i then
                state <= DONE;
            else
                transfer_start_o <= '0';
                overflow_error_o <= '0';
                became_ready_event_o <= '0';
                case state is
                    -- state in which a new buffer is accepted
                    when NO_ADDRESS =>
                        repeat_count <= to_unsigned(1, 32);
                        if length_wstb_i then
                            if length_taken then
                                length_o(30 downto 0) <= length_i(30 downto 0);
                                more_o <= length_i(MORE_FLAG_INDEX);
                                state <= WAIT_LENGTH_TAKEN when not length_taken else
                                         WAIT_DMA;
                            else
                                length <= length_i;
                                state <= WAIT_LENGTH_TAKEN;
                            end if;
                        end if;
                    -- states in which a new buffer is not accepted
                    when WAIT_LENGTH_TAKEN =>
                        if length_wstb_i then
                            overflow_error_o <= '1';
                            state <= DONE;
                        end if;
                        if length_taken then
                            length_o(30 downto 0) <= length(30 downto 0);
                            more_o <= length(MORE_FLAG_INDEX);
                            state <= WAIT_DMA;
                        end if;
                    when WAIT_DMA =>
                        if length_wstb_i then
                            overflow_error_o <= '1';
                            state <= DONE;
                        end if;
                        if not transfer_busy_i then
                            if length_i(MORE_FLAG_INDEX) then
                                state <= NO_ADDRESS;
                                became_ready_event_o <= '1';
                                length_taken_reg <= '0';
                            else
                                if repeat_count >= unsigned(repeat_i) and
                                        repeat_i /= x"00000000" then
                                    state <= DONE;
                                else
                                    repeat_count <= repeat_count + 1;
                                end if;
                            end if;
                            transfer_start_o <= '1';
                        end if;
                    when DONE =>
                        if length_wstb_i then
                            overflow_error_o <= '1';
                        end if;
                        completed_o <= not transfer_busy_i;
                end case;
                if length_taken_i then
                    length_taken_reg <= '1';
                end if;
            end if;
        end if;
    end process;
end;

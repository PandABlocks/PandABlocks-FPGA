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
        length_i : in  std_logic_vector(31 downto 0);
        length_wstb_i : in  std_logic;
        length_zero_event_o : out std_logic;
        completed_o : out std_logic := '0';
        last_buffer_o : out std_logic := '0';
        overflow_error_o : out std_logic := '0';
        became_ready_event_o : out std_logic := '0';
        transfer_busy_i : in std_logic;
        transfer_start_o : out std_logic := '0';
        streaming_mode_o : out std_logic := '0';
        one_buffer_mode_o : out std_logic := '0';
        loop_one_buffer_i : in std_logic
    );
end;

architecture rtl of table_read_engine_client_length_manager is
    type state_t is (IDLE, ONE_BUFFER, STREAMING, STREAMING_WAIT, DONE);
    signal state : state_t := IDLE;
    signal length : std_logic_vector(31 downto 0) := (others => '0');
    constant MORE_FLAG_INDEX : positive := 31;
begin
    length_zero_event_o <= '1' when length_wstb_i = '1' and
                                    length_i = x"00000000" else
                           '0';

    process (clk_i)
        procedure error_if_new_length is
        begin
            if length_wstb_i then
                overflow_error_o <= '1';
                state <= DONE;
            end if;
        end procedure;
    begin
        if rising_edge(clk_i) then
            if length_zero_event_o then
                streaming_mode_o <= '0';
                one_buffer_mode_o <= '0';
                state <= IDLE;
                completed_o <= '0';
            elsif abort_i then
                if state /= ONE_BUFFER then
                    state <= DONE;
                end if;
            else
                transfer_start_o <= '0';
                overflow_error_o <= '0';
                became_ready_event_o <= '0';
                case state is
                    -- state in which a new buffer is accepted
                    when IDLE =>
                        streaming_mode_o <= '0';
                        one_buffer_mode_o <= '0';
                        last_buffer_o <= '0';
                        if length_wstb_i then
                            if length_i(MORE_FLAG_INDEX) then
                                streaming_mode_o <= '1';
                                state <= STREAMING;
                            else
                                one_buffer_mode_o <= '1';
                                state <= ONE_BUFFER;
                            end if;
                        end if;
                    when ONE_BUFFER =>
                        error_if_new_length;
                        if not transfer_busy_i then
                            transfer_start_o <= '1';
                            if not loop_one_buffer_i then
                                state <= DONE;
                            end if;
                        end if;
                    when STREAMING =>
                        error_if_new_length;
                        if not transfer_busy_i then
                            if length_i(MORE_FLAG_INDEX) then
                                state <= STREAMING_WAIT;
                                became_ready_event_o <= '1';
                            else
                                last_buffer_o <= '1';
                                state <= DONE;
                            end if;
                            transfer_start_o <= '1';
                        end if;
                    when STREAMING_WAIT =>
                        if length_wstb_i then
                            state <= STREAMING;
                        end if;
                    when DONE =>
                        error_if_new_length;
                        completed_o <= not transfer_busy_i;
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end;

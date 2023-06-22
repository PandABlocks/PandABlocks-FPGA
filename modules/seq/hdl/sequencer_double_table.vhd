library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.sequencer_defines.all;

entity sequencer_double_table is
generic (
    SEQ_LEN             : positive := 1024
);
port (
    clk_i               : in  std_logic;

    reset_tables_i      : in  std_logic;
    reset_error_i       : in  std_logic;

    -- Block Input and Outputs
    load_next_i         : in  std_logic;
    table_ready_o       : out std_logic;
    frame_o             : out seq_t;
    last_o              : out std_logic;
    can_write_next_o    : out std_logic;
    next_expected_o     : out std_logic;
    error_o             : out std_logic;
    error_type_o        : out std_logic_vector(3 downto 0);

    -- Block Parameters
    TABLE_START         : in  std_logic;
    TABLE_DATA          : in  std_logic_vector(31 downto 0);
    TABLE_WSTB          : in  std_logic;
    TABLE_FRAMES        : in  std_logic_vector(15 downto 0);
    TABLE_LENGTH_WSTB   : in  std_logic
);
end sequencer_double_table;


architecture rtl of sequencer_double_table is
    signal corrected_table_frames : std_logic_vector(15 downto 0) := (others => '0');
    signal wrtable_index : unsigned(0 downto 0) := (others => '0');
    signal rdtable_index : unsigned(0 downto 0) := (others => '0');
    type table_state_t is (TABLE_INVALID, TABLE_LAST, TABLE_CONT, TABLE_LOADING);
    type state_array_t is array(0 to 1) of table_state_t;
    signal table_state : state_array_t := (others => TABLE_INVALID);
    signal start_mux : std_logic_vector(0 to 1) := (others => '0');
    signal data_wstb_mux : std_logic_vector(0 to 1) := (others => '0');
    signal length_wstb_mux : std_logic_vector(0 to 1) := (others => '0');
    signal load_next_mux : std_logic_vector(0 to 1) := (others => '0');
    signal ready_mux : std_logic_vector(0 to 1) := (others => '0');
    type frame_mux_t is array(0 to 1) of seq_t;
    signal frame_mux : frame_mux_t;
    signal last_mux : std_logic_vector(0 to 1) := (others => '0');
    signal has_cont_mark : std_logic := '0';
    signal has_written_last : std_logic := '0';
    signal error_cond : std_logic := '0';
    signal read_error : std_logic := '0';
    signal read_invalid_error : boolean := false;
    signal read_underrun_error : boolean := false;
    signal entry_zero_history : std_logic_vector(3 downto 0) := (others => '0');
    signal load_next_table : boolean := false;
begin
    can_write_next_o <=
        to_std_logic(wrtable_index /= rdtable_index) and not has_written_last;
    next_expected_o <=
        to_std_logic(table_state(to_integer(rdtable_index)) = TABLE_CONT);
    last_o <= last_mux(to_integer(rdtable_index));
    load_next_table <= load_next_i = '1'
        and last_mux(to_integer(rdtable_index)) = '1'
        and table_state(to_integer(rdtable_index)) = TABLE_CONT;

    -- if the table contains a continuation mark, substract 1 to avoid
    -- spending time on iterating that entry
    corrected_table_frames <= TABLE_FRAMES when has_cont_mark = '0'
                              else std_logic_vector(unsigned(TABLE_FRAMES) - 1)
                                when TABLE_FRAMES /= x"0000"
                              else x"0000";

    error_cond <= read_error;

    -- write path
    wstb_mux_for: for I in 0 to 1 generate
        start_mux(I) <= TABLE_START when wrtable_index = I else '0';
        data_wstb_mux(I) <= TABLE_WSTB when wrtable_index = I else '0';
        length_wstb_mux(I) <= TABLE_LENGTH_WSTB when wrtable_index = I else '0';
    end generate;

    -- read path
    load_next_mux_for: for I in 0 to 1 generate
        load_next_mux(I) <= load_next_i and (to_std_logic(rdtable_index = I));
    end generate;

    table_ready_o <= ready_mux(to_integer(rdtable_index));
    frame_o <= frame_mux(to_integer(rdtable_index));

    error_o <= error_cond;

    gen_tables: for I in 0 to 1 generate
        TABLE_INST : entity work.sequencer_table
        generic map (
            SEQ_LEN             => SEQ_LEN
        )
        port map (
            clk_i               => clk_i,

            reset_raddr_i       => reset_tables_i,
            load_next_i         => load_next_mux(I),
            table_ready_o       => ready_mux(I),
            frame_o             => frame_mux(I),
            last_o              => last_mux(I),

            TABLE_START         => start_mux(I),
            TABLE_DATA          => TABLE_DATA,
            TABLE_WSTB          => data_wstb_mux(I),
            TABLE_FRAMES        => corrected_table_frames,
            TABLE_LENGTH_WSTB   => length_wstb_mux(I)
        );
    end generate;

    -- process that handled writing to the proper table and updating states
    process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if reset_tables_i = '1' then
                -- 3 cases need to be considered while resetting:
                --   - case 1: if both table indexes are the same, no index is
                --             updated
                --   - case 2: if we are loading a table, then table read index
                --             needs to be set to write index, so the next run
                --             starts in the proper table
                --   - case 3: if we are not loading and we have a valid
                --             reading table, then table write index is set to
                --             read index and that way, it can be reused in
                --             next run
                if table_state(to_integer(wrtable_index)) /= TABLE_LOADING then
                        wrtable_index <= rdtable_index;
                end if;
            elsif TABLE_START = '1' then
                table_state(to_integer(wrtable_index)) <= TABLE_LOADING;
            elsif TABLE_LENGTH_WSTB = '1' and
                    table_state(to_integer(wrtable_index)) = TABLE_LOADING then
                if corrected_table_frames = x"0000" then
                    table_state(to_integer(wrtable_index)) <= TABLE_INVALID;
                    has_written_last <= '1';
                elsif has_cont_mark = '1' then
                    table_state(to_integer(wrtable_index)) <= TABLE_CONT;
                    wrtable_index <= wrtable_index + 1;
                    has_written_last <= '0';
                else
                    table_state(to_integer(wrtable_index)) <= TABLE_LAST;
                    has_written_last <= '1';
                end if;
            end if;
        end if;
    end process;

    -- process to advance to next table when needed
    process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if reset_tables_i = '1' then
                if table_state(to_integer(wrtable_index)) = TABLE_LOADING then
                    rdtable_index <= wrtable_index;
                end if;
            -- switching to next table if current contains continuation mark
            elsif load_next_table then
                rdtable_index <= rdtable_index + 1;
            end if;
        end if;
    end process;

    -- process to detect error conditions
    process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if read_invalid_error or read_underrun_error then
                read_error <= '1';
                error_type_o <= c_table_error_underrun;
            elsif reset_error_i = '1' then
                read_error <= '0';
                error_type_o <= c_table_error_ok;
            end if;
        end if;
    end process;

    read_invalid_error <= load_next_i = '1'
        and (table_state(to_integer(rdtable_index)) = TABLE_LOADING or
             table_state(to_integer(rdtable_index)) = TABLE_INVALID);

    read_underrun_error <= load_next_table and rdtable_index + 1 = wrtable_index;

    -- detect zero entry (continuation mark)
    has_cont_mark <= to_std_logic(entry_zero_history = "1111");

    zero_counter_proc: process(clk_i) is
    begin
        if rising_edge(clk_i) then
            if TABLE_START = '1' then
                entry_zero_history <= "0000";
            elsif TABLE_WSTB = '1' then
                entry_zero_history <= entry_zero_history(2 downto 0) & to_std_logic(TABLE_DATA = x"00000000");
            end if;
        end if;
    end process;

end rtl;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.env.finish;

library work;
use work.top_defines.all;
use work.sequencer_defines.all;

entity sequencer_double_table_tb is
end sequencer_double_table_tb;


architecture rtl of sequencer_double_table_tb is
    signal clk : std_logic := '1';
    signal reset :  std_logic := '0';
    signal load_next : std_logic := '0';
    signal table_ready : std_logic;
    signal frame : seq_t;
    signal error_cond : std_logic;
    signal error_type : std_logic_vector(3 downto 0);
    signal table_start : std_logic;
    signal table_data : std_logic_vector(31 downto 0);
    signal table_wstb : std_logic := '0';
    signal table_frames : std_logic_vector(15 downto 0) := (others => '0');
    signal table_length_wstb : std_logic := '0';
    signal can_write_next : std_logic := '0';
    signal test_number : integer := 0;
    procedure clk_wait(count : in natural :=1) is
    begin
        for i in 0 to count-1 loop
            wait until rising_edge(clk);
        end loop;
    end procedure;
begin

-- 125MHz clock
clk <= not clk after 4 ns;

sequencer_double_table_inst: entity work.sequencer_double_table port map (
    clk_i => clk,
    reset_tables_i => reset,
    reset_error_i => reset,
    load_next_i => load_next,
    table_ready_o => table_ready,
    can_write_next_o => can_write_next,
    frame_o => frame,
    error_o => error_cond,
    error_type_o => error_type,
    table_start => table_start,
    table_data => table_data,
    table_wstb => table_wstb,
    table_frames => table_frames,
    table_length_wstb => table_length_wstb
);

process
    procedure start_write is
    begin
        table_start <= '1';
        clk_wait;
        table_start <= '0';
        clk_wait;
    end procedure;
    procedure write_data(data : in std_logic_vector(31 downto 0)) is
    begin
        table_data <= data;
        table_wstb <= '1';
        clk_wait;
        table_wstb <= '0';
        clk_wait;
    end procedure;
    procedure write_entry(entry : in std_logic_vector(127 downto 0)) is
    begin
        write_data(entry(31 downto 0));
        write_data(entry(63 downto 32));
        write_data(entry(95 downto 64));
        write_data(entry(127 downto 96));
    end;
    procedure end_write(nframes : in std_logic_vector(15 downto 0)) is
    begin
        table_frames <= nframes;
        table_length_wstb <= '1';
        clk_wait;
        table_length_wstb <= '0';
        clk_wait;
    end procedure;
    procedure manager_reset is
    begin
        reset <= '1';
        clk_wait;
        reset <= '0';
        clk_wait;
    end procedure;
    procedure read_next_entry is
    begin
        load_next <= '1';
        clk_wait;
        load_next <= '0';
    end procedure;
    procedure assert_frame_equal(expected : unsigned(15 downto 0)) is
    begin
        assert frame.repeats = expected
            report "Expected " & to_hstring(expected) &
                   " got " & to_hstring(frame.repeats)
            severity error;
    end procedure;
    procedure assert_error(val : std_logic) is
    begin
        assert error_cond = val
            report "Expected error_o to be asserted"
            severity error;
    end procedure;
    procedure assert_can_write_next(val : std_logic) is
    begin
        assert can_write_next = val
            report "Expected can_write_next to be asserted"
            severity error;
    end procedure;
begin
    -- TEST
    -- test writing without continuation then reading
    test_number <= 1;
    start_write;
    write_entry(128x"02");
    write_entry(128x"03");
    write_entry(128x"04");
    end_write(x"0003");
    -- expected to be repeated as it is last
    for I in 0 to 1 loop
        -- extra read to deal with the 1 tick memory latency
        read_next_entry;
        assert_frame_equal(x"0002");
        read_next_entry;
        assert_frame_equal(x"0003");
        read_next_entry;
        assert_frame_equal(x"0004");
    end loop;
    -- TEST
    -- write 2 tables, first with continuation, second is last, read both tables
    test_number <= 2;
    manager_reset;
    start_write;
    write_entry(128x"10");
    write_entry(128x"11");
    write_entry(128x"00");
    end_write(x"0003");
    start_write;
    write_entry(128x"12");
    write_entry(128x"13");
    end_write(x"0002");
    -- extra read to deal with the 1 tick memory latency
    read_next_entry;
    assert_frame_equal(x"0010");
    read_next_entry;
    assert_frame_equal(x"0011");
    -- expected to be repeated as it is last
    for I in 0 to 1 loop
        read_next_entry;
        assert_frame_equal(x"0012");
        read_next_entry;
        assert_frame_equal(x"0013");
    end loop;
    -- TEST
    -- reading an invalid table should be an error
    test_number <= 3;
    manager_reset;
    start_write;
    end_write(x"0000");  -- force table to be invalid
    assert_error('0');
    read_next_entry;
    clk_wait;
    assert_error('1');
    manager_reset;
    assert_error('0');
    -- TEST
    -- reading a table being written should be an error
    test_number <= 4;
    manager_reset;
    start_write;
    assert_error('0');
    read_next_entry;
    clk_wait;
    assert_error('1');
    manager_reset;
    assert_error('0');
    -- TEST
    -- underflow should be detected as an error
    -- write 2 tables with continuation, read more than there is
    test_number <= 5;
    manager_reset;
    start_write;
    write_entry(128x"01");
    write_entry(128x"02");
    write_entry(128x"00");
    end_write(x"0003");
    start_write;
    write_entry(128x"03");
    write_entry(128x"04");
    write_entry(128x"00");
    end_write(x"0003");
    for I in 1 to 4 loop
        read_next_entry;
        assert_frame_equal(to_unsigned(I, 16));
    end loop;
    read_next_entry;
    assert_error('1');
    -- TEST
    -- resetting when reading table with continuation should turn it invalid
    test_number <= 6;
    manager_reset;
    start_write;
    write_entry(128x"01");
    write_entry(128x"02");
    write_entry(128x"00");
    end_write(x"0003");
    manager_reset;
    read_next_entry;
    clk_wait;
    assert_error('1');
    -- TEST
    -- can_write_next is asserted when we can write to next table
    test_number <= 7;
    manager_reset;
    assert_can_write_next('0');
    start_write;
    write_entry(128x"01");
    write_entry(128x"02");
    write_entry(128x"00");
    end_write(x"0003");
    start_write;
    -- last write switches to next table and we can write
    assert_can_write_next('1');
    write_entry(128x"03");
    write_entry(128x"04");
    write_entry(128x"00");
    end_write(x"0003");
    assert_can_write_next('0');
    -- consume information on initial table
    read_next_entry;
    assert_can_write_next('0');
    read_next_entry;
    clk_wait;
    -- initial table can be written again
    assert_can_write_next('1');
    finish;

end process;

end rtl;

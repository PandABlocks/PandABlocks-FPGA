-- Testbench for zmi_master / zmi_hamming
--
-- Sends Hamming (16,11) encoded ZMI frames (32 bit mode, 40 Mbit/s, ZMI 4100
-- Series Measurement Board manual, Table 3-12) and checks correction of single
-- bit errors, rejection of double bit errors, the Zmi_err flag, stop bit errors, the
-- 1 ms link timeout and the status counters.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zmi_tb is
end zmi_tb;

architecture sim of zmi_tb is
    signal clk_i    : std_logic := '0';
    signal clk_200  : std_logic := '0';
    signal reset    : std_logic := '1';
    signal dat      : std_logic := '1';
    signal posn     : std_logic_vector(31 downto 0);
    signal pvalid   : std_logic;
    signal status   : std_logic_vector(31 downto 0);
    signal done     : boolean := false;

    -- Build frame bits 1..48 from position and zmi_err
    function encode(pos : std_logic_vector(31 downto 0); err : std_logic)
        return std_logic_vector is
        variable d   : std_logic_vector(32 downto 0);
        variable f   : std_logic_vector(47 downto 0) := (others => '0');
        variable idx : integer := 0;
        variable s   : unsigned(3 downto 0);
        variable par : std_logic;
    begin
        d := err & pos;
        for k in 0 to 2 loop
            for p in 1 to 15 loop
                if p /= 1 and p /= 2 and p /= 4 and p /= 8 then
                    f(16*k+p-1) := d(idx); idx := idx + 1;
                end if;
            end loop;
            s := (others => '0');
            for p in 1 to 15 loop
                if f(16*k+p-1) = '1' then s := s xor to_unsigned(p,4); end if;
            end loop;
            f(16*k+0) := s(0); f(16*k+1) := s(1); f(16*k+3) := s(2); f(16*k+7) := s(3);
            par := '0';
            for p in 0 to 14 loop par := par xor f(16*k+p); end loop;
            f(16*k+15) := par;
        end loop;
        return f;
    end function;
begin
    clk_i   <= not clk_i after 4 ns when not done;
    clk_200 <= not clk_200 after 2.5 ns when not done;

    dut : entity work.zmi_master
    port map (clk_i => clk_i, clk_200_i => clk_200, reset_i => reset,
              zmi_sck_o => open, zmi_dat_i => dat,
              posn_o => posn, posn_valid_o => pvalid, posn_status_o => status);

    stim : process
        variable f : std_logic_vector(47 downto 0);
        variable nerr : integer := 0;
        variable nframe : integer := 0;
        procedure send(fr : std_logic_vector(47 downto 0);
                       stop : std_logic := '1') is
        begin
            -- ZMI is asynchronous to the FPGA: vary the phase of the data
            -- edges relative to clk_200 from frame to frame
            wait for (nframe mod 7) * 0.7 ns;
            nframe := nframe + 1;
            dat <= '0'; wait for 25 ns;                 -- start
            for i in 0 to 47 loop dat <= fr(i); wait for 25 ns; end loop;
            dat <= stop; wait for 25 ns;                -- stop
            dat <= '1'; wait for 1000 ns;               -- idle
        end procedure;
        procedure check(name : string; exp_pos : std_logic_vector(31 downto 0);
                        exp_valid : std_logic; exp_stat : std_logic_vector(7 downto 0)) is
        begin
            if posn /= exp_pos or pvalid /= exp_valid or status(7 downto 0) /= exp_stat then
                report name & " FAILED: posn=" & to_hstring(posn) & " exp " & to_hstring(exp_pos) &
                       " valid=" & std_logic'image(pvalid) & " status=" & to_hstring(status)
                       severity error;
                nerr := nerr + 1;
            else
                report name & " ok: posn=" & to_hstring(posn) & " status=" & to_hstring(status);
            end if;
        end procedure;
    begin
        wait for 100 ns; reset <= '0'; wait for 200 ns;

        -- 1. clean frame
        send(encode(x"12345678", '0'));
        check("clean", x"12345678", '1', x"01");

        -- 2. every single bit error position in each frame bit
        for b in 0 to 47 loop
            f := encode(std_logic_vector(to_unsigned(b*7919+1, 32)) xor x"A5A5A5A5", '0');
            f(b) := not f(b);
            send(f);
            check("single bit " & integer'image(b),
                  std_logic_vector(to_unsigned(b*7919+1, 32)) xor x"A5A5A5A5", '1', x"03");
        end loop;

        -- 3. single errors in all three blocks at once
        f := encode(x"CAFEBABE", '0');
        f(4) := not f(4); f(20) := not f(20); f(40) := not f(40);
        send(f);
        check("3 blocks single", x"CAFEBABE", '1', x"03");

        -- 4. double error in block 2 -> discard, keep last posn
        f := encode(x"DEADBEEF", '0');
        f(17) := not f(17); f(25) := not f(25);
        send(f);
        check("double block2", x"CAFEBABE", '0', x"44");

        -- 5. recovery
        send(encode(x"00000042", '0'));
        check("recover", x"00000042", '1', x"01");

        -- 6. zmi_err flag set
        send(encode(x"FFFFFFFF", '1'));
        check("zmi_err", x"FFFFFFFF", '0', x"11");

        -- 7. stop bit error: Hamming ok, position accepted, status bit 3
        send(encode(x"01234567", '0'), '0');
        check("stop bit", x"01234567", '1', x"09");

        -- 8. link timeout: no frame for 1 ms clears CONN and status
        wait for 0.9 ms;
        check("no timeout yet", x"01234567", '1', x"09");
        wait for 0.2 ms;
        check("timeout", x"01234567", '0', x"00");

        -- 9. recovery after timeout
        send(encode(x"7654321F", '0'));
        check("recover timeout", x"7654321F", '1', x"01");

        report "counters: corrected=" & integer'image(to_integer(unsigned(status(15 downto 8)))) &
               " uncorrectable=" & integer'image(to_integer(unsigned(status(31 downto 16))));
        if unsigned(status(15 downto 8)) /= 49 or unsigned(status(31 downto 16)) /= 1 then
            report "counter mismatch" severity error;
            nerr := nerr + 1;
        end if;
        assert nerr = 0 report "ERRORS: " & integer'image(nerr) severity failure;
        report "ALL TESTS PASSED";
        done <= true;
        wait;
    end process;
end sim;

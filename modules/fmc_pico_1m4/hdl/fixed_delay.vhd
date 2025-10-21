-- General delay.
--
-- Implements a fixed delay.  The delay can be implemented in four ways:
--
--  0.  Short cut if delay is equal to zero.
--  1.  Using distributed memory.  This is the most efficient implementation for
--      delays up to 32 ticks.
--  2.  Using block RAM.  This is suitable for longer delays.
--  3.  Using individual registers.  This is suitable when the delay line is
--      used to help with timing closure.

library ieee;
use ieee.std_logic_1164.all;

use work.support.all;

entity fixed_delay is
    generic (
        WIDTH : natural := 1;
        DELAY : natural;
        -- The memory style can be one of
        --  "" or "AUTO"    Automatically determine
        --  "DISTRIBUTED"   Use distributed RAM
        --  "BLOCK"         Use block RAM
        --  "REGISTER"      Used fixed registers
        MEM_STYLE : string := "";   -- Default to automatic
        INITIAL : std_ulogic := '0'
    );
    port (
        clk_i : in std_ulogic;
        enable_i : in std_ulogic := '1';
        data_i : in std_ulogic_vector(WIDTH-1 downto 0);
        data_o : out std_ulogic_vector(WIDTH-1 downto 0)
    );
end;

architecture arch of fixed_delay is
    type mem_style_t is (MEM_DISTRIBUTED, MEM_BLOCK, MEM_REGISTER, MEM_ERROR);
    function compute_style return mem_style_t is
    begin
        if DELAY = 0 then
            return MEM_DISTRIBUTED;
        elsif MEM_STYLE = "" or MEM_STYLE = "AUTO" then
            -- The correct automated choice here is a bit tricky, as we really
            -- ought to take WIDTH into account as well, and whatever we do here
            -- is going to be hueristic.
            if DELAY * WIDTH > 128 and DELAY > 32 then
                return MEM_BLOCK;
            else
                return MEM_DISTRIBUTED;
            end if;
        elsif MEM_STYLE = "DISTRIBUTED" then
            return MEM_DISTRIBUTED;
        elsif MEM_STYLE = "BLOCK" then
            return MEM_BLOCK;
        elsif MEM_STYLE = "REGISTER" then
            return MEM_REGISTER;
        else
            return MEM_ERROR;
        end if;

    end;

    -- Extra delay imposed by long_delay entity.
    constant LONG_DELAY_EXTRA : natural := 2;

begin
    gen : case compute_style generate
        when MEM_BLOCK =>
            assert DELAY > LONG_DELAY_EXTRA
                report "Cannot use MEM_BLOCK for short delay"
                severity failure;
            long_delay : entity work.long_delay generic map (
                WIDTH => WIDTH,
                INITIAL => INITIAL,
                EXTRA_DELAY => LONG_DELAY_EXTRA
            ) port map (
                clk_i => clk_i,
                delay_i => to_unsigned(DELAY - LONG_DELAY_EXTRA),
                enable_i => enable_i,
                data_i => data_i,
                data_o => data_o
            );

        when MEM_DISTRIBUTED =>
            fixed_delay_dram : entity work.fixed_delay_dram generic map (
                WIDTH => WIDTH,
                INITIAL => INITIAL,
                DELAY => DELAY
            ) port map (
                clk_i => clk_i,
                enable_i => enable_i,
                data_i => data_i,
                data_o => data_o
            );

        when MEM_REGISTER =>
            fixed_delay_dram : entity work.fixed_delay_dram generic map (
                WIDTH => WIDTH,
                INITIAL => INITIAL,
                DELAY => DELAY,
                KEEP_REG => string'("true")
            ) port map (
                clk_i => clk_i,
                enable_i => enable_i,
                data_i => data_i,
                data_o => data_o
            );

        when MEM_ERROR =>
            assert false
                report "Invalid MEM_STYLE string: '" & MEM_STYLE &"'"
                severity error;
    end generate;
end;

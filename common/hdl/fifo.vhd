-- FIFO with AXI style handshaking.  The valid signal is asserted by the
-- producer when data is available to be transferred, and the ready signal is
-- asserted when the receiver is ready: transfer happens on the clock cycle when
-- ready and valid are asserted.  Two further AXI rules are followed: when valid
-- is asserted it must remain asserted until ready is seen; and the assertion of
-- valid must be independent of the state of ready.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity fifo is
    generic (
        FIFO_BITS : natural := 5;       -- log2 FIFO depth
        DATA_WIDTH : natural;           -- Width of data path
        MEM_STYLE : string := ""        -- Can override tool default
    );
    port (
        clk_i : in std_ulogic;

        -- Write interface
        write_valid_i : in std_ulogic;
        write_ready_o : out std_ulogic := '0';
        write_data_i : in std_ulogic_vector(DATA_WIDTH-1 downto 0);

        -- Read interface
        read_valid_o : out std_ulogic := '0';
        read_ready_i : in std_ulogic;
        read_data_o : out std_ulogic_vector(DATA_WIDTH-1 downto 0);

        -- Control and status
        reset_fifo_i : in std_ulogic := '0';
        fifo_depth_o : out unsigned(FIFO_BITS downto 0) := (others => '0')
    );
end;

architecture arch of fifo is
    subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
    subtype ADDRESS_RANGE is natural range 0 to 2**FIFO_BITS-1;
    subtype ADDRESS_RANGE_BITS is natural range FIFO_BITS downto 0;

    signal fifo : vector_array(ADDRESS_RANGE)(DATA_RANGE);
    attribute RAM_STYLE : string;
    attribute RAM_STYLE of fifo : signal is MEM_STYLE;

    -- This is just computing a mask with only the top bit set to be used for
    -- detecting the FIFO full condition
    function COMPARE_MASK return unsigned
    is
        variable result : unsigned(ADDRESS_RANGE_BITS) := (others => '0');
    begin
        result(FIFO_BITS) := '1';
        return result;
    end;

    signal write_pointer : unsigned(ADDRESS_RANGE_BITS) := (others => '0');
    signal read_pointer : unsigned(ADDRESS_RANGE_BITS) := (others => '0');
    -- The read valid state is separated from read_valid_o to improve data flow
    signal read_valid : std_ulogic := '0';

begin
    process (clk_i)
        variable read_enable : std_ulogic;
        variable next_write_pointer : unsigned(ADDRESS_RANGE_BITS);
        variable next_read_pointer : unsigned(ADDRESS_RANGE_BITS);
        variable write_address : ADDRESS_RANGE;
        variable read_address : ADDRESS_RANGE;
        variable next_read_valid : std_ulogic;

    begin
        if rising_edge(clk_i) then
            next_write_pointer := write_pointer;
            next_read_pointer := read_pointer;
            if reset_fifo_i then
                next_write_pointer := (others => '0');
                next_read_pointer := (others => '0');
                -- Block writes during reset
                write_ready_o <= '0';
                read_valid <= '0';
                read_enable := '0';
            else
                -- Advance write pointer if writing
                if write_valid_i and write_ready_o then
                    next_write_pointer := write_pointer + 1;
                end if;

                -- Advance read pointer if reading.  We keep read_data_o valid
                -- at all times when possible
                read_enable :=
                    read_valid and (read_ready_i or not read_valid_o);
                if read_enable then
                    next_read_pointer := read_pointer + 1;
                end if;

                -- Compute full and empty conditions.  Empty is simply equality
                -- of pointers, full is when the write pointer is exactly one
                -- FIFO depth ahead of the read pointer.  This computation can
                -- safely be done on the next_ pointers, which gives a small
                -- flow optimisation.
                write_ready_o <= to_std_ulogic(
                    next_write_pointer /= (next_read_pointer xor COMPARE_MASK));
                read_valid <= to_std_ulogic(
                    next_write_pointer /= next_read_pointer);
            end if;
            write_pointer <= next_write_pointer;
            read_pointer <= next_read_pointer;

            -- Throw away the top bit of the read/write pointers for access, the
            -- top bit is only used as a cycle counter to distinguish full and
            -- empty states
            write_address := to_integer(write_pointer(FIFO_BITS-1 downto 0));
            read_address  := to_integer(read_pointer(FIFO_BITS-1 downto 0));

            -- Write
            if write_valid_i and write_ready_o then
                fifo(write_address) <= write_data_i;
            end if;

            -- Read
            next_read_valid := read_valid_o;
            if reset_fifo_i then
                next_read_valid := '0';
            elsif read_enable then
                read_data_o <= fifo(read_address);
                next_read_valid := '1';
            elsif read_ready_i then
                next_read_valid := '0';
            end if;
            read_valid_o <= next_read_valid;

            -- Compute number of points in FIFO, also counting the output buffer
            fifo_depth_o <=
                next_write_pointer - next_read_pointer + next_read_valid;
        end if;
    end process;
end;

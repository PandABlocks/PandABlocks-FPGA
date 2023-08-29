-- Implements register interface to LMBF system

-- This is an AXI-Lite slave which only accepts full 32-bit writes.  The
-- incoming 16-bit address is split into four parts:
--
--  +----------+---------------+---------------+------+
--  | Ignored  | Module select | Reg address   | Byte |
--  +----------+---------------+---------------+------+
--              MOD_ADDR_BITS   REG_ADDR_BITS   BYTE_BITS
--
-- The module select field is used to determine which sub-module receives the
-- associated read or write, and the reg address field is passed through to the
-- sub-module.
--
-- The internal write interface is quite simple: the appropriate read_strobe as
-- selected by "module select" is pulsed for one clock cycle after the
-- write_address and write_data outputs are valid:
--
--  State           | IDLE  |WRITING| DONE  |
--                           ________________
--  write_data_o,   XXXXXXXXX________________
--  write_address_o
--                            _______
--  write_strobe_o  _________/       \_______
--
-- This means that modules can implement a simple one-cycle write interface.
--
-- Inevitably, the read interface is a little more involved, and completion can
-- be stretched by the module using the module specific read_ack signal.  For
-- single cycle reads which don't depend on read_strobe, read_ack can be
-- permanently high as shown here:
--
--  State           | IDLE  |READING| DONE  |
--                           ________________
--  read_address_o  XXXXXXXXX________________
--                            _______
--  read_strobe_o   _________/       \_______
--                           ________
--  read_data_i     XXXXXXXXX________XXXXXXXX
--                  _________________________
--  read_ack_i                                  (permanently high)
--
-- Alternatively read_ack can be generated some delay after read_strobe if it is
-- necessary to delay the generation of read_data:
--
--  State           | IDLE  |READING|READING|READING| DONE  |
--                           ________________________________
--  read_address_o  XXXXXXXXX________________________________
--                            _______
--  read_strobe_o   _________/       \_______________________
--                                           ________
--  read_data_i     XXXXXXXXXXXXXXXXXXXXXXXXX________XXXXXXXX
--                                            _______
--  read_ack_i      _________________________/       \_______
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity axi_lite_slave is
generic (
    ADDR_BITS : natural := 32;
    DATA_BITS : natural := 32
);
port (
    clk_i           : in std_logic;
    reset_i         : in std_logic;

    -- AXI-Lite read interface
    araddr_i        : in std_logic_vector(ADDR_BITS-1 downto 0);
    arprot_i        : in std_logic_vector(2 downto 0);        -- Ignored
    arready_o       : out std_logic;
    arvalid_i       : in std_logic;
    --
    rdata_o         : out std_logic_vector(DATA_BITS-1 downto 0);
    rresp_o         : out std_logic_vector(1 downto 0);
    rready_i        : in std_logic;
    rvalid_o        : out std_logic;

    -- AXI-Lite write interface
    awaddr_i        : in std_logic_vector(ADDR_BITS-1 downto 0);
    awprot_i        : in std_logic_vector(2 downto 0);        -- Ignored
    awready_o       : out std_logic;
    awvalid_i       : in std_logic;
    --
    wdata_i         : in std_logic_vector(DATA_BITS-1 downto 0);
    wstrb_i         : in std_logic_vector(DATA_BITS/8-1 downto 0);
    wready_o        : out std_logic;
    wvalid_i        : in std_logic;
    --
    bresp_o         : out std_logic_vector(1 downto 0);
    bready_i        : in std_logic;
    bvalid_o        : out std_logic;

    -- Internal read interface
    read_strobe_o   : out std_logic_vector(MOD_COUNT-1 downto 0);
    read_address_o  : out std_logic_vector(PAGE_AW-1 downto 0);
    read_data_i     : in  std32_array(MOD_COUNT-1 downto 0);
    read_ack_i      : in  std_logic_vector(MOD_COUNT-1 downto 0);

    -- Internal write interface
    write_strobe_o  : out std_logic_vector(MOD_COUNT-1 downto 0);
    write_address_o : out std_logic_vector(PAGE_AW-1 downto 0);
    write_data_o    : out std_logic_vector(31 downto 0);
    write_ack_i     : in  std_logic_vector(MOD_COUNT-1 downto 0)
);
end;

architecture axi_lite_slave of axi_lite_slave is

constant BYTE_BITS : natural := 2;

function to_std_logic(bool : boolean) return std_logic is
begin
    if bool then
        return '1';
    else
        return '0';
    end if;
end;

-- Returns field of specified width starting at offset start in data
function read_field(
    data : std_logic_vector;
    width : natural; start : natural) return std_logic_vector
is
    variable result : std_logic_vector(width-1 downto 0);
begin
    result := data(start + width - 1 downto start);
    return result;
end;

-- Decodes an address into a single bit strobe
function compute_strobe(index : natural) return std_logic_vector
is
    variable result : std_logic_vector(MOD_COUNT-1 downto 0) := (others => '0');
begin
    result(index) := '1';
    return result;
end;

-- Extracts module address from AXI address
function module_address(addr : std_logic_vector) return MOD_RANGE
is begin
    return to_integer(unsigned(
        read_field(addr, PAGE_NUM, PAGE_AW + BYTE_BITS)));
end;

-- Extracts register address from AXI address
function register_address(addr : std_logic_vector) return std_logic_vector
is begin
    return read_field(addr, PAGE_AW, BYTE_BITS);
end;

function vector_and(data : std_logic_vector) return std_logic is
    variable result : std_logic := '1';
begin
    for i in data'range loop
        result := result and data(i);
    end loop;
    return result;
end function;

-- ------------------------------------------------------------------------
-- Reading state
type read_state_t is (READ_IDLE, READ_READING, READ_DONE);
signal read_state           : read_state_t;
signal read_module_address  : MOD_RANGE;

signal read_strobe          : std_logic_vector(MOD_COUNT-1 downto 0);
signal read_ack             : std_logic := '0';
signal read_data            : std_logic_vector(31 downto 0);

-- ------------------------------------------------------------------------
-- Writing state

-- The data and address for writes can come separately.
type write_state_t is (WRITE_IDLE, WRITE_WRITING, WRITE_DONE);
signal write_state          : write_state_t;
signal write_module_address : MOD_RANGE;
signal awready_out          : std_logic := '0';
signal wready_out           : std_logic := '0';

signal write_strobe         : std_logic_vector(MOD_COUNT-1 downto 0);
signal write_ack            : std_logic;

begin

-- ------------------------------------------------------------------------
-- Read interface.
read_strobe <= compute_strobe(module_address(araddr_i));
read_ack <= read_ack_i(read_module_address);
read_data <= read_data_i(read_module_address);

process (clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            read_state <= READ_IDLE;
            read_strobe_o <= (others => '0');
            read_address_o <= (others => '0');
        else
            case read_state is
                when READ_IDLE =>
                    -- On valid read request latch read address
                    if (arvalid_i = '1') then
                        read_module_address <= module_address(araddr_i);
                        read_strobe_o <= read_strobe;
                        read_address_o <= register_address(araddr_i);
                        read_state <= READ_READING;
                    end if;
                when READ_READING =>
                    -- Wait for read acknowledge from module
                    read_strobe_o <= (others => '0');
                    if (read_ack = '1') then
                        rdata_o <= read_data;
                        read_state <= READ_DONE;
                    end if;
                when READ_DONE =>
                    -- Waiting for master to acknowledge our data.
                    if (rready_i = '1') then
                        read_state <= READ_IDLE;
                    end if;
            end case;
        end if;
    end if;
end process;

arready_o <= to_std_logic(read_state = READ_IDLE);
rvalid_o  <= to_std_logic(read_state = READ_DONE);
rresp_o <= "00";


-- ------------------------------------------------------------------------
-- Write interface.
write_strobe <= compute_strobe(module_address(awaddr_i));
write_ack <= write_ack_i(write_module_address);

process (clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            write_state <= WRITE_IDLE;
            write_address_o <= (others => '0');
            write_strobe_o <= (others => '0');
            awready_out <= '0';
            wready_out <= '0';
        else
            case write_state is
                when WRITE_IDLE =>
                    -- Wait for valid read and write data
                    if (awvalid_i = '1' and wvalid_i = '1') then
                        write_address_o <= register_address(awaddr_i);
                        write_module_address <= module_address(awaddr_i);
                        write_data_o <= wdata_i;
                        awready_out <= '1';
                        wready_out <= '1';
                        if vector_and(wstrb_i) = '1' then
                            -- Generate write strobe for valid cycle
                            write_strobe_o <= write_strobe;
                            if write_ack = '1' then
                                write_state <= WRITE_DONE;
                            else
                                write_state <= WRITE_WRITING;
                            end if;
                        else
                            -- For invalid write go straight to completion
                            write_state <= WRITE_DONE;
                        end if;
                    end if;

                when WRITE_WRITING =>
                    awready_out <= '0';
                    wready_out <= '0';
                    write_strobe_o <= (others => '0');
                    if (write_ack = '1') then
                        write_state <= WRITE_DONE;
                    end if;

                when WRITE_DONE =>
                    awready_out <= '0';
                    wready_out <= '0';
                    write_strobe_o <= (others => '0');
                    -- Wait for master to accept our response
                    if (bready_i = '1') then
                        write_state <= WRITE_IDLE;
                    end if;
            end case;
        end if;
   end if;
end process;

awready_o <= awready_out;
wready_o <= wready_out;
bvalid_o  <= to_std_logic(write_state = WRITE_DONE);
bresp_o <= "00";

end;

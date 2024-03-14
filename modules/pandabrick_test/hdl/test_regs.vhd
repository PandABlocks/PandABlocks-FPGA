----------------------------------------------------------------------------------
-- Dummy Module - replaced SYSTEM with this which returns test_val 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;


entity test_regs is
    Port ( 
    
        clk_i         : in  std_logic;
    
        test_val      : in std_logic_vector (31 downto 0);
        
        -- Internal read interface
        read_strobe   : in  std_logic;
        read_address  : in  std_logic_vector(PAGE_AW-1 downto 0);
        read_data     : out std_logic_vector(31 downto 0);
        read_ack      : out std_logic;

        -- Internal write interface
        write_strobe  : in  std_logic;
        write_address : in  std_logic_vector(PAGE_AW-1 downto 0);
        write_data    : in  std_logic_vector(31 downto 0);
        write_ack     : out std_logic

	);
end test_regs;

architecture arch_test_regs of test_regs is

signal test_address  :  std_logic_vector(PAGE_AW-1 downto 0);

begin

read_ack  <= '1';
write_ack <= '1';

process (clk_i) is
begin
    if rising_edge(clk_i) then
    
        -- Start by creating a full set of 'zero's
        --for index in 0 to (MOD_COUNT-1) loop
        --    read_data(index) <= (others => '0');
        --end loop;
        
        -- Check for 'SYSTEM' module address
        if (read_strobe='1') then
            -- Check for address=0.
            test_address <= (others => '0');
            if (read_address = test_address) then
                read_data <= test_val;
            else
                read_data <= (others => '0');
            end if;
        end if;
        
    end if;
end process;



end arch_test_regs;

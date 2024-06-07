library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity endat_crc is

port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    bitval_i        : in  std_logic;
    bitstrb_i       : in  std_logic;
    crc_o           : out std_logic_vector(4 downto 0)
    );
    
end endat_crc;


architecture rtl of endat_crc is

signal or_input   : std_logic;
signal or_input2  : std_logic;
signal and_input  : std_logic;
signal and_input2 : std_logic;
signal crc        : std_logic_vector(4 downto 0);

begin


ps_crc: process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            crc <= (others => '1');
        else
            and_input <= crc(4) and bitstrb_i;
            or_input <= bitval_i or and_input;    
            and_input2 <= or_input and bitstrb_i;
            or_input2 <= and_input2 or crc(0);
            if (bitstrb_i = '1') then
                crc(0) <= or_input;
                crc(1) <= crc(0);
                crc(2) <= crc(1);
                crc(3) <= and_input2 or crc(2);
                crc(4) <= crc(3);
            end if;
        end if;                            
    end if;
end process ps_crc;                
            
            
end rtl;    

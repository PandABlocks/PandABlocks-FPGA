library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity sfp_transmitter is
    
    port (clk_i          : in  std_logic;
          reset_i        : in  std_logic;
          rx_link_ok_i   : in  std_logic;
          loss_lock_i    : in  std_logic;     
          rx_error_i     : in  std_logic;          
          mgt_ready_i    : in  std_logic;   
          rxdata_i       : in  std_logic_vector(15 downto 0);            
          err_cnt_o      : out std_logic_vector(15 downto 0);     
          txdata_o       : out std_logic_vector(15 downto 0);
          txcharisk_o    : out std_logic_vector(1 downto 0)
          );

end sfp_transmitter;

architecture rtl of sfp_transmitter is

component sfp_transmit_mem
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic_vector(0 downto 0);
        addra : in  std_logic_vector(11 downto 0);
        dina  : in  std_logic_vector(15 downto 0);
        douta : out std_logic_vector(15 downto 0)
  );
end component;

-- The special K character
constant c_k28_5            : std_logic_vector(7 downto 0) := X"BC";
constant c_last_sample      : std_logic_vector(15 downto 0) := x"f07d";

signal mem_en               : std_logic;
signal mem_wr_en            : std_logic_vector(0 downto 0);
signal mem_addr             : std_logic_vector(11 downto 0);
signal mem_din              : std_logic_vector(15 downto 0);
signal mem_dout             : std_logic_vector(15 downto 0);      
signal mem_addr_cnt         : unsigned(11 downto 0);

signal mem_comp_en          : std_logic;
signal mem_comp_wr_en       : std_logic_vector(0 downto 0);
signal mem_comp_addr        : std_logic_vector(11 downto 0);
signal mem_comp_din         : std_logic_vector(15 downto 0);
signal mem_comp_dout        : std_logic_vector(15 downto 0);      
signal mem_comp_addr_cnt    : unsigned(11 downto 0) := (others => '0');

signal mem_comp_addr_en_dly : std_logic_vector(2 downto 0);
signal err_cnt              : unsigned(15 downto 0) := (others => '0');
signal mem_comp_addr_en     : std_logic;

begin

err_cnt_o <= std_logic_vector(err_cnt);

txdata_o <= mem_dout;


ps_txcharisk: process(mem_dout)
begin
    -- Event Code bus contains the K cahracters so 
    -- check for k characters being transmitted you
    -- need to indicate to the MGT core that this is
    -- a special K character 
    if mem_dout(7 downto 0) = c_k28_5 then
        txcharisk_o <= "01";
    else
        txcharisk_o <= "00";
    end if;
end process ps_txcharisk;            



ps_mgt_ready: process(clk_i)
begin
    if rising_edge(clk_i) then
        -- The link is up so start transmitting data
        if mgt_ready_i = '1' then
            mem_en <= '1';
            mem_addr_cnt <= mem_addr_cnt +1;
        -- The link is down so reset the address counter 
        -- so we always start on the first sample to 
        -- enable the synch up     
        else
            mem_en <= '0';
            mem_addr_cnt <= (others => '0');
        end if;
    end if;
end process ps_mgt_ready;                        


 
ps_compare: process(clk_i)
begin
    if rising_edge(clk_i) then
        mem_comp_addr_en_dly <= mem_comp_addr_en_dly(1 downto 0) & mem_comp_addr_en;
        mem_comp_en <= '1';
        -- Start the compare memory 
        -- Last sample F07D
        if rx_link_ok_i = '1' then 
            if rxdata_i = c_last_sample then
                mem_comp_addr_en <= '1';
            end if;
        else
            mem_comp_addr_en <= '0';            
        end if;
        -- Synch up the received data with the expected data 
        if (rx_link_ok_i = '1' and (mem_comp_addr_en = '1' or rxdata_i = c_last_sample)) then 
            mem_comp_addr_cnt <= mem_comp_addr_cnt +1;
        else
            mem_comp_addr_cnt <= (others => '0');
        end if;
        -- Reset the error counter 
        if mem_comp_addr_en_dly(2) = '1' then
            err_cnt <= (others => '0');
        -- error indicator
        -- Will get errors when the link goes down or coming up so done 
        -- this to ignore errors when i know link is going up or going down  
        elsif rx_link_ok_i = '1' and loss_lock_i = '0' and 
              rx_error_i = '0' and mem_comp_dout /= rxdata_i then
            err_cnt <= err_cnt +1;
        end if;        
    end if;
end process ps_compare;


                        
mem_addr <= std_logic_vector(mem_addr_cnt);
mem_wr_en <= "0";
mem_din <= (others => '0');

-- Transmit memory
sfp_transmit_mem_inst: sfp_transmit_mem
port map (
    clka  => clk_i,
    ena   => mem_en,
    wea   => mem_wr_en,
    addra => mem_addr,
    dina  => mem_din,
    douta => mem_dout
);                                  



mem_comp_addr <= std_logic_vector(mem_comp_addr_cnt);
mem_comp_wr_en <= "0";
mem_comp_din <= (others => '0');

-- Compare memory
sfp_compare_mem_inst: sfp_transmit_mem
port map (
    clka  => clk_i,
    ena   => mem_comp_en,
    wea   => mem_comp_wr_en,
    addra => mem_comp_addr,
    dina  => mem_comp_din,
    douta => mem_comp_dout
);                                  
                        
                        
end rtl;                        

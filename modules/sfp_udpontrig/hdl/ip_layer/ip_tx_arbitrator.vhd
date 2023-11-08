--==============================================================================
-- Company        : Synchrotron SOLEIL
-- Project        : PandABox FPGA
-- Design name    : sfp_udpontrig
-- Module name    : ip_tx_arbitrator.vhd
-- Purpose        : multichannel ip_tx round-robin arbitrer
--
-- Author         : Thierry GARREL (ELSYS-Design)
-- Synthesizable  : YES
-- Language       : VHDL-93
--------------------------------------------------------------------------------
-- Copyright (c) 2021 Synchrotron SOLEIL - L'Orme des Merisiers Saint-Aubin
-- BP 48 91192 Gif-sur-Yvette Cedex  - https://www.synchrotron-soleil.fr
--------------------------------------------------------------------------------


--==============================================================================
-- Libraries Declaration
--==============================================================================
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.axi_types.all;
  use work.ipv4_types.all;
  use work.ipv4_channels_types.all;


-- =============================================================================
-- Entity Declaration
--==============================================================================
entity ip_tx_arbitrator is
  generic (
    NB_CHANNELS               : integer := 2       -- nb of ip_tx channels (2 to C_MAX_CHANNELS)
  );
  port (
    -- System signals (in)
    clk                     : in  std_logic;                      -- asynchronous clock
    reset                   : in  std_logic;                      -- synchronous active high reset input
    -- IP layer TX input channels (in)
    ip_tx_start_bus         : in  ip_tx_start_array(0 to NB_CHANNELS-1);
    ip_tx_bus               : in  ip_tx_bus_array(0 to NB_CHANNELS-1);
    ip_tx_result_bus        : out ip_tx_result_array(0 to NB_CHANNELS-1);
    ip_tx_dout_ready_bus    : out ip_tx_dout_ready_array(0 to NB_CHANNELS-1);
   -- IP layer TX signals (out)
    ip_tx_start             : out  std_logic;
    ip_tx                   : out ipv4_tx_type;                   -- IP tx cxns
    ip_tx_result            : in  std_logic_vector(1 downto 0);   -- tx status (changes during transmission)
    ip_tx_data_out_ready    : in  std_logic                       -- indicates IP TX is ready to take data
  );
end ip_tx_arbitrator;



--==============================================================================
-- Entity Architecture
--==============================================================================
architecture behavioral of ip_tx_arbitrator is


  signal r_source   : unsigned(C_LOG2_MAX_CHANNELS-1 downto 0);   -- round robin priority counter
  signal r_select   : integer range 0 to NB_CHANNELS-1;           -- indicates which channel is selected
  signal r_busy     : std_logic;                                  -- indicates that selected channel is busy



--==============================================================================
-- Beginning of Code
--==============================================================================
begin

  -------------------------------------------------------------------
  -- Process : arbitraction_proc
  -- Description : arbitration processing
  -------------------------------------------------------------------
  arbitraction_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        r_busy    <= '0';
        r_source  <= (others=>'0');
      else
        if r_busy = '0' then
          -- test if there is a request on selected channel
          -- if no : switch to next channel
          if ip_tx_start_bus(r_select) = '0' then
            if r_source /= (NB_CHANNELS-1) then
              r_source <= r_source + 1;
            else
              r_source <= (others=>'0');
            end if;
          -- if yes : turn on busy
          else
            r_busy <= '1';
          end if;

        else -- busy = 1
          -- wait until ip_tx_start = '0' and turn off busy
          -- or wait until last data of selected channel : ip_tx.data.data_out_last(channel) = '1'
          if ip_tx_start_bus(r_select) = '0' then
            r_busy <= '0';
          end if;
        end if; -- r_busy

      end if; -- reset
    end if;--clk
  end process arbitraction_proc;

  r_select <= to_integer(r_source);


  -------------------------------------------------------------------
  -- Process : output_proc
  -- Description : outputs followers processing
  -------------------------------------------------------------------
  outputs_proc : process(r_select,ip_tx_start_bus,ip_tx_bus)
  begin
    ip_tx_start   <= ip_tx_start_bus(r_select);
    --ip_tx         <= ip_tx_bus(r_select);
    ip_tx.hdr     <= ip_tx_bus(r_select).hdr;
    ip_tx.data    <= ip_tx_bus(r_select).data;
  end process outputs_proc;

  -- ip_tx result and ip_tx_data_out_ready outputs generation
  ackgen: for i_channel in 0 to NB_CHANNELS-1 generate
  begin
      ip_tx_result_bus(i_channel)     <= ip_tx_result         when r_select = i_channel else IPTX_RESULT_NONE;
      ip_tx_dout_ready_bus(i_channel) <= ip_tx_data_out_ready when r_select = i_channel else '0';
  end generate;



--   r_select <= to_integer(r_source);
--
--   process(clk)
--   begin
--     if rising_edge(clk) then
--       if rst = '1' then
--         r_busy <= '0';
--         r_source <= "0000";
--       elsif r_busy = '0' then
--         if src_tx_valid_bus(r_select) = '0' then
--           if r_source /= (NB_CHANNELS-1) then
--             r_source <= r_source + 1;
--           else
--             r_source <= (others => '0');
--           end if;
--         else
--           r_busy <= '1';
--         end if;
--       elsif src_tx_last_bus(r_select) = '1' then
--         r_busy <= '0';
--       end if;
--     end if;
--   end process;
--
--   mac_tx_valid <= src_tx_valid_bus(r_select);
--   mac_tx_last <= src_tx_last_bus(r_select);
--   mac_tx_error <= src_tx_error_bus(r_select);
--   mac_tx_data <= src_tx_data_bus(r_select);
--
--   ackgen: for i in NB_CHANNELS - 1 downto 0 generate
--   begin
--     src_tx_ready_bus(i) <= mac_tx_ready when r_select = i else '0';
--   end generate;



end behavioral;
--==============================================================================
-- End of Code
--==============================================================================




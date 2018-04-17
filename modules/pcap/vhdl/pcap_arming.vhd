--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Manage arming of the position capture operation.
--                Position capture starts following soft ARM, and enable signal
--                The capture stops either on successful completion, DISARM or
--                error
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pcap_arming is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Register interface
    ARM                 : in  std_logic;
    DISARM              : in  std_logic;
    -- Block Inputs and Outputs
    enable_i            : in  std_logic;
    pcap_error_i        : in  std_logic;
    ongoing_capture_i   : in  std_logic;
    dma_error_i         : in  std_logic;
    pcap_armed_o        : out std_logic;
    pcap_done_o         : out std_logic;
    timestamp_o         : out std_logic_vector(63 downto 0);
    pcap_status_o       : out std_logic_vector(2 downto 0)
);
end pcap_arming;

architecture rtl of pcap_arming is

type pcap_arm_t is (IDLE, ARMED, ENABLED, WAIT_ONGOING_WRITE);
signal arm_fsm                  : pcap_arm_t;

signal timestamp                : unsigned(63 downto 0);
signal enable_prev              : std_logic;
signal enable_fall              : std_logic;
signal abort_capture            : std_logic;
signal pcap_armed               : std_logic;
signal disable_armed            : std_logic; 

begin

-- Assign outputs
pcap_armed_o <= pcap_armed;

--------------------------------------------------------------------------
-- Register inputs, and detect rise/falling edge of internal signals.
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
    	enable_prev <= enable_i;
    end if;
end process;

enable_fall <= enable_prev and not enable_i;


-- Blocks operation is aborted under following conditions.
abort_capture <= DISARM or pcap_error_i or dma_error_i;

--------------------------------------------------------------------------
-- Arm/Enable/Disarm State Machine
--------------------------------------------------------------------------
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            arm_fsm <= IDLE;
            pcap_armed <= '0';
            disable_armed <= '0';    
            pcap_done_o <= '0';
            pcap_status_o <= "000";
        -- Stop capturing on error if armed.
        elsif (pcap_armed = '1' and abort_capture = '1') then
            arm_fsm <= IDLE;
            pcap_armed <= '0';
            disable_armed <= '0';
            pcap_done_o <= '1';
            -- Set abort flags accordingly.
            -- User disarm;
            if (DISARM = '1') then
                pcap_status_o(0) <= '1';
            end if;

            -- Pcap frame or buffer error (capture too close together)
            if (pcap_error_i = '1') then
                pcap_status_o(1) <= '1';
            end if;

            -- DMA FIFO full (Sample Overflow)
            if (dma_error_i = '1') then
                pcap_status_o(2) <= '1';
            end if;
        else
            case (arm_fsm) is
                -- Wait for user arm.
                when IDLE =>
                    pcap_done_o <= '0';
                    if (ARM = '1') then
                        pcap_armed <= '1';    
                        arm_fsm <= ARMED;
                        pcap_status_o <= "000";
                    end if;

                -- Wait for enable pulse from the system bus.
                when ARMED =>
                    if (enable_i = '1') then
                        arm_fsm <= ENABLED;
                    end if;

                -- Enabled until capture is finished or user disarm or
                -- block error.
                when ENABLED =>
                    disable_armed <= '0';
                    if (enable_fall = '1' or DISARM = '1') then                     
                        -- Complete gracefully, and make sure that ongoing write
                        -- into the DMA fifo is completed.
                        if (ongoing_capture_i = '1') then
                            arm_fsm <= WAIT_ONGOING_WRITE;
                        else
                            arm_fsm <= IDLE;
                            pcap_armed <= '0';
                            pcap_done_o <= '1';
                        end if;
                    end if;

                -- Wait for ongoing capture capture finish.
                when WAIT_ONGOING_WRITE =>
                    if (ongoing_capture_i = '0') then
                        arm_fsm <= IDLE;
                        pcap_armed <= '0';
                        pcap_done_o <= '1';
                    end if;

                when others =>
                    arm_fsm <= IDLE;
            end case;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Timestamp counter for the experiment starting from ARM.
--------------------------------------------------------------------------
timestamp_o <= std_logic_vector(timestamp);

process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            timestamp <= (others => '0');
		elsif (ARM = '0' and enable_i = '0') then
			timestamp <= (others => '0');	
        elsif (ARM = '1') then
            timestamp <= to_unsigned(1, 64);
		elsif (pcap_armed = '1' and enable_i = '1') then	
            timestamp <= timestamp + 1;
        end if;
    end if;
end process;

end rtl;

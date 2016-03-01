--------------------------------------------------------------------------------
--  File:       panda_pcap_arming.vhd
--  Desc:       Position capture module
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity panda_pcap_arming is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Register interface
    ARM                 : in  std_logic;
    DISARM              : in  std_logic;
    -- Block Inputs and Outputs
    enable_i            : in  std_logic;
    abort_i             : in  std_logic;
    ongoing_capture_i   : in  std_logic;
    dma_full_i          : in  std_logic;
    pcap_armed_o        : out std_logic;
    pcap_enabled_o      : out std_logic;
    pcap_done_o         : out std_logic;
    pcap_status_o       : out std_logic_vector(2 downto 0)
);
end panda_pcap_arming;

architecture rtl of panda_pcap_arming is

type pcap_arm_t is (IDLE, ARMED, ENABLED, WAIT_ONGOING_WRITE);
signal panda_arm_fsm        : pcap_arm_t;

signal enable_prev          : std_logic;
signal enable_fall          : std_logic;
signal abort_capture        : std_logic;

begin

-- Register inputs, and detect rise/falling edge of internal signals.
enable_fall <= not enable_i and enable_prev;

process(clk_i) begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

-- Blocks operation is aborted under following conditions.
abort_capture <= DISARM or abort_i or dma_full_i;

process(clk_i) begin
    if rising_edge(clk_i) then
        enable_prev <= enable_i;
    end if;
end process;

--
-- Arm/Enable/Disarm State Machine
--
process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            panda_arm_fsm <= IDLE;
            pcap_armed_o <= '0';
            pcap_enabled_o <= '0';
            pcap_done_o <= '0';
            pcap_status_o <= "000";
        else
            case (panda_arm_fsm) is
                -- Wait for user arm.
                when IDLE =>
                    pcap_done_o <= '0';
                    if (ARM = '1') then
                        panda_arm_fsm <= ARMED;
                        pcap_armed_o <= '1';
                        pcap_enabled_o <= '0';
                        pcap_status_o <= "000";
                    end if;

                -- Wait for enable pulse from the system bus.
                when ARMED =>
                    -- Abort has priority than enable pulse.
                    if (abort_capture = '1') then
                        panda_arm_fsm <= IDLE;
                        pcap_armed_o <= '0';
                        pcap_enabled_o <= '0';
                        pcap_done_o <= '1';
                    elsif (enable_i = '1') then
                        panda_arm_fsm <= ENABLED;
                        pcap_enabled_o <= '1';
                    end if;

                    -- Set abort flags accordingly. If finish_block is due
                    -- to completion, no disarmed bits are set.
                    if (DISARM = '1') then
                        pcap_status_o(0) <= '1';
                    end if;

                    if (abort_i = '1') then
                        pcap_status_o(1) <= '1';
                    end if;

                -- Enabled until capture is finished or user disarm or
                -- block error.
                when ENABLED =>
                    if (abort_capture = '1' or enable_fall = '1') then
                        -- Abort gracefully, and make sure that ongoing write
                        -- into the DMA fifo is completed.
                        if (ongoing_capture_i = '1') then
                            panda_arm_fsm <= WAIT_ONGOING_WRITE;
                        else
                            panda_arm_fsm <= IDLE;
                            pcap_armed_o <= '0';
                            pcap_enabled_o <= '0';
                            pcap_done_o <= '1';
                        end if;

                        -- Set abort flags accordingly.
                        -- User disarm;
                        if (DISARM = '1') then
                            pcap_status_o(0) <= '1';
                        end if;

                        -- Pcap block error;
                        if (abort_i = '1') then
                            pcap_status_o(1) <= '1';
                        end if;

                        -- DMA FIFO full;
                        if (dma_full_i = '1') then
                            pcap_status_o(2) <= '1';
                        end if;
                    end if;

                -- Wait for ongoing capture capture finish.
                when WAIT_ONGOING_WRITE =>
                    if (ongoing_capture_i = '0') then
                        panda_arm_fsm <= IDLE;
                        pcap_armed_o <= '0';
                        pcap_enabled_o <= '0';
                        pcap_done_o <= '1';
                    end if;

                when others =>
                    panda_arm_fsm <= IDLE;
            end case;
        end if;
    end if;
end process;

end rtl;


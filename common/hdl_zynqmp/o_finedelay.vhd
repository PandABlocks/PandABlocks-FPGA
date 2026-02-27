library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity o_finedelay is
    port (
        clk_i : in std_logic;
        calibration_ready_i : in std_logic;
        fine_delay_i : in std_logic_vector(8 downto 0);
        fine_delay_wstb_i : in std_logic;
        fine_delay_compensated_o : out std_logic_vector(8 downto 0) := (others => '0');
        signal_i : in std_logic;
        signal_o : out std_logic
    );
end;

architecture rtl of o_finedelay is
    signal en_vtc : std_logic := '1';
    signal load : std_logic := '0';
    signal odelay_cnt_in_latch : std_logic_vector(8 downto 0) := (others => '0');
    type state_t is (IDLE, WAIT_AFTER_DISABLE, PRELOAD, START_LOAD, WAIT_BEFORE_ENABLE);
    signal state : state_t := IDLE;
    signal wait_counter : unsigned(3 downto 0) := (others => '1');
begin
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            case state is
                when IDLE =>
                    load <= '0';
                    wait_counter <= (others => '1');
                    if fine_delay_wstb_i and calibration_ready_i then
                        state <= WAIT_AFTER_DISABLE;
                        en_vtc <= '0';
                    end if;
                when WAIT_AFTER_DISABLE =>
                    load <= '0';
                    wait_counter <= wait_counter - 1;
                    if wait_counter = 0 then
                        odelay_cnt_in_latch <= fine_delay_i;
                        state <= PRELOAD;
                    end if;
                when PRELOAD =>
                    state <= START_LOAD;
                when START_LOAD =>
                    load <= '1';
                    state <= WAIT_BEFORE_ENABLE;
                    wait_counter <= (others => '1');
                when WAIT_BEFORE_ENABLE =>
                    load <= '0';
                    wait_counter <= wait_counter - 1;
                    if wait_counter = 0 then
                        en_vtc <= '1';
                        state <= IDLE;
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    odelay_inst : ODELAYE3 generic map (
        SIM_DEVICE => "ULTRASCALE_PLUS",
        DELAY_TYPE => "VAR_LOAD",
        DELAY_FORMAT => "TIME",
        DELAY_VALUE => 1000
    ) port map (
        CLK => clk_i,
        CASC_IN => '0',
        CASC_RETURN => '0',
        EN_VTC => en_vtc,
        CE => '0',
        INC => '0',
        RST => '0',
        LOAD => load,
        CNTVALUEIN => odelay_cnt_in_latch,
        CNTVALUEOUT => fine_delay_compensated_o,
        ODATAIN => signal_i,
        DATAOUT => signal_o
    );
end;

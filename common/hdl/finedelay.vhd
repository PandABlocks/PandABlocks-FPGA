
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity finedelay is
port (
    -- Main clock
    clk_i : in std_logic;
    -- double rate clock for ODDR
    clk_2x_i : in std_logic;
    q_delay_i : in std_logic_vector(1 downto 0);
    o_delay_i : in std_logic_vector(4 downto 0);
    o_delay_strobe_i : in std_logic;
    signal_i : in std_logic;
    signal_o : out std_logic
);
end finedelay;

architecture rtl of finedelay is
    signal in_signal_delay : std_logic := '0';
    signal in_signal_delay_on2x : std_logic := '0';
    signal in_signal_on2x : std_logic := '0';
    signal q_delay_on2x : std_logic_vector(1 downto 0) := "00";
    signal ddr_a : std_logic;
    signal ddr_b : std_logic;
    signal oddr_out : std_logic;
    signal phase_on2x : std_logic;
begin

    process (clk_i) begin
        if rising_edge(clk_i) then
            in_signal_delay <= signal_i;
        end if;
    end process;

    process (clk_2x_i) begin
        if rising_edge(clk_2x_i) then
            in_signal_on2x <= signal_i;
            in_signal_delay_on2x <= in_signal_delay;
            q_delay_on2x <= q_delay_i;
        end if;
    end process;

    process (in_signal_on2x, in_signal_delay_on2x, phase_on2x, q_delay_on2x)
    begin
        case phase_on2x & q_delay_on2x is
            when "000" =>
                ddr_a <= in_signal_on2x;
                ddr_b <= in_signal_on2x;
            when "100" =>
                ddr_a <= in_signal_on2x;
                ddr_b <= in_signal_on2x;
            when "001" =>
                ddr_a <= in_signal_delay_on2x;
                ddr_b <= in_signal_on2x;
            when "101" =>
                ddr_a <= in_signal_on2x;
                ddr_b <= in_signal_on2x;
            when "010" =>
                ddr_a <= in_signal_delay_on2x;
                ddr_b <= in_signal_delay_on2x;
            when "110" =>
                ddr_a <= in_signal_on2x;
                ddr_b <= in_signal_on2x;
            when "011" =>
                ddr_a <= in_signal_delay_on2x;
                ddr_b <= in_signal_delay_on2x;
            when "111" =>
                ddr_a <= in_signal_delay_on2x;
                ddr_b <= in_signal_on2x;
           when others =>
        end case;

    end process;

    oddr_inst : ODDR port map (
        Q => oddr_out,
        C => clk_2x_i,
        CE => '1',
        D1 => ddr_b,
        D2 => ddr_a
    );

    clock2_phase_inst : entity work.clock2_phase port map (
        clk_i => clk_i,
        clk_2x_i => clk_2x_i,
        phase_o => phase_on2x
    );

    odelay_inst : ODELAYE2 generic map (
        ODELAY_TYPE => "VAR_LOAD",
        HIGH_PERFORMANCE_MODE => "TRUE"
    ) port map (
        C => clk_i,
        ODATAIN => oddr_out,
        DATAOUT => signal_o,
        CLKIN => '0',
        CNTVALUEIN => o_delay_i,
        LD => o_delay_strobe_i,
        LDPIPEEN => '0',
        REGRST => '0',
        INC => '0',
        CINVCTRL => '0',
        CE => '0'
    );

end rtl;

library IEEE;
use IEEE.std_logic_1164.all;

package picxo_pkg is

    COMPONENT PICXO_FRACXO
      PORT (
        RESET_I : IN STD_LOGIC;
        REF_CLK_I : IN STD_LOGIC;
        TXOUTCLK_I : IN STD_LOGIC;
        DRPEN_O : OUT STD_LOGIC;
        DRPWEN_O : OUT STD_LOGIC;
        DRPDO_I : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        DRPDATA_O : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        DRPADDR_O : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
        DRPRDY_I : IN STD_LOGIC;
        RSIGCE_I : IN STD_LOGIC;
        VSIGCE_I : IN STD_LOGIC;
        VSIGCE_O : OUT STD_LOGIC;
        ACC_STEP : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        G1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        G2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        R : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        V : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        CE_DSP_RATE : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        C_I : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        P_I : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        N_I : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        OFFSET_PPM : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
        OFFSET_EN : IN STD_LOGIC;
        HOLD : IN STD_LOGIC;
        DON_I : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        DRP_USER_REQ_I : IN STD_LOGIC;
        DRP_USER_DONE_I : IN STD_LOGIC;
        DRPEN_USER_I : IN STD_LOGIC;
        DRPWEN_USER_I : IN STD_LOGIC;
        DRPADDR_USER_I : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
        DRPDATA_USER_I : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        DRPDATA_USER_O : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        DRPRDY_USER_O : OUT STD_LOGIC;
        DRPBUSY_O : OUT STD_LOGIC;
        ACC_DATA : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        ERROR_O : OUT STD_LOGIC_VECTOR(20 DOWNTO 0);
        VOLT_O : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
        DRPDATA_SHORT_O : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        CE_PI_O : OUT STD_LOGIC;
        CE_PI2_O : OUT STD_LOGIC;
        CE_DSP_O : OUT STD_LOGIC;
        OVF_PD : OUT STD_LOGIC;
        OVF_AB : OUT STD_LOGIC;
        OVF_VOLT : OUT STD_LOGIC;
        OVF_INT : OUT STD_LOGIC
      );
    END COMPONENT;

    COMPONENT picxo_ila
      PORT (
        clk    : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(20 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(7  DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe8 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe9 : IN STD_LOGIC_VECTOR(0  DOWNTO 0)
      );
    END COMPONENT;

    COMPONENT picxo_vio
      PORT (
        clk : IN STD_LOGIC;
        probe_out0  : OUT STD_LOGIC_VECTOR(4  DOWNTO 0);
        probe_out1  : OUT STD_LOGIC_VECTOR(4  DOWNTO 0);
        probe_out2  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_out3  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_out4  : OUT STD_LOGIC_VECTOR(3  DOWNTO 0);
        probe_out5  : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        probe_out6  : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
        probe_out7  : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe_out8  : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe_out9  : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe_out10 : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe_out11 : OUT STD_LOGIC_VECTOR(0  DOWNTO 0);
        probe_out12 : OUT STD_LOGIC_VECTOR(6  DOWNTO 0);
        probe_out13 : OUT STD_LOGIC_VECTOR(9  DOWNTO 0);
        probe_out14 : OUT STD_LOGIC_VECTOR(9  DOWNTO 0)
      );
    END COMPONENT;

    constant  c_G1                              : STD_LOGIC_VECTOR (4 downto 0);
    constant  c_G2                              : STD_LOGIC_VECTOR (4 downto 0);
    constant  c_R                               : STD_LOGIC_VECTOR (15 downto 0);
    constant  c_V                               : STD_LOGIC_VECTOR (15 downto 0);
    constant  c_ce_dsp_rate                     : std_logic_vector (23 downto 0);
    constant  c_C                               : STD_LOGIC_VECTOR (6 downto 0);
    constant  c_P                               : STD_LOGIC_VECTOR (9 downto 0);
    constant  c_N                               : STD_LOGIC_VECTOR (9 downto 0);
    constant  c_don                             : STD_LOGIC_VECTOR (0 downto 0);

    constant  c_Offset_ppm                      : std_logic_vector (21 downto 0);
    constant  c_Offset_en                       : std_logic;
    constant  c_hold                            : std_logic;
    constant  c_acc_step                        : STD_LOGIC_VECTOR (3 downto 0);

end;

package body picxo_pkg is

    constant  c_G1                              : STD_LOGIC_VECTOR (4 downto 0)     := "0" & x"8";
    constant  c_G2                              : STD_LOGIC_VECTOR (4 downto 0)     := "1" & x"0";
    constant  c_R                               : STD_LOGIC_VECTOR (15 downto 0)    := x"0200";
    constant  c_V                               : STD_LOGIC_VECTOR (15 downto 0)    := x"0200";
    constant  c_ce_dsp_rate                     : std_logic_vector (23 downto 0)    := x"0003ff";
    constant  c_C                               : STD_LOGIC_VECTOR (6 downto 0)     := "000" & x"0";
    constant  c_P                               : STD_LOGIC_VECTOR (9 downto 0)     := "00" & x"00";
    constant  c_N                               : STD_LOGIC_VECTOR (9 downto 0)     := "00" & x"00";
    constant  c_don                             : STD_LOGIC_VECTOR (0 downto 0)     := "0";

    constant  c_Offset_ppm                      : std_logic_vector (21 downto 0)    := "00" & x"00000";
    constant  c_Offset_en                       : std_logic                         := '0';
    constant  c_hold                            : std_logic                         := '0';
    constant  c_acc_step                        : STD_LOGIC_VECTOR (3 downto 0)     := x"4";

end;


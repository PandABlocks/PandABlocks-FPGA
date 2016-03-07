library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_busses is
port (

    -- REG Block

    -- DRV Block

    -- TTLIN Block
    TTLIN_VAL   : in std_logic_vector(5 downto 0);

    -- TTLOUT Block

    -- LVDSIN Block
    LVDSIN_VAL   : in std_logic_vector(1 downto 0);

    -- LVDSOUT Block

    -- LUT Block
    LUT_OUT   : in std_logic_vector(7 downto 0);

    -- SRGATE Block
    SRGATE_OUT   : in std_logic_vector(3 downto 0);

    -- DIV Block
    DIV_OUTD   : in std_logic_vector(3 downto 0);
    DIV_OUTN   : in std_logic_vector(3 downto 0);

    -- PULSE Block
    PULSE_OUT   : in std_logic_vector(3 downto 0);
    PULSE_PERR   : in std_logic_vector(3 downto 0);

    -- SEQ Block
    SEQ_OUTA   : in std_logic_vector(3 downto 0);
    SEQ_OUTB   : in std_logic_vector(3 downto 0);
    SEQ_OUTC   : in std_logic_vector(3 downto 0);
    SEQ_OUTD   : in std_logic_vector(3 downto 0);
    SEQ_OUTE   : in std_logic_vector(3 downto 0);
    SEQ_OUTF   : in std_logic_vector(3 downto 0);
    SEQ_ACTIVE   : in std_logic_vector(3 downto 0);

    -- INENC Block
    INENC_A   : in std_logic_vector(3 downto 0);
    INENC_B   : in std_logic_vector(3 downto 0);
    INENC_Z   : in std_logic_vector(3 downto 0);
    INENC_CONN   : in std_logic_vector(3 downto 0);
    INENC_VAL   : in std32_array(3 downto 0);

    -- QDEC Block
    QDEC_OUT   : in std32_array(3 downto 0);

    -- OUTENC Block

    -- POSENC Block
    POSENC_A   : in std_logic_vector(3 downto 0);
    POSENC_B   : in std_logic_vector(3 downto 0);

    -- ADDER Block
    ADDER_OUT   : in std32_array(1 downto 0);

    -- COUNTER Block
    COUNTER_CARRY   : in std_logic_vector(7 downto 0);
    COUNTER_OUT   : in std32_array(7 downto 0);

    -- PGEN Block
    PGEN_OUT   : in std32_array(1 downto 0);

    -- PCOMP Block
    PCOMP_ACTIVE   : in std_logic_vector(3 downto 0);
    PCOMP_OUT   : in std_logic_vector(3 downto 0);

    -- ADC Block
    ADC_OUT   : in std32_array(7 downto 0);

    -- PCAP Block
    PCAP_ACTIVE   : in std_logic_vector(0 downto 0);

    -- BITS Block
    BITS_OUTA   : in std_logic_vector(0 downto 0);
    BITS_OUTB   : in std_logic_vector(0 downto 0);
    BITS_OUTC   : in std_logic_vector(0 downto 0);
    BITS_OUTD   : in std_logic_vector(0 downto 0);
    BITS_ZERO   : in std_logic_vector(0 downto 0);
    BITS_ONE   : in std_logic_vector(0 downto 0);

    -- CLOCKS Block
    CLOCKS_OUTA   : in std_logic_vector(0 downto 0);
    CLOCKS_OUTB   : in std_logic_vector(0 downto 0);
    CLOCKS_OUTC   : in std_logic_vector(0 downto 0);
    CLOCKS_OUTD   : in std_logic_vector(0 downto 0);

    -- POSITIONS Block
    POSITIONS_ZERO   : in std32_array(0 downto 0);

    -- SLOW Block


    -- Bus Outputs
    bitbus_o            : out std_logic_vector(127 downto 0);
    posbus_o            : out std32_array(31 downto 0)
);
end panda_busses;

architecture rtl of panda_busses is

begin

-- REG Outputs:

-- DRV Outputs:

-- TTLIN Outputs:
bitbus_o(2) <= TTLIN_VAL(0);
bitbus_o(3) <= TTLIN_VAL(1);
bitbus_o(4) <= TTLIN_VAL(2);
bitbus_o(5) <= TTLIN_VAL(3);
bitbus_o(6) <= TTLIN_VAL(4);
bitbus_o(7) <= TTLIN_VAL(5);

-- TTLOUT Outputs:

-- LVDSIN Outputs:
bitbus_o(8) <= LVDSIN_VAL(0);
bitbus_o(9) <= LVDSIN_VAL(1);

-- LVDSOUT Outputs:

-- LUT Outputs:
bitbus_o(10) <= LUT_OUT(0);
bitbus_o(11) <= LUT_OUT(1);
bitbus_o(12) <= LUT_OUT(2);
bitbus_o(13) <= LUT_OUT(3);
bitbus_o(14) <= LUT_OUT(4);
bitbus_o(15) <= LUT_OUT(5);
bitbus_o(16) <= LUT_OUT(6);
bitbus_o(17) <= LUT_OUT(7);

-- SRGATE Outputs:
bitbus_o(18) <= SRGATE_OUT(0);
bitbus_o(19) <= SRGATE_OUT(1);
bitbus_o(20) <= SRGATE_OUT(2);
bitbus_o(21) <= SRGATE_OUT(3);

-- DIV Outputs:
bitbus_o(22) <= DIV_OUTD(0);
bitbus_o(23) <= DIV_OUTD(1);
bitbus_o(24) <= DIV_OUTD(2);
bitbus_o(25) <= DIV_OUTD(3);
bitbus_o(26) <= DIV_OUTN(0);
bitbus_o(27) <= DIV_OUTN(1);
bitbus_o(28) <= DIV_OUTN(2);
bitbus_o(29) <= DIV_OUTN(3);

-- PULSE Outputs:
bitbus_o(30) <= PULSE_OUT(0);
bitbus_o(31) <= PULSE_OUT(1);
bitbus_o(32) <= PULSE_OUT(2);
bitbus_o(33) <= PULSE_OUT(3);
bitbus_o(34) <= PULSE_PERR(0);
bitbus_o(35) <= PULSE_PERR(1);
bitbus_o(36) <= PULSE_PERR(2);
bitbus_o(37) <= PULSE_PERR(3);

-- SEQ Outputs:
bitbus_o(38) <= SEQ_OUTA(0);
bitbus_o(39) <= SEQ_OUTA(1);
bitbus_o(40) <= SEQ_OUTA(2);
bitbus_o(41) <= SEQ_OUTA(3);
bitbus_o(42) <= SEQ_OUTB(0);
bitbus_o(43) <= SEQ_OUTB(1);
bitbus_o(44) <= SEQ_OUTB(2);
bitbus_o(45) <= SEQ_OUTB(3);
bitbus_o(46) <= SEQ_OUTC(0);
bitbus_o(47) <= SEQ_OUTC(1);
bitbus_o(48) <= SEQ_OUTC(2);
bitbus_o(49) <= SEQ_OUTC(3);
bitbus_o(50) <= SEQ_OUTD(0);
bitbus_o(51) <= SEQ_OUTD(1);
bitbus_o(52) <= SEQ_OUTD(2);
bitbus_o(53) <= SEQ_OUTD(3);
bitbus_o(54) <= SEQ_OUTE(0);
bitbus_o(55) <= SEQ_OUTE(1);
bitbus_o(56) <= SEQ_OUTE(2);
bitbus_o(57) <= SEQ_OUTE(3);
bitbus_o(58) <= SEQ_OUTF(0);
bitbus_o(59) <= SEQ_OUTF(1);
bitbus_o(60) <= SEQ_OUTF(2);
bitbus_o(61) <= SEQ_OUTF(3);
bitbus_o(62) <= SEQ_ACTIVE(0);
bitbus_o(63) <= SEQ_ACTIVE(1);
bitbus_o(64) <= SEQ_ACTIVE(2);
bitbus_o(65) <= SEQ_ACTIVE(3);

-- INENC Outputs:
bitbus_o(66) <= INENC_A(0);
bitbus_o(67) <= INENC_A(1);
bitbus_o(68) <= INENC_A(2);
bitbus_o(69) <= INENC_A(3);
bitbus_o(70) <= INENC_B(0);
bitbus_o(71) <= INENC_B(1);
bitbus_o(72) <= INENC_B(2);
bitbus_o(73) <= INENC_B(3);
bitbus_o(74) <= INENC_Z(0);
bitbus_o(75) <= INENC_Z(1);
bitbus_o(76) <= INENC_Z(2);
bitbus_o(77) <= INENC_Z(3);
bitbus_o(78) <= INENC_CONN(0);
bitbus_o(79) <= INENC_CONN(1);
bitbus_o(80) <= INENC_CONN(2);
bitbus_o(81) <= INENC_CONN(3);
posbus_o(1) <= INENC_VAL(0);
posbus_o(2) <= INENC_VAL(1);
posbus_o(3) <= INENC_VAL(2);
posbus_o(4) <= INENC_VAL(3);

-- QDEC Outputs:
posbus_o(5) <= QDEC_OUT(0);
posbus_o(6) <= QDEC_OUT(1);
posbus_o(7) <= QDEC_OUT(2);
posbus_o(8) <= QDEC_OUT(3);

-- OUTENC Outputs:

-- POSENC Outputs:
bitbus_o(82) <= POSENC_A(0);
bitbus_o(83) <= POSENC_A(1);
bitbus_o(84) <= POSENC_A(2);
bitbus_o(85) <= POSENC_A(3);
bitbus_o(86) <= POSENC_B(0);
bitbus_o(87) <= POSENC_B(1);
bitbus_o(88) <= POSENC_B(2);
bitbus_o(89) <= POSENC_B(3);

-- ADDER Outputs:
posbus_o(10) <= ADDER_OUT(0);
posbus_o(11) <= ADDER_OUT(1);

-- COUNTER Outputs:
bitbus_o(90) <= COUNTER_CARRY(0);
bitbus_o(91) <= COUNTER_CARRY(1);
bitbus_o(92) <= COUNTER_CARRY(2);
bitbus_o(93) <= COUNTER_CARRY(3);
bitbus_o(94) <= COUNTER_CARRY(4);
bitbus_o(95) <= COUNTER_CARRY(5);
bitbus_o(96) <= COUNTER_CARRY(6);
bitbus_o(97) <= COUNTER_CARRY(7);
posbus_o(12) <= COUNTER_OUT(0);
posbus_o(13) <= COUNTER_OUT(1);
posbus_o(14) <= COUNTER_OUT(2);
posbus_o(15) <= COUNTER_OUT(3);
posbus_o(16) <= COUNTER_OUT(4);
posbus_o(17) <= COUNTER_OUT(5);
posbus_o(18) <= COUNTER_OUT(6);
posbus_o(19) <= COUNTER_OUT(7);

-- PGEN Outputs:
posbus_o(20) <= PGEN_OUT(0);
posbus_o(21) <= PGEN_OUT(1);

-- PCOMP Outputs:
bitbus_o(98) <= PCOMP_ACTIVE(0);
bitbus_o(99) <= PCOMP_ACTIVE(1);
bitbus_o(100) <= PCOMP_ACTIVE(2);
bitbus_o(101) <= PCOMP_ACTIVE(3);
bitbus_o(102) <= PCOMP_OUT(0);
bitbus_o(103) <= PCOMP_OUT(1);
bitbus_o(104) <= PCOMP_OUT(2);
bitbus_o(105) <= PCOMP_OUT(3);

-- ADC Outputs:
posbus_o(22) <= ADC_OUT(0);
posbus_o(23) <= ADC_OUT(1);
posbus_o(24) <= ADC_OUT(2);
posbus_o(25) <= ADC_OUT(3);
posbus_o(26) <= ADC_OUT(4);
posbus_o(27) <= ADC_OUT(5);
posbus_o(28) <= ADC_OUT(6);
posbus_o(29) <= ADC_OUT(7);

-- PCAP Outputs:
bitbus_o(106) <= PCAP_ACTIVE(0);

-- BITS Outputs:
bitbus_o(118) <= BITS_OUTA(0);
bitbus_o(119) <= BITS_OUTB(0);
bitbus_o(120) <= BITS_OUTC(0);
bitbus_o(121) <= BITS_OUTD(0);
bitbus_o(0) <= BITS_ZERO(0);
bitbus_o(1) <= BITS_ONE(0);

-- CLOCKS Outputs:
bitbus_o(122) <= CLOCKS_OUTA(0);
bitbus_o(123) <= CLOCKS_OUTB(0);
bitbus_o(124) <= CLOCKS_OUTC(0);
bitbus_o(125) <= CLOCKS_OUTD(0);

-- POSITIONS Outputs:
posbus_o(0) <= POSITIONS_ZERO(0);

-- SLOW Outputs:



end rtl;
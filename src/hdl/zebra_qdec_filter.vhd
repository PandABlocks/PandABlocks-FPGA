
LIBRARY  IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
--
-- v2
-- with error
ENTITY zebra_qdec_filter IS
PORT (
	CLK			: In std_logic;
	MODE		: In std_logic;
	P_BYPASS	: In std_logic;
	SEUIL		: In std_logic_vector(7 downto 0);
	DIR			: In std_logic;
	PULSE		: In std_logic;
	DIR_OUT 	: Out std_logic;
	PULSE_OUT 	: Out std_logic;
	ERR			: Out std_logic
);
END zebra_qdec_filter ;

ARCHITECTURE rtl OF zebra_qdec_filter IS
--Declarations constantes
	CONSTANT ZERO : std_logic_vector(7 downto 0):= (others =>'0');
--Declarations des etats
--Declarations Signaux
	SIGNAL count,count2 : std_logic_vector(7 downto 0):= (others =>'0');
	SIGNAL s_dir,s_dir2 : std_logic := '0';
	SIGNAL sERR : std_logic := '0';
	SIGNAL s_Pulse,s_Pulse2 : std_logic := '0';
	
	SIGNAL reg : std_logic := '0';
	
	SIGNAL countp,countn : std_logic_vector(7 downto 0):= (others =>'0');

	SIGNAL s_D_out,s_P_out : std_logic;
--
BEGIN

-- Hysteresis pour tendance
CHANGE_DIR_02:PROCESS (CLK)
BEGIN
if (CLK'event and CLK = '1') then
	if (PULSE = '1') then
		reg <= DIR;
		if reg /= DIR then
			count2 <= ZERO;
			s_Pulse2 <= '0';
		elsif (count2 = SEUIL) then
			s_Pulse2 <= '1';
			if DIR = '0' then
				s_dir2 <= '0';
			else
				s_dir2 <= '1';
			end if;
		else
			s_Pulse2 <= '0';
			count2 <= count2 + 1;
		end if;
	else
		s_Pulse2 <= '0';
	end if;
	
end if ;
End Process;

-- Hysteresis pour tendance
CHANGE_DIR_01:PROCESS (CLK)
BEGIN
if (CLK'event and CLK = '1') then
	if (PULSE = '1') then
		if DIR = '0' then
			if (count = SEUIL) then
				s_dir <= '0';
				s_Pulse <= '1';
			else
				count <= count + 1;
				s_Pulse <= '0';
			end if;
		else
			if (count = ZERO) then
				s_dir <= '1';
				s_Pulse <= '1';
			else
				count <= count - 1;
				s_Pulse <= '0';
			end if;
		end if;
	else
		s_Pulse <= '0';
	end if ;
end if ;
End Process;


s_D_out <= s_dir when MODE = '0' else s_dir2;
s_P_out <= s_Pulse when MODE = '0' else s_Pulse2;

DIR_OUT <= DIR when P_BYPASS = '0' else s_D_out;
PULSE_OUT <= PULSE when P_BYPASS = '0' else s_P_out;

ERR <= sERR;

end rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.support.all;

entity ssi_error_detect is
port ( 
    clk_i           : in  std_logic;
    serial_dat_i    : in  std_logic;
    ssi_frame_i     : in  std_logic;
    link_up_o       : out std_logic
);
end ssi_error_detect;

architecture rtl of ssi_error_detect is

constant ENCODER_TIMEOUT    : natural := 125 * 10; -- 10usec (Minimum timeout/2)

signal ssi_frame_prev       : std_logic;
signal timeout_cnt_en       : std_logic;
signal timeout_ctr          : unsigned(LOG2(ENCODER_TIMEOUT-1) downto 0);
signal frame_start          : std_logic;
signal frame_end            : std_logic;

begin

frame_err_det: process(clk_i)
begin
    if rising_edge(clk_i) then

        ssi_frame_prev <= ssi_frame_i;

        if ssi_frame_i = '1' and ssi_frame_prev = '0' then -- rising edge
            -- Encoder must drive the line high when IDLE
            frame_start <= serial_dat_i;
            timeout_cnt_en <= '0';
        elsif ssi_frame_i = '0' and ssi_frame_prev = '1' then --falling edge
            timeout_cnt_en <= '1';
            timeout_ctr <= (others => '0');
        elsif timeout_cnt_en = '1' then
            if timeout_ctr = ENCODER_TIMEOUT-1 then
                -- Encoder must drive the line low during TIMEOUT dwell time
                frame_end <= serial_dat_i;
                timeout_ctr <= (others => '0');
                timeout_cnt_en <= '0';
            else
                timeout_ctr <= timeout_ctr + 1;
            end if;
        end if;

        -- Link is up when line is high during IDLE and low during TIMEOUT
        link_up_o <= frame_start and not frame_end;
    end if;
end process;

end rtl;


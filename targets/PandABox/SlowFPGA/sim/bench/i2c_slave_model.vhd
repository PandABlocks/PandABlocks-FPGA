--------------------------------------------------------------------/
----                                                             ----
----  WISHBONE rev.B2 compliant synthesizable I2C Slave model    ----
----                                                             ----
----                                                             ----
----  Authors: Richard Herveille (richard@asics.ws) www.asics.ws ----
----           John Sheahan (jrsheahan@optushome.com.au)         ----
----                                                             ----
----  Downloaded from: http:--www.opencores.org/projects/i2c/    ----
----                                                             ----
--------------------------------------------------------------------/
----                                                             ----
---- Copyright (C) 2001,2002 Richard Herveille                   ----
----                         richard@asics.ws                    ----
----                                                             ----
---- This source file may be used and distributed without        ----
---- restriction provided that this copyright statement is not   ----
---- removed from the file and that any derivative work contains ----
---- the original copyright notice and the associated disclaimer.----
----                                                             ----
----     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ----
---- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ----
---- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ----
---- FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ----
---- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ----
---- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ----
---- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ----
---- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ----
---- BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ----
---- LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ----
---- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ----
---- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ----
---- POSSIBILITY OF SUCH DAMAGE.                                 ----
----                                                             ----
--------------------------------------------------------------------/

--  CVS Log
--
--  $Id: i2c_slave_model.v,v 1.6 2005/02/28 11:33:48 rherveille Exp $
--
--  $Date: 2005/02/28 11:33:48 $
--  $Revision: 1.6 $
--  $Author: rherveille $
--  $Locker:  $
--  $State: Exp $
--
-- Change History:
--               $Log: i2c_slave_model.v,v $
--               Revision 1.6  2005/02/28 11:33:48  rherveille
--               Fixed Tsu:sta timing check.
--               Added Thd:sta timing check.
--
--               Revision 1.5  2003/12/05 11:05:19  rherveille
--               Fixed slave address MSB='1' bug
--
--               Revision 1.4  2003/09/11 08:25:37  rherveille
--               Fixed a bug in the timing section. Changed 'tst_scl' into 'tst_sto'.
--
--               Revision 1.3  2002/10/30 18:11:06  rherveille
--               Added timing tests to i2c_model.
--               Updated testbench.
--
--               Revision 1.2  2002/03/17 10:26:38  rherveille
--               Fixed some race conditions in the i2c-slave model.
--               Added debug information.
--               Added headers.
--

library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;
use ieee.std_logic_misc.all ;

entity i2c_slave_model is
generic (
    I2C_ADR : std_logic_vector(6 downto 0) := "1001000"
);
port (
    scl : in std_logic;
    sda : inout std_logic
);
end i2c_slave_model;


architecture syn of i2c_slave_model is

constant debug :std_logic := '1';

type std_2d             is array(natural range <>)  of std_logic_vector(7 downto 0);
type i2s_slave_sm_type  is (idle, slave_ack, get_mem_adr, gma_ack, data, data_ack);

signal state    : i2s_slave_sm_type:=idle;

signal mem      : std_2d(7 downto 0) := (
                        X"00", X"01", X"02", X"03", X"04", X"05", X"06", X"07"
                );
signal mem_adr      : std_logic_vector(7 downto 0);
signal mem_do       : std_logic_vector(7 downto 0);

signal sr           : std_logic_vector(7 downto 0);
signal bit_cnt      : std_logic_vector(2 downto 0);
signal sta          : std_logic;
signal d_sta        : std_logic;
signal sto          : std_logic;
signal d_sto        : std_logic;

signal i2c_reset    : std_logic;
signal sda_o        : std_logic := '1';

signal sda_dly      : std_logic;
signal ld           : std_logic;
signal acc_done     : std_logic;
signal my_adr       : std_logic;
signal rw           : std_logic;

begin

shift_reg: process(scl)
begin

if( scl'event and (scl = '1' or scl = 'H')) then
   if (sda = '1' or sda = 'H') then
      sr <= sr(6 downto 0) & '1' after 1 ns;
   else
      sr <= sr(6 downto 0) & '0' after 1 ns;
   end if;

   if (ld = '1') then
      bit_cnt <= (others =>'1') after 1 ns;
   else
      bit_cnt <= bit_cnt - 1  after 1 ns;
   end if;


end if;
end process;

detct_proc: process(sda, scl)
begin

if( sda'event and sda = '0' ) then
   if(scl = '1' or scl = 'H') then
      sta   <= '1' after 1 ns;
      d_sta <= '0' after 1 ns;
      sto   <= '0' after 1 ns;
      if(debug = '1') then
         report("DEBUG i2c_slave; start condition detected ");
      end if;
   else
      sta <= '0' after 1 ns;
   end if;

elsif( sda'event and (sda = '1' or sda = 'H')) then
   if(scl = '1' or scl = 'H') then
      sta   <= '0' after 1 ns;
      sto   <= '1' after 1 ns;
      if(debug = '1') then
         report("DEBUG i2c_slave; stop condition detected");
      end if;
   else
      sto <= '0' after 1 ns;
   end if;

elsif ( scl'event and (scl = '1' or scl = 'H')) then
   d_sta <= sta after 1 ns;

end if;
end process;

sm_proc: process(scl, sto)
variable rw_var :std_logic;
begin

if( (scl'event and scl = '0') or (sto'event and sto = '0')) then
   if (sto = '1' or( sta = '1' and d_sta= '0')) then
      state <= idle after 1 ns;
      sda_o <= '1' after 1 ns;
      ld    <= '1' after 1 ns;
   else
      sda_o <= '1' after 1 ns;
      ld    <= '0' after 1 ns;

      case state is
         when idle =>
            if(acc_done = '1' and my_adr= '1') then
               state <= slave_ack after 1 ns;
               rw    <= sr(0) after 1 ns;
               rw_var := sr(0);
               sda_o <= '0' after 1 ns;

               if (debug = '1' and sr(0) = '1') then
                  report("DEBUG i2c_slave; command byte received (read)" );
               elsif (debug = '1' and sr(0) = '0') then
                  report("DEBUG i2c_slave; command byte received (write)" );
               end if;

               if (rw_var = '1') then
                  mem_do <= mem(conv_integer(mem_adr)) after 1 ns;
                  if (debug = '1') then
                     report ("DEBUG i2c_slave; data block read from address ");
                  end if;
               end if;
            end if;


         when slave_ack =>
            if (rw = '1') then
               state <= data after 1 ns;
               sda_o <= mem_do(7) after 1 ns;
            else
               state <= get_mem_adr after 1 ns;
               ld    <= '1' after 1 ns;
            end if;



         when get_mem_adr =>
            if (acc_done = '1') then
               state <= gma_ack  after 1 ns;
               mem_adr <= sr  after 1 ns;
               if (sr <= conv_std_logic_vector(15,7)) then
                  sda_o <= '0' after 1 ns;
               else
                  sda_o <= '1' after 1 ns;
               end if;

               if (debug = '1') then
                  report ("DEBUG i2c_slave; address received. ");
               end if;
            end if;


         when gma_ack =>
            state <= data after 1 ns;
            ld <= '1' after 1 ns;


         when data =>
            if(rw = '1') then
               sda_o <= mem_do(7) after 1 ns;
            end if;

            if(acc_done = '1') then
               state <= data_ack after 1 ns;
               mem_adr <= mem_adr + 1 after 2 ns;
               if (rw= '1'and mem_adr <= conv_std_logic_vector(15,7)) then
                  sda_o    <= '1' after 3 ns;
               else
                  sda_o    <= '0' after 1 ns;
               end if;

               if(rw= '1') then
                  mem_do <= mem(conv_integer(mem_adr)) after 3 ns;
                  if (debug = '1') then
                     report ("DEBUG i2c_slave; data block read");
                  end if;
               end if;

               if (rw= '0') then
                  mem(conv_integer(mem_adr)) <= sr after 1 ns;
                  if (debug = '1') then
                     report ("DEBUG i2c_slave; data block write ");
                  end if;
               end if;
            end if;




         when data_ack =>
            ld <= '1' after 1 ns;

            if (rw= '1') then
               if (sda = '1'  or sda = 'H') then
                  state <= idle after 1 ns;
                  sda_o <= '1' after 1 ns;
               else
                  state <= data after 1 ns;
                  sda_o <= mem_do(7) after 1 ns;
               end if;
            else
               state <= data after 1 ns;
               sda_o <= '1' after 1 ns;
            end if;

         end case;


   end if;
elsif( scl'event and (scl = '1' or scl = 'H')) then
   if (acc_done = '0' and rw = '1') then
      mem_do <= mem_do(6 downto 0) & '1';
   end if;

end if;


end process;

my_adr      <= '1' when sr(7 downto 1) = i2c_adr else '0'; --detect if it is our address

acc_done    <= not or_reduce(bit_cnt);    --generate access done signal

-- generate delayed version of sda
-- this model assumes a hold time for sda after the falling edge of scl.
-- According to the Phillips i2c spec, there s/b a 0 ns hold time for sda
-- with regards to scl. If the data changes coincident with the clock, the
-- acknowledge is missed
-- Fix by Michael Sosnoski
sda_dly <= '1'  after 1 ns when sda = '1' or sda = 'H' else '0' after 1 ns;

--generate i2c_reset signal
i2c_reset <= sta or sto;

-- generate tri-states
sda <= '0' when sda_o = '0' else 'Z';

end syn;


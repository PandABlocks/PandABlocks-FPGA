/*
 virtexHex2Bin - filter program for converting the  FPGA Virtex  XCVP20 
 prom file in HEX format  into the binary format.
 
 The HEX format is the only format, which provides the non-reversal 
 bits-byte orientation, what is necessary for the CEP direct download. 

 procedure on the ISE:
  Generate Programing File
  Genetrate PROM, ACE, or JTAG File (run)
  Prepare configuration File
  Prom File 
  Xilinx Serial Prom,HEX, Swap Bits
  Auto Select PROM
  Add file *.bit
  Finish 
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>


int main(int argc, char **argv)
{
    unsigned char StreamData;
    while(EOF!=fscanf(stdin,"%02x",&StreamData))
        write(1,&StreamData,1);
    return 0;
}

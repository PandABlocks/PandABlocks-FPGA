/* This file contains APIs used for testbench */


function [127:0] rsp_str;
 input [1:0] rsp;
 case(rsp)
  2'b00: rsp_str = "OKAY";
  2'b01: rsp_str = "EX_OKAY";
  2'b10: rsp_str = "SLV_ERR";
  2'b11: rsp_str = "DEC_ERR";
 endcase
endfunction
 

/* Read data to file */
task automatic tb_read_to_file;
input [511:0] port_name; 
input [1023:0] file_name;
input [31:0] start_addr;
input [31:0] rd_size;
output [1:0] response;
reg [1:0] rresp, rrrsp;
reg [31:0] addr;
reg [31:0] bytes;
reg [3:0] trnsfr_lngth;
reg [511:0] rd_data;
integer rd_fd;
begin
addr = start_addr;
rresp = 2'b00;
bytes = rd_size;
if(bytes > 64)
 trnsfr_lngth = 15;
else if(bytes%4 == 0)
 trnsfr_lngth = bytes/4 - 1;
else 
 trnsfr_lngth = bytes/4;
rd_fd = $fopen(file_name,"a+");

$display("From TB_TEST : %0s : Starting Read burst at address %h",port_name,addr);
while (bytes > 0) begin
  case(port_name)
   "master_hp1" :   tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.READ_BURST(20, addr, trnsfr_lngth, 3'b010, 2'b00, 2'b00, 4'b0000, 3'b000, rd_data, rrrsp);
  endcase

  repeat(trnsfr_lngth+1) begin
//   $fdisplayh(rd_fd,rd_data[31:0]);
   $fdisplay(rd_fd,rd_data[31:0]);
   rd_data = rd_data >> 32;
  end
  
  addr = addr + (trnsfr_lngth+1)*4;
  if(bytes > 64)
   bytes = bytes - (trnsfr_lngth+1)*4;
  else
   bytes = 0;
  if(bytes > 64)
   trnsfr_lngth = 15;
  else if(bytes%4 == 0)
   trnsfr_lngth = bytes/4 - 1;
  else 
   trnsfr_lngth = bytes/4;
  rresp = rresp | rrrsp;
end /// while 
response = rresp;
$display("From TB_TEST : %0s : Read Done with %0s Response",port_name,rsp_str(rresp));

end
endtask

/* Write data from file */
task automatic tb_write_from_file;
input [511:0] port_name;
input [1023:0] file_name;
input [31:0] start_addr;
input [31:0] wr_size;
output [1:0] response;
reg [1:0] wresp,rwrsp;
reg [31:0] addr;
reg [31:0] bytes;
reg [31:0] trnsfr_bytes;
reg [511:0] wr_data;
integer wr_fd;
integer succ;
integer trnsfr_lngth;

begin
addr = start_addr;
bytes = wr_size;
wresp = 2'b00;
 
if(bytes > 64)
 trnsfr_bytes = 64;
else
 trnsfr_bytes = bytes;

if(bytes > 64)
 trnsfr_lngth = 15;
else if(bytes%4 == 0)
 trnsfr_lngth = bytes/4 - 1;
else 
 trnsfr_lngth = bytes/4;

wr_fd = $fopen(file_name,"r");

$display("From TB_TEST : %0s : Starting Write burst at address %h",port_name,addr);
while (bytes > 0) begin
  repeat(16) begin
   wr_data = wr_data >> 32;
   succ = $fscanf(wr_fd,"%h",wr_data[511:480]);
  end 
  case(port_name)  
    "master_hp1" : tb.uut.ps.ps.hp1.cdn_axi3_master_bfm_inst.WRITE_BURST(71,addr, trnsfr_lngth, 3'b010, 2'b00, 2'b00, 4'b0000, 3'b000, wr_data, trnsfr_bytes, rwrsp);
  endcase

  bytes = bytes - trnsfr_bytes;
  addr = addr + trnsfr_bytes;
  if(bytes >= 64)
   trnsfr_bytes = 64;
  else
   trnsfr_bytes = bytes;

  if(bytes > 64)
   trnsfr_lngth = 15;
  else if(bytes%4 == 0)
   trnsfr_lngth = bytes/4 - 1;
  else 
   trnsfr_lngth = bytes/4;

  wresp = wresp | rwrsp;
end /// while 
response = wresp;
$display("From TB_TEST : %0s : Write Done with %0s Response",port_name,rsp_str(wresp));
end
endtask


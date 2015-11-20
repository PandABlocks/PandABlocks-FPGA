// -- (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved. 
// --                                                             
// -- This file contains confidential and proprietary information 
// -- of Xilinx, Inc. and is protected under U.S. and             
// -- international copyright and other intellectual property     
// -- laws.                                                       
// --                                                             
// -- DISCLAIMER                                                  
// -- This disclaimer is not a license and does not grant any     
// -- rights to the materials distributed herewith. Except as     
// -- otherwise provided in a valid license issued to you by      
// -- Xilinx, and to the maximum extent permitted by applicable   
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND     
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES 
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING   
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-      
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and    
// -- (2) Xilinx shall not be liable (whether in contract or tort,
// -- including negligence, or under any other theory of          
// -- liability) for any loss or damage of any kind or nature     
// -- related to, arising under or in connection with these       
// -- materials, including for any direct, or any indirect,       
// -- special, incidental, or consequential loss or damage        
// -- (including loss of data, profits, goodwill, or any type of  
// -- loss or damage suffered as a result of any action brought   
// -- by a third party) even if such damage or loss was           
// -- reasonably foreseeable or Xilinx had been advised of the    
// -- possibility of the same.                                    
// --                                                             
// -- CRITICAL APPLICATIONS                                       
// -- Xilinx products are not designed or intended to be fail-    
// -- safe, or for use in any application requiring fail-safe     
// -- performance, such as life-support or safety devices or      
// -- systems, Class III medical devices, nuclear facilities,     
// -- applications related to the deployment of airbags, or any   
// -- other applications that could lead to death, personal       
// -- injury, or severe property or environmental damage          
// -- (individually and collectively, "Critical                   
// -- Applications"). Customer assumes the sole risk and          
// -- liability of any use of Xilinx products in Critical         
// -- Applications, subject only to applicable laws and           
// -- regulations governing limitations on product liability.     
// --                                                             
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS    
// -- PART OF THIS FILE AT ALL TIMES.                             
// --  
//-----------------------------------------------------------------------------
//
// File name: zynq_ps_hp1_0.v
//
// Description: Verilog wrapper for Cadence's "cdn_axi_bfm" module.
//
//
//-----------------------------------------------------------------------------
`timescale 1ps/1ps

//-----------------------------------------------------------------------------
// The AXI 3 Master BFM Top Level Wrapper
//-----------------------------------------------------------------------------

module zynq_ps_hp1_0 (m_axi_aclk, m_axi_aresetn, 
 m_axi_awid, m_axi_awaddr, m_axi_awlen, m_axi_awsize, m_axi_awburst, m_axi_awlock, 
                                 m_axi_awcache, m_axi_awprot, m_axi_awvalid, m_axi_awready,
m_axi_wid,  m_axi_wdata, m_axi_wstrb, m_axi_wlast, m_axi_wvalid, m_axi_wready,
m_axi_bid,  m_axi_bresp, m_axi_bvalid, m_axi_bready,
m_axi_arid, m_axi_araddr, m_axi_arlen, m_axi_arsize, m_axi_arburst, m_axi_arlock,
                                 m_axi_arcache, m_axi_arprot, m_axi_arvalid, m_axi_arready,
m_axi_rid,  m_axi_rdata, m_axi_rresp, m_axi_rlast, m_axi_rvalid, m_axi_rready
                                 );
//-----------------------------------------------------------------------------

parameter C_M_AXI3_NAME = "zynq_ps_hp1_0";
parameter C_M_AXI3_DATA_WIDTH = 32;
parameter C_M_AXI3_ADDR_WIDTH = 32;
parameter C_M_AXI3_ID_WIDTH = 4;
parameter C_INTERCONNECT_M_AXI3_READ_ISSUING = 8;
parameter C_INTERCONNECT_M_AXI3_WRITE_ISSUING = 8;
parameter C_M_AXI3_EXCLUSIVE_ACCESS = 0;
// Global Clock Input. All signals are sampled on the rising edge.
input wire m_axi_aclk;
// Global Reset Input. Active Low.
input wire m_axi_aresetn;
input  wire [C_M_AXI3_ID_WIDTH-1:0]          m_axi_bid;     // Slave Response ID.
output wire [C_M_AXI3_ID_WIDTH-1:0]          m_axi_awid;    // Master Write address ID. 
output wire [C_M_AXI3_ID_WIDTH-1:0]          m_axi_wid;     // Master Write ID tag.
output wire [C_M_AXI3_ID_WIDTH-1:0]          m_axi_arid;    // Master Read address ID.
input  wire [C_M_AXI3_ID_WIDTH-1:0]          m_axi_rid;     // Slave Read ID tag. 
// Write Address Channel Signals.
output wire [C_M_AXI3_ADDR_WIDTH-1:0]        m_axi_awaddr;  // Master Write address. 
output wire [3:0]                            m_axi_awlen;   // Master Burst length.
output wire [2:0]                            m_axi_awsize;  // Master Burst size.
output wire [1:0]                            m_axi_awburst; // Master Burst type.
output wire [1:0]                            m_axi_awlock;  // Master Lock type.
output wire [3:0]                            m_axi_awcache; // Master Cache type.
output wire [2:0]                            m_axi_awprot;  // Master Protection type.
output wire                                  m_axi_awvalid; // Master Write address valid.
input  wire                                  m_axi_awready; // Slave Write address ready.

// Write Data Channel Signals.
output wire [C_M_AXI3_DATA_WIDTH-1:0]        m_axi_wdata;   // Master Write data.
output wire [(C_M_AXI3_DATA_WIDTH/8)-1:0]    m_axi_wstrb;   // Master Write strobes.
output wire                                  m_axi_wlast;   // Master Write last.
output wire                                  m_axi_wvalid;  // Master Write valid.
input  wire                                  m_axi_wready;  // Slave Write ready.

// Write Response Channel Signals.
input  wire [1:0]                            m_axi_bresp;   // Slave Write response.
input  wire                                  m_axi_bvalid;  // Slave Write response valid. 
output wire                                  m_axi_bready;  // Master Response ready.
 
// Read Address Channel Signals.
output wire [C_M_AXI3_ADDR_WIDTH-1:0]        m_axi_araddr;  // Master Read address.
//output wire [32-1:0]                       m_axi_araddr;  // Master Read address.
output wire [3:0]                            m_axi_arlen;   // Master Burst length.
output wire [2:0]                            m_axi_arsize;  // Master Burst size.
output wire [1:0]                            m_axi_arburst; // Master Burst type.
output wire [1:0]                            m_axi_arlock;  // Master Lock type.
output wire [3:0]                            m_axi_arcache; // Master Cache type.
output wire [2:0]                            m_axi_arprot;  // Master Protection type.
output wire                                  m_axi_arvalid; // Master Read address valid.
input  wire                                  m_axi_arready; // Slave Read address ready.
  
// Read Data Channel Signals.
input  wire [C_M_AXI3_DATA_WIDTH-1:0]        m_axi_rdata;   // Slave Read data.
input  wire [1:0]                            m_axi_rresp;   // Slave Read response.
input  wire                                  m_axi_rlast;   // Slave Read last.
input  wire                                  m_axi_rvalid;  // Slave Read valid.
output wire                                  m_axi_rready;  // Master Read ready.
 
cdn_axi3_master_bfm #(.NAME(C_M_AXI3_NAME),
                      .DATA_BUS_WIDTH(C_M_AXI3_DATA_WIDTH),
                      .ADDRESS_BUS_WIDTH(C_M_AXI3_ADDR_WIDTH),
                      .ID_BUS_WIDTH(C_M_AXI3_ID_WIDTH), 
                      .MAX_OUTSTANDING_TRANSACTIONS(C_INTERCONNECT_M_AXI3_READ_ISSUING),
                      .EXCLUSIVE_ACCESS_SUPPORTED(C_M_AXI3_EXCLUSIVE_ACCESS)
                      ) 
cdn_axi3_master_bfm_inst(.ACLK(m_axi_aclk), 
                         .ARESETn(m_axi_aresetn),
                         .AWID(m_axi_awid),
 
                         .AWADDR(m_axi_awaddr), 
                         .AWLEN(m_axi_awlen),         
                         .AWSIZE(m_axi_awsize),         
                         .AWBURST(m_axi_awburst),       
                         .AWLOCK(m_axi_awlock),         
                         .AWCACHE(m_axi_awcache),       
                         .AWPROT(m_axi_awprot),             
                         .AWVALID(m_axi_awvalid),       
                         .AWREADY(m_axi_awready),        
                         .WID(m_axi_wid),
                         .WDATA(m_axi_wdata),         
                         .WSTRB(m_axi_wstrb),         
                         .WLAST(m_axi_wlast),         
                         .WVALID(m_axi_wvalid),         
                         .WREADY(m_axi_wready),        
                         .BID(m_axi_bid),          
                         .BRESP(m_axi_bresp),         
                         .BVALID(m_axi_bvalid),         
                         .BREADY(m_axi_bready),        
                         .ARID(m_axi_arid),        
 
                         .ARADDR(m_axi_araddr),         
                         .ARLEN(m_axi_arlen),         
                         .ARSIZE(m_axi_arsize),         
                         .ARBURST(m_axi_arburst),       
                         .ARLOCK(m_axi_arlock),        
                         .ARCACHE(m_axi_arcache),       
                         .ARPROT(m_axi_arprot),              
                         .ARVALID(m_axi_arvalid),       
                         .ARREADY(m_axi_arready),        
                         .RID(m_axi_rid),          
                         .RDATA(m_axi_rdata),         
                         .RRESP(m_axi_rresp),         
                         .RLAST(m_axi_rlast),         
                         .RVALID(m_axi_rvalid),         
                         .RREADY(m_axi_rready)        
                       );
// These runtime parameters are set based on selection in GUI
// All these parameters can be changed during the runtime in the TB also
initial
begin
cdn_axi3_master_bfm_inst.set_write_burst_data_transfer_gap(0);
cdn_axi3_master_bfm_inst.set_response_timeout(500);
cdn_axi3_master_bfm_inst.set_disable_reset_value_checks(0);
cdn_axi3_master_bfm_inst.set_clear_signals_after_handshake(0);
cdn_axi3_master_bfm_inst.set_error_on_slverr(0);
cdn_axi3_master_bfm_inst.set_error_on_decerr(0);
cdn_axi3_master_bfm_inst.set_stop_on_error(1);
cdn_axi3_master_bfm_inst.set_channel_level_info(0);
cdn_axi3_master_bfm_inst.set_function_level_info(1);
cdn_axi3_master_bfm_inst.set_write_id_order_check_feature_value(0);
cdn_axi3_master_bfm_inst.set_task_call_and_reset_handling(0);
cdn_axi3_master_bfm_inst.set_input_signal_delay(0);
end

endmodule

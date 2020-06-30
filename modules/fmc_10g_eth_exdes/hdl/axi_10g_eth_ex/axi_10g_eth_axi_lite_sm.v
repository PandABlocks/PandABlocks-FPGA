// ----------------------------------------------------------------------------
// (c) Copyright 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// ----------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Title      : AXI Lite configuration state machine
// Project    : 10G Gigabit Ethernet
//------------------------------------------------------------------------------
// File       : axi_10g_eth_axi_lite_sm.v
// Author     : Xilinx Inc.
// -----------------------------------------------------------------------------
// Description:  This module is reponsible for bringing up the Ethernet core to
//               enable basic packet transfer in both directions.
//               This module signals configuration completion by asserting the
//               enable_gen output once the core is in block lock or if it is
//               set into loopback mode.
//
//------------------------------------------------------------------------------

`timescale 1 ps/1 ps

(* dont_touch = "yes" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module axi_10g_eth_axi_lite_sm (
      input                s_axi_aclk,
      input                s_axi_reset,

      input                pcs_loopback,

      input                enable_vlan,
      input                enable_custom_preamble,

      output reg           enable_gen = 0,
      output reg           block_lock = 0,

      output reg  [10:0]   s_axi_awaddr = 0,
      output reg           s_axi_awvalid = 0,
      input                s_axi_awready,

      output reg  [31:0]   s_axi_wdata = 0,
      output reg           s_axi_wvalid = 0,
      input                s_axi_wready,

      input       [1:0]    s_axi_bresp,
      input                s_axi_bvalid,
      output reg           s_axi_bready = 0,

      output reg  [10:0]   s_axi_araddr = 0,
      output reg           s_axi_arvalid = 0,
      input                s_axi_arready,

      input       [31:0]   s_axi_rdata,
      input       [1:0]    s_axi_rresp,
      input                s_axi_rvalid,
      output reg           s_axi_rready = 0
);

  // Main state machine
  localparam  STARTUP                   = 0,
              RESET_MAC_TX              = 1,
              RESET_MAC_RX              = 2,
              MDIO_ADDR                 = 3,
              MDIO_RD                   = 4,
              MDIO_RD_1                 = 5,
              MDIO_WR                   = 6,
              MDIO_ADDR_1               = 7,
              MDIO_ADDR_2               = 8,
              MDIO_POLL_CHECK           = 9,
              MDIO_CHECK_DATA           = 10,
              CONFIG_DONE               = 11,
              MDIO_READ_PCS_RESET       = 12,
              MDIO_READ_PCS_RESET_POLL  = 13,
              MDIO_READ_PCS_RESET_READ  = 14,
              MDIO_RESET_CHECK          = 15;

  // MDIO State machine
  localparam  IDLE                  = 0,
              SET_DATA              = 1,
              INIT                  = 2,
              POLL                  = 3;

  // AXI State Machine
  localparam  READ                  = 1,
              WRITE                 = 2,
              DONE                  = 3;

    // Management configuration register address     (0x500)
  localparam CONFIG_MANAGEMENT_ADDR  = 17'h500;

  // Receiver configuration register address       (0x404)
  localparam RECEIVER_ADDR           = 17'h404;

  // Transmitter configuration register address    (0x408)
  localparam TRANSMITTER_ADDR        = 17'h408;

  // MDIO registers
  localparam MDIO_CONTROL           = 17'h504;
  localparam MDIO_TX_DATA           = 17'h508;
  localparam MDIO_RX_DATA           = 17'h50C;
  localparam MDIO_OP_ADDR           = 2'b00;
  localparam MDIO_OP_RD             = 2'b11;
  localparam MDIO_OP_RD_INCR        = 2'b10;
  localparam MDIO_OP_WR             = 2'b01;

  // PHY Registers
  // phy address is actually a 6 bit field but other bits are reserved so simpler to specify as 8 bit
  localparam PRT_ADDR                = 5'h00;
  localparam DEV_ADDR                = 5'h03;
  localparam PHY_CONTROL_REG         = 8'h0;
  localparam PHY_STATUS_REG          = 8'h1;
  localparam PHY_ABILITY_REG         = 8'h4;
  localparam PHY_1000BASET_CONTROL_REG = 8'h9;

  //-------------------------------------------------
  // Wire/reg declarations
  reg      [4:0]    axi_status;          // used to keep track of axi transactions
  reg               mdio_ready;          // captured to acknowledge the end of mdio transactions

  reg      [31:0]   axi_rd_data;
  reg      [31:0]   axi_wr_data;
  reg      [31:0]   mdio_wr_data;

  reg      [4:0]    axi_state;           // main state machine to configure example design
  reg      [4:0]    prev_axi_state;      // previous state
  reg      [1:0]    mdio_access_sm;      // mdio state machine to handle mdio register config
  reg      [1:0]    axi_access_sm;       // axi state machine - handles the 5 channels

  reg               start_access;        // used to kick the axi acees state machine
  reg               start_mdio;          // used to kick the mdio state machine
  reg               drive_mdio;          // selects between mdio fields and direct sm control
  reg      [1:0]    mdio_op;
  reg      [4:0]    mdio_reg_addr;
  reg               writenread;
  reg      [16:0]   addr;


  reg     pcs_loopback_conf_done;
  reg     pcs_default_conf_done;
  reg     pcs_loopback_reg  = 0;

  wire   [1:0]      config_mode;
  

  
//synthesis translate_off

  //sample AXI Lite IF
  //sample OP
  //sample tx data for MDIO

  reg mdio_cfg1;
  reg mdio_txd;
  reg [1:0] mdio_op_check='b0;
  reg [4:0] mdio_dev='b0;
  reg mdio_start=1'b0;
  reg mdio_addr_txn=1'b0;
  reg mdio_read_txn=1'b0;
  reg mdio_write_txn=1'b0;
  reg [31:0] mdio_tx_data = 'h0;
  reg [15:0] mdio_reg_addr_check = 'h0;
  reg mdio_reg_addr_txn = 1'b0;
  reg mdio_reg_32_addr_txn = 1'b0;
  reg check_now=1'b0;

    always@* begin
      if(s_axi_awaddr == 32'h504 && s_axi_awready && s_axi_awvalid) begin
        mdio_cfg1  = 1'b1; 
        mdio_txd   = 1'b0;
      end else if(s_axi_awaddr == 32'h508 && s_axi_awready && s_axi_awvalid) begin
        mdio_cfg1  = 1'b0; 
        mdio_txd   = 1'b1;
      end else if(s_axi_awvalid) begin 
        mdio_cfg1  = 1'b0; 
        mdio_txd   = 1'b0;
      end
      if(mdio_cfg1) begin
        if(s_axi_wready && s_axi_wvalid) begin
          mdio_op_check    = s_axi_wdata[15:14];
          mdio_dev   =  s_axi_wdata[20:16];
          mdio_start =  s_axi_wdata[11];
        end
      end
      if(mdio_op_check == MDIO_OP_ADDR && mdio_dev == 3 && mdio_start) begin //device is PCS
        mdio_start = 1'b0;
        mdio_addr_txn  = 1'b1;
        mdio_read_txn  = 1'b0;
        mdio_write_txn = 1'b0;
      end else if((mdio_op_check == MDIO_OP_RD || mdio_op_check == MDIO_OP_RD_INCR) && mdio_dev == 3 && mdio_start) begin
        mdio_start = 1'b0;
        mdio_read_txn  = 1'b1;
        mdio_addr_txn  = 1'b0;
        mdio_write_txn = 1'b0;
      end else if(mdio_op_check == MDIO_OP_WR && mdio_dev == 3 && mdio_start) begin
        mdio_start = 1'b0;
        mdio_write_txn = 1'b1;
        mdio_read_txn  = 1'b0;
        mdio_addr_txn  = 1'b0;
      end

      if(mdio_txd == 1'b1 && s_axi_wvalid == 1'b1 && s_axi_wready == 1'b1  ) begin
        mdio_tx_data = s_axi_wdata;
      end

      if(mdio_addr_txn) begin
        mdio_reg_addr_check = mdio_tx_data[15:0];
        mdio_reg_addr_txn = 1'b1;
        if(mdio_tx_data[15:0] == 32'h0020)  begin
          mdio_reg_32_addr_txn = 1'b1;
        end else begin
          mdio_reg_32_addr_txn = 1'b0;
        end
      end else begin
        mdio_reg_addr_txn = 1'b0;
      end

      check_now = (axi_state == MDIO_CHECK_DATA && prev_axi_state != MDIO_CHECK_DATA);
      
      if(mdio_read_txn) begin
        if(check_now) begin
          if(!mdio_reg_32_addr_txn) begin
             $display("%d Error: PCS MDIO REG32 Accessed wihtout MDIO Address Operation",$time);
          end else begin
             $display("%d PCS MDIO REG32 Accessed After MDIO Address Operation",$time);
          end
          mdio_reg_32_addr_txn = 1'b0;
          mdio_read_txn = 1'b0;
          check_now = 1'b0;
        end
      end

    end
    
//synthesis translate_on  

  assign config_mode = {enable_vlan, enable_custom_preamble};  // Controlled by DIP switches

  always @(posedge s_axi_aclk)
  begin
     pcs_loopback_reg <= pcs_loopback;
  end

  always @(posedge s_axi_aclk)
  begin
     if (s_axi_reset) begin
        prev_axi_state <= STARTUP;
     end
     else begin
        prev_axi_state <= axi_state;
     end
  end

  //----------------------------------------------------------------------------
  // Management process. This process sets up the configuration by
  // turning off flow control, then checks gathered statistics at the
  // end of transmission
  //----------------------------------------------------------------------------
  always @(posedge s_axi_aclk)
  begin
     if (s_axi_reset) begin
        axi_state      <= STARTUP;
        enable_gen     <= 0;
        start_access   <= 0;
        start_mdio     <= 0;
        drive_mdio     <= 0;
        mdio_op        <= 0;
        mdio_reg_addr  <= 0;
        writenread     <= 0;
        addr           <= 0;
        axi_wr_data    <= 0;
        block_lock     <= 0;
        pcs_loopback_conf_done <= 0;
        pcs_default_conf_done  <= 0;
     end
     // main state machine is kicking off multi cycle accesses in each state so has to
     // stall while they take place
     else if (axi_access_sm == IDLE && (mdio_access_sm == IDLE) && !start_access && !start_mdio ) begin
        case (axi_state)
           STARTUP : begin
              // this state will be ran after reset to wait for count_shift
              // set up MDC frequency. Write 1A to Management configuration
              // register (Add=340). This will enable MDIO and set MDC to 10Mhz
              // (set CLOCK_DIVIDE value to 5 dec. for 125MHz s_axi_aclk
              // resulting in 125/(2x(1+5))=10.4MHz and enable mdio)
              $display("** Note: Setting MDC Frequency to 10.4MHZ....");
              start_access   <= 1;
              writenread     <= 1;
              addr           <= CONFIG_MANAGEMENT_ADDR;
              axi_wr_data    <= 32'h45;
              axi_state      <= RESET_MAC_RX;
           end
           RESET_MAC_RX : begin
              $display("** Note: Reseting MAC RX");
              start_access   <= 1;
              writenread     <= 1;
              addr           <= RECEIVER_ADDR;
            case (config_mode)
               2'b00 : axi_wr_data <= 32'h90000000;
               2'b01 : axi_wr_data <= 32'h94000000;
               2'b10 : axi_wr_data <= 32'h98000000;
               2'b11 : axi_wr_data <= 32'h9C000000;
            endcase
              axi_state      <= RESET_MAC_TX;
           end
           // this state will drive the reset to the example design (apart from this block)
           // this will be separately captured and synched into the various clock domains
           RESET_MAC_TX : begin
              $display("** Note: Reseting MAC TX");
              start_access   <= 1;
              writenread     <= 1;
              addr           <= TRANSMITTER_ADDR;
            case (config_mode)
               2'b00 : axi_wr_data <= 32'h90000000;
               2'b01 : axi_wr_data <= 32'h90800000;
               2'b10 : axi_wr_data <= 32'h98000000;
               2'b11 : axi_wr_data <= 32'h98800000;
            endcase
              axi_state      <= MDIO_ADDR_1;
           end
          MDIO_ADDR_1 : begin
              // read phy status - if response is all ones then do not perform any
              // further MDIO accesses
              start_mdio     <= 1;
              drive_mdio     <= 1;   // switch axi transactions to use mdio values..
              writenread     <= 1;
              addr           <= MDIO_CONTROL;
              mdio_reg_addr  <= DEV_ADDR;  //devad 1 in MDIO Register 1.8: 10G PMA/PMD Status 2
              // if(mdio_ready && !start_mdio) begin
              if(mdio_ready) begin
                 $display("** Note: Specified PCS control register address for 10GBASE-R");
                 mdio_op        <= MDIO_OP_WR;
                 if (pcs_loopback_reg) begin
                    $display("** Note: Issuing PCS reset");
                    axi_wr_data    <= 32'h8000;   //BASE-R CONTROL 1 write value to enable PCS (XGMII) loopback
                    axi_state      <= MDIO_READ_PCS_RESET;
                 end
                 else begin
                    $display("** Note: Set BASE-R control into PCS default");
                    axi_wr_data    <= 32'h2000;   //BASE-R CONTROL 1 write value for default no PCS (XGMII) loopback
                    axi_state      <= MDIO_WR;
                 end
              end
           end
          MDIO_READ_PCS_RESET : begin
              // read phy status - if response is all ones then do not perform any
              // further MDIO accesses
              start_mdio     <= 1;
              drive_mdio     <= 1;   // switch axi transactions to use mdio values..
              mdio_reg_addr  <= DEV_ADDR;  //devad 1 in MDIO Register 1.8: 10G PMA/PMD Status 2
              // if(mdio_ready && !start_mdio) begin
              if(mdio_ready) begin

                 mdio_op        <= MDIO_OP_RD;
                 axi_state      <= MDIO_READ_PCS_RESET_POLL;
              end
           end
          MDIO_READ_PCS_RESET_POLL : begin
              start_mdio     <= 1;
              drive_mdio     <= 1;
              writenread     <= 0;
              mdio_op     <= MDIO_OP_RD;
              mdio_reg_addr  <= DEV_ADDR;
              if (mdio_ready) begin

                    axi_state      <= MDIO_READ_PCS_RESET_READ;
              end
           end
          MDIO_READ_PCS_RESET_READ : begin
              start_mdio     <= 1;
              drive_mdio     <= 1;
              mdio_op     <= MDIO_OP_RD;
              mdio_reg_addr  <= DEV_ADDR;
              if (mdio_ready) begin

                    addr        <= MDIO_RX_DATA;
                    axi_state   <= MDIO_RESET_CHECK;
              end
           end
         MDIO_RESET_CHECK : begin
            // Read the MDIO Status register until no faults are
            // reported then start MAC configuration
            start_mdio     <= 1;
            drive_mdio     <= 1;
            if (mdio_ready) begin

                  $display("** Note: PCS RESET POLL");
               if (axi_rd_data[15:0] == 16'h2040) begin
                  $display("** Note: PCS RESET is cleared");
                  axi_state      <= MDIO_ADDR_2;
               end
            end
         end
         MDIO_ADDR_2 : begin
              // read phy status - if response is all ones then do not perform any
              // further MDIO accesses
              start_mdio     <= 1;
              drive_mdio     <= 1;   // switch axi transactions to use mdio values..
              writenread     <= 1;
              addr           <= MDIO_CONTROL;
              mdio_reg_addr  <= DEV_ADDR;  //devad 1 in MDIO Register 1.8: 10G PMA/PMD Status 2
              if(mdio_ready && !start_mdio) begin
                 $display("** Note: Specified PCS control register address for 10GBASE-R");
                 mdio_op        <= MDIO_OP_WR;
                 axi_state      <= MDIO_WR;
                 if (pcs_loopback_reg) begin
                    $display("** Note: Set BASE-R control into PCS loopback ");
                    axi_wr_data       <= 32'h4000;   //BASE-R CONTROL 1 write value to enable PCS (XGMII) loopback
                 end
                 else begin
                    axi_wr_data       <= 32'h2000;   //BASE-R CONTROL 1 write value for default no PCS (XGMII) loopback
                 end
              end
           end
         MDIO_WR : begin
            // read phy status - if response is all ones then do not perform any
            // further MDIO accesses
            start_mdio     <= 1;
            drive_mdio     <= 1;   // switch axi transactions to use mdio values..
            writenread     <= 1;
            mdio_op        <= MDIO_OP_WR;
            mdio_reg_addr  <= DEV_ADDR;
             if(mdio_ready && !start_mdio) begin
                if (pcs_loopback_reg) begin
                   pcs_loopback_conf_done <= 1;
                end
                else begin
                   pcs_default_conf_done <= 1;
                end
                axi_state  <= MDIO_RD_1;
             end
         end
         MDIO_RD_1 : begin
            start_mdio     <= 1;
            drive_mdio     <= 1;   // switch axi transactions to use mdio values..
            writenread     <= 1;
            mdio_op        <= MDIO_OP_RD;
            mdio_reg_addr  <= DEV_ADDR;
            block_lock     <= 0;
            mdio_op        <= MDIO_OP_RD;
            if(pcs_loopback_conf_done && pcs_loopback_reg) begin
               enable_gen <= 1;
            end
            else begin
               pcs_loopback_conf_done <= 0;
               if(mdio_ready && !start_mdio) begin
                  $display("** Note: Read PCS control");
                  if (pcs_default_conf_done) begin
                     axi_state   <= MDIO_ADDR;
                     axi_wr_data <= 32'h20;       //BASE-R Status 1
                  end
                  else begin
                     axi_state   <= MDIO_ADDR_1;
                     axi_wr_data <= 32'h00;  //BASE-R PCS control register address
                  end
               end
            end
         end
         MDIO_ADDR : begin
              // read phy status - if response is all ones then do not perform any
              // further MDIO accesses
              start_mdio     <= 1;
              drive_mdio     <= 1;   // switch axi transactions to use mdio values..
              writenread     <= 0;
              mdio_op        <= MDIO_OP_ADDR;
              addr           <= MDIO_CONTROL;
              mdio_reg_addr  <= DEV_ADDR;
              axi_wr_data    <= 32'h20;    // 3.32 BASE-R Status 1 register address
              if(mdio_ready) begin
                 $display("** Note: Specified status register 1 address for 10GBASE-R");
                 axi_state   <= MDIO_RD;
              end
           end
         MDIO_RD : begin
            // read phy status - if response is all ones then do not perform any
            // further MDIO accesses
            start_mdio     <= 1;
            drive_mdio     <= 1;   // switch axi transactions to use mdio values..
            writenread     <= 0;
            mdio_op        <= MDIO_OP_RD;
            mdio_reg_addr  <= DEV_ADDR;  //devad
            if(mdio_ready) begin
               $display("** Note: Reading status register ");
               axi_state   <= MDIO_POLL_CHECK;
               addr        <= MDIO_RX_DATA;
            end
         end
         MDIO_POLL_CHECK : begin
            // Read the 10GBASE-R Status 1 register until no faults are
            // reported then start MAC configuration
            start_mdio     <= 1;
            drive_mdio     <= 1;
            if (mdio_ready) begin
               $display("** Note: MDIO_POLL_CHECK");
               axi_state      <= MDIO_CHECK_DATA;
            end
         end
         MDIO_CHECK_DATA : begin
            start_mdio     <= 1;
            drive_mdio     <= 1;
            // Read the 10GBASE-R Status 1 register until no faults are
            // reported 17'h01005 means BASE-R Link aligned and BlockLock
            if (mdio_ready) begin
               if (axi_rd_data[16:0] == 17'h11005) begin
                  start_access   <= 0;
                  start_mdio     <= 0;
                  drive_mdio     <= 0;
                  mdio_op        <= 0;
                  mdio_reg_addr  <= 0;
                  writenread     <= 0;
                  addr           <= 0;
                  axi_state      <= CONFIG_DONE;
                  $display("** Note: CONFIG_DONE, BASE-R is in lock");
                  drive_mdio     <= 0;
                  block_lock     <= 1;
                end
                else if (axi_rd_data[16:0] != 17'h11005) begin
                   axi_state      <= MDIO_ADDR;
                end
             end
          end
          // this state drives the enable_gen to the example design
          // this is separately captured and synched into the various clock domains
          CONFIG_DONE : begin
              if (pcs_loopback_reg) begin
                 start_access          <= 1;
                 axi_state             <= RESET_MAC_TX;
                 pcs_default_conf_done <= 0;
              end
              else begin
                 enable_gen <= 1;
              end
           end
           default : begin
              axi_state <= STARTUP;
           end
        endcase
     end
     else begin
        start_access <= 0;
        start_mdio   <= 0;
     end
  end

  //-------------------------------------------------------------------
  // MDIO setup - split from main state machine to make more manageable
  //-------------------------------------------------------------------

  always @(posedge s_axi_aclk)
  begin
     if (s_axi_reset) begin
        mdio_access_sm <= IDLE;
     end
     else if (axi_access_sm == IDLE || axi_access_sm == DONE) begin
        case (mdio_access_sm)
           IDLE : begin
              if (start_mdio) begin
                 if (mdio_op == MDIO_OP_ADDR || mdio_op == MDIO_OP_WR ||
                     mdio_op == MDIO_OP_RD) begin
                    mdio_access_sm <= SET_DATA;
                    mdio_wr_data   <= axi_wr_data;
                 end
                 else begin
                    mdio_access_sm <= INIT;
                    // compose write data
                    mdio_wr_data   <= {3'h0,PRT_ADDR, 3'b000,mdio_reg_addr, mdio_op, 3'b001, 11'h0};

                 end
              end
           end
           SET_DATA : begin
              mdio_access_sm <= INIT;
              mdio_wr_data   <= {PRT_ADDR, 3'b000, mdio_reg_addr, mdio_op, 3'h1, 11'h0};

           end
           INIT : begin
              mdio_access_sm <= POLL;
           end
           POLL : begin
              if (mdio_ready)
                 mdio_access_sm <= IDLE;
           end
        endcase
     end
     else if (mdio_access_sm == POLL && mdio_ready) begin
        mdio_access_sm <= IDLE;
     end
  end


  //-------------------------------------------------------------------------------------------
  // Processes to generate the axi transactions - only simple reads and write can be generated
  //-------------------------------------------------------------------------------------------

  always @(posedge s_axi_aclk)
  begin
     if (s_axi_reset) begin
        axi_access_sm <= IDLE;
     end
     else begin
        case (axi_access_sm)
           IDLE : begin
              if (start_access || start_mdio || mdio_access_sm != IDLE) begin
                 if (mdio_access_sm == POLL) begin
                    axi_access_sm <= READ;
                 end
                 else if ((start_access && writenread) ||
                          (mdio_access_sm == SET_DATA || mdio_access_sm == INIT) || start_mdio) begin
                    axi_access_sm <= WRITE;
                 end
                 else begin
                    axi_access_sm <= READ;
                 end
              end
           end
           WRITE : begin
              // wait in this state until axi_status signals the write is complete
              if (axi_status[4:2] == 3'b111)
                 axi_access_sm <= DONE;
           end
           READ : begin
              // wait in this state until axi_status signals the read is complete
              if (axi_status[1:0] == 2'b11)
                 axi_access_sm <= DONE;
           end
           DONE : begin
              axi_access_sm <= IDLE;
           end
        endcase
     end
  end

  // need a process per axi interface (i.e 5)
  // in each case the interface is driven accordingly and once acknowledged a sticky
  // status bit is set and the process waits until the access_sm moves on
  // READ ADDR
  always @(posedge s_axi_aclk)
  begin
     if (axi_access_sm == READ) begin
        if (!axi_status[0]) begin
           s_axi_araddr   <= addr;
           s_axi_arvalid  <= 1'b1;
           if (s_axi_arready == 1'b1 && s_axi_arvalid) begin
              axi_status[0] <= 1;
              s_axi_araddr      <= 0;
              s_axi_arvalid     <= 0;
           end
        end
     end
     else begin
        axi_status[0]     <= 0;
        s_axi_araddr      <= 0;
        s_axi_arvalid     <= 0;
     end
  end

  // READ DATA/RESP
  always @(posedge s_axi_aclk)
  begin
     if (axi_access_sm == READ) begin
        if (!axi_status[1]) begin
           s_axi_rready  <= 1'b1;
           if (s_axi_rvalid == 1'b1 && s_axi_rready) begin
              axi_status[1] <= 1;
              s_axi_rready  <= 0;
              axi_rd_data   <= s_axi_rdata;
              if (addr == MDIO_RX_DATA) begin
                 if (drive_mdio & s_axi_rdata[16])
                    mdio_ready <= 1;
              end
              else begin
                 if (drive_mdio & s_axi_rdata[7])
                    mdio_ready <= 1;
              end
           end
        end
     end
     else begin
        s_axi_rready      <= 0;
        axi_status[1]     <= 0;
        if (axi_access_sm == IDLE & (start_access || start_mdio)) begin
           mdio_ready     <= 0;
           axi_rd_data    <= 0;
        end
     end
  end

  // WRITE ADDR
  always @(posedge s_axi_aclk)
  begin
     if (axi_access_sm == WRITE) begin
        if (!axi_status[2]) begin
           if (drive_mdio) begin
              if (mdio_access_sm == SET_DATA)
                 s_axi_awaddr <= MDIO_TX_DATA;
              else
                 s_axi_awaddr <= MDIO_CONTROL;
           end
           else begin
              s_axi_awaddr   <= addr;
           end
           s_axi_awvalid  <= 1'b1;
           if (s_axi_awready == 1'b1 && s_axi_awvalid) begin
              axi_status[2] <= 1;
              s_axi_awaddr  <= 0;
              s_axi_awvalid <= 0;
           end
        end
     end
     else begin
        s_axi_awaddr      <= 0;
        s_axi_awvalid     <= 0;
        axi_status[2]     <= 0;
     end
  end

  // WRITE DATA
  always @(posedge s_axi_aclk)
  begin
     if (axi_access_sm == WRITE) begin
        if (!axi_status[3]) begin
           if (drive_mdio) begin
              s_axi_wdata   <= mdio_wr_data;
           end
           else begin
              s_axi_wdata   <= axi_wr_data;
           end
           s_axi_wvalid  <= 1'b1;
           if (s_axi_wready == 1'b1 && s_axi_wvalid) begin
              axi_status[3] <= 1;
              s_axi_wdata      <= 0;
              s_axi_wvalid     <= 0;
           end
        end
     end
     else begin
        s_axi_wdata      <= 0;
        s_axi_wvalid     <= 0;
        axi_status[3]     <= 0;
     end
  end

  // WRITE RESP
  always @(posedge s_axi_aclk)
  begin
     if (axi_access_sm == WRITE) begin
        if (!axi_status[4]) begin
           s_axi_bready  <= 1'b1;
           if (s_axi_bvalid == 1'b1 && s_axi_bready) begin
              axi_status[4] <= 1;
              s_axi_bready     <= 0;
           end
        end
     end
     else begin
        s_axi_bready     <= 0;
        axi_status[4]    <= 0;
     end
  end

endmodule

`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000


module panda_pgen_tb;

parameter STATE_IDLE = 0;
parameter STATE_TABLE_ADDR = 1;
parameter STATE_FINISHED = 2;

reg [1:0]   STATE;

// Inputs
reg         clk_i = 0;

reg         SIM_RESET;
reg         ENABLE;
reg         TRIG;
reg  [31:0] OUT;
wire [31:0] health_o;
reg  [31:0] HEALTH; 

reg  [31:0] CYCLES;
reg         CYCLES_WSTB;
reg  [31:0] TABLE_ADDRESS;
reg         TABLE_ADDRESS_WSTB;
reg  [31:0] TABLE_LENGTH;
reg         TABLE_LENGTH_WSTB;

integer     timestamp = 0;

// Outputs
reg         test_result;
wire [31:0] out_o;    

wire        dma_req_o;
reg         dma_ack_i; 
reg         dma_done_i;
wire [31:0] dma_addr_o;
wire [7:0]  dma_len_o;
reg  [31:0] dma_data_i = 0;
reg         dma_valid_i = 0;

 
integer fid[3:0];
integer r[3:0];

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//

initial begin
    repeat (5) @(posedge clk_i);
    while (1) begin
        timestamp <= timestamp + 1;
        @(posedge clk_i);
    end
end


// Clock and Reset
always #4 clk_i = !clk_i;


// pgen_bus_in.txt
// TS ####### SIM_RESET ###### ENABLE ###### TRIG

//
// READ BLOCK INPUTS VECTOR FILE
//
integer bus_in[3:0];     // TS SET RST

initial begin
    SIM_RESET = 0;
    ENABLE = 0;
    TRIG = 0;

    @(posedge clk_i);
    fid[0] = $fopen("pgen_bus_in.txt", "r");

    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s\n", bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d\n", bus_in[3],  bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[3]) begin
            SIM_RESET <= bus_in[2];
            ENABLE <= bus_in[1];
            TRIG <= bus_in[0];
        end
        @(posedge clk_i);
    end
end


// pgen_bus_out.txt
// TS ###### ACTIVE ###### OUT

//
// READ BLOCK EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BLOCK
// OUTPUTS
//
integer bus_out[1:0];
reg     is_file_end;

initial begin
    OUT = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("pgen_bus_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s \n", bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d \n", bus_out[1], bus_out[0]);
        
        wait (timestamp == bus_out[1]) begin
            OUT <= bus_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end


// pgen_reg_out.txt
// TS ###### HEALTH ###### PRODUCED ###### STATE  

integer reg_out[1:0];
reg     is_2file_end;

initial begin
    HEALTH = 0;
    is_2file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[3] = $fopen("pgen_reg_out.txt", "r"); // TS, VAL

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s \n", reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d \n", reg_out[1], reg_out[0]);
        
        wait (timestamp == reg_out[1]) begin
            HEALTH <= reg_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_2file_end = 1;
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) // 
    if (is_file_end & is_2file_end) begin
        $stop(2);
    end    


//pgen_reg_in.txt
// TS ###### PRE_START ###### CYCLE ###### TABLE_ADDRESS ###### TABLE_LENGTH 
integer reg_in[6:0];


initial begin
    CYCLES = 0;
    CYCLES_WSTB = 0;
    TABLE_ADDRESS_WSTB = 0;
    TABLE_LENGTH = 0;
    TABLE_LENGTH_WSTB = 0;

    @(posedge clk_i);

    // Open "reg_in" file
    fid[1] = $fopen("pgen_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s\n", reg_in[6], reg_in[5], 
            reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %s %d %d %d\n", reg_in[6], reg_in[5], 
//        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d\n", reg_in[6], reg_in[5], 
            reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);
            
        wait (timestamp == reg_in[6]) begin
            CYCLES <= reg_in[5];
            CYCLES_WSTB <= reg_in[4];
            TABLE_ADDRESS_WSTB <= reg_in[2];
            TABLE_LENGTH <= reg_in[1];
            TABLE_LENGTH_WSTB <= reg_in[0];
        end
        @(posedge clk_i);
    end
end



integer     pfid;
integer     pr;
integer     preg_in;

reg [5:0]   cnt;
reg [31:0]  data_mem [31:0];

initial begin
    cnt = 0;
    
    @(posedge clk_i);
    
    // Open "PGEN_1000" file
    pfid = $fopen("PGEN_1000.txt", "r");
    // Read and ignore description field
    pr = $fscanf(pfid, "%s\n", preg_in);
    
    while (!$feof(pfid)) begin
        pr = $fscanf(pfid, "%d\n", preg_in); 
        data_mem[cnt] <= preg_in;
        cnt <= cnt +1;
    
        @(posedge clk_i);
        
    end
end        



reg [5:0]   mem_loop = 0;
reg [5:0]   mem_cnt = 0;

always @(posedge clk_i or posedge SIM_RESET) begin

    if (SIM_RESET == 1) begin
        STATE = STATE_IDLE;
        dma_valid_i = 0;
        mem_loop = 0;
        mem_cnt = 0;
        dma_ack_i = 0;
        dma_done_i = 0;
    end else begin
        case (STATE)
        
            STATE_IDLE:
            begin
                // Wait until the TABLE_ADDRESS_WSTB is active 
                if (TABLE_ADDRESS_WSTB == 1) begin
                    STATE <= STATE_TABLE_ADDR;
                end
            end        
        
            STATE_TABLE_ADDR:
            begin
                dma_ack_i <= 1;
                dma_done_i <= 1;
                TABLE_ADDRESS <= 32'h00000000;
                dma_valid_i <= 1;
                // This is the last read out of the memory increment the loop counter 
                if (mem_cnt == cnt-1) begin
                    mem_loop <= mem_loop +1;
                    mem_cnt <= 0;
                    dma_data_i <= data_mem[mem_cnt];
                    // The mem_loop equals the number of CYCLES to be done
                    if (mem_loop == CYCLES-1) begin
                        STATE <= STATE_FINISHED;
                    end    
                // Read the values out of the memory    
                end else begin
                    mem_cnt <= mem_cnt +1;
                    dma_data_i <= data_mem[mem_cnt];
                end    
            end        
            
            STATE_FINISHED:
            begin
                // Finished reset everything
                dma_ack_i = 0;
                dma_done_i = 0;
                dma_valid_i <= 0;
                mem_loop <= 0;
                mem_cnt  <= 0;
                STATE <= STATE_IDLE;
            end      
    
            default:
                STATE <= STATE_IDLE;
    
        endcase
    end         
end     


//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
reg       err_health;
reg       err_out; 

always @(posedge clk_i)
begin
    if (~is_file_end) begin
        if (err_out == 1 | err_health == 1) begin
            test_result <= 1;    
        end     
        if (out_o !== OUT) begin
            $display("Output error detected at timestamp %d\n", timestamp, out_o, OUT);            
            err_out <= 1;
        end else begin
            err_out <= 0;    
        end                
        if (health_o !== HEALTH) begin
            $display("Health error detected at timestamp %d\n", timestamp, health_o, HEALTH);
            err_health <= 1;
        end else begin
            err_health <= 0;
        end         
    end 
end

         


// Instantiate the Unit Under Test (UUT)
pgen uut_pgen (
    .clk_i              ( clk_i             ),
    .enable_i           ( ENABLE            ),
    .trig_i             ( TRIG              ),    
    .out_o              ( out_o             ),
    
    .CYCLES             ( CYCLES            ),
    .TABLE_ADDR         ( TABLE_ADDRESS     ),    
    .TABLE_LENGTH       ( TABLE_LENGTH      ),    
    .TABLE_LENGTH_WSTB  ( TABLE_LENGTH_WSTB ),
    .health_o           ( health_o          ),    
    
    .dma_req_o          ( dma_req_o         ),
    .dma_ack_i          ( dma_ack_i         ),
    .dma_done_i         ( dma_done_i        ),
    .dma_addr_o         ( dma_addr_o        ),
    .dma_len_o          ( dma_len_o         ),  
    .dma_data_i         ( dma_data_i        ),
    .dma_valid_i        ( dma_valid_i       )
);
    

endmodule


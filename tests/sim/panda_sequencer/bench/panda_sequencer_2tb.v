`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000

module panda_sequencer_2tb;

// Inputs
reg clk_i = 0;

reg reset_i;
reg enable_i;
reg inpa_i;
reg inpb_i;
reg inpc_i;
reg inpd_i;

reg [31:0] PRESCALE;
reg PRESCALE_WSTB;
reg TABLE_START;
reg TABLE_START_WSTB;
reg [31:0] TABLE_DATA;
reg TABLE_DATA_WSTB;
reg [31:0] TABLE_CYCLE;
reg TABLE_CYCLE_WSTB;
reg [15:0] TABLE_LENGTH;
reg TABLE_LENGTH_WSTB;

// Outputs
wire outa_o;
reg OUTA;
reg err_outa;
wire outb_o;
reg OUTB;
reg err_outb;
wire outc_o;
reg OUTC;
reg err_outc;
wire outd_o;
reg OUTD;
reg err_outd;
wire oute_o;
reg OUTE;
reg err_oute;
wire outf_o;
reg OUTF;
reg err_outf;
wire active_o;
reg ACTIVE;

wire [31:0] CUR_FRAME;
reg [31: 0] TB_CUR_FRAME;
reg err_cur_frame;
wire [31:0] CUR_FCYCLE;
reg [31: 0] TB_CUR_FCYCLE;
reg err_cur_fcycle;
wire [31:0] CUR_TCYCLE;
reg [31: 0] TB_CUR_TCYCLE;
reg err_cur_tcycle;

reg test_result = 0;


// Testbench specific
integer timestamp = 0;


integer fid[3:0];

integer r[3:0];


// Clock and Reset
always #4 clk_i = !clk_i;

initial begin
    reset_i = 1;
    repeat(10) @(posedge clk_i);
    reset_i = 0;
end

//
// Values in the test files are arranged on FPGA clock ticks on the
// first column. This way all files are read syncronously.
//
// To achieve that a free running global Timestamp Counter below
// is used.
//
initial begin
    repeat(5) @(posedge clk_i);
    while (1) begin
        @(posedge clk_i);
        timestamp <= timestamp + 1;
    end
end


// Instantiate the Unit Under Test (UUT)
sequencer uut (
    .clk_i              ( clk_i                 ),
    .reset_i            ( reset_i               ),
    .enable_i           ( enable_i              ),
    .inpa_i             ( inpa_i                ),
    .inpb_i             ( inpb_i                ),
    .inpc_i             ( inpc_i                ),
    .inpd_i             ( inpd_i                ),
    .outa_o             ( outa_o                ),
    .outb_o             ( outb_o                ),
    .outc_o             ( outc_o                ),
    .outd_o             ( outd_o                ),
    .oute_o             ( oute_o                ),
    .outf_o             ( outf_o                ),
    .active_o           ( active_o              ),
    .PRESCALE           ( PRESCALE              ),
    .TABLE_START        ( TABLE_START           ),
    .TABLE_DATA         ( TABLE_DATA            ),
    .TABLE_WSTB         ( TABLE_DATA_WSTB       ),
    .TABLE_CYCLE        ( TABLE_CYCLE           ),
    .TABLE_LENGTH       ( TABLE_LENGTH          ),
    .TABLE_LENGTH_WSTB  ( TABLE_LENGTH_WSTB     ),
    .CUR_FRAME          ( CUR_FRAME             ),
    .CUR_FCYCLE         ( CUR_FCYCLE            ),
    .CUR_TCYCLE         ( CUR_TCYCLE            )
);


//
// READ BUS INPUTS VECTOR FILE
//
// TS»¯¯¯¯¯reset_i»¯¯¯¯¯¯enable_i»¯¯¯¯inpa_i»¯¯¯¯inpb_i»¯¯¯¯inpc_i»¯¯¯¯inpd_i
integer bus_in[6:0];

initial begin
    reset_i = 0;
    enable_i = 0;
    inpa_i = 0;
    inpb_i = 0;
    inpc_i = 0;
    inpd_i = 0;

    @(posedge clk_i);
    fid[0] = $fopen("seq_bus_in.txt", "r");
    
    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s %s %s\n", bus_in[6], bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d %d %d %d\n", bus_in[6], bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[6]) begin
            reset_i <= bus_in[5];
            enable_i <= bus_in[4];
            inpa_i <= bus_in[3];
            inpb_i <= bus_in[2];
            inpc_i <= bus_in[1];
            inpd_i <= bus_in[0];
        end
        @(posedge clk_i);
    end
end


//
// READ REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯PRESCALE»¯¯¯¯PRESCALE_WSTB»¯¯¯¯TABLE_CYCLE»¯¯¯¯TABLE_CYCLE_WSTB»¯¯¯¯TABLE_START»¯¯¯¯TABLE_START_WSTB»¯¯¯¯TABLE_DATA»¯¯¯¯TABLE_DATA_WSTB»¯¯¯¯TABLE_LENGTH»¯¯¯¯TABLE_LENGTH_WSTB
integer reg_in[10:0];

initial begin
    PRESCALE  = 0;
    PRESCALE_WSTB = 0;
    TABLE_CYCLE = 0;
    TABLE_CYCLE_WSTB = 0;
    TABLE_START = 0;
    TABLE_START_WSTB = 0;
    TABLE_DATA = 0;
    TABLE_DATA_WSTB = 0;
    TABLE_LENGTH = 0;
    TABLE_LENGTH_WSTB = 0;

    @(posedge clk_i);

    // Open "reg_in" file
     fid[1] = $fopen("seq_reg_in.txt", "r");

    // Read and ignore description field
    r[1] = $fscanf(fid[1], "%s %s %s %s %s %s %s %s %s %s %s\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], 
                                                                  reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]);

    while (!$feof(fid[1])) begin
        r[1] = $fscanf(fid[1], "%d %d %d %d %d %d %d %d %d %d %d\n", reg_in[10], reg_in[9], reg_in[8], reg_in[7], reg_in[6], 
                                                                 reg_in[5], reg_in[4], reg_in[3], reg_in[2], reg_in[1], reg_in[0]); 
        wait (timestamp == reg_in[10])begin              
            PRESCALE = reg_in[9];        
            PRESCALE_WSTB = reg_in[8];
            TABLE_CYCLE = reg_in[7];
            TABLE_CYCLE_WSTB = reg_in[6];
            TABLE_START = reg_in[5];
            TABLE_START_WSTB = reg_in[4];
            TABLE_DATA = reg_in[3];
            TABLE_DATA_WSTB = reg_in[2];
            TABLE_LENGTH = reg_in[1];
            TABLE_LENGTH_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end


//
// READ BUS EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BUS
// OUTPUTS
//
// TS»¯¯¯¯¯OUTA»¯¯¯¯¯OUTB»¯¯¯¯¯OUTC»¯¯¯¯¯OUTD»¯¯¯¯¯OUTE»¯¯¯¯¯OUTF»¯¯¯¯¯ACTIVE
integer bus_out[7:0];
reg     is_file_end;

initial begin
    OUTA = 0;
    OUTB = 0;
    OUTC = 0;
    OUTD = 0;
    OUTE = 0;
    OUTF = 0;
    ACTIVE = 0;
    is_file_end = 0;

    @(posedge clk_i);

    // Open "bus_out" file
    fid[2] = $fopen("seq_bus_out.txt", "r"); 

    // Read and ignore description field
    r[2] = $fscanf(fid[2], "%s %s %s %s %s %s %s %s\n", bus_out[7], bus_out[6], bus_out[5], bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);

    while (!$feof(fid[2])) begin
        r[2] = $fscanf(fid[2], "%d %d %d %d %d %d %d %d\n", bus_out[7], bus_out[6], bus_out[5], bus_out[4], bus_out[3], bus_out[2], bus_out[1], bus_out[0]);
        wait (timestamp == bus_out[7]) begin
            OUTA = bus_out[6];
            OUTB = bus_out[5];
            OUTC = bus_out[4];
            OUTD = bus_out[3];
            OUTE = bus_out[2];
            OUTF = bus_out[1];
            ACTIVE = bus_out[0];
        end
        @(posedge clk_i);
    end

    repeat(100) @(posedge clk_i);

    is_file_end = 1;
end


// $stop Halts a simulation and enters an interactive debug mode
// $finish Finishes a simulation and exits the simulation process
always @ (posedge clk_i) //----------------------------------------- HERE 
    if (is_file_end) begin
        $stop(2);
    end  


//
// READ REG EXPECTED ERROR OUTPUTS FILE TO COMPARE AGAINTS ERROR
// OUTPUTS
//
// TS»¯¯¯¯¯TB_CUR_FRAME»¯¯¯¯¯TB_CUR_FCYCLE»¯¯¯¯¯TB_CUR_TCYCLE
integer reg_out[3:0];

initial begin
    TB_CUR_FRAME = 0;
    TB_CUR_FCYCLE = 0;
    TB_CUR_TCYCLE = 0;

    @(posedge clk_i);

    // Open "reg_out" file
    fid[3] = $fopen("seq_reg_out.txt", "r"); 

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s %s\n", reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d %d %d\n", reg_out[3], reg_out[2], reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[3]) begin
            TB_CUR_FRAME = reg_out[2];
            TB_CUR_FCYCLE = reg_out[1];
            TB_CUR_TCYCLE = reg_out[0];
        end
        @(posedge clk_i);
    end
end


//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin 

    if (~is_file_end) begin
        if (err_outa == 1 | err_outb == 1  | err_outc == 1 | err_outd == 1  | err_oute == 1  
          | err_outf == 1  | err_cur_frame == 1 | err_cur_fcycle == 1 | err_cur_tcycle == 1) begin
            test_result = 1;
        end 
          
        if (OUTA != outa_o) begin
            $display("OUTA error detected at timestamp %d\n", timestamp);  
            err_outa = 1;
        end 
        else begin
            err_outa = 0;    
        end
        if (OUTB != outb_o) begin
            $display("OUTB error detected at timestamp %d\n", timestamp);  
            err_outb = 1; 
        end
        else begin
            err_outb = 0;
        end    
        if (OUTC != outc_o) begin
            $display("OUTC error detected at timestamp %d\n", timestamp);  
            err_outc = 1;
        end
        else begin
            err_outc = 0;
        end 
        if (OUTD != outd_o) begin
            $display("OUTD error detected at timestamp %d\n", timestamp);  
            err_outd = 1;
        end
        else begin
            err_outd = 0;
        end 
        if (OUTE != oute_o) begin
            $display("OUTE error detected at timestamp %d\n", timestamp);  
            err_oute = 1;
        end
        else begin
            err_oute = 0;
        end 
        if (OUTF != outf_o) begin
            $display("OUTF error detected at timestamp %d\n", timestamp);  
            err_outf = 1; 
        end
        else begin
            err_outf = 0;
        end 
        if (CUR_FRAME != TB_CUR_FRAME) begin
            $display("CUR_FRAME error detected at timestamp %d\n", timestamp);  
            err_cur_frame = 1;
        end
        else begin
            err_cur_frame = 0;
        end 
        if (CUR_FCYCLE != TB_CUR_FCYCLE) begin
            $display("CUR_FCYCLE error detected at timestamp %d\n", timestamp); 
            err_cur_fcycle = 1; 
        end
        else begin
            err_cur_fcycle = 0;
        end 
        if (CUR_TCYCLE != TB_CUR_TCYCLE) begin
            $display("CUR_TCYCLE error detected at timestamp %d\n", timestamp);
            err_cur_tcycle = 1;  
        end
        else begin
           err_cur_tcycle = 0;
        end    
    end
end


endmodule


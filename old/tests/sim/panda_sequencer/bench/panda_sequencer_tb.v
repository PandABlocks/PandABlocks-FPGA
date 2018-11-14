`timescale 1ns / 1ps
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000

module panda_sequencer_tb;

// Inputs
reg clk_i = 0;

reg reset_i;
reg enable_i;
reg bita_i;
reg bitb_i;
reg bitc_i;
reg [31:0] posa_i;
reg [31:0] posb_i;
reg [31:0] posc_i;

reg [31:0] PRESCALE;
reg PRESCALE_WSTB;
reg TABLE_START;
reg TABLE_START_WSTB;
reg [31:0] TABLE_DATA;
reg TABLE_DATA_WSTB;
reg [31:0] REPEATS;
reg REPEATS_WSTB;
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
reg err_active=0;

wire [31:0] table_line_o;
reg [31: 0] TABLE_LINE;
reg         err_table_line;
wire [31:0] line_repeat_o;
reg [31: 0] LINE_REPEAT;
reg         err_line_repeat;
wire [31:0] table_repeat_o;
reg [31: 0] TABLE_REPEAT;
reg         err_table_repeat;
reg  [2: 0] STATE;
wire [2: 0] state_o;
reg         err_state=0;
reg         test_result;
reg [31: 0] count_tests=0;
reg         enable_dly;


// Testbench specific
integer timestamp = 0;


integer fid[3:0];

integer r[3:0];


// Clock and Reset
always #4 clk_i = !clk_i;


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
    .bita_i             ( bita_i                ),
    .bitb_i             ( bitb_i                ),
    .bitc_i             ( bitc_i                ),
    .posa_i             ( posa_i                ),
    .posb_i             ( posb_i                ),
    .posc_i             ( posc_i                ),     
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
    .REPEATS            ( REPEATS               ),
    .TABLE_LENGTH       ( TABLE_LENGTH          ),
    .TABLE_LENGTH_WSTB  ( TABLE_LENGTH_WSTB     ),
    .table_line_o       ( table_line_o          ),
    .line_repeat_o      ( line_repeat_o         ),
    .table_repeat_o     ( table_repeat_o        ),
    .state_o            ( state_o               )
);


//
// READ BUS INPUTS VECTOR FILE
//
// TS»¯¯¯¯¯reset_i»¯¯¯¯¯¯enable_i»¯¯¯¯bita_i»¯¯¯¯bitb_i»¯¯¯¯bitc_i»¯¯¯¯posa_i»¯¯¯¯posb_i»¯¯¯¯posc_i
integer bus_in[8:0];

initial begin
    reset_i = 0;
    enable_i = 0;
    bita_i = 0;
    bitb_i = 0;
    bitc_i = 0;
    posa_i = 0;
    posb_i = 0;
    posc_i = 0;
    
    @(posedge clk_i);
    fid[0] = $fopen("seq_bus_in.txt", "r");
    
    // Read and ignore description field
    r[0] = $fscanf(fid[0], "%s %s %s %s %s %s %s %s %s\n", bus_in[8], bus_in[7], bus_in[6], 
                          bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

    while (!$feof(fid[0])) begin

        r[0] = $fscanf(fid[0], "%d %d %d %d %d %d %d %d %d\n", bus_in[8], bus_in[7], bus_in[6], 
                              bus_in[5], bus_in[4], bus_in[3], bus_in[2], bus_in[1], bus_in[0]);

        wait (timestamp == bus_in[8]) begin
            reset_i <= bus_in[7];
            enable_i <= bus_in[6];
            bita_i <= bus_in[5];
            bitb_i <= bus_in[4];
            bitc_i <= bus_in[3];
            posa_i <= bus_in[2];
            posb_i <= bus_in[1];
            posc_i <= bus_in[0];
        end
        @(posedge clk_i);
    end
end


//
// READ REGISTERS VECTOR FILE
//
// TS»¯¯¯¯¯PRESCALE»¯¯¯¯PRESCALE_WSTB»¯¯¯¯REPEATS»¯¯¯¯REPEATS_WSTB»¯¯¯¯TABLE_START»¯¯¯¯TABLE_START_WSTB»¯¯¯¯TABLE_DATA»¯¯¯¯TABLE_DATA_WSTB»¯¯¯¯TABLE_LENGTH»¯¯¯¯TABLE_LENGTH_WSTB
integer reg_in[10:0];

initial begin
    PRESCALE  = 0;
    PRESCALE_WSTB = 0;
    REPEATS = 0;
    REPEATS_WSTB = 0;
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
            TABLE_START = reg_in[9];
            TABLE_START_WSTB = reg_in[8];
            TABLE_DATA = reg_in[7];
            TABLE_DATA_WSTB = reg_in[6];
            TABLE_LENGTH = reg_in[5];
            TABLE_LENGTH_WSTB = reg_in[4];
            PRESCALE = reg_in[3];
            PRESCALE_WSTB = reg_in[2];
            REPEATS = reg_in[1];
            REPEATS_WSTB = reg_in[0];
        end
        @(posedge clk_i);
    end
end


//
// READ BUS EXPECTED OUTPUTS FILE TO COMPARE AGAINTS BUS
// OUTPUTS
//
// TS»¯¯¯¯¯ACTIVE¯¯¯¯¯OUTA»¯¯¯¯¯OUTB»¯¯¯¯¯OUTC»¯¯¯¯¯OUTD»¯¯¯¯¯OUTE»¯¯¯¯¯OUTF
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
            ACTIVE = bus_out[6];
            OUTA = bus_out[5];
            OUTB = bus_out[4];
            OUTC = bus_out[3];
            OUTD = bus_out[2];
            OUTE = bus_out[1];
            OUTF = bus_out[0];
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
// TS»¯¯¯¯¯TB_TABLE_LINE»¯¯¯¯¯TB_LINE_REPEAT»¯¯¯¯¯TB_TABLE_REPEAT
integer reg_out[4:0];

initial begin
    TABLE_LINE = 0;
    LINE_REPEAT = 0;
    TABLE_REPEAT = 0;
    STATE = 0;

    @(posedge clk_i);

    // Open "reg_out" file
    fid[3] = $fopen("seq_reg_out.txt", "r"); 

    // Read and ignore description field
    r[3] = $fscanf(fid[3], "%s %s %s %s %s\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);

    while (!$feof(fid[3])) begin
        r[3] = $fscanf(fid[3], "%d %d %d %d %d\n", reg_out[4], reg_out[3], reg_out[2], reg_out[1], reg_out[0]);
        wait (timestamp == reg_out[4]) begin
            TABLE_REPEAT = reg_out[3];
            TABLE_LINE = reg_out[2];
            LINE_REPEAT = reg_out[1];
            STATE = reg_out[0];
        end
        @(posedge clk_i);
    end
end



// Count tests
always @(posedge clk_i)
begin
    enable_dly <= enable_i;
    if (enable_dly == 0 & enable_i == 1) begin
        count_tests <= count_tests +1;
    end 
end   


//
// ERROR DETECTION:
// Compare Block Outputs and Expected Outputs.
//
always @(posedge clk_i)
begin 

    if (~is_file_end) begin
        if (err_outa == 1 | err_outb == 1  | err_outc == 1 | err_outd == 1  | err_oute == 1  | err_outf == 1  | 
            err_table_line == 1 | err_line_repeat == 1 | err_table_repeat == 1 | err_state == 1 | err_active == 1) begin
            test_result = 1;
        end 
        // OUTA error check  
        if (OUTA != outa_o) begin
            $display("OUTA error detected at timestamp %d\n",timestamp,"TEST NUMBER %d\n", count_tests);  
            err_outa = 1;
        end 
        else begin
            err_outa = 0;    
        end
        // OUTB error check
        if (OUTB != outb_o) begin
            $display("OUTB error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);  
            err_outb = 1; 
        end
        else begin
            err_outb = 0;
        end    
        // OUTC error check
        if (OUTC != outc_o) begin
            $display("OUTC error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);  
            err_outc = 1;
        end
        else begin
            err_outc = 0;
        end 
        // OUTD error check
        if (OUTD != outd_o) begin
            $display("OUTD error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);  
            err_outd = 1;
        end
        else begin
            err_outd = 0;
        end 
        // OUTE error check
        if (OUTE != oute_o) begin
            $display("OUTE error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);  
            err_oute = 1;
        end
        else begin
            err_oute = 0;
        end 
        // OUTF error check
        if (OUTF != outf_o) begin
            $display("OUTF error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);  
            err_outf = 1; 
        end
        else begin
            err_outf = 0;
        end 
        
        if (enable_dly == 1) begin
            // TABLE_LINE error check
            if ((TABLE_LINE != 0) && (TABLE_LINE != table_line_o)) begin
                $display("TABLE_LINE error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);  
                err_table_line = 1;
            end 
            else begin
                err_table_line = 0;
            end 
            // LINE_REPEAT error check
            if ((LINE_REPEAT != 0) && (LINE_REPEAT != line_repeat_o)) begin
                $display("LINE_REPEAT error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests); 
                err_line_repeat = 1; 
            end
            else begin
                err_line_repeat = 0;
            end 
            // TABLE_REPEAT error check
            if ((TABLE_REPEAT != 0) && (TABLE_REPEAT != table_repeat_o)) begin
                $display("TABLE_REPEAT error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);
                err_table_repeat = 1;  
            end
            else begin
                err_table_repeat =0;    
            end     
            // STATE error check
            if ((STATE != 0) && (STATE != state_o)) begin
                $display("STATE error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);
                err_state = 1;
            end         
            else begin
                err_state = 0;
            end 
            // ACTIVE error check
            if (ACTIVE != active_o) begin
                $display("ACTIVE error detected at timestamp %d\n", timestamp,"TEST NUMBER %d\n", count_tests);
                err_active = 1;
           end 
           else begin
                err_active = 0;
           end  
        end 
        else begin
            err_table_line = 0;
            err_line_repeat = 0;
            err_table_repeat = 0;
            err_state = 0;            
        end 
    end
end


endmodule


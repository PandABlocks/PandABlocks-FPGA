module incr_encoder_model (
    CLK, A, B,
);

input  CLK;
output reg A;
output reg B;

reg [0:1] Phase_Table[0:3];

task Turn;
    input integer N;
    integer Phase;
    integer J;
begin
    Phase = 0;
    J = N;
    while (J != 0) begin
        if (J < 0) begin
            J = J + 1;
            Phase = Phase - 1;
        end
        else begin
            J = J-1;
            Phase = Phase + 1;
        end
        {A,B} = Phase_Table[Phase % 4];
        repeat(25) @(posedge CLK);
    end
end
endtask

initial begin
    A = 0;
    B = 0;

    Phase_Table[0] = 2'b00;
    Phase_Table[1] = 2'b10;
    Phase_Table[2] = 2'b11;
    Phase_Table[3] = 2'b01;

end

endmodule

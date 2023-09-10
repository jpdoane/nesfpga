`timescale 1ns/1ps

module apu_divider
#( parameter DEPTH=4)
    (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic [DEPTH-1:0]  period, //actual period is period+1
    input  logic        reload,
    output logic        sync
    );

logic [DEPTH-1:0] cnt;
always_ff @(posedge clk) begin
    if(rst) begin
        cnt <= 0;
        sync <= 0;
    end else begin
        cnt <= reload ? period : cnt;
        sync <= 0;
        if(en) begin
            cnt <= cnt - 1;
            if(cnt == 0) begin                
                cnt <= period;
                sync <= 1;
            end
        end
    end
end

endmodule
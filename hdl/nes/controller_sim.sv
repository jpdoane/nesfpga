`timescale 1ns/1ps

// 0 - A
// 1 - B
// 2 - Select
// 3 - Start
// 4 - Up
// 5 - Down
// 6 - Left
// 7 - Right

module controller_sim
    (
    input logic clk,rst,
    input logic strobe,
    input logic rd,
    input logic [7:0] btns,
    output logic data
    );

    logic [7:0] sr;
    logic strobe_r, rd_r;
    wire strobe_re = strobe && !strobe_r;
    wire rd_re = rd && !rd_r;
    always_ff @(posedge clk) begin
        if(rst) begin
            sr <= 0;
            strobe_r <= 0;
            rd_r <= 0;
        end else begin
            strobe_r <= strobe;
            rd_r <= rd;
            sr <= strobe_re ? btns : rd_re ? sr >> 1 : sr;
        end
    end
    assign data = ~sr[0];

endmodule
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
    always_ff @(posedge clk) begin
        if(rst)
            sr <= 0;
        else
            sr <= strobe ? btns : rd ? sr >> 1 : sr;
    end
    assign data = sr[0];

endmodule
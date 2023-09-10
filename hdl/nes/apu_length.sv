`timescale 1ns/1ps

module apu_length
    (
    input  logic        clk,
    input  logic        rst,
    input  logic        halfframe,
    input  logic        en, halt, update,
    input  logic [4:0]  len,
    output logic        active
    );

logic [7:0] length_lookup[0:31] =
'{
8'd10, 8'd254, 8'd20, 8'd2, 8'd40, 8'd4, 8'd80,  8'd6, 8'd160,  8'd8, 8'd60, 8'd10, 8'd14, 8'd12, 8'd26, 8'd14,
8'd12, 8'd16, 8'd24, 8'd18, 8'd48, 8'd20, 8'd96, 8'd22, 8'd192, 8'd24, 8'd72, 8'd26, 8'd16, 8'd28, 8'd32, 8'd30
};

// TODO : understand this...
// In the actual APU, the length counter silences the channel when clocked while already zero (provided the length counter halt flag isn't set). The values in the above table are the actual values the length counter gets loaded with plus one, to allow us to use a model where the channel is silenced when the length counter becomes zero.
// The triangle's linear counter works differently, and does silence the channel when it reaches zero. 


logic [7:0] cnt;
always_ff @(posedge clk) begin
    if(rst) begin
        cnt <= 0;
    end else begin
        cnt <= update ? length_lookup[len] : cnt;
        if(en) begin
            if(active && halfframe && !halt) cnt <= cnt - 1;
        end
        else cnt <= 0;
    end
end

assign active = cnt != 0;

endmodule
`timescale 1ns/1ps

module apu_sweep
#( parameter NEGATE_ONESCOMPLIMENT=0 )
(
input  logic clk, rst, halfframe,
input logic en,
input logic [10:0] pulse_period,
input logic [2:0] sweep_period,
input logic neg, reload,
input logic [2:0] shift,
output logic [10:0] target_period,
output logic update_pulse_period,
output logic mute
);

wire [10:0] period_shift = pulse_period >> shift;
wire [10:0] period_shift_1scomp = ~period_shift;
wire [10:0] period_shift_2scomp = period_shift_1scomp + 1;

logic [11:0] change_amount;
logic [11:0] target_period_sum;
logic mute_period;

always_comb begin
    if (neg) begin
        if (NEGATE_ONESCOMPLIMENT) change_amount = {1'b1, period_shift_1scomp};
        else change_amount = {1'b1, period_shift_2scomp};
    end
    else change_amount = {1'b0, period_shift};

    target_period_sum = {1'b0, pulse_period} + change_amount;

    if(neg && target_period_sum[11]) begin
        target_period = 0; // clamp negative total to 0
        mute_period = 0;
    end else begin
        mute_period = target_period_sum[11]; //mute if target_period>7ff
        target_period = target_period_sum[10:0];
    end
end

assign mute = (~|pulse_period[10:3]) || mute_period; //pulse_period<8 or target_period>7ff

logic reload_flag;
logic [2:0] divcnt;
always_ff @(posedge clk) begin
    if(rst) begin
        divcnt <= 0;
        reload_flag <= 0;
    end else begin
        if (reload) reload_flag <= 1;
        if(halfframe) begin
            if(divcnt==0 || reload_flag) begin
                divcnt <= sweep_period;
                reload_flag <= 0;
            end else begin
                divcnt <= divcnt - 1;
            end
        end
    end
end

assign update_pulse_period = halfframe && divcnt==0 && en && !mute && |shift;

endmodule
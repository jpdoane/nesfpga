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
output logic [10:0] current_period,
output logic mute
);

wire [10:0] sweep_change = pulse_period >> shift;
logic [11:0] target_period;

always_comb begin
    if(en) begin
        if (neg) begin
            if (NEGATE_ONESCOMPLIMENT) target_period = {1'b0, current_period} + {1'b1, ~sweep_change};
            else target_period = {1'b0, current_period} - {1'b0, sweep_change};
        end
        else target_period = {1'b0, current_period} + {1'b0, sweep_change};
    end else target_period = {1'b0, pulse_period};
end

assign mute = current_period<8 || target_period[11];

logic sync;
always_ff @(posedge clk) begin
    if(rst) begin
        current_period <= 0;
    end else begin
        if(sync && en && !mute) current_period <= target_period[10:0];
        else current_period <= reload ? pulse_period : current_period;
    end
end

apu_divider #( .DEPTH(3) )u_apu_divider(
    .clk    (clk    ),
    .rst    (rst    ),
    .en     (halfframe     ),
    .period (sweep_period ),
    .reload (reload ),
    .sync   (sync   )
);

endmodule
`timescale 1ns/1ps

module apu_triangle
    (
    input  logic clk, rst,
    input qtrframe, halfframe,
    input en,
    input  logic [7:0] reg_ctrl,
    input  logic [7:0] reg_timelow,
    input  logic [7:0] reg_timehigh,

    input  logic reg_ctrl_update,
    input  logic reg_len_update,
    output logic active,
    output logic [3:0] sample
    );

wire [6:0] counter_reload = reg_ctrl[6:0];
wire halt = reg_ctrl[7];
wire ctrl = reg_ctrl[7];

wire [10:0] timer_len = {reg_timehigh[2:0], reg_timelow};
wire [4:0] length = reg_timehigh[7:3];

apu_length u_apu_length(
    .clk       (clk       ),
    .rst       (rst       ),
    .halfframe (halfframe ),
    .en        (en        ),
    .halt      (halt      ),
    .update    (reg_len_update),
    .len       (length       ),
    .active    (active      )
);

logic sync;

apu_divider #( .DEPTH(11) )u_apu_divider(
    .clk    (clk    ),
    .rst    (rst    ),
    .en     (active     ),
    .period (timer_len ),
    .reload (reg_len_update ),
    .sync   (sync   )
);

logic [3:0] count;
logic up;
always_ff @(posedge clk) begin
    if(rst) begin
        count <= 4'hf;
        up <= 0;
    end else begin
        if(active) begin
            if (sync) begin
                if (up) begin
                    if (&count) up <= 0; // count == 15, ramp back down
                    else count <= count + 1;
                end else begin
                    if (|count) count <= count - 1;
                    else up <= 1;  // count == 0, ramp back up
                end
            end else begin
                count <= count;
                up <= up;
            end
        end else begin
            count <= 4'hf;
            up <= 0;
        end
    end
end

assign sample = active ? count : 4'h0;

endmodule
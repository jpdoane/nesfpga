`timescale 1ns/1ps

module apu_triangle
    (
    input  logic clk, rst,
    input qtrframe, halfframe,
    input en,
    input  logic [7:0] reg_ctrl,
    input  logic [7:0] reg_timelow,
    input  logic [7:0] reg_timehigh,

    input  logic update,                // write to $400b
    output logic active,
    output logic [3:0] sample
    );


wire [10:0] timer_len = {reg_timehigh[2:0], reg_timelow};
wire [4:0] length = reg_timehigh[7:3];
wire length_halt = reg_ctrl[7];

wire [6:0] linear_counter_reload = reg_ctrl[6:0];
wire linear_ctrl_flag = reg_ctrl[7];
logic linear_counter_reload_flag;
logic [6:0] linear_cnt;
wire linear_active = linear_cnt != 0;
always_ff @(posedge clk) begin
    if (rst) begin
        linear_counter_reload_flag <= 0;
        linear_cnt <= 0;
    end else begin
        if(update) linear_counter_reload_flag <= 1;

        // When the frame counter generates a linear counter clock, the following actions occur in order:
        if(qtrframe) begin
            // If the linear counter reload flag is set, the linear counter is reloaded with the counter reload value, otherwise if the linear counter is non-zero, it is decremented.
            if(linear_counter_reload_flag || update) linear_cnt <= linear_counter_reload;
            else if(linear_active) linear_cnt <= linear_cnt - 1;

            //If the control flag is clear, the linear counter reload flag is cleared.
            if(!linear_ctrl_flag) linear_counter_reload_flag <= 0;
        end
    end
end

// length counter  (coarse note duration)
apu_length u_apu_length(
    .clk       (clk       ),
    .rst       (rst       ),
    .halfframe (halfframe ),
    .en        (en        ),
    .halt      (length_halt      ),
    .update    (update),
    .len       (length       ),
    .active    (active      )
);

wire active_both = active && linear_active;

// timer  (note pitch)
logic sync;
apu_divider #( .DEPTH(11) )u_apu_divider(
    .clk    (clk    ),
    .rst    (rst    ),
    .en     (active_both     ),
    .period (timer_len ),
    .reload (update ),
    .sync   (sync   )
);

logic [3:0] count;
logic up;
always_ff @(posedge clk) begin
    if(rst) begin
        count <= 4'hf;
        up <= 0;
    end else begin

        count <= count;
        up <= up;

        if(active_both && sync) begin
            if (up) begin
                if (&count) up <= 0; // count == 15, ramp back down
                else count <= count + 1;
            end else begin
                if (|count) count <= count - 1;
                else up <= 1;  // count == 0, ramp back up
            end
        end
    end
end

assign sample = count;

endmodule
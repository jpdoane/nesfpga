`timescale 1ns/1ps

module apu_pulse
#( parameter id=0 )
    (
    input  logic clk, rst, apu_cycle,
    input qtrframe, halfframe,
    input en,
    input  logic [7:0] reg_ctrl,
    input  logic [7:0] reg_sweep,
    input  logic [7:0] reg_timelow,
    input  logic [7:0] reg_timehigh,

    input  logic reg_ctrl_update,
    input  logic reg_sweep_update,
    input  logic reg_len_update,
    output logic active,
    output logic [3:0] sample
    );

wire [1:0] dc = reg_ctrl[7:6];
wire halt = reg_ctrl[5];
wire loop = reg_ctrl[5];
wire use_const_vol = reg_ctrl[4];
wire [3:0] const_vol = reg_ctrl[3:0];
wire [3:0] env_period = reg_ctrl[3:0];

wire sweep_en = reg_sweep[7];
wire [2:0] sweep_per = reg_sweep[6:4];
wire sweep_neg = reg_sweep[3];
wire [2:0] shift_cnt = reg_sweep[2:0];

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

logic [3:0] env_level;
apu_envelope u_apu_envelope(
    .clk       (clk       ),
    .rst       (rst       ),
    .qtrframe  (qtrframe  ),
    .period    (env_period    ),
    .start     (reg_ctrl_update     ),
    .loop      (loop      ),
    .use_const_vol (use_const_vol ),
    .const_vol (const_vol ),
    .env_level (env_level )
);

logic [10:0] current_period;
logic mute;
apu_sweep  #(.NEGATE_ONESCOMPLIMENT (id ))
u_apu_sweep(
    .clk        (clk        ),
    .rst        (rst        ),
    .halfframe  (halfframe  ),
    .en         (sweep_en         ),
    .pulse_period (timer_len ),
    .sweep_period (sweep_per ),
    .neg        (sweep_neg        ),
    .reload     (reg_sweep_update     ),
    .shift      (shift_cnt      ),
    .current_period   (current_period       ),
    .mute       (mute       )
);

logic sync;

apu_divider #( .DEPTH(11) )u_apu_divider(
    .clk    (clk    ),
    .rst    (rst    ),
    .en     (apu_cycle     ),
    .period (current_period ),
    .reload (1'b0 ),
    .sync   (sync   )
);

logic [2:0] seq;
always_ff @(posedge clk) begin
    if(rst) seq <= 0;
    else seq <= sync ? seq - 1 : seq;
end

reg [7:0] seq_lookup [0:3] = '{8'h80, 8'hc0, 8'hf0, 8'h3f};
wire pulse = seq_lookup[dc][seq] && !mute && active;
assign sample = pulse ? env_level : 0;

endmodule
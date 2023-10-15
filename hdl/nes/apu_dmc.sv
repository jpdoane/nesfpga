// `timescale 1ns/1ps

// module apu_dmc
//     (
//     input  logic clk, rst, apu_cycle,
//     input qtrframe, halfframe,
//     input en,
//     input  logic [7:0] reg_ctrl,
//     input  logic [7:0] ,
//     input  logic [7:0] reg_addr,
//     input  logic [7:0] reg_len,

//     input  logic reg_ctrl_update,
//     input  logic reg_len_update,
//     output logic active,
//     output logic [3:0] sample
//     );

// wire irq_en = reg_ctrl[7]; 
// wire loop = reg_ctrl[6]; 
// wire [3:0] rate = reg_ctrl[3:0]; 

// wire [6:0] = reg_ctrl[5]; 
// wire use_const_vol = reg_ctrl[4];
// wire [3:0] const_vol = reg_ctrl[3:0];
// wire [3:0] env_period = reg_ctrl[3:0];

// wire mode = reg_period[7]; 
// wire [3:0] period_id = reg_period[3:0]; 

// // CPU cycles:                      4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068
// logic [10:0] period_lookup[0:15] = '{2, 4, 8, 16, 32, 48, 64, 80, 101, 127, 190, 254, 381, 508, 1017, 2034};

// wire [4:0] length = reg_len[7:3];

// apu_length u_apu_length(
//     .clk       (clk       ),
//     .rst       (rst       ),
//     .halfframe (halfframe ),
//     .en        (en        ),
//     .halt      (halt      ),
//     .update    (reg_len_update),
//     .len       (length       ),
//     .active    (active      )
// );

// logic [3:0] env_level;
// apu_envelope u_apu_envelope(
//     .clk       (clk       ),
//     .rst       (rst       ),
//     .qtrframe  (qtrframe  ),
//     .period    (env_period    ),
//     .start     (reg_len_update     ),
//     .loop      (0      ),
//     .use_const_vol (use_const_vol ),
//     .const_vol (const_vol ),
//     .env_level (env_level )
// );

// logic sync;
// apu_divider #( .DEPTH(11) )u_apu_divider(
//     .clk    (clk    ),
//     .rst    (rst    ),
//     .en     (apu_cycle     ),
//     .period (current_period ),
//     .reload (1'b0 ),
//     .sync   (sync   )
// );

// logic [14:0] sr;
// logic [10:0] current_period;

// always_ff @(posedge clk) begin
//     if(rst) begin
//         sr <= 15'h1;
//         current_period <= 2;
//     end else begin
//         current_period <= period_lookup[period_id];
//         if(sync) sr <= {lfsr, sr[14:1]};
//     end
// end
// wire lfsr = sr[0] ^ (mode ? sr[6] : sr[1]);

// assign sample = (sr[0] && active) ? env_level : 0;

// endmodule
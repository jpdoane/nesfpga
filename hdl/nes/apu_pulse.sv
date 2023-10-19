`timescale 1ns/1ps

module apu_pulse
#( parameter id=0 )
    (
    input  logic clk, rst, apu_cycle,
    input qtrframe, halfframe,
    input en,
    input  logic [4:0] apu_addr,
    input  logic [7:0] data_in,
    input  logic apu_wr,
    output logic active,
    output logic [3:0] sample
    );

    logic [7:0] reg4000, reg4001, reg4002, reg4003;
    logic reg4000wr, reg4001wr, reg4002wr, reg4003wr;

    wire [1:0] dc = reg4000[7:6];
    wire halt = reg4000[5];
    wire loop = halt;
    wire use_const_vol = reg4000[4];
    wire [3:0] const_vol = reg4000[3:0];
    wire [3:0] env_period = const_vol;

    wire sweep_en = reg4001[7];
    wire [2:0] sweep_per = reg4001[6:4];
    wire sweep_neg = reg4001[3];
    wire [2:0] shift_cnt = reg4001[2:0];

    wire [10:0] pulse_period = {reg4003[2:0], reg4002};
    wire [4:0] length = reg4003[7:3];

    logic [2:0] seq;
    logic sync, pulse, mute;
    reg [7:0] seq_lookup [0:3] = '{8'h80, 8'hc0, 8'hf0, 8'h3f};

    logic update_pulse_period;
    logic [10:0] target_period;

    always_ff @(posedge clk) begin
        reg4000wr <= 0;
        reg4001wr <= 0;
        reg4002wr <= 0;
        reg4003wr <= 0;
        if(rst) begin
            reg4000 <= 0;
            reg4001 <= 0;
            reg4002 <= 0;
            reg4003 <= 0;
            seq <= 0;
        end else begin
            seq <= sync ? seq - 1 : seq;
            pulse <= seq_lookup[dc][seq];
            if (update_pulse_period) begin
                reg4002 <= target_period[7:0];
                reg4003 <= {length, target_period[10:8]};
            end
            if(apu_wr) begin
                case(apu_addr)
                    5'(0 | id << 2): begin
                                     reg4000 <= data_in;
                                     reg4000wr <= 1;
                                     end
                    5'(1 | id << 2): begin
                                     reg4001 <= data_in;
                                     reg4001wr <= 1;
                                     end
                    5'(2 | id << 2): begin
                                     reg4002 <= data_in;
                                     reg4002wr <= 1;
                                     end
                    5'(3 | id << 2): begin
                                     reg4003 <= data_in;
                                     reg4003wr <= 1;
                                     seq <= 0;
                                     end
                    default: begin end
                endcase
            end
        end
    end

    logic [3:0] env_level;
    assign sample = (!mute && active && pulse) ? env_level : 0;

    apu_length u_apu_length(
        .clk       (clk       ),
        .rst       (rst       ),
        .halfframe (halfframe ),
        .en        (en        ),
        .halt      (halt      ),
        .update    (reg4003wr ),
        .len       (length    ),
        .active    (active    )
    );

    apu_envelope u_apu_envelope(
        .clk       (clk       ),
        .rst       (rst       ),
        .qtrframe  (qtrframe  ),
        .period    (env_period    ),
        .start     (reg4003wr     ),
        .loop      (loop      ),
        .use_const_vol (use_const_vol ),
        .const_vol (const_vol ),
        .env_level (env_level )
    );

    apu_sweep  #(.NEGATE_ONESCOMPLIMENT (id ))
    u_apu_sweep(
        .clk        (clk        ),
        .rst        (rst        ),
        .halfframe  (halfframe  ),
        .en         (sweep_en         ),
        .pulse_period (pulse_period ),
        .sweep_period (sweep_per ),
        .neg        (sweep_neg        ),
        .reload     (reg4001wr     ),
        .shift      (shift_cnt      ),
        .target_period   (target_period       ),
        .update_pulse_period   (update_pulse_period       ),
        .mute       (mute       )
    );

    apu_divider #( .DEPTH(11) )u_apu_divider(
        .clk    (clk    ),
        .rst    (rst    ),
        .en     (apu_cycle     ),
        .period (pulse_period ),
        .reload (1'b0 ),
        .sync   (sync   )
    );

endmodule
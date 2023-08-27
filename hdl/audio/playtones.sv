`timescale 1ns/1ps

module playtones
(
  input logic clk,   
  input logic rst,
  input logic en,
  input logic uptone,
  input logic downtone,
  output logic pwm
);

    logic [7:0] wave [0:255];
    initial $readmemh("/home/jpdoane/dev/nesfpga/tb/audio/wave.mem", wave);

    logic [18:0] cnt;
    // assign pwm = cnt[15];

    logic [7:0] step;
    logic [7:0] sample;
    wire [7:0] idx = cnt[18:11];
    always_ff @(posedge clk) begin
        if(rst) begin
            cnt <= 0;
            sample <= 0;
        end else begin
            cnt <= cnt + step;
            sample <= wave[idx];
        end
    end

    logic up_r, down_r;
    logic up_re, down_re;
    assign  up_re = uptone & ~up_r;
    assign  down_re = downtone & ~down_r;
    always_ff @(posedge clk) begin
        if(rst) begin
            up_r <= 0;
            down_r <= 0;
            step <= 8;
        end else begin
            up_r <= uptone;
            down_r <= downtone;
            step <= up_re ? step + 1 : down_re ? step - 1 : step;
        end
    end

    pdm 
    #(
        .DEPTH (8 )
    )
    u_pdm(
        .clk    (clk    ),
        .rst    (rst    ),
        .en     (en     ),
        .sample (sample ),
        .pdm    (pwm    )
    );


endmodule
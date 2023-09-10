`timescale 1ns/1ps

module apu_mixer
#(parameter AUDIO_DEPTH=16)
    (
    input  logic clk, rst,
    input  logic [3:0] pulse0,
    input  logic [3:0] pulse1,
    input  logic [3:0] triangle,
    input  logic [3:0] noise,
    input  logic [6:0] dmc,
    output logic [AUDIO_DEPTH-1:0] mix
    );


logic [AUDIO_DEPTH-1:0] pulse_table[0:30];
initial $readmemh(`PULSE_TABLE_FILE, pulse_table);

logic [AUDIO_DEPTH-1:0] tnd_table[0:202];
initial $readmemh(`TND_TABLE_FILE, tnd_table);

wire [7:0] tnd_lookup_tri = {4'b0, triangle} + {3'b0, triangle<<1}; //tri * 3
wire [7:0] tnd_lookup_noisedmc = {3'b0, noise<<1} + {1'b0, dmc};   //noise*2 + dmc

logic [4:0] pulse_lookup;
logic [7:0] tnd_lookup;
logic [AUDIO_DEPTH-1:0] pulse_r;
logic [AUDIO_DEPTH-1:0] tnd_r;
always_ff @(posedge clk) begin
    if(rst) begin
        pulse_lookup <= 0;
        tnd_lookup <= 0;
        pulse_r <= 0;
        tnd_r <= 0;
        mix <= 0;
    end else begin
        pulse_lookup <= pulse0 + pulse1;
        tnd_lookup <= tnd_lookup_tri + tnd_lookup_noisedmc;
        pulse_r <= pulse_table[pulse_lookup];
        tnd_r <= tnd_table[tnd_lookup];
        mix <= pulse_r + tnd_r;
    end
end


endmodule
`timescale 1ns/1ps

module sprite #(parameter index=0)
    (
    input logic clk, rst,
    input logic [8:0] cycle,
    input logic eval,
    input logic frame_on,
    input logic save_pat0,
    input logic save_pat1,
    input logic load_sr,
    input logic [7:0] at_i,
    input logic [7:0] pat_i,
    input logic inscan,
    input logic [7:0] x_i,
    output logic [3:0] px,
    output logic pri
    );

    //sprite data registers
    logic [7:0] pat0;
    logic [7:0] pat1;
    logic [7:0] at;
    logic [7:0] x;

    wire sp_flip_x = at_i[6];
    wire [7:0] pat = inscan ? pat_i : 8'h0;
    wire [7:0] pat_rev = {pat[0],pat[1],pat[2],pat[3],pat[4],pat[5],pat[6],pat[7]};
    wire [7:0] sp_pat = sp_flip_x ? pat_rev : pat;

    // save sprite data from oam2
    wire eval_this = eval && (cycle[5:3] == index);
    always @(posedge clk) begin
        if (rst) begin
            pat0 <= 0;
            pat1 <= 0;
            at <= 0;
            x <= 0;
        end else begin

            if(eval_this) begin
                if (save_pat0) pat0 <= sp_pat;
                if (save_pat1) begin
                    pat1 <= sp_pat;
                    at <= at_i;
                    x <= x_i;
                end
            end
        end
    end

    // pixel shift registers and x counter
    logic [7:0] sr0, sr1, xc;
    // enable sprite once the counter reaches zero
    wire en = frame_on && (xc==0);

    always @(posedge clk) begin
        if (rst) begin
            sr0 <= 0;
            sr1 <= 0;
            xc <= 0;
        end else begin

            if(load_sr) begin
                sr0 <= pat0;
                sr1 <= pat1;
            end

           if (en) begin
                sr0 <= sr0 << 1;
                sr1 <= sr1 << 1;
            end else if(frame_on) begin
                xc <= xc - 1;
            end else begin
                xc <= x;
            end
        end
    end

    assign px = {at[1:0], sr1[7]&en, sr0[7]&en};
    assign pri = at[5];


endmodule
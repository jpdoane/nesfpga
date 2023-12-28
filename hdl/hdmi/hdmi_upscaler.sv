// ratio of hdmi to ppu clock must be:  858*2 / 341 = 5.03225806452
`timescale 1ns/1ps

module hdmi_upscaler #(
    parameter  ISCREEN_WIDTH = 256,
    parameter  ISCREEN_HEIGHT = 240,
    parameter  IFRAME_WIDTH = 341,
    parameter  IFRAME_HEIGHT = 262,
    parameter  OSCREEN_WIDTH = 720,
    parameter  OSCREEN_HEIGHT = ISCREEN_HEIGHT*SUB_Y,
    parameter  OFRAME_WIDTH = 858,
    parameter  OFRAME_HEIGHT = 525,
    parameter  SUB_X = 2,
    parameter  SUB_Y = 2,
    parameter  OSCREEN_SHIFT = (OSCREEN_WIDTH - ISCREEN_WIDTH*SUB_X) >> 1,
    parameter  PIXEL_DEPTH = 6,
    parameter  PPU_LATENCY = 2,
    parameter  PRERENDER_LINES = 1
    )
(
  input logic clk_p,                // ppu pixel clock
  input logic rst_p,                // clk_p domain reset
  input logic clk_h,                // hdmi pixel clock
  input logic rst_h,                // clk_h domain reset
  input logic [8:0] px,             // ppu x position
  input logic [PIXEL_DEPTH-1:0] pixel_p,         // pixel from ppu
  output logic [9:0] hx, hy,        // ouput hdmi counters
  output logic [PIXEL_DEPTH-1:0] pixel_h,        // pixel to hdmi
  output logic nes_on,             // nes screen is being rendered
  output logic hdmi_on,             // hdmi screen is being rendered
  output logic new_frame             // signal to render new frame, pixel_p data is read after PRERENDER_LINES input scan lines. signal is high for full hdmi scanline
);

    assign new_frame = hy == OFRAME_HEIGHT-SUB_Y*(PRERENDER_LINES+1);

    logic [PIXEL_DEPTH-1:0] ibuf [0:ISCREEN_WIDTH-1];     // input buffer from ppu
    logic [PIXEL_DEPTH-1:0] obuf [0:ISCREEN_WIDTH-1];     // playback buffer to hdmi

// clk_p domain (slower)
//
    
    // manage px coutner and offset fo pixel latency
    logic [8:0] px_reg[0:PPU_LATENCY-1];
    genvar j;
    always_ff @(posedge clk_p) px_reg[0] <= px;
    for (j = 1; j < PPU_LATENCY; j++)
        always_ff @(posedge clk_p) px_reg[j] <= px_reg[j-1];
    wire [8:0] px_delay = px_reg[PPU_LATENCY-1];

    always_ff @(posedge clk_p) begin
        if (px_delay < ISCREEN_WIDTH)
            ibuf[px_delay[7:0]] <= pixel_p;
    end

    
// clk_h domain (faster)
//

    // pixel and subpixel counters for output frame
    logic [7:0] hx_idx;
    wire  [7:0] hx_idx_nxt = (hx_idx == ISCREEN_WIDTH[7:0]-1) ? 8'h0 : hx_idx + 1;
    logic sub_hx,sub_hy;

    logic draw_on;
    wire pen_down = hx == OSCREEN_SHIFT;
    wire pen_up = hx == OSCREEN_SHIFT+ISCREEN_WIDTH*SUB_X;
    
    wire new_hline = hx == OFRAME_WIDTH - 1;
    wire last_hline = hy == OFRAME_HEIGHT - 1;
    wire new_hframe = last_hline && new_hline;
    assign hdmi_on = (hx < OSCREEN_WIDTH) && (hy <= OSCREEN_HEIGHT);

    always_ff @(posedge clk_h)
    begin
        if (rst_h)
        begin
            hx <= 0;
            hy <= 0;
            sub_hx <= 0;
            sub_hy <= 0;
            hx_idx <= 0;
            draw_on <= 0;
            nes_on <= 0;
        end
        else
        begin
            draw_on <= (draw_on || pen_down) && ~pen_up;

            hx <= new_hframe || new_hline ? 0 : hx + 1;
            hy <= new_hframe ? 0 : new_hline ? hy + 1 : hy;

            sub_hx <= draw_on ? sub_hx + 1 : 0;
            sub_hy <= new_hframe ? 0: new_hline ? sub_hy + 1 : sub_hy;

            hx_idx <=   new_hframe || new_hline ? 0 :
                        draw_on && sub_hx ? hx_idx_nxt :
                        hx_idx;

            pixel_h <= draw_on ? pixel_buf : 0;
            nes_on <= draw_on;
        end
    end

    // load new scanline from input buffer every SUB_Y lines 
    wire load_iline = new_hframe || (new_hline && sub_hy);

    for (j = 0; j < ISCREEN_WIDTH; j++)
        always_ff @(posedge clk_h) begin
            if (rst_h) obuf[j] <= 0;
            else if (load_iline) obuf[j] <= ibuf[j];
        end

    wire [PIXEL_DEPTH-1:0] pixel_buf = obuf[hx_idx];


endmodule

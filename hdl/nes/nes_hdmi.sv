`timescale 1ns/1ps

module nes_hdmi (
    //master clock and resets
    input logic clk_125MHZ,
    input logic rst_clocks,
    input logic rst_global,

    //controller
    input  logic [1:0] ctrl_data,
    output logic [1:0] ctrl_out,
    output logic [1:0] ctrl_strobe,

    //cart
    output logic clk_ppu,
    output logic clk_cpu,
    output logic cart_rst,
    output logic cart_m2,
    output logic [14:0] cart_cpu_addr,
    input logic [7:0] cart_cpu_data_i,
    output logic [7:0] cart_cpu_data_o,
    output logic cart_cpu_rw,
    output logic cart_romsel,
    input logic cart_ciram_ce,
    input logic cart_ciram_a10,
    output logic [13:0] cart_ppu_addr,
    input logic [7:0] cart_ppu_data_i,
    output logic [7:0] cart_ppu_data_o,
    output logic cart_ppu_rd,
    output logic cart_ppu_wr,
    input logic cart_irq,

    //audio out
    output logic aud_pwm,
    output logic audio_en,

    // HDMI out
    output logic [2:0] HDMI_TX,
    output logic [2:0] HDMI_TX_N,
    output logic HDMI_CLK,
    output logic HDMI_CLK_N
);

    wire clk_tmds, clk_hdmi;
    wire locked_hdmi;
    hdmi_clocks u_hdmi_clocks
    (
    .clk_125(clk_125MHZ),
    .reset(rst_clocks), 
    .clk_hdmi(clk_hdmi),
    .clk_tmds(clk_tmds),
    .locked(locked_hdmi)
    );
    logic rst_hdmi_rr, rst_hdmi_r, rst_hdmi;
    always_ff @(posedge clk_hdmi) begin
        if(~locked_hdmi | rst_global) begin
            rst_hdmi_rr <= 1;
            rst_hdmi_r <= 1;
            rst_hdmi <= 1;
        end else begin
            rst_hdmi_rr <= 0;
            rst_hdmi_r <= rst_hdmi_rr;
            rst_hdmi <= rst_hdmi_r;
        end
    end
    wire clk_nes;
    wire locked_nes;
    clocks_nes_from_hdmi u_clocks_nes_from_hdmi(
        .clk_hdmi (clk_hdmi ),
        .reset    (rst_hdmi ),
        .clk_nes (clk_nes ),
        .locked   (locked_nes   )
    );
    logic rst_nes_rr, rst_nes_r, rst_nes;
    always_ff @(posedge clk_nes) begin
        if(~locked_nes | rst_global) begin
            rst_nes_rr <= 1;
            rst_nes_r <= 1;
            rst_nes <= 1;
        end else begin
            rst_nes_rr <= 0;
            rst_nes_r <= rst_nes_rr;
            rst_nes <= rst_nes_r;
        end
    end    

    wire rst_cpu, rst_ppu;
    assign cart_rst = rst_cpu;
    logic [7:0] pixel;
    logic frame_trigger, vblank, pixel_en;
    logic [2:0] strobe;
    assign ctrl_strobe = {strobe[0],strobe[0]};



    logic [15:0] audio;
    nes
    #(
    .EXTERNAL_FRAME_TRIGGER(1),
    .SKIP_CYCLE_ODD_FRAMES(0)
    )
    u_nes(
        .clk_master       (clk_nes       ),
        .rst_master       (rst_nes       ),
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (frame_trigger ),
        .pixel         (pixel         ),
        .pixel_en      (pixel_en      ),
        .audio    (audio),
        .audio_en    (audio_en),
        .vblank    (vblank    ),
        .ctrl_strobe   (strobe),
        .ctrl_out       (ctrl_out),
        .ctrl_data       (~ctrl_data),
        .cart_m2          (cart_m2),
        .cart_cpu_addr    (cart_cpu_addr),
        .cart_cpu_data_i  (cart_cpu_data_i),
        .cart_cpu_data_o  (cart_cpu_data_o),
        .cart_cpu_rw      (cart_cpu_rw),
        .cart_romsel      (cart_romsel),
        .cart_ciram_ce    (cart_ciram_ce),
        .cart_ciram_a10   (cart_ciram_a10),
        .cart_ppu_addr    (cart_ppu_addr),
        .cart_ppu_data_i  (cart_ppu_data_i),
        .cart_ppu_data_o  (cart_ppu_data_o),
        .cart_ppu_rd      (cart_ppu_rd),
        .cart_ppu_wr      (cart_ppu_wr),
        .cart_irq         (cart_irq)
    );

    // audio
    pdm #(.DEPTH (16 )) u_pdm(
        .clk    (clk_nes    ),
        .rst    (rst_ppu    ),
        .en     (audio_en),
        .sample (audio ),
        .pdm    (aud_pwm    )
    );

    // rgb palette
    logic [23:0] pal [63:0];
    initial $readmemh(`PALFILE, pal);
    logic [23:0] rgb_p;
    always @(posedge clk_ppu) rgb_p <= pal[pixel[5:0]];

    // hdmi upscale
    logic [9:0] hx, hy;
    logic [23:0] rgb_h;
    localparam PPU_LATENCY = 4;
    hdmi_upscaler #(.IPIXEL_LATENCY (341 + PPU_LATENCY))
    u_hdmi_upscaler (
        .clk_p     (clk_ppu     ),
        .rst_p     (rst_ppu       ),
        .clk_h     (clk_hdmi     ),
        .rst_h     (rst_hdmi       ),
        .rgb_p     (rgb_p     ),
       .new_frame (frame_trigger),
         .hx        (hx        ),
        .hy        (hy        ),
        .rgb_h     (rgb_h     )
    );

    /// hmdi
    logic [2:0] tmds;
    logic tmds_clock;

    hdmi_noaudio 
    #(
        .VIDEO_ID_CODE(2),
        .BIT_WIDTH  (10),
        .BIT_HEIGHT (10),
        .VIDEO_REFRESH_RATE ( 59.94 )
    )
    u_hdmi(
        .clk_pixel_x5      (clk_tmds      ),
        .clk_pixel         (clk_hdmi         ),
        .reset             (rst_hdmi             ),
        .rgb               (rgb_h               ),
        .tmds              (tmds              ),
        .tmds_clock        (tmds_clock        ),
        .cx                 (hx        ),
        .cy                 (hy        )
    );

    genvar i;
    generate
        for (i = 0; i < 3; i++)
        begin: obufds_gen
            OBUFDS #(.IOSTANDARD("TMDS_33")) obufds (.I(tmds[i]), .O(HDMI_TX[i]), .OB(HDMI_TX_N[i]));
        end
        OBUFDS #(.IOSTANDARD("TMDS_33")) obufds_clock(.I(tmds_clock), .O(HDMI_CLK), .OB(HDMI_CLK_N));
    endgenerate

endmodule

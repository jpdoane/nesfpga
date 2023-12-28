`timescale 1ns/1ps

module nes_hdmi_tb
(
    input clk_nes,
    input clk_hdmi,
    input rst_global,
    output logic [23:0] rgb,
    output logic pixel_on,
    output logic video_frame,
    output logic audio_pwm
);
    
    logic rst_hdmi_rr, rst_hdmi_r, rst_hdmi;
    always_ff @(posedge clk_hdmi) begin
        if(rst_global) begin
            rst_hdmi_rr <= 1;
            rst_hdmi_r <= 1;
            rst_hdmi <= 1;
        end else begin
            rst_hdmi_rr <= 0;
            rst_hdmi_r <= rst_hdmi_rr;
            rst_hdmi <= rst_hdmi_r;
        end
    end


    logic rst_nes_rr, rst_nes_r, rst_nes;
    always_ff @(posedge clk_nes) begin
        if(rst_global) begin
            rst_nes_rr <= 1;
            rst_nes_r <= 1;
            rst_nes <= 1;
        end else begin
            rst_nes_rr <= 0;
            rst_nes_r <= rst_nes_rr;
            rst_nes <= rst_nes_r;
        end
    end    


    logic clk_cpu, clk_ppu;
    logic rst_cpu, rst_ppu;
    

    logic [2:0] strobe;
    logic [1:0] ctrl_out, ctrl_data, ctrl_strobe;
    assign ctrl_strobe = {strobe[0], strobe[0]};

    logic [15:0] audio;
    logic audio_en;


    logic cart_m2;
    logic [14:0] cart_cpu_addr;
    logic [7:0] data_cart2cpu;
    logic [7:0] data_cpu2cart;
    logic cart_cpu_rw;
    logic cart_romsel;
    logic cart_ciram_ce;
    logic cart_ciram_a10;
    logic [13:0] cart_ppu_addr;
    logic [7:0] data_cart2ppu;
    logic [7:0] data_ppu2cart;
    logic cart_ppu_rd;
    logic cart_ppu_wr;
    logic cart_irq;

    logic ppu_frame;
    wire nes_en = !ppu_frame || video_frame; 
    wire [7:0] pixel_p;
    wire [8:0] px, py;
    wire pixel_en, vblank;
    nes
    #(
        .SKIP_CYCLE_ODD_FRAMES (1)
    )
    u_nes(
        .clk_master       (clk_nes       ),
        .rst_master       (rst_nes       ),
        .nes_clk_en     (nes_en),
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .pixel         (pixel_p         ),
        .px         (px),
        .py         (py),
        .pixel_en      (pixel_en      ),
        .audio    (audio),
        .audio_en    (audio_en),
        .vblank    (vblank    ),
        .new_frame (ppu_frame),
        .ctrl_strobe   (strobe),
        .ctrl_out       (ctrl_out),
        .ctrl_data       (~ctrl_data),
        .cart_m2          (cart_m2),
        .cart_cpu_addr    (cart_cpu_addr),
        .cart_cpu_data_i  (data_cart2cpu),
        .cart_cpu_data_o  (data_cpu2cart),
        .cart_cpu_rw      (cart_cpu_rw),
        .cart_romsel      (cart_romsel),
        .cart_ciram_ce    (cart_ciram_ce),
        .cart_ciram_a10   (cart_ciram_a10),
        .cart_ppu_addr    (cart_ppu_addr),
        .cart_ppu_data_i  (data_cart2ppu),
        .cart_ppu_data_o  (data_ppu2cart),
        .cart_ppu_rd      (cart_ppu_rd),
        .cart_ppu_wr      (cart_ppu_wr),
        .cart_irq         (cart_irq)

    );


    // hdmi upscale
    logic [9:0] hx, hy;
    logic nes_on, hdmi_on;
    logic [5:0] pixel_h;
    localparam PPU_LATENCY = 2;
    hdmi_upscaler #(.PPU_LATENCY(PPU_LATENCY)) u_hdmi_upscaler (
        .clk_p     (clk_ppu     ),
        .rst_p     (rst_ppu       ),
        .clk_h     (clk_hdmi     ),
        .rst_h     (rst_hdmi       ),
        .px     (px     ),
        .pixel_p     (pixel_p[5:0]     ),
         .hx        (hx        ),
        .hy        (hy        ),
        .pixel_h     (pixel_h     ),
        .nes_on   (nes_on),
        .hdmi_on   (hdmi_on),
        .new_frame (video_frame)
    );

    logic [23:0] pal [0:63] = '{ 24'h666666, 24'h002a88, 24'h1412a7, 24'h3b00a4, 24'h5c007e, 24'h6e0040, 24'h6c0600, 24'h561d00, 24'h333500, 24'h0b4800, 24'h005200, 24'h004f08, 24'h00404d, 24'h000000, 24'h000000, 24'h000000, 24'hadadad, 24'h155fd9, 24'h4240ff, 24'h7527fe, 24'ha01acc, 24'hb71e7b, 24'hb53120, 24'h994e00, 24'h6b6d00, 24'h388700, 24'h0c9300, 24'h008f32, 24'h007c8d, 24'h000000, 24'h000000, 24'h000000, 24'hfffeff, 24'h64b0ff, 24'h9290ff, 24'hc676ff, 24'hf36aff, 24'hfe6ecc, 24'hfe8170, 24'hea9e22, 24'hbcbe00, 24'h88d800, 24'h5ce430, 24'h45e082, 24'h48cdde, 24'h4f4f4f, 24'h000000, 24'h000000, 24'hfffeff, 24'hc0dfff, 24'hd3d2ff, 24'he8c8ff, 24'hfbc2ff, 24'hfec4ea, 24'hfeccc5, 24'hf7d8a5, 24'he4e594, 24'hcfef96, 24'hbdf4ab, 24'hb3f3cc, 24'hb5ebf2, 24'hb8b8b8, 24'h000000, 24'h000000 };
    always @(posedge clk_hdmi) begin
        rgb <= nes_on ? pal[pixel_h] : 0;
        pixel_on <= hdmi_on;
    end


    `ifdef CART_INCL
        `include `CART_INCL
    `else 
        `define NES_HEADER 0
        `define NES_PRG_FILE ""
        `define NES_CHR_FILE ""
        `define NES_SAV_FILE ""
    `endif

    /* verilator lint_off PINMISSING */
    cart_multimapper  #(
        .NES_HEADER(`NES_HEADER),
        .NES_PRG_FILE(`NES_PRG_FILE),
        .NES_SAV_FILE(`NES_SAV_FILE),
        .NES_CHR_FILE(`NES_CHR_FILE)
    )  u_cart (
        // cart interface to NES
        .rst                     (rst_cpu),
        .clk_cpu                 (clk_cpu),
        .m2                      (cart_m2),
        .cpu_addr                (cart_cpu_addr),
        .cpu_data_i             (data_cpu2cart ),
        .cpu_data_o             (data_cart2cpu ),
        .cpu_rw                  (cart_cpu_rw),
        .romsel                  (cart_romsel),
        .ciram_ce                (cart_ciram_ce),
        .ciram_a10               (cart_ciram_a10),
        .clk_ppu                 (clk_ppu),
        .ppu_addr                (cart_ppu_addr),
        .ppu_data_i             (data_ppu2cart ),
        .ppu_data_o             (data_cart2ppu ),
        .ppu_rd                  (cart_ppu_rd),
        .ppu_wr                  (cart_ppu_wr),
        .irq                     (cart_irq),
        .ctrl1_state            (btns0),
        .ctrl2_state            (btns1),
        .nes_reset               (),
        .BRAM_CHR_addr           (0),
        .BRAM_CHR_clk            (0),
        .BRAM_CHR_wr           (0),
        .BRAM_CHR_en             (0),
        .BRAM_CHR_rst            (0),
        .BRAM_CHR_we             (0),
        .BRAM_CHR_rd            (),
        .BRAM_PRG_addr           (0),
        .BRAM_PRG_clk            (0),
        .BRAM_PRG_wr           (0),
        .BRAM_PRG_en             (0),
        .BRAM_PRG_rst            (0),
        .BRAM_PRG_we             (0),
        .BRAM_PRG_rd            (),
        .BRAM_PRGRAM_addr        (0),
        .BRAM_PRGRAM_clk         (0),
        .BRAM_PRGRAM_wr        (0),
        .BRAM_PRGRAM_en          (0),
        .BRAM_PRGRAM_rst         (0),
        .BRAM_PRGRAM_we          (0),
        .BRAM_PRGRAM_rd         (),
        .S_AXI_ACLK         (clk_cpu),
        .S_AXI_ARESETN         (rst_global),
    );
    /* verilator lint_on PINMISSING */

    // always u_nes.u_cpu_bus.PRG[15'h0fdd] = 0; // no demo wait

    int frame_cnt;
    always_ff @(posedge clk_ppu) begin
        if(rst_ppu) begin
            frame_cnt <= 1;
        end else begin
            if (py==239 && px==340) frame_cnt <= frame_cnt+1;
        end
    end




  logic ctrl_outA;
  logic ctrl_strobeA;
  logic [7:0] btns;

  controller_monitor u_controller_monitor
    (
    .clk(clk_cpu),
    .rst(rst_cpu),
    .strobe_in(ctrl_strobe[0]),
    .rd_in(ctrl_out[0]),
    .data_in(ctrl_data[0]),
    .strobe_out(ctrl_strobeA),
    .rd_out(ctrl_outA),
    .btns(btns)
    );

    logic [7:0] btns0;
    logic [7:0] btns1;

    localparam BTN_NONE    = 8'h00;
    localparam BTN_A       = 8'h01;
    localparam BTN_B       = 8'h02;
    localparam BTN_SELECT  = 8'h04;
    localparam BTN_START   = 8'h08;
    localparam BTN_UP      = 8'h10;
    localparam BTN_DOWN    = 8'h20;
    localparam BTN_LEFT    = 8'h40;
    localparam BTN_RIGHT   = 8'h80;

   
    always_comb begin
        btns0 = 0;
        // if(frame_cnt < 18) btns0 = BTN_NONE;
        // else if(frame_cnt < 20) btns0 = BTN_START;
        // else if(frame_cnt < 30) btns0 = BTN_NONE;
        // else if(frame_cnt < 32) btns0 = BTN_START;
        // else if(frame_cnt < 40) btns0 = BTN_NONE;
        // else if(frame_cnt < 45) btns0 = BTN_DOWN;
        // else if(frame_cnt < 50) btns0 = BTN_NONE;
        // else if(frame_cnt < 55) btns0 = BTN_DOWN;
        // else if(frame_cnt < 60) btns0 = BTN_NONE;
        // else if(frame_cnt < 65) btns0 = BTN_A;
        // else if(frame_cnt < 80) btns0 = BTN_DOWN;
        // else if(frame_cnt < 85) btns0 = BTN_NONE;
        // else if(frame_cnt < 90) btns0 = BTN_DOWN;
        // else if(frame_cnt < 95) btns0 = BTN_NONE;
        // else if(frame_cnt < 100) btns0 = BTN_A;
        // else if(frame_cnt < 300) btns0 = BTN_NONE;
        // else if(frame_cnt < 310) btns0 = BTN_A;
        // // else if(frame_cnt < 200) btns0 = BTN_NONE;
        // // else if(frame_cnt < 205) btns0 = BTN_RIGHT;
        // // else if(frame_cnt < 210) btns0 = BTN_A;
        // else btns0 = BTN_NONE;

        btns1 = 0;
    end

    controller_sim u_controller_sim0(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .strobe (ctrl_strobe[0] ),
        .rd     (ctrl_out[0]     ),
        .btns   (btns0   ),
        .data   (ctrl_data[0]   )
    );

    controller_sim u_controller_sim1(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .strobe (ctrl_strobe[1] ),
        .rd     (ctrl_out[1]     ),
        .btns   (btns1   ),
        .data   (ctrl_data[1]   )
    );

    pdm #(.DEPTH (16 )) u_pdm(
        .clk    (clk_nes    ),
        .rst    (rst_nes    ),
        .en     (audio_en     ),
        .sample (audio ),
        .pdm    (audio_pwm    )
    );


    `include "nes_logger.svi"

endmodule
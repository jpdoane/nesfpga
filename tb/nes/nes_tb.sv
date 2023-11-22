`timescale 1ns/1ps

module nes_tb
(
    input clk, rst,
    output logic [7:0] pixel,
    output logic pixel_clk,
    output logic pixel_en,
    output logic vblank,
    output logic audio_pwm
);
    // initial begin
    //     $dumpfile("logs/nes_tb.fst");
    //     $dumpvars(0, nes_tb);
    // end

    logic clk_cpu, clk_ppu;
    logic rst_cpu, rst_ppu;
    assign pixel_clk=clk_ppu;
    
    // logic odd_frame;
    // logic [17:0] ppu_frame_cnt;
    // always_ff @(posedge clk_ppu) begin
    //     if (rst_ppu) begin
    //         //frame_trigger initiates prescanline, but on boot we start at scanline 0, so startup 341 ticks into count...
    //         ppu_frame_cnt<= 341;
    //         odd_frame <= 1;
    //     end else begin
    //         ppu_frame_cnt <= frame_trigger ? 0 : ppu_frame_cnt + 1;
    //         odd_frame <= frame_trigger ? ~odd_frame : odd_frame;
    //     end
    // end

    // `ifdef HDMI_TIMING
    //     // hdmi frame timing (extra 1/2 scanline)
    //     localparam PPU_CYCLES_FRAME_EVEN = 89513;
    //     localparam PPU_CYCLES_FRAME_ODD = 89512;
    //     wire frame_trigger_odd = ppu_frame_cnt == PPU_CYCLES_FRAME_ODD-1;
    //     wire frame_trigger_even = ppu_frame_cnt == PPU_CYCLES_FRAME_EVEN-1;
    //     wire frame_trigger = odd_frame ? frame_trigger_odd : frame_trigger_even;

    // `else
    //     // nes frame timing
    //     localparam PPU_CYCLES_FRAME_EVEN = 89342;
    //     localparam PPU_CYCLES_FRAME_ODD = 89341;
    //     wire frame_trigger_odd = ppu_frame_cnt == PPU_CYCLES_FRAME_ODD-1;
    //     wire frame_trigger_even = ppu_frame_cnt == PPU_CYCLES_FRAME_EVEN-1;
    //     wire frame_trigger = odd_frame && |u_nes.u_ppu.ppumask[4:3] ? frame_trigger_odd : frame_trigger_even;
    // `endif 


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

    nes
    #(
        .EXTERNAL_FRAME_TRIGGER (0),
        .SKIP_CYCLE_ODD_FRAMES (1)
    )
    u_nes(
        .clk_master       (clk       ),
        .rst_master       (rst       ),
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (1'b0 ),
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
        .S_AXI_ACLK         (clk),
        .S_AXI_ARESETN         (rst),
    );
    /* verilator lint_on PINMISSING */

    // always u_nes.u_cpu_bus.PRG[15'h0fdd] = 0; // no demo wait

    logic vblank_reg;
    int frame_cnt;
    always_ff @(posedge clk) begin
        if(rst) begin
            frame_cnt <= 0;
            vblank_reg <= vblank;
        end else begin
            vblank_reg <= vblank;
            if (vblank && !vblank_reg) frame_cnt <= frame_cnt+1;
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

   
    // press start then right...
    always_comb begin
        if(frame_cnt < 40) btns0 = BTN_NONE;
        // else if(frame_cnt < 45) btns0 = BTN_START;
        // else if(frame_cnt < 70) btns0 = BTN_NONE;
        // else if(frame_cnt < 75) btns0 = BTN_START;
        // else if(frame_cnt < 200) btns0 = BTN_NONE;
        // else if(frame_cnt < 205) btns0 = BTN_RIGHT;
        // else if(frame_cnt < 210) btns0 = BTN_A;
        else btns0 = BTN_NONE;

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
        .clk    (clk    ),
        .rst    (rst    ),
        .en     (audio_en     ),
        .sample (audio ),
        .pdm    (audio_pwm    )
    );

endmodule
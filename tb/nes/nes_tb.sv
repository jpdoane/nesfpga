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

    initial begin
        $dumpfile("logs/nes_tb.fst");
        $dumpvars(0, nes_tb);
    end

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
    logic [7:0] cart_cpu_data_i;
    logic [7:0] cart_cpu_data_o;
    logic cart_cpu_rw;
    logic cart_romsel;
    logic cart_ciram_ce;
    logic cart_ciram_a10;
    logic [13:0] cart_ppu_addr;
    logic [7:0] cart_ppu_data_i;
    logic [7:0] cart_ppu_data_o;
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
        .ctrl_data       (ctrl_data),
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

    `CART u_cart (
        .rst (rst_cpu),
        .clk_cpu    (clk_cpu    ),
        .m2         (cart_m2         ),
        .cpu_addr   (cart_cpu_addr   ),
        .cpu_data_i (cart_cpu_data_i ),
        .cpu_data_o (cart_cpu_data_o ),
        .cpu_rw     (cart_cpu_rw     ),
        .romsel     (cart_romsel     ),
        .ciram_ce   (cart_ciram_ce   ),
        .ciram_a10  (cart_ciram_a10  ),
        .clk_ppu    (clk_ppu    ),
        .ppu_addr   (cart_ppu_addr   ),
        .ppu_data_i (cart_ppu_data_i ),
        .ppu_data_o (cart_ppu_data_o ),
        .ppu_rd     (cart_ppu_rd     ),
        .ppu_wr     (cart_ppu_wr     ),
        .irq        (cart_irq        )
    );


    // always u_nes.u_cpu_bus.PRG[15'h0fdd] = 0; // no demo wait



    logic [7:0] btns0 = 0;
    logic [7:0] btns1 = 0;
            // 0 - A
            // 1 - B
            // 2 - Select
            // 3 - Start
            // 4 - Up
            // 5 - Down
            // 6 - Left
            // 7 - Right
    
    // press start...
    // always_comb begin
    //     if(u_nes.u_apu.u_core_6502.cpu_cycle < 900_000) btns0 = 0;
    //     else if(u_nes.u_apu.u_core_6502.cpu_cycle < 1_100_000) btns0 = 8'b00001000; //start
    //     else btns0 = 8'b00000000; //right
    // end


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
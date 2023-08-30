`timescale 1ns/1ps

module nes_tb
(
    input clk, rst,
    output logic [7:0] pixel,
    output logic pixel_clk,
    output logic pixel_en,
    output logic vblank
);

    int cycle;
    always_ff @(posedge clk_cpu) begin
        if(rst_cpu) cycle <= 0;
        else cycle <= cycle+1;
    end
    // logic [15:0] pc_init = 16'hc004;

    initial begin
        $dumpfile("logs/nes_tb.fst");
        $dumpvars(0, nes_tb);
    end

    logic clk_cpu, rst_cpu, m2;
    logic clk_ppu, rst_ppu;
    
    clocks_sim u_clocks_sim(
    	.clk_ppu8  (clk  ),
        .rst       (rst       ),
        .clk_ppu   (clk_ppu   ),
        .clk_cpu   (clk_cpu   ),
        .m2 (m2 ),
        .rst_ppu   (rst_ppu   ),
        .rst_cpu   (rst_cpu   )
    );
    assign pixel_clk=clk_ppu;

    logic frame_trigger;
    hdmi_trigger  u_hdmi_trigger(
        .clk_p     (clk_ppu     ),
        .rst_p     (rst_ppu     ),
        .new_frame (frame_trigger )
    );


    logic [2:0] strobe;
    logic [1:0] ctrl_out, ctrl_data, ctrl_strobe;
    assign ctrl_strobe = {strobe[0], strobe[0]};


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


    nes  u_nes(
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .m2       (m2       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (frame_trigger ),
        .pixel         (pixel         ),
        .pixel_en      (pixel_en      ),
        .audio    (),
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


    cart_000 
    #(
        .MIRRORV       (1)
    )
    u_cart_000 (
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



    logic [7:0] btns = 0;
            // 0 - A
            // 1 - B
            // 2 - Select
            // 3 - Start
            // 4 - Up
            // 5 - Down
            // 6 - Left
            // 7 - Right
    
    // always_comb begin
    //     if(cycle < 800_000) btns = 0;
    //     else if(cycle < 2_000_000) btns = 8'b00001000; //start
    //     else if(cycle < 2_200_000) btns = 8'b00000001; //A
    //     else btns = 8'b10000000; //right
    // end


    controller_sim u_controller_sim(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .strobe (ctrl_strobe[0] ),
        .rd     (ctrl_out[0]     ),
        .btns   (btns   ),
        .data   (ctrl_data[0]   )
    );


endmodule
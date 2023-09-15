`timescale 1ns/1ps

module nes_top 
(
  input CLK_125MHZ,

    //GPIO
  input [1:0] SW,
  input [3:0] btn,
  output [3:0] LED,

  // contollers
  input [1:0] ctrl_data,
  output [1:0] ctrl_out,
  output [1:0] ctrl_strobe,

  // HDMI output
  output [2:0] HDMI_TX,
  output [2:0] HDMI_TX_N,
  output HDMI_CLK,
  output HDMI_CLK_N,

  //audio out
  output aud_sd,
  output aud_pwm
);

    logic audio_en;
    assign aud_sd = audio_en && SW[0];
    assign  LED[0] = aud_sd; 
    assign  LED[1] = aud_pwm; 

    wire rst_clocks = btn[0];
    wire rst_global = btn[1];

    logic clk_ppu;
    logic clk_cpu;
    logic cart_rst;
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

    nes_hdmi u_nes_hdmi(
        .clk_125MHZ       (CLK_125MHZ       ),
        .rst_clocks       (rst_clocks       ),
        .rst_global       (rst_global       ),
        .ctrl_data        (ctrl_data),
        .ctrl_out         (ctrl_out),
        .ctrl_strobe      (ctrl_strobe),
        .clk_ppu          (clk_ppu),
        .clk_cpu          (clk_cpu),
        .cart_rst          (cart_rst),
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
        .cart_irq         (cart_irq),

        .aud_pwm            (aud_pwm),
        .audio_en           (audio_en),
        .HDMI_TX            (HDMI_TX),
        .HDMI_TX_N          (HDMI_TX_N),
        .HDMI_CLK           (HDMI_CLK),
        .HDMI_CLK_N          (HDMI_CLK_N)
    );

    `CART u_cart (
        .clk_cpu    (clk_cpu    ),
        .rst        (cart_rst),
        .m2         (cart_m2         ),
        .cpu_addr   (cart_cpu_addr   ),
        .cpu_data_i (cart_cpu_data_o ),
        .cpu_data_o (cart_cpu_data_i ),
        .cpu_rw     (cart_cpu_rw     ),
        .romsel     (cart_romsel     ),
        .ciram_ce   (cart_ciram_ce   ),
        .ciram_a10  (cart_ciram_a10  ),
        .clk_ppu    (clk_ppu    ),
        .ppu_addr   (cart_ppu_addr   ),
        .ppu_data_i (cart_ppu_data_o ),
        .ppu_data_o (cart_ppu_data_i ),
        .ppu_rd     (cart_ppu_rd     ),
        .ppu_wr     (cart_ppu_wr     ),
        .irq        (cart_irq        )
    );

endmodule

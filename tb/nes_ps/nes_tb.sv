`timescale 1ns/1ps

module nes_tb();

  logic clk_master;
  logic rst_master;

  initial begin
    clk_master=0;
    rst_master=1;
    #100
    rst_master=0;
  end
  always #10 clk_master = ~clk_master;
  wire rst_mastern = ~rst_master;


  wire [31:0]BRAM_CHR_addr;
  wire BRAM_CHR_clk;
  wire [31:0]BRAM_CHR_din;
  wire [31:0]BRAM_CHR_dout;
  wire BRAM_CHR_en;
  wire BRAM_CHR_rst;
  wire [3:0]BRAM_CHR_we;
  wire [31:0]BRAM_PRGRAM_addr;
  wire BRAM_PRGRAM_clk;
  wire [31:0]BRAM_PRGRAM_din;
  wire [31:0]BRAM_PRGRAM_dout;
  wire BRAM_PRGRAM_en;
  wire BRAM_PRGRAM_rst;
  wire [3:0]BRAM_PRGRAM_we;
  wire [31:0]BRAM_PRG_addr;
  wire BRAM_PRG_clk;
  wire [31:0]BRAM_PRG_din;
  wire [31:0]BRAM_PRG_dout;
  wire BRAM_PRG_en;
  wire BRAM_PRG_rst;
  wire [3:0]BRAM_PRG_we;
//  wire [30:0]MCART_AXI_araddr;
//  wire [2:0]MCART_AXI_arprot;
//  wire MCART_AXI_arready;
//  wire MCART_AXI_arvalid;
//  wire [30:0]MCART_AXI_awaddr;
//  wire [2:0]MCART_AXI_awprot;
//  wire MCART_AXI_awready;
//  wire MCART_AXI_awvalid;
//  wire MCART_AXI_bready;
//  wire [1:0]MCART_AXI_bresp;
//  wire MCART_AXI_bvalid;
//  wire [31:0]MCART_AXI_rdata;
//  wire MCART_AXI_rready;
//  wire [1:0]MCART_AXI_rresp;
//  wire MCART_AXI_rvalid;
//  wire [31:0]MCART_AXI_wdata;
//  wire MCART_AXI_wready;
//  wire [3:0]MCART_AXI_wstrb;
//  wire MCART_AXI_wvalid;
//  wire [0:0]peripheral_reset_0;

  cart_mem_bd u_cart_mem_bd
       (.BRAM_CHR_addr(BRAM_CHR_addr),
        .BRAM_CHR_clk(BRAM_CHR_clk),
        .BRAM_CHR_din(BRAM_CHR_din),
        .BRAM_CHR_dout(BRAM_CHR_dout),
        .BRAM_CHR_en(BRAM_CHR_en),
//        .BRAM_CHR_rst(BRAM_CHR_rst),
        .BRAM_CHR_we(BRAM_CHR_we),
        .BRAM_PRGRAM_addr(BRAM_PRGRAM_addr),
        .BRAM_PRGRAM_clk(BRAM_PRGRAM_clk),
        .BRAM_PRGRAM_din(BRAM_PRGRAM_din),
        .BRAM_PRGRAM_dout(BRAM_PRGRAM_dout),
        .BRAM_PRGRAM_en(BRAM_PRGRAM_en),
//        .BRAM_PRGRAM_rst(BRAM_PRGRAM_rst),
        .BRAM_PRGRAM_we(BRAM_PRGRAM_we),
        .BRAM_PRG_addr(BRAM_PRG_addr),
        .BRAM_PRG_clk(BRAM_PRG_clk),
        .BRAM_PRG_din(BRAM_PRG_din),
        .BRAM_PRG_dout(BRAM_PRG_dout),
        .BRAM_PRG_en(BRAM_PRG_en),
//        .BRAM_PRG_rst(BRAM_PRG_rst),
        .BRAM_PRG_we(BRAM_PRG_we)
);


    logic clk_ppu, rst_ppu;
    logic clk_cpu, rst_ppu;
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

    nes u_nes(
        .clk_master       (clk_master       ),
        .rst_master       (rst_master       ),
      .clk_cpu(clk_cpu),
      .rst_cpu(rst_cpu),
      .clk_ppu(clk_ppu),
      .rst_ppu(rst_ppu),
    .frame_trigger            (),
    .pixel            (),
    .pixel_en           (),
    .vblank           (),
        .audio            (),
        .audio_en           (),
        .ctrl_data        (0),
        .ctrl_out         (),
        .ctrl_strobe      (),
        //.clk_ppu          (clk_ppu),
        //.clk_cpu          (clk_cpu),
        //.cart_rst          (cart_rst),
        .cart_m2          (cart_m2),
        .cart_cpu_addr    (cart_cpu_addr),
        .cart_cpu_data_i  (cart_cpu_data_o),
        .cart_cpu_data_o  (cart_cpu_data_i),
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

cart_top u_cart_top (
    // cart interface to NES
    .rst                     (cart_rst),
    .clk_cpu                 (clk_cpu),
    .m2                      (cart_m2),
    .cpu_addr                (cart_cpu_addr),
    .cpu_data_i              (cart_cpu_data_i),
    .cpu_data_o              (cart_cpu_data_o),
    .cpu_rw                  (cart_cpu_rw),
    .romsel                  (cart_romsel),
    .ciram_ce                (cart_ciram_ce),
    .ciram_a10               (cart_ciram_a10),
    .clk_ppu                 (clk_ppu),
    .ppu_addr                (cart_ppu_addr),
    .ppu_data_i              (cart_ppu_data_i),
    .ppu_data_o              (cart_ppu_data_o),
    .ppu_rd                  (cart_ppu_rd),
    .ppu_wr                  (cart_ppu_wr),
    .irq                     (cart_irq),
    .cart_init               (cart_init),
    // memory interfaces
    .BRAM_CHR_addr           (BRAM_CHR_addr),
    .BRAM_CHR_clk            (BRAM_CHR_clk),
    .BRAM_CHR_dout           (BRAM_CHR_din),
    .BRAM_CHR_en             (BRAM_CHR_en),
    .BRAM_CHR_rst            (BRAM_CHR_rst),
    .BRAM_CHR_we             (BRAM_CHR_we),
    .BRAM_CHR_din            (BRAM_CHR_dout),
    .BRAM_PRG_addr           (BRAM_PRG_addr),
    .BRAM_PRG_clk            (BRAM_PRG_clk),
    .BRAM_PRG_dout           (BRAM_PRG_din),
    .BRAM_PRG_en             (BRAM_PRG_en),
    .BRAM_PRG_rst            (BRAM_PRG_rst),
    .BRAM_PRG_we             (BRAM_PRG_we),
    .BRAM_PRG_din            (BRAM_PRG_dout),
    .BRAM_PRGRAM_addr        (BRAM_PRGRAM_addr),
    .BRAM_PRGRAM_clk         (BRAM_PRGRAM_clk),
    .BRAM_PRGRAM_dout        (BRAM_PRGRAM_din),
    .BRAM_PRGRAM_en          (BRAM_PRGRAM_en),
    .BRAM_PRGRAM_rst         (BRAM_PRGRAM_rst),
    .BRAM_PRGRAM_we          (BRAM_PRGRAM_we),
    .BRAM_PRGRAM_din         (BRAM_PRGRAM_dout),
    .S_AXI_ACLK              (clk_master),            
    .S_AXI_ARESETN           (rst_mastern)   
//    .S_AXI_AWADDR            (MCART_AXI_awaddr),      
//    .S_AXI_AWPROT            (MCART_AXI_awprot),      
//    .S_AXI_AWVALID           (MCART_AXI_awvalid),     
//    .S_AXI_AWREADY           (MCART_AXI_awready),     
//    .S_AXI_WDATA             (MCART_AXI_wdata),     
//    .S_AXI_WSTRB             (MCART_AXI_wstrb),     
//    .S_AXI_WVALID            (MCART_AXI_wvalid),      
//    .S_AXI_WREADY            (MCART_AXI_wready),      
//    .S_AXI_BRESP             (MCART_AXI_bresp),     
//    .S_AXI_BVALID            (MCART_AXI_bvalid),      
//    .S_AXI_BREADY            (MCART_AXI_bready),      
//    .S_AXI_ARADDR            (MCART_AXI_araddr),      
//    .S_AXI_ARPROT            (MCART_AXI_arprot),      
//    .S_AXI_ARVALID           (MCART_AXI_arvalid),     
//    .S_AXI_ARREADY           (MCART_AXI_arready),     
//    .S_AXI_RDATA             (MCART_AXI_rdata),     
//    .S_AXI_RRESP             (MCART_AXI_rresp),     
//    .S_AXI_RVALID            (MCART_AXI_rvalid),      
//    .S_AXI_RREADY            (MCART_AXI_rready)     
);




endmodule

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
  output aud_pwm,

  // ps signals
  inout [14:0]DDR_addr,
  inout [2:0]DDR_ba,
  inout DDR_cas_n,
  inout DDR_ck_n,
  inout DDR_ck_p,
  inout DDR_cke,
  inout DDR_cs_n,
  inout [3:0]DDR_dm,
  inout [31:0]DDR_dq,
  inout [3:0]DDR_dqs_n,
  inout [3:0]DDR_dqs_p,
  inout DDR_odt,
  inout DDR_ras_n,
  inout DDR_reset_n,
  inout DDR_we_n,
  inout FIXED_IO_ddr_vrn,
  inout FIXED_IO_ddr_vrp,
  inout [53:0]FIXED_IO_mio,
  inout FIXED_IO_ps_clk,
  inout FIXED_IO_ps_porb,
  inout FIXED_IO_ps_srstb
);



  wire AXI_CLK;
  wire [0:0]AXI_RSTN;
  wire BRAM_CHR_clk;
  wire [31:0]BRAM_CHR_addr;
  wire [31:0]BRAM_CHR_wr;
  wire [31:0]BRAM_CHR_rd;
  wire BRAM_CHR_en;
  wire BRAM_CHR_rst;
  wire [3:0]BRAM_CHR_we;
  (* mark_debug = "true" *)  wire [31:0]BRAM_PRGRAM_addr;
  wire BRAM_PRGRAM_clk;
  (* mark_debug = "true" *)  wire [31:0]BRAM_PRGRAM_wr;
  wire [31:0]BRAM_PRGRAM_rd;
  (* mark_debug = "true" *)  wire BRAM_PRGRAM_en;
  wire BRAM_PRGRAM_rst;
  (* mark_debug = "true" *)  wire [3:0]BRAM_PRGRAM_we;
  wire [31:0]BRAM_PRG_addr;
  wire BRAM_PRG_clk;
  wire [31:0]BRAM_PRG_wr;
  wire [31:0]BRAM_PRG_rd;
  wire BRAM_PRG_en;
  wire BRAM_PRG_rst;
  wire [3:0]BRAM_PRG_we;
  wire [30:0]MCART_AXI_araddr;
  wire [2:0]MCART_AXI_arprot;
  wire MCART_AXI_arready;
  wire MCART_AXI_arvalid;
  wire [30:0]MCART_AXI_awaddr;
  wire [2:0]MCART_AXI_awprot;
  wire MCART_AXI_awready;
  wire MCART_AXI_awvalid;
  wire MCART_AXI_bready;
  wire [1:0]MCART_AXI_bresp;
  wire MCART_AXI_bvalid;
  wire [31:0]MCART_AXI_rdata;
  wire MCART_AXI_rready;
  wire [1:0]MCART_AXI_rresp;
  wire MCART_AXI_rvalid;
  wire [31:0]MCART_AXI_wdata;
  wire MCART_AXI_wready;
  wire [3:0]MCART_AXI_wstrb;
  wire MCART_AXI_wvalid;
  wire [0:0]peripheral_reset_0;

  cart_ps_bd cart_ps_bd_i
       (.AXI_CLK(AXI_CLK),
        .AXI_RSTN(AXI_RSTN),
        .BRAM_CHR_addr(BRAM_CHR_addr),
        .BRAM_CHR_clk(BRAM_CHR_clk),
        .BRAM_CHR_din(BRAM_CHR_wr),
        .BRAM_CHR_dout(BRAM_CHR_rd),
        .BRAM_CHR_en(BRAM_CHR_en),
        .BRAM_CHR_rst(BRAM_CHR_rst),
        .BRAM_CHR_we(BRAM_CHR_we),
        .BRAM_PRGRAM_addr(BRAM_PRGRAM_addr),
        .BRAM_PRGRAM_clk(BRAM_PRGRAM_clk),
        .BRAM_PRGRAM_din(BRAM_PRGRAM_wr),
        .BRAM_PRGRAM_dout(BRAM_PRGRAM_rd),
        .BRAM_PRGRAM_en(BRAM_PRGRAM_en),
        .BRAM_PRGRAM_rst(BRAM_PRGRAM_rst),
        .BRAM_PRGRAM_we(BRAM_PRGRAM_we),
        .BRAM_PRG_addr(BRAM_PRG_addr),
        .BRAM_PRG_clk(BRAM_PRG_clk),
        .BRAM_PRG_din(BRAM_PRG_wr),
        .BRAM_PRG_dout(BRAM_PRG_rd),
        .BRAM_PRG_en(BRAM_PRG_en),
        .BRAM_PRG_rst(BRAM_PRG_rst),
        .BRAM_PRG_we(BRAM_PRG_we),
        .DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .MCART_AXI_araddr(MCART_AXI_araddr),
        .MCART_AXI_arprot(MCART_AXI_arprot),
        .MCART_AXI_arready(MCART_AXI_arready),
        .MCART_AXI_arvalid(MCART_AXI_arvalid),
        .MCART_AXI_awaddr(MCART_AXI_awaddr),
        .MCART_AXI_awprot(MCART_AXI_awprot),
        .MCART_AXI_awready(MCART_AXI_awready),
        .MCART_AXI_awvalid(MCART_AXI_awvalid),
        .MCART_AXI_bready(MCART_AXI_bready),
        .MCART_AXI_bresp(MCART_AXI_bresp),
        .MCART_AXI_bvalid(MCART_AXI_bvalid),
        .MCART_AXI_rdata(MCART_AXI_rdata),
        .MCART_AXI_rready(MCART_AXI_rready),
        .MCART_AXI_rresp(MCART_AXI_rresp),
        .MCART_AXI_rvalid(MCART_AXI_rvalid),
        .MCART_AXI_wdata(MCART_AXI_wdata),
        .MCART_AXI_wready(MCART_AXI_wready),
        .MCART_AXI_wstrb(MCART_AXI_wstrb),
        .MCART_AXI_wvalid(MCART_AXI_wvalid),
        .peripheral_reset_0(peripheral_reset_0));



    logic clk_ppu;
    logic clk_cpu;
    logic cart_rst;
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

    logic nes_reset;
    wire rst_clocks = btn[0];
    wire rst_global = btn[1] || nes_reset;

    logic audio_en;
    assign aud_sd = audio_en && SW[0];

    logic [1:0] nes_ctrl_out;
    logic [1:0] nes_ctrl_strobe;

    nes_hdmi u_nes_hdmi(
        .clk_125MHZ       (CLK_125MHZ       ),
        .rst_clocks       (rst_clocks       ),
        .rst_global       (rst_global       ),
        .ctrl_data        (ctrl_data),
        .ctrl_out         (nes_ctrl_out),
        .ctrl_strobe      (nes_ctrl_strobe),
        .clk_ppu          (clk_ppu),
        .clk_cpu          (clk_cpu),
        .cart_rst          (cart_rst),
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
        .cart_irq         (cart_irq),

        .aud_pwm            (aud_pwm),
        .audio_en           (audio_en),
        .HDMI_TX            (HDMI_TX),
        .HDMI_TX_N          (HDMI_TX_N),
        .HDMI_CLK           (HDMI_CLK),
        .HDMI_CLK_N          (HDMI_CLK_N)
    );


  `ifdef CART_INCL
      `include `CART_INCL
  `else 
      `define NES_HEADER 0
      `define NES_PRG_FILE ""
      `define NES_CHR_FILE ""
  `endif

  cart_multimapper
  #(
          .NES_HEADER(`NES_HEADER),
          .NES_PRG_FILE(`NES_PRG_FILE),
          .NES_CHR_FILE(`NES_CHR_FILE)
  )
  u_cart_top (
      // cart interface to NES
      .rst                     (cart_rst),
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
      .ctrl1_state              (btns),
      .ctrl2_state              (8'h0),
      .nes_reset               (nes_reset),
      // memory interfaces
      .BRAM_CHR_addr           (BRAM_CHR_addr),
      .BRAM_CHR_clk            (BRAM_CHR_clk),
      .BRAM_CHR_wr           (BRAM_CHR_wr),
      .BRAM_CHR_en             (BRAM_CHR_en),
      .BRAM_CHR_rst            (BRAM_CHR_rst),
      .BRAM_CHR_we             (BRAM_CHR_we),
      .BRAM_CHR_rd            (BRAM_CHR_rd),
      .BRAM_PRG_addr           (BRAM_PRG_addr),
      .BRAM_PRG_clk            (BRAM_PRG_clk),
      .BRAM_PRG_wr           (BRAM_PRG_wr),
      .BRAM_PRG_en             (BRAM_PRG_en),
      .BRAM_PRG_rst            (BRAM_PRG_rst),
      .BRAM_PRG_we             (BRAM_PRG_we),
      .BRAM_PRG_rd            (BRAM_PRG_rd),
      .BRAM_PRGRAM_addr        (BRAM_PRGRAM_addr),
      .BRAM_PRGRAM_clk         (BRAM_PRGRAM_clk),
      .BRAM_PRGRAM_wr        (BRAM_PRGRAM_wr),
      .BRAM_PRGRAM_en          (BRAM_PRGRAM_en),
      .BRAM_PRGRAM_rst         (BRAM_PRGRAM_rst),
      .BRAM_PRGRAM_we          (BRAM_PRGRAM_we),
      .BRAM_PRGRAM_rd         (BRAM_PRGRAM_rd),
      .S_AXI_ACLK              (AXI_CLK),            
      .S_AXI_ARESETN           (AXI_RSTN),     
      .S_AXI_AWADDR            (MCART_AXI_awaddr),      
      .S_AXI_AWPROT            (MCART_AXI_awprot),      
      .S_AXI_AWVALID           (MCART_AXI_awvalid),     
      .S_AXI_AWREADY           (MCART_AXI_awready),     
      .S_AXI_WDATA             (MCART_AXI_wdata),     
      .S_AXI_WSTRB             (MCART_AXI_wstrb),     
      .S_AXI_WVALID            (MCART_AXI_wvalid),      
      .S_AXI_WREADY            (MCART_AXI_wready),      
      .S_AXI_BRESP             (MCART_AXI_bresp),     
      .S_AXI_BVALID            (MCART_AXI_bvalid),      
      .S_AXI_BREADY            (MCART_AXI_bready),      
      .S_AXI_ARADDR            (MCART_AXI_araddr),      
      .S_AXI_ARPROT            (MCART_AXI_arprot),      
      .S_AXI_ARVALID           (MCART_AXI_arvalid),     
      .S_AXI_ARREADY           (MCART_AXI_arready),     
      .S_AXI_RDATA             (MCART_AXI_rdata),     
      .S_AXI_RRESP             (MCART_AXI_rresp),     
      .S_AXI_RVALID            (MCART_AXI_rvalid),      
      .S_AXI_RREADY            (MCART_AXI_rready)     
  );


    logic [7:0] btns;
    // 0 - A
    // 1 - B
    // 2 - Select
    // 3 - Start
    // 4 - Up
    // 5 - Down
    // 6 - Left
    // 7 - Right

    logic ctrl_outA;
    logic ctrl_strobeA;

    controller_monitor u_controller_monitor
      (
      .clk(clk_cpu),
      .rst(rst_cpu),
      .strobe_in(nes_ctrl_strobe[0]),
      .rd_in(nes_ctrl_out[0]),
      .data_in(ctrl_data[0]),
      .strobe_out(ctrl_strobeA),
      .rd_out(ctrl_outA),
      .btns(btns)
      );

    assign ctrl_out = {nes_ctrl_out[1], ctrl_outA};
    assign ctrl_strobe = {nes_ctrl_strobe[1], ctrl_strobeA};
    assign  LED = btns[3:0]; 

endmodule

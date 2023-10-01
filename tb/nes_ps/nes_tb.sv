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


    logic clk_ppu, rst_ppu;
    logic clk_cpu, rst_ppu;
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

cart_multimapper
#(
    .CHR_FILE({`ROM_PATH,"/smb/CHR.mem"}),
    .PRG_FILE({`ROM_PATH,"/smb/PRG.mem"}),
    .PRGRAM_FILE("") 
)
 u_cart (
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
    .cart_init               (cart_init),
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
    .BRAM_PRGRAM_rd         ()    
);



endmodule

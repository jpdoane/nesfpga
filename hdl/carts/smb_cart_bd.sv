`timescale 1ns/1ps

module smb_cart_bd(
    input logic rst,
    input logic clk_cpu, m2,
    input logic [14:0] cpu_addr,
    input logic [7:0] cpu_data_i,
    output logic [7:0] cpu_data_o,
    input logic cpu_rw,
    input logic romsel,
    output logic ciram_ce,
    output logic ciram_a10,

    input logic clk_ppu,
    input logic [13:0] ppu_addr,
    input logic [7:0] ppu_data_i,
    output logic [7:0] ppu_data_o,
    input logic ppu_rd,
    input logic ppu_wr,

    output logic irq
);

    initial $display("Loading cart: Super Mario Bros");

    cart_top #(
        .CHR_FILE({`ROM_PATH,"/smb/CHR32.mem"}),
        .PRG_FILE({`ROM_PATH,"/smb/PRG32.mem"})
    )
    u_cart_top(
    .rst        (rst),
    .clk_cpu    (clk_cpu    ),
    .m2         (m2         ),
    .cpu_addr   (cpu_addr   ),
    .cpu_data_i (cpu_data_i ),
    .cpu_data_o (cpu_data_o ),
    .cpu_rw     (cpu_rw     ),
    .romsel     (romsel     ),
    .ciram_ce   (ciram_ce   ),
    .ciram_a10  (ciram_a10  ),
    .clk_ppu    (clk_ppu    ),
    .ppu_addr   (ppu_addr   ),
    .ppu_data_i (ppu_data_i ),
    .ppu_data_o (ppu_data_o ),
    .ppu_rd     (ppu_rd     ),
    .ppu_wr     (ppu_wr     ),
    .irq        (irq        ),
    .cart_init (),
    .BRAM_CHR_addr(0),
    .BRAM_CHR_clk(clk_ppu),
    .BRAM_CHR_wr(0),
    .BRAM_CHR_en(0),
    .BRAM_CHR_rst(0),
    .BRAM_CHR_we(0),
    .BRAM_CHR_rd(),
    .BRAM_PRG_addr(0),
    .BRAM_PRG_clk(clk_ppu),
    .BRAM_PRG_wr(0),
    .BRAM_PRG_en(0),
    .BRAM_PRG_rst(0),
    .BRAM_PRG_we(0),
    .BRAM_PRG_rd(),
    .BRAM_PRGRAM_addr(0),
    .BRAM_PRGRAM_clk(clk_ppu),
    .BRAM_PRGRAM_wr(0),
    .BRAM_PRGRAM_en(0),
    .BRAM_PRGRAM_rst(0),
    .BRAM_PRGRAM_we(0),
    .BRAM_PRGRAM_rd(),
    .S_AXI_ACLK(clk_ppu),
    .S_AXI_ARESETN(0),
    .S_AXI_AWADDR(0),
    .S_AXI_AWPROT(0),
    .S_AXI_AWVALID(0),
    .S_AXI_AWREADY(),
    .S_AXI_WDATA(0),
    .S_AXI_WSTRB(0),
    .S_AXI_WVALID(0),
    .S_AXI_WREADY(),
    .S_AXI_BRESP(),
    .S_AXI_BVALID(),
    .S_AXI_BREADY(0),
    .S_AXI_ARADDR(0),
    .S_AXI_ARPROT(0),
    .S_AXI_ARVALID(0),
    .S_AXI_ARREADY(),
    .S_AXI_RDATA(),
    .S_AXI_RRESP(),
    .S_AXI_RVALID(),
    .S_AXI_RREADY(0)
    );

    // cart_000 
    // #(
    //     .PRG_FILE({`ROM_PATH,"/smb/PRG.mem"}),
    //     .CHR_FILE({`ROM_PATH,"/smb/CHR.mem"}),
    //     .MIRRORV(1)
    // )
    // u_cart_000 (
    //     .rst        (rst),
    //     .clk_cpu    (clk_cpu    ),
    //     .m2         (m2         ),
    //     .cpu_addr   (cpu_addr   ),
    //     .cpu_data_i (cpu_data_i ),
    //     .cpu_data_o (cpu_data_o ),
    //     .cpu_rw     (cpu_rw     ),
    //     .romsel     (romsel     ),
    //     .ciram_ce   (ciram_ce   ),
    //     .ciram_a10  (ciram_a10  ),
    //     .clk_ppu    (clk_ppu    ),
    //     .ppu_addr   (ppu_addr   ),
    //     .ppu_data_i (ppu_data_i ),
    //     .ppu_data_o (ppu_data_o ),
    //     .ppu_rd     (ppu_rd     ),
    //     .ppu_wr     (ppu_wr     ),
    //     .irq        (irq        )
    // );

endmodule


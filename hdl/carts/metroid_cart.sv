`timescale 1ns/1ps

module metroid_cart(
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

    initial $display("Loading cart: Metroid");

    cart_001
    #(
        .PRG_FILE({`ROM_PATH,"/metroid/PRG.mem"}),
        .PRG_ROM_DEPTH (17),
        .CHR_ROM_DEPTH (13),
        .CHR_RAM (1),
        .PRG_RAM (0)
    )
    u_cart_001 (
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
        .irq        (irq        )
    );

endmodule




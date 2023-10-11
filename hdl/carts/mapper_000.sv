`timescale 1ns/1ps

module mapper_000 #(
    parameter PRG_ROM_DEPTH=17,
    parameter CHR_ROM_DEPTH=15,
    parameter PRG_RAM_DEPTH=13
    )(
    input logic rst,
    input logic clk_cpu,
    input logic [14:0] cpu_addr,
    input logic [7:0] cpu_data_i,
    input logic [13:0] ppu_addr,
    input logic cpu_rw,
    input logic romsel,
    input logic mirrorv,
    input logic chr_ram,
    input logic prg_ram,
    input logic [PRG_ROM_DEPTH-1:0] prg_mask,
    input logic [CHR_ROM_DEPTH-1:0] chr_mask,
    input logic [PRG_RAM_DEPTH-1:0] prgram_mask,

    output logic [PRG_ROM_DEPTH-1:0] prg_addr,
    output logic [CHR_ROM_DEPTH-1:0] chr_addr,
    output logic [PRG_RAM_DEPTH-1:0] prgram_addr,
    output logic prg_cs,
    output logic chr_cs,
    output logic prgram_cs,
    output logic [7:0] mapper_reg_o,

    output logic ciram_ce,
    output logic ciram_a10,
    output logic irq

);

    assign ciram_ce = ppu_addr[13];
    assign ciram_a10 = mirrorv ? ppu_addr[10] : ppu_addr[11];
    assign irq = 0;

    assign prg_cs = romsel;
    assign prg_addr = prg_mask & PRG_ROM_DEPTH'(cpu_addr);

    assign chr_cs = ~ciram_ce;
    assign chr_addr = chr_mask & CHR_ROM_DEPTH'(ppu_addr);

    assign prgram_cs = prg_ram && ~romsel && (cpu_addr[14:13] == 2'b11);
    assign prgram_addr = prgram_mask & PRG_RAM_DEPTH'(cpu_addr);

    assign mapper_reg_o = 0;
endmodule
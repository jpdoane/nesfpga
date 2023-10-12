`timescale 1ns/1ps

module mapper_bank #(
    parameter PRG_ROM_DEPTH=17,
    parameter CHR_ROM_DEPTH=15,
    parameter PRG_RAM_DEPTH=13
    )(
    input logic rst,
    input logic clk_cpu,
    input logic [7:0] mapper_id,
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

    logic [7:0] bank;
    always_ff @(posedge clk_cpu) begin
        if (rst) begin
            bank <= 0;
        end else begin
            if (romsel && !cpu_rw) bank <= cpu_data_i;
        end
    end

    wire prg_banking = mapper_id == 8'h2;
    wire chr_banking = mapper_id == 8'h3;

    assign prg_cs = romsel;
    wire [PRG_ROM_DEPTH-15:0] prg_bank = cpu_addr[14] ? {(PRG_ROM_DEPTH-14){1'b1}} : bank[PRG_ROM_DEPTH-15:0];
    wire [PRG_ROM_DEPTH-1:0] prg_addr_full = prg_banking ? PRG_ROM_DEPTH'({prg_bank, cpu_addr[13:0]}) : PRG_ROM_DEPTH'(cpu_addr);
    assign prg_addr = prg_mask & prg_addr_full;

    assign chr_cs = ~ciram_ce;
    wire [CHR_ROM_DEPTH-1:0] chr_addr_full = chr_banking ? CHR_ROM_DEPTH'({bank, ppu_addr[12:0]}) : CHR_ROM_DEPTH'(ppu_addr[12:0]);
    assign chr_addr = chr_mask & CHR_ROM_DEPTH'(chr_addr_full);

    assign prgram_cs = prg_ram && ~romsel && (cpu_addr[14:13] == 2'b11);
    assign prgram_addr = prgram_mask & PRG_RAM_DEPTH'(cpu_addr);

    assign mapper_reg_o = 0;
endmodule
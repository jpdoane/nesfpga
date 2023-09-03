`timescale 1ns/1ps

module cart_000 #(
    parameter PRG_FILE,
    parameter CHR_FILE,
    parameter PRG_ROM_DEPTH=15,
    parameter CHR_ROM_DEPTH=13,
    parameter MIRRORV=1
    )(
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

    assign ciram_a10 = MIRRORV ? ppu_addr[10] : ppu_addr[11];
    assign ciram_ce = ppu_addr[13];
    assign irq = 0;
    wire chr_cs = ~ciram_ce;

    // PRG ROM
    logic [7:0] prg_rom[0:2**PRG_ROM_DEPTH-1];
    initial begin
        $display("Loading PRG ROM: %s", PRG_FILE);
        $readmemh(PRG_FILE, prg_rom);
    end
    logic [7:0] prg_rom_rd;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr = cpu_addr[PRG_ROM_DEPTH-1:0];
    always @(posedge clk_cpu) begin
        if (romsel) begin
            prg_rom_rd <= prg_rom[prg_rom_addr];
        end
    end

    // CHR ROM
    logic [7:0] chr_rom  [0:2**CHR_ROM_DEPTH-1];
    initial begin
        $display("Loading CHR ROM: %s ", CHR_FILE);
        $readmemh(CHR_FILE, chr_rom);
    end

    logic [7:0] chr_rd;
    wire [CHR_ROM_DEPTH-1:0] chr_addr = ppu_addr[CHR_ROM_DEPTH-1:0];
    always @(posedge clk_ppu) begin
        if (chr_cs) begin
            chr_rd <= chr_rom[chr_addr];
        end
    end

    logic romsel_r, chr_cs_r;
    always @(posedge clk_cpu) romsel_r <= romsel;
    always @(posedge clk_ppu) chr_cs_r <= chr_cs;

    assign cpu_data_o = romsel_r ? prg_rom_rd : 0;
    assign ppu_data_o = chr_cs_r ? chr_rd : 0;

endmodule
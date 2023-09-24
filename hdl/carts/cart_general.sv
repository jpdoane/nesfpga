`timescale 1ns/1ps

module cart_config (

    // cart interface to NES
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
    output logic irq,

// memory interfaces
  output [31:0] BRAM_CHR_addr,
  output        BRAM_CHR_clk,
  output [31:0] BRAM_CHR_dout,
  output        BRAM_CHR_en,
  output        BRAM_CHR_rst,
  output [3:0]  BRAM_CHR_we,
  input [31:0]  BRAM_CHR_din,

  output [31:0] BRAM_PRG_addr,
  output        BRAM_PRG_clk,
  output [31:0] BRAM_PRG_dout,
  output        BRAM_PRG_en,
  output        BRAM_PRG_rst,
  output [3:0]  BRAM_PRG_we,
  input [31:0]  BRAM_PRG_din,

  output [31:0] BRAM_PRGRAM_addr,
  output        BRAM_PRGRAM_clk,
  output [31:0] BRAM_PRGRAM_dout,
  output        BRAM_PRGRAM_en,
  output        BRAM_PRGRAM_rst,
  output [3:0]  BRAM_PRGRAM_we,
  input [31:0]  BRAM_PRGRAM_din,

// config interface
  input wire [31:0] mapper_config,
  input wire [31:0] CHR_mask,
  input wire [31:0] PRG_mask,
  input wire [31:0] PRGRAM_mask
);

    wire  mirrorv = mapper_config[0];

    assign ciram_a10 = mirrorv ? ppu_addr[10] : ppu_addr[11];
    assign ciram_ce = ppu_addr[13];
    assign irq = 0;
    wire chr_cs = ~ciram_ce;

    // PRG ROM
    assign BRAM_PRG_addr = {17'b0, cpu_addr[14:2], 2'b0} & PRG_mask;
    assign BRAM_PRG_clk = clk_cpu;
    assign BRAM_PRG_dout = 0;
    assign BRAM_PRG_en = romsel;
    assign BRAM_PRG_rst = 0;
    assign BRAM_PRG_we = 0;

    // CHR ROM
    assign BRAM_CHR_addr = {18'b0, ppu_addr[13:2], 2'b0} & CHR_mask;
    assign BRAM_CHR_clk = clk_ppu;
    assign BRAM_CHR_dout = 0;
    assign BRAM_CHR_en = chr_cs;
    assign BRAM_CHR_rst = 0;
    assign BRAM_CHR_we = 0;

    // CHR RAM (not used in mapper 0)
    assign BRAM_CHR_addr = 0;
    assign BRAM_CHR_clk = clk_cpu;
    assign BRAM_CHR_dout = 0;
    assign BRAM_CHR_en = 0;
    assign BRAM_CHR_rst = 0;
    assign BRAM_CHR_we = 0;

    logic romsel_r, chr_cs_r;
    always @(posedge clk_cpu) romsel_r <= romsel;
    always @(posedge clk_ppu) chr_cs_r <= chr_cs;

    logic [7:0] BRAM_PRG_byte_rd;
    logic [7:0] BRAM_CHR_byte_rd;
    always_comb begin
        case(cpu_addr[1:0])
            2'h0: BRAM_PRG_byte_rd = BRAM_PRG_din[7:0];
            2'h1: BRAM_PRG_byte_rd = BRAM_PRG_din[15:8];
            2'h2: BRAM_PRG_byte_rd = BRAM_PRG_din[23:16];
            2'h3: BRAM_PRG_byte_rd = BRAM_PRG_din[31:24];
        endcase
        case(ppu_addr[1:0])
            2'h0: BRAM_CHR_byte_rd = BRAM_CHR_din[7:0];
            2'h1: BRAM_CHR_byte_rd = BRAM_CHR_din[15:8];
            2'h2: BRAM_CHR_byte_rd = BRAM_CHR_din[23:16];
            2'h3: BRAM_CHR_byte_rd = BRAM_CHR_din[31:24];
        endcase       
    end
    assign cpu_data_o = romsel_r ? BRAM_PRG_byte_rd : 0;
    assign ppu_data_o = chr_cs_r ? BRAM_CHR_byte_rd : 0;

endmodule
`timescale 1ns/1ps

module cart_top
#(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 6,

    parameter integer CHR_WIDTH = 15,
    parameter integer PRG_WIDTH = 17,
    parameter integer PRGRAM_WIDTH = 13,
    parameter CHR_FILE="",
    parameter PRG_FILE=""
)
(
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

    output logic cart_init,

// memory interface to AXI
  input [CHR_WIDTH-1:0] BRAM_CHR_addr,
  input        BRAM_CHR_clk,
  input [31:0] BRAM_CHR_wr,
  input        BRAM_CHR_en,
  input        BRAM_CHR_rst,
  input [3:0]  BRAM_CHR_we,
  output [31:0]  BRAM_CHR_rd,

  input [PRG_WIDTH-1:0] BRAM_PRG_addr,
  input        BRAM_PRG_clk,
  input [31:0] BRAM_PRG_wr,
  input        BRAM_PRG_en,
  input        BRAM_PRG_rst,
  input [3:0]  BRAM_PRG_we,
  output [31:0]  BRAM_PRG_rd,

  input [PRGRAM_WIDTH-1:0] BRAM_PRGRAM_addr,
  input        BRAM_PRGRAM_clk,
  input [31:0] BRAM_PRGRAM_wr,
  input        BRAM_PRGRAM_en,
  input        BRAM_PRGRAM_rst,
  input [3:0]  BRAM_PRGRAM_we,
  output [31:0]  BRAM_PRGRAM_rd,

// axi interface for config

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
        // privilege and security level of the transaction, and whether
        // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
        // valid write address and control information.
    input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
        // to accept an address and associated control signals.
    output wire  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
        // valid data. There is one write strobe bit for each eight
        // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
        // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
        // can accept the write data.
    output wire  S_AXI_WREADY,
    // Write response. This signal indicates the status
        // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
        // is signaling a valid write response.
    output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
        // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
        // and security level of the transaction, and whether the
        // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
        // is signaling valid read address and control information.
    input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
        // ready to accept an address and associated control signals.
    output wire  S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
        // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
        // signaling the required read data.
    output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
        // accept the read data and response information.
    input wire  S_AXI_RREADY

);


    (* mark_debug = "true" *)  logic [PRG_WIDTH-1:0] BRAM_PRG_addr;
    (* mark_debug = "true" *)  logic        BRAM_PRG_clk;
    (* mark_debug = "true" *)  logic [31:0] BRAM_PRG_wr;
    (* mark_debug = "true" *)  logic        BRAM_PRG_en;
    (* mark_debug = "true" *)  logic        BRAM_PRG_rst;
    (* mark_debug = "true" *)  logic [3:0]  BRAM_PRG_we;
    (* mark_debug = "true" *)  logic [31:0]  BRAM_PRG_rd;

    (* mark_debug = "true" *)  logic [31:0] mapper_config;
    (* mark_debug = "true" *)  logic [31:0] CHR_mask;
    (* mark_debug = "true" *)  logic [31:0] PRG_mask;
    (* mark_debug = "true" *)  logic [31:0] PRGRAM_mask;

	axi_cart_regs
	#(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .mapper_config_init(32'h1),
        .CHR_mask_init(32'h1fff),
        .PRG_mask_init(32'h7fff),
        .PRGRAM_mask_init(0)
	)
	u_axi_cart_regs (
		.mapper_config(mapper_config),
		.CHR_mask(CHR_mask),
		.PRG_mask(PRG_mask),
		.PRGRAM_mask(PRGRAM_mask),
       .S_AXI_ACLK(S_AXI_ACLK),
       .S_AXI_ARESETN(S_AXI_ARESETN),
       .S_AXI_AWADDR(S_AXI_AWADDR),
       .S_AXI_AWPROT(S_AXI_AWPROT),
       .S_AXI_AWVALID(S_AXI_AWVALID),
       .S_AXI_AWREADY(S_AXI_AWREADY),
       .S_AXI_WDATA(S_AXI_WDATA),
       .S_AXI_WSTRB(S_AXI_WSTRB),
       .S_AXI_WVALID(S_AXI_WVALID),
       .S_AXI_WREADY(S_AXI_WREADY),
       .S_AXI_BRESP(S_AXI_BRESP),
       .S_AXI_BVALID(S_AXI_BVALID),
       .S_AXI_BREADY(S_AXI_BREADY),
       .S_AXI_ARADDR(S_AXI_ARADDR),
       .S_AXI_ARPROT(S_AXI_ARPROT),
       .S_AXI_ARVALID(S_AXI_ARVALID),
       .S_AXI_ARREADY(S_AXI_ARREADY),
       .S_AXI_RDATA(S_AXI_RDATA),
       .S_AXI_RRESP(S_AXI_RRESP),
       .S_AXI_RVALID(S_AXI_RVALID),
       .S_AXI_RREADY(S_AXI_RREADY)
	);

    wire  mirrorv = mapper_config[0];
    assign  cart_init = mapper_config[31];

    assign ciram_a10 = mirrorv ? ppu_addr[10] : ppu_addr[11];
    assign ciram_ce = ppu_addr[13];
    assign irq = 0;
    wire chr_cs = ~ciram_ce;

    (* mark_debug = "true" *)  logic [7:0] PRG_rd;
    (* mark_debug = "true" *)  logic [7:0] CHR_rd;

    (* mark_debug = "true" *)  logic [CHR_WIDTH-1:0] chr_addr;
    (* mark_debug = "true" *)  logic chr_en;
    assign chr_en = chr_cs && !cart_init;
    generate
        if (CHR_WIDTH<=14)
            assign chr_addr = CHR_mask[CHR_WIDTH-1:0] & ppu_addr[CHR_WIDTH-1:0];
        else
            assign chr_addr = CHR_mask[CHR_WIDTH-1:0] & { {(CHR_WIDTH-14){1'b0}} ,ppu_addr};
    endgenerate

    (* mark_debug = "true" *)  logic [PRG_WIDTH-1:0] prg_addr;
    (* mark_debug = "true" *)  logic prg_en;
    assign prg_en = romsel && !cart_init;
    generate
        if (PRG_WIDTH<=15)
            assign prg_addr = PRG_mask[PRG_WIDTH-1:0] & cpu_addr[PRG_WIDTH-1:0];
        else
            assign prg_addr = PRG_mask[PRG_WIDTH-1:0] & { {(PRG_WIDTH-15){1'b0}} ,cpu_addr};
    endgenerate

    cart_mem_dual #(
        .ADDR_WIDTHA(CHR_WIDTH),
        .MEM_FILE(CHR_FILE)
    ) u_chr_ram
    (
    //NES
    .clkA   (clk_ppu),
    .enaA   (chr_en),
    .weA    (0),
    .addrA  (chr_addr),
    .dinA   (0),
    .doutA  (CHR_rd),
    //AXI
    .clkB   (BRAM_CHR_clk),
    .enaB   (BRAM_CHR_en),
    .weB    (BRAM_CHR_we),
    .addrB  (BRAM_CHR_addr[CHR_WIDTH-1:2]),
    .dinB   (BRAM_CHR_wr),
    .doutB  (BRAM_CHR_rd)
    );


    cart_mem_dual #(
        .ADDR_WIDTHA(PRG_WIDTH),
        .MEM_FILE(PRG_FILE)
    ) u_prg_ram
    (
    //NES
    .clkA   (clk_cpu),
    .enaA   (prg_en),
    .weA    (0),
    .addrA  (prg_addr),
    .dinA   (0),
    .doutA  (PRG_rd),
    //AXI
    .clkB   (BRAM_PRG_clk),
    .enaB   (BRAM_PRG_en),
    .weB    (BRAM_PRG_we),
    .addrB  (BRAM_PRG_addr[PRG_WIDTH-1:2]),
    .dinB   (BRAM_PRG_wr),
    .doutB  (BRAM_PRG_rd)
    );

    assign BRAM_PRGRAM_rd = 0;


    logic romsel_r, chr_cs_r;
    always @(posedge clk_cpu) begin
        romsel_r <= romsel;
    end
    always @(posedge clk_ppu) begin
        chr_cs_r <= chr_cs;
    end

    always_comb begin
        cpu_data_o = romsel_r ? PRG_rd : 0;
        ppu_data_o = chr_cs_r ? CHR_rd : 0;
    end

endmodule
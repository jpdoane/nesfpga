`timescale 1ns/1ps

module cart_top
#(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 6
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

    wire [31:0] mapper_config;
    wire [31:0] CHR_mask;
    wire [31:0] PRG_mask;
    wire [31:0] PRGRAM_mask;

	axi_cart_regs
	#(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
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
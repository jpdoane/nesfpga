`timescale 1ns/1ps

module cart_multimapper
#(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 6,

    parameter integer CHR_WIDTH = 17,       //128kb
    parameter integer PRG_WIDTH = 18,       //256kb
    parameter integer PRGRAM_WIDTH = 13,

    parameter NES_HEADER = 64'h0,
    parameter NES_PRG_FILE = "",
    parameter NES_SAV_FILE = "",
    parameter NES_CHR_FILE = ""    
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

    input logic [7:0] ctrl1_state,
    input logic [7:0] ctrl2_state,
    output logic nes_reset,

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

    // cart/mapper config from ines header
    logic [63:0] ines_header;
    wire [7:0] prg_16k_chunks = ines_header[7:0];
    wire [7:0] chr_8k_chunks = ines_header[15:8];
    wire [1:0] mirroring = {ines_header[19], ines_header[16]};
    wire batt = ines_header[17];
    wire [7:0] mapper = {ines_header[31:28], ines_header[23:20]};
    wire  chr_ram = chr_8k_chunks==0;
    wire  prg_ram = 1;

    logic [CHR_WIDTH-1:0] CHR_mask;
    logic [PRG_WIDTH-1:0] PRG_mask;
    always_comb begin
        CHR_mask = CHR_WIDTH'( 13'h1fff ); // default 8k
        // here we are assuming the memory will always be a power of 2
        if(chr_8k_chunks[1]) CHR_mask = CHR_WIDTH'( {14{1'b1}} ); //chr_8k_chunks = 2
        if(chr_8k_chunks[2]) CHR_mask = CHR_WIDTH'( {15{1'b1}} ); //chr_8k_chunks = 4
        if(chr_8k_chunks[3]) CHR_mask = CHR_WIDTH'( {16{1'b1}} ); //chr_8k_chunks = 8
        if(chr_8k_chunks[4]) CHR_mask = CHR_WIDTH'( {17{1'b1}} ); //chr_8k_chunks = 16
        if(chr_8k_chunks[5]) CHR_mask = CHR_WIDTH'( {18{1'b1}} ); //chr_8k_chunks = 32
        if(chr_8k_chunks[6]) CHR_mask = CHR_WIDTH'( {19{1'b1}} ); //chr_8k_chunks = 64
        if(chr_8k_chunks[7]) CHR_mask = CHR_WIDTH'( {20{1'b1}} ); //chr_8k_chunks = 128

        PRG_mask = PRG_WIDTH'( 14'h3fff ); // default 16k
        // here we are assuming the memory will always be a power of 2
        if(prg_16k_chunks[1]) PRG_mask = PRG_WIDTH'( {15{1'b1}} );
        if(prg_16k_chunks[2]) PRG_mask = PRG_WIDTH'( {16{1'b1}} );
        if(prg_16k_chunks[3]) PRG_mask = PRG_WIDTH'( {17{1'b1}} );
        if(prg_16k_chunks[4]) PRG_mask = PRG_WIDTH'( {18{1'b1}} );
        if(prg_16k_chunks[5]) PRG_mask = PRG_WIDTH'( {19{1'b1}} );
        if(prg_16k_chunks[6]) PRG_mask = PRG_WIDTH'( {20{1'b1}} );
        if(prg_16k_chunks[7]) PRG_mask = PRG_WIDTH'( {21{1'b1}} );
    end
    wire [PRGRAM_WIDTH-1:0] PRGRAM_mask = PRGRAM_WIDTH'(13'h1fff); // always 8k (for ines 1.0)

	axi_cart_regs
	#(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .default_ines_header(NES_HEADER)
	)
	u_axi_cart_regs (
		.nes_reset(nes_reset),
		.ines_header(ines_header),
		.ctrl1_state(ctrl1_state),
		.ctrl2_state(ctrl2_state),
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


    // mapper ouputs
    logic [PRG_WIDTH-1:0] prg_addr;
    logic [CHR_WIDTH-1:0] chr_addr;
    (* mark_debug = "true" *)  logic [PRGRAM_WIDTH-1:0] prgram_addr;
    logic prg_cs;
    logic chr_cs;
    logic prgram_cs;
    logic [7:0] mapper_reg_o;

    logic ciram_ce_mapbank;
    logic ciram_a10_mapbank;
    logic irq_mapbank;
    logic [PRG_WIDTH-1:0] prg_addr_mapbank;
    logic [CHR_WIDTH-1:0] chr_addr_mapbank;
    logic [PRGRAM_WIDTH-1:0] prgram_addr_mapbank;
    logic prg_cs_mapbank;
    logic chr_cs_mapbank;
    logic prgram_cs_mapbank;
    logic [7:0] mapper_reg_o_mapbank;

    logic ciram_ce_map1;
    logic ciram_a10_map1;
    logic irq_map1;
    logic [PRG_WIDTH-1:0] prg_addr_map1;
    logic [CHR_WIDTH-1:0] chr_addr_map1;
    logic [PRGRAM_WIDTH-1:0] prgram_addr_map1;
    logic prg_cs_map1;
    logic chr_cs_map1;
    logic prgram_cs_map1;
    logic [7:0] mapper_reg_o_map1;

    logic ciram_ce_map4;
    logic ciram_a10_map4;
    logic irq_map4;
    logic [PRG_WIDTH-1:0] prg_addr_map4;
    logic [CHR_WIDTH-1:0] chr_addr_map4;
    logic [PRGRAM_WIDTH-1:0] prgram_addr_map4;
    logic prg_cs_map4;
    logic chr_cs_map4;
    logic prgram_cs_map4;
    logic [7:0] mapper_reg_o_map4;

    /* verilator lint_off CASEOVERLAP */
    always_comb begin
        casez(mapper)
            8'h1:   begin
                    ciram_ce = ciram_ce_map1;
                    ciram_a10 = ciram_a10_map1;
                    irq = irq_map1;
                    prg_addr = prg_addr_map1;
                    chr_addr = chr_addr_map1;
                    prgram_addr = prgram_addr_map1;
                    prg_cs = prg_cs_map1;
                    chr_cs = chr_cs_map1;
                    prgram_cs = prgram_cs_map1;
                    mapper_reg_o = mapper_reg_o_map1;
                    end
            8'b000000??:   begin //mapper 0,2,3 (not 1 which is handled above)
                    ciram_ce = ciram_ce_mapbank;
                    ciram_a10 = ciram_a10_mapbank;
                    irq = irq_mapbank;
                    prg_addr = prg_addr_mapbank;
                    chr_addr = chr_addr_mapbank;
                    prgram_addr = prgram_addr_mapbank;
                    prg_cs = prg_cs_mapbank;
                    chr_cs = chr_cs_mapbank;
                    prgram_cs = prgram_cs_mapbank;
                    mapper_reg_o = mapper_reg_o_mapbank;
                    end
            8'b00000100:   begin //mapper 4
                    ciram_ce = ciram_ce_map4;
                    ciram_a10 = ciram_a10_map4;
                    irq = irq_map4;
                    prg_addr = prg_addr_map4;
                    chr_addr = chr_addr_map4;
                    prgram_addr = prgram_addr_map4;
                    prg_cs = prg_cs_map4;
                    chr_cs = chr_cs_map4;
                    prgram_cs = prgram_cs_map4;
                    mapper_reg_o = mapper_reg_o_map4;
                    end

            default: begin
                    ciram_ce = 0;
                    ciram_a10 = 0;
                    irq = 0;
                    prg_addr = 0;
                    chr_addr = 0;
                    prgram_addr = 0;
                    prg_cs = 0;
                    chr_cs = 0;
                    prgram_cs = 0;
                    mapper_reg_o = 0;
                    end
        endcase
    end
    /* verilator lint_on CASEOVERLAP */

    mapper_bank #(
    .PRG_ROM_DEPTH(PRG_WIDTH),
    .CHR_ROM_DEPTH(CHR_WIDTH),
    .PRG_RAM_DEPTH(PRGRAM_WIDTH)
    ) u_mapper_bank (
    .rst            (rst),
    .clk_cpu        (clk_cpu),
    .mapper_id      (mapper),
    .cpu_addr       (cpu_addr),
    .cpu_data_i     (cpu_data_i),
    .ppu_addr       (ppu_addr),
    .cpu_rw         (cpu_rw),
    .romsel         (romsel),
    .mirrorv        (mirroring[0]),
    .chr_ram        (chr_ram),
    .prg_ram        (prg_ram),
    .prg_mask       (PRG_mask),
    .chr_mask       (CHR_mask),
    .prgram_mask    (PRGRAM_mask),
    .prg_addr       (prg_addr_mapbank),
    .chr_addr       (chr_addr_mapbank),
    .prgram_addr    (prgram_addr_mapbank),
    .prg_cs         (prg_cs_mapbank),
    .chr_cs         (chr_cs_mapbank),
    .prgram_cs      (prgram_cs_mapbank),
    .mapper_reg_o   (mapper_reg_o_mapbank),
    .ciram_ce       (ciram_ce_mapbank),
    .ciram_a10      (ciram_a10_mapbank),
    .irq            (irq_mapbank)
    );

    mapper_001 #(
    .PRG_ROM_DEPTH(PRG_WIDTH),
    .CHR_ROM_DEPTH(CHR_WIDTH),
    .PRG_RAM_DEPTH(PRGRAM_WIDTH)
    ) u_mapper_001 (
    .rst            (rst),
    .clk_cpu        (clk_cpu),
    .cpu_addr       (cpu_addr),
    .cpu_data_i     (cpu_data_i),
    .ppu_addr       (ppu_addr),
    .cpu_rw         (cpu_rw),
    .romsel         (romsel),
    .mirrorv        (mirroring[0]),
    .chr_ram        (chr_ram),
    .prg_ram        (prg_ram),
    .prg_mask       (PRG_mask),
    .chr_mask       (CHR_mask),
    .prgram_mask    (PRGRAM_mask),
    .prg_addr       (prg_addr_map1),
    .chr_addr       (chr_addr_map1),
    .prgram_addr    (prgram_addr_map1),
    .prg_cs         (prg_cs_map1),
    .chr_cs         (chr_cs_map1),
    .prgram_cs      (prgram_cs_map1),
    .mapper_reg_o   (mapper_reg_o_map1),
    .ciram_ce       (ciram_ce_map1),
    .ciram_a10      (ciram_a10_map1),
    .irq            (irq_map1)
    );

    mapper_004 #(
    .PRG_ROM_DEPTH(PRG_WIDTH),
    .CHR_ROM_DEPTH(CHR_WIDTH),
    .PRG_RAM_DEPTH(PRGRAM_WIDTH)
    ) u_mapper_004 (
    .rst            (rst),
    .clk_cpu        (clk_cpu),
    .m2             (m2),
    .clk_ppu        (clk_ppu),
    .cpu_addr       (cpu_addr),
    .cpu_data_i     (cpu_data_i),
    .ppu_addr       (ppu_addr),
    .cpu_rw         (cpu_rw),
    .romsel         (romsel),
    .mirroring        (mirroring),
    .chr_ram        (chr_ram),
    .prg_ram        (prg_ram),
    .prg_mask       (PRG_mask),
    .chr_mask       (CHR_mask),
    .prgram_mask    (PRGRAM_mask),
    .prg_addr       (prg_addr_map4),
    .chr_addr       (chr_addr_map4),
    .prgram_addr    (prgram_addr_map4),
    .prg_cs         (prg_cs_map4),
    .chr_cs         (chr_cs_map4),
    .prgram_cs      (prgram_cs_map4),
    .mapper_reg_o   (mapper_reg_o_map4),
    .ciram_ce       (ciram_ce_map4),
    .ciram_a10      (ciram_a10_map4),
    .irq            (irq_map4)
    );

    (* mark_debug = "true" *)  logic [7:0] PRG_rd;
    (* mark_debug = "true" *)  logic [7:0] PRGRAM_rd;
    (* mark_debug = "true" *)  logic [7:0] CHR_rd;

    wire prg_en = prg_cs && !nes_reset;
    wire chr_en = chr_cs && !nes_reset;
    (* mark_debug = "true" *)  wire prgram_en = prg_ram && prgram_cs && !nes_reset;

    wire chr_wr = chr_en && ppu_wr && chr_ram;
    wire prgram_wr = prgram_en && !cpu_rw;

    cart_mem_dual #(
        .ADDR_WIDTHA(CHR_WIDTH),
        .MEM_FILE(NES_CHR_FILE)
    ) u_chr
    (
    //NES
    .clkA   (clk_ppu),
    .enaA   (chr_en),
    .weA    (chr_wr),
    .addrA  (chr_addr),
    .dinA   (ppu_data_i),
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
        .MEM_FILE(NES_PRG_FILE)
    ) u_prg
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

    cart_mem_dual #(
        .ADDR_WIDTHA(PRGRAM_WIDTH),
        .MEM_FILE(NES_SAV_FILE)
    ) u_prgram
    (
    //NES
    .clkA   (clk_cpu),
    .enaA   (prgram_en),
    .weA    (prgram_wr),
    .addrA  (prgram_addr),
    .dinA   (cpu_data_i),
    .doutA  (PRGRAM_rd),
    //AXI
    .clkB   (BRAM_PRGRAM_clk),
    .enaB   (BRAM_PRGRAM_en),
    .weB    (BRAM_PRGRAM_we),
    .addrB  (BRAM_PRGRAM_addr[PRGRAM_WIDTH-1:2]),
    .dinB   (BRAM_PRGRAM_wr),
    .doutB  (BRAM_PRGRAM_rd)
    );

    logic prg_cs_r, prgram_cs_r, chr_cs_r;
    always @(posedge clk_cpu) begin
        prg_cs_r <= prg_cs;
        prgram_cs_r <= prgram_cs;
    end
    always @(posedge clk_ppu) begin
        chr_cs_r <= chr_cs;
    end

    always_comb begin
        cpu_data_o = prg_cs_r ? PRG_rd :
                     prgram_cs_r ? PRGRAM_rd : mapper_reg_o;
        ppu_data_o = chr_cs_r ? CHR_rd : 0;
    end

endmodule
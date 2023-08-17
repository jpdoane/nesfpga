`timescale 1ns/1ps

module ppu_bus #(
        parameter MIRRORV=1,
        parameter CHR_INIT={`ROM_PATH,"CHR.mem"},
        parameter VRAM_INIT=""
    )(
    input logic clk, rst,
    input logic [13:0] addr,
    input logic rw,
    input logic [7:0] data_i,
    output logic [7:0] data_o
    );

    logic [7:0] CHR  [0:2**CHR_DEPTH-1];
    logic [7:0] VRAM [0:2**VRAM_DEPTH-1];

`ifdef RESET_RAM
        initial begin
            $display("Clearing PPU VRAM...");
            for(int j = 0; j < 2**VRAM_DEPTH; j = j+1)  VRAM[j] = 8'h0;
        end
`endif

    integer file, cnt;
    // string chr_file = string(CHR_INIT);
    // string vram_file = string(VRAM_INIT);
    initial begin
        // if (chr_file.len() > 0) begin
            $display("Loading CHR memory: %s ", CHR_INIT);
            $readmemh(CHR_INIT, CHR);
        // end
        // if (vram_file.len() > 0) begin
        //     $display("Loading VRAM memory: %s ", vram_file);
        //     $readmemh(VRAM_INIT, VRAM);
        // end
    end

    logic [7:0] v_data, c_data;

    logic cs, cs_r;                         // chip select, 1:CHR, 0:VRAM

    logic [CHR_DEPTH-1:0] chr_addr;
    assign cs = ~addr[13]; 
    assign chr_addr = addr[CHR_DEPTH-1:0];

    logic vram_topbit;
    logic [VRAM_DEPTH-1:0] vram_addr;
    assign vram_topbit = MIRRORV ? addr[VRAM_DEPTH-1] : addr[VRAM_DEPTH];
    assign vram_addr = {vram_topbit, addr[VRAM_DEPTH-2:0]};

    // VRAM mapping and mirroring:
    // Vertical mirroring: $2000 equals $2800 and $2400 equals $2C00 (e.g. Super Mario Bros.)
        // 14'h2000 = 14'h2800 = 14'b10_X000_0000_0000
        // 14'h2400 = 14'h2C00 = 14'b10_X100_0000_0000
    // Horizontal mirroring: $2000 equals $2400 and $2800 equals $2C00 (e.g. Kid Icarus)
        // 14'h2000 = 14'h2400 = 14'b10_0X00_0000_0000
        // 14'h2*00 = 14'h2C00 = 14'b10_1X00_0000_0000
    // One-screen mirroring: All nametables refer to the same memory at any given time, and the mapper directly manipulates CIRAM address bit 10 (e.g. many Rare games using AxROM)
        // 14'h2000 = 14'h2400 = 14'h2800 = 14'h2C00 =14'b10_XX00_0000_0000
    // Four-screen mirroring: CIRAM is disabled, and the cartridge contains additional VRAM used for all nametables (e.g. Gauntlet, Rad Racer 2)
    // Other: Some advanced mappers can present arbitrary combinations of CIRAM, VRAM, or even CHR ROM in the nametable area. Such exotic setups are rarely used.

    //CHR
    always @(posedge clk) begin
        c_data <= CHR[chr_addr];
        // if (cs && ~rw) CHR[chr_addr] <= data_i;
        cs_r <= cs;
    end

    //VRAM
    always @(posedge clk) begin
        v_data <= VRAM[vram_addr];
        if (~cs && ~rw) VRAM[vram_addr] <= data_i;
    end

    // final mux
    always_comb begin
        data_o = cs_r ? c_data : v_data;
    end

endmodule
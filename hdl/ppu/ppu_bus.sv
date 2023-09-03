`timescale 1ns/1ps

module ppu_bus #(
        parameter VRAM_DEPTH=11
    )(
    input logic clk, rst,
    input logic [13:0] addr,
    input logic rd, wr,
    input logic vram_cs, vram_a10,
    input logic [7:0] ppu_data_i,
    input logic [7:0] cart_data_i,
    output logic [7:0] data_o
    );

    logic [7:0] vram [0:2**VRAM_DEPTH-1];
`ifdef RESET_RAM
        initial begin
            $display("Clearing PPU VRAM...");
            for(int j = 0; j < 2**VRAM_DEPTH; j = j+1)  vram[j] = 8'h0;
        end
`endif
`ifdef VRAM_FILE
        initial begin
            $display("Initializing PPU VRAM: %s", `VRAM_FILE);
            $readmemh(VRAM_FILE, vram);
        end
`endif
`ifdef SAVERAMS
        final begin
            $display("Saving PPU VRAM");
            $writememh("logs/vram.mem", vram);
        end
`endif

    wire [VRAM_DEPTH-1:0] vram_addr = {vram_a10, addr[VRAM_DEPTH-2:0]};
    logic [7:0] vram_data_rd;
    always @(posedge clk) begin
        if (vram_cs) begin
            if (wr) vram[vram_addr] <= ppu_data_i;
            else vram_data_rd <= vram[vram_addr];
        end
    end

    logic vram_cs_r;
    always @(posedge clk) vram_cs_r <= vram_cs;

    // output mux
    assign data_o = vram_cs_r ? vram_data_rd : cart_data_i;

endmodule
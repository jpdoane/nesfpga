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

    wire [VRAM_DEPTH-1:0] vram_addr = {vram_a10, addr[VRAM_DEPTH-2:0]};

    always @(posedge clk) begin
        if (vram_cs && wr) vram[vram_addr] <= ppu_data_i;
    end
    wire [7:0] vram_data_rd = vram[vram_addr];

    // output mux
    logic [7:0] data_mux;
    always @(posedge clk) begin
        if (rst)
            data_mux <= 0;
        else begin
            if (wr)             data_mux <= ppu_data_i;
            else if (vram_cs)   data_mux <= vram_data_rd;
            else                data_mux <= cart_data_i;
        end
    end
    assign data_o = data_mux;

endmodule
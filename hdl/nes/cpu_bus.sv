`timescale 1ns/1ps

module cpu_bus (
    input logic clk, rst, rw,
    input logic [15:0] bus_addr,
    input logic [7:0] cpu_data_i,
    input logic [7:0] ppu_data_i,
    input logic [7:0] cart_data_i,
    output logic [7:0] data_o,
    output logic ppu_cs,
    output logic rom_cs
    );

    // CPU internal RAM: 0x0000-0x07ff mirrored up to 0x1fff
    wire ram_cs                 = (bus_addr & 16'he000) == 16'h0000;
    wire [10:0] ram_cpu_addr    = bus_addr[10:0];

    // PPU registers: 0x2000-0x2007 mirrored up to 0x3fff
    assign ppu_cs               = (bus_addr & 16'he000) == 16'h2000;

    // PRG ROM: 0x8000-0xffff
    assign rom_cs               = (bus_addr & 16'h8000) == 16'h8000;

    // internal RAM
    logic [7:0] ram [0:2047];
    logic [7:0] ram_data_rd;
    always @(posedge clk) begin
        if (ram_cs) begin
            if (!rw) ram[ram_cpu_addr] <= cpu_data_i;
            else ram_data_rd <= ram[ram_cpu_addr];
        end
    end

`ifdef RESET_RAM
        initial begin
            $display("Clearing CPU RAM...");
            for(int j = 0; j < 2048; j = j+1)  ram[j] = 8'h0;
        end
`endif
`ifdef RAM_FILE
        initial begin
            $display("Initializing CPU RAM: %s", `RAM_FILE);
            $readmemh(RAM_FILE, ram);
        end
`endif
`ifdef SAVERAMS
        final begin
            $display("Saving CPU VRAM");
            $writememh("logs/ram.mem", ram);
        end
`endif

    logic ram_cs_r, cart_cs_r, ppu_cs_r;
    logic [7:0] ppu_data_reg;
    always @(posedge clk) begin
        ram_cs_r <= ram_cs;
        cart_cs_r <= rom_cs;
        ppu_cs_r <= ppu_cs;
        ppu_data_reg <= ppu_data_i;
    end

    // output mux
    logic [7:0] data_mux;
    always_comb begin
        if (ram_cs_r)       data_mux = ram_data_rd;
        else if (cart_cs_r) data_mux = cart_data_i;
        else if (ppu_cs_r)  data_mux = ppu_data_reg;
        else                data_mux = 0;
    end
    assign data_o = data_mux;

endmodule
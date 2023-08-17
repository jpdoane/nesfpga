`timescale 1ns/1ps

module cpu_bus #(
        parameter PRG_ROM={`ROM_PATH,"PRG.mem"}
    )(
    input logic clk, rst, rw,
    input logic [15:0] bus_addr_i,
    input logic [7:0] cpu_data_i,
    input logic [7:0] ppu_data_i,
    output logic [7:0] bus_data_o,
    output logic ppu_cs
    );

    // CPU internal RAM: 0x0000-0x07ff mirrored up to 0x1fff
    wire ram_cs                 = (bus_addr_i & 16'he000) == 16'h0000;
    wire [10:0] ram_cpu_addr    = bus_addr_i[10:0];

    // PPU registers: 0x2000-0x2007 mirrored up to 0x3fff
    // implemented externally
    assign ppu_cs               = (bus_addr_i & 16'he000) == 16'h2000;

    // CPU/APU register space 0x4000-0x401f
    // implemented internally to apu

    // Cartrage space: 0x4020-0x7fff (mappers and stuff...)

    // PRG ROM: 0x8000-0xffff
    wire prg_cs                 = (bus_addr_i & 16'h8000) == 16'h8000;
    wire [14:0] prg_cpu_addr    = bus_addr_i[14:0];

    // internal RAM
    logic [7:0] RAM [0:2047];
    always @(posedge clk) begin
        if (ram_cs && !rw)
            RAM[ram_cpu_addr] <= cpu_data_i;
    end
    wire [7:0] ram_data_rd = RAM[ram_cpu_addr];

`ifdef RESET_RAM
        initial begin
            $display("Clearing CPU RAM...");
            for(int j = 0; j < 2048; j = j+1)  RAM[j] = 8'h0;
        end
`endif

    // PRG ROM
    logic [7:0] PRG[0:32767];
    initial begin
        $display("Loading PRG ROM: %s", PRG_ROM);
        $readmemh(PRG_ROM, PRG);
    end
    wire [7:0] prg_data_rd = PRG[prg_cpu_addr];

    // output mux
    logic [7:0] data_mux;
    always @(posedge clk) begin
        if (rst)
            data_mux <= 0;
        else begin
            data_mux <= 0;
            if (ram_cs)         data_mux <= ram_data_rd;
            else if (prg_cs)    data_mux <= prg_data_rd;
            else if (ppu_cs)    data_mux <= ppu_data_i;
        end
    end
    assign bus_data_o = data_mux;

endmodule
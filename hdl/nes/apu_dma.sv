`timescale 1ns/1ps

module apu_dma (
    input logic clk, rst,
    input logic apu_cycle,
    input logic rw_i,
    input logic [15:0] cpu_addr_i,
    input logic [7:0] cpu_data_i,
    input logic [7:0] bus_data_i,
    output logic [15:0] cpu_addr_o,
    output logic [7:0] cpu_data_o,
    output logic rw_o,
    output logic halt,

    input logic dmc_dma_req,
    output logic dmc_dma_active,
    input logic [15:0] dmc_dma_address    
    );

    // dma control of bus
    logic oam_dma_req, oam_dma_rw;
    logic [15:0] oam_dma_address;
    // dma cannot halt cpu on write cycle. DMC dma takes precidence over OAM
    assign dmc_dma_active = dmc_dma_req && rw_i;
    wire oam_dma_active = oam_dma_req && rw_i && !dmc_dma_req;
    assign halt = dmc_dma_active || oam_dma_active;

    oam_dma  u_oam_dma(
    .clk            (clk),
    .rst            (rst),
    .apu_cycle      (apu_cycle),
    .rw_i           (rw_i),
    .cpu_addr_i     (cpu_addr_i),
    .cpu_data_i     (cpu_data_i),
    .bus_data_i     (bus_data_i),
    .cpu_data_o     (cpu_data_o),
    .dma_req        (oam_dma_req),
    .dma_active     (oam_dma_active),
    .dma_address    (oam_dma_address),
    .dma_rw         (oam_dma_rw)
    );

    always_comb begin
        cpu_addr_o = cpu_addr_i;
        cpu_data_o = cpu_data_i;
        rw_o = rw_i;
        if (dmc_dma_active) begin
            cpu_addr_o = dmc_dma_address;
            rw_o = 1;
        end else if (oam_dma_active) begin
            cpu_addr_o = oam_dma_address;
            cpu_data_o = bus_data_i;
            rw_o = oam_dma_rw;
        end
    end

endmodule

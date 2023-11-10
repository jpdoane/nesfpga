`timescale 1ns/1ps

module oam_dma (
    input logic clk, rst,
    input logic apu_cycle,
    input logic rw_i,
    input logic [15:0] cpu_addr_i,
    input logic [7:0] cpu_data_i,
    input logic [7:0] bus_data_i,
    output logic [7:0] cpu_data_o,
    // dma
    output logic dma_req,
    input logic dma_active,
    output logic [15:0] dma_address,
    output logic dma_rw
    );

    localparam OAMDMA=16'h4014;
    localparam OAMDATA=16'h2004;
 

    wire read_cycle = apu_cycle;

    logic [7:0] dma_page;
    logic [7:0] dma_cnt;

    logic [1:0] state, next_state;
    logic init_dma, inc_cnt;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= DMA_IDLE;
            dma_page <= 0;
            dma_cnt <= 0;
        end else begin
            state <= next_state;
            dma_page <= init_dma ? cpu_data_i : dma_page;
            dma_cnt <= init_dma ? 0 : inc_cnt ? dma_cnt + 1 : dma_cnt;
        end
    end

    localparam DMA_IDLE=2'h0;
    localparam DMA_STALL=2'h1;
    localparam DMA_ACTIVE=2'h2;

    always_comb begin
        next_state = DMA_IDLE;
        init_dma = 0;
        cpu_data_o = cpu_data_i;
        dma_rw = rw_i;
        inc_cnt = 0;
        dma_req = 0;
        dma_address = 0;
        case(state)
            DMA_IDLE:   begin
                        if (cpu_addr_i == OAMDMA && !rw_i) begin 
                            init_dma = 1;
                            next_state = read_cycle ? DMA_STALL : DMA_ACTIVE;
                            dma_req=1;
                        end else next_state = DMA_IDLE;
                        end
            DMA_STALL:  begin
                        next_state = DMA_ACTIVE;    // extra cycle so we start on read
                        dma_req=1;
                        end
            DMA_ACTIVE: begin
                        dma_address = read_cycle ? {dma_page, dma_cnt} : OAMDATA;
                        dma_req=1;
                        cpu_data_o = bus_data_i;    // read byte from mem, write to oam 
                        dma_rw = read_cycle;
                        inc_cnt = ~read_cycle;
                        next_state = (dma_cnt==8'hff && ~read_cycle) ? DMA_IDLE : DMA_ACTIVE;
                        end
            default:    begin end
        endcase
    end


endmodule

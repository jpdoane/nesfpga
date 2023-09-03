`timescale 1ns/1ps

module oam_dma (
    input logic clk, rst,
    input logic rw_i,
    input logic [15:0] cpu_addr_i,
    input logic [7:0] cpu_data_i,
    input logic [7:0] bus_data_i,
    output logic [15:0] cpu_addr_o,
    output logic [7:0] cpu_data_o,
    output logic rw_o,
    output logic dma_en
    );

    localparam OAMDMA=16'h4014;
    localparam OAMDATA=16'h2004;
 

    logic [7:0] dma_page;
    logic [7:0] dma_cnt;
    wire [15:0] dma_addr = {dma_page, dma_cnt};

    logic [1:0] state, next_state;
    logic init_dma, inc_cnt;

    logic read_cycle;
    always_ff @(posedge clk) begin
        if(rst) begin
            state <= DMA_IDLE;
            dma_page <= 0;
            dma_cnt <= 0;
            read_cycle <= 0;
        end else begin
            read_cycle <= ~read_cycle;
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
        cpu_addr_o = cpu_addr_i;
        cpu_data_o = cpu_data_i;
        rw_o = rw_i;
        inc_cnt = 0;
        dma_en = 0;
        case(state)
            DMA_IDLE:   begin
                        if (cpu_addr_i == OAMDMA && !rw_i) begin 
                            init_dma = 1;
                            next_state = read_cycle ? DMA_STALL : DMA_ACTIVE;
                            dma_en=1;
                        end else next_state = DMA_IDLE;
                        end
            DMA_STALL:  begin
                        next_state = DMA_ACTIVE;    // extra cycle so we start on read
                        dma_en=1;
                        end
            DMA_ACTIVE: begin
                        dma_en=1;
                        cpu_addr_o = read_cycle ? dma_addr : OAMDATA;
                        cpu_data_o = bus_data_i;    // read byte from mem, write to oam 
                        rw_o = read_cycle;
                        inc_cnt = ~read_cycle;
                        next_state = (dma_cnt==8'hff && ~read_cycle) ? DMA_IDLE : DMA_ACTIVE;
                        end
            default:    begin end
        endcase
    end


endmodule

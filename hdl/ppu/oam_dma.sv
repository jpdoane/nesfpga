
module oam_dma #(
    parameter OAMDMA_ADDR=16'h4014,
    parameter OAMDATA_ADDR=16'h2004
    )(
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

    logic [7:0] dma_page;
    logic [7:0] dma_cnt;
    wire [15:0] dma_addr = {dma_page, dma_cnt};

    logic [1:0] state, next_state;
    logic init_dma, inc_cnt;

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= DMA_WAIT;
            dma_page <= 0;
            dma_cnt <= 0;
        end else begin
            state <= next_state;
            dma_page <= init_dma ? cpu_data_i : dma_page;
            dma_cnt <= init_dma ? 0 : inc_cnt ? dma_cnt + 1 : dma_cnt;
        end
    end

    localparam DMA_WAIT=2'h0;
    localparam DMA_READ=2'h1;
    localparam DMA_WRITE=2'h2;

    always_comb begin
        next_state = DMA_WAIT;
        init_dma = 0;
        cpu_addr_o = cpu_addr_i;
        cpu_data_o = cpu_data_i;
        rw_o = rw_i;
        inc_cnt = 0;
        dma_en = 0;
        case(state)
            DMA_WAIT:   begin
                        if (cpu_addr_i == OAMDMA_ADDR && !rw_i) begin 
                            init_dma = 1;
                            next_state = DMA_READ;
                            dma_en=1;
                        end else next_state = DMA_WAIT;
                        end
            DMA_READ:   begin
                            next_state = DMA_WRITE;
                            dma_en=1;
                            cpu_addr_o = dma_addr;
                            rw_o = 1;
                        end
            DMA_WRITE:  begin
                        dma_en=1;
                        next_state = DMA_READ;
                        cpu_addr_o = OAMDATA_ADDR;
                        cpu_data_o = bus_data_i;    // read byte from mem, write to oam 
                        rw_o = 0;
                        inc_cnt = 1;
                        next_state = dma_cnt==8'hff ? DMA_WAIT : DMA_READ;
                        end
        endcase
    end


endmodule

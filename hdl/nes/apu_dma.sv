`timescale 1ns/1ps

module apu_dma
    (
    input logic clk, rst,
    input logic apu_cycle,
    input logic rw_i,
    input logic [15:0] cpu_addr_i,
    input logic [7:0] cpu_data_i,
    input logic [7:0] bus_data_i,
    output logic [7:0] cpu_data_o,
    output logic [15:0] cpu_addr_o,
    output logic rw_o,
    output logic halt,

    // oam dma
    input logic oam_init,

    // dmc dma
    input logic dmc_addr_wr,
    input logic dmc_init,
    input logic dmc_req,
    output logic dmc_read
    );

    localparam IDLE=2'h0;
    localparam STALL=2'h1;
    localparam FETCH=2'h2;
    localparam COPY=2'h3;
 
    localparam OAMDATA=16'h2004; // ppu address to copy oam data to
 
    // dmc dma engine
    logic [7:0] dmc_addr_reg;
    logic [14:0] dmc_address_short;
    wire [15:0] dmc_address = {1'b1, dmc_address_short};

    logic [1:0] dmc_state, dmc_next;
    always_ff @(posedge clk) begin
        if(rst) begin
            dmc_addr_reg <= 0;
            dmc_address_short <= 0;
            dmc_state <= IDLE;
        end else begin
            if(dmc_addr_wr) dmc_addr_reg <= cpu_data_i;

            if(dmc_init) dmc_address_short <= {1'b1, dmc_addr_reg, 6'b0};
            else if(dmc_fetch) dmc_address_short <= dmc_address_short+1;

            dmc_state <= dmc_next;
        end
    end

    logic dmc_fetch, dmc_block, dmc_active;
    always_comb begin
        dmc_next = IDLE;
        dmc_fetch = 0;
        dmc_block = 0;
        dmc_read = 0;
        dmc_active = 0;
        case(dmc_state)
            IDLE:   begin
                        dmc_next = dmc_req ? STALL : IDLE;
                    end
            STALL:  begin
                        dmc_active = 1;
                        if (rw_i && apu_cycle) begin
                            dmc_next = FETCH;
                            dmc_block = 1;
                        end
                        else dmc_next = STALL;
                    end
            FETCH:  begin
                        dmc_active = 1;
                        dmc_fetch=1;
                        dmc_next = COPY;
                    end
            COPY:  begin
                        dmc_active = 1;
                        dmc_read=1;
                        dmc_next = IDLE;
                    end
        endcase
    end

    // oam dma engine
    logic [1:0] oam_state, oam_next;

    logic [7:0] oam_page;
    logic [7:0] oam_cnt;
    wire [15:0] oam_address = {oam_page, oam_cnt};

    logic oam_active, oam_fetch, oam_copy;
    always_ff @(posedge clk) begin
        if(rst) begin
            oam_state <= IDLE;
            oam_page <= 0;
            oam_cnt <= 0;
        end else begin
            oam_state <= oam_next;
            if (oam_init) begin
                oam_page <= cpu_data_i;
                oam_cnt <= 0;
            end else begin
                oam_cnt <= oam_fetch ? oam_cnt + 1 : oam_cnt;
            end
        end
    end

    wire oam_fetch_ready = (rw_i && apu_cycle && !dmc_block);
    always_comb begin
        oam_active = 1;
        oam_next = IDLE;
        oam_fetch = 0;
        oam_copy = 0;
        case(oam_state)
            IDLE:   begin
                        if(oam_init) begin
                            oam_next = oam_fetch_ready ? FETCH : STALL;
                            oam_active = 1;
                        end else begin
                            oam_next = IDLE;
                            oam_active = 0;
                        end
                    end
            STALL:  oam_next = oam_fetch_ready ? FETCH : STALL;
            FETCH:  begin
                        oam_fetch=1;
                        oam_next = COPY;
                    end
            COPY:   begin
                        oam_copy=1;
                        oam_next = (oam_cnt==8'hff) ? IDLE :
                                   dmc_block ? STALL : FETCH;
                    end
            default: begin end
        endcase
    end

    // dma control of bus
    assign halt = dmc_active || oam_active; 

    assign cpu_addr_o = dmc_fetch ? dmc_address : 
                        oam_fetch ? oam_address : 
                        oam_copy  ? OAMDATA : 
                        cpu_addr_i;

    assign cpu_data_o = oam_copy ? bus_data_i : cpu_data_i;

    assign rw_o = halt ? !oam_copy : rw_i;
  
endmodule
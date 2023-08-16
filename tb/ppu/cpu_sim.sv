`timescale 1ns/1ps

module cpu_sim
    #(
        parameter START_X = 0,
        parameter START_Y = 0,
        parameter AUTOSCROLL_BG = 0,
        parameter CTRL_SPRITE = 5,
        parameter INITIAL_SPRITEX = 10,
        parameter OAM_INIT={`ROM_PATH,"oam.mem"}
    )(
    input logic clk, rst,
    input logic nmi,
    input logic left,
    input logic right,
    output logic rw_o,
    output logic [15:0] addr_o,
    output logic [7:0] data_o,
    input logic [7:0] data_i

    );
    localparam CTRL_NMI = 8'h90; // enanble NMI and select upper NT
    localparam REND_OFF = 8'h00;
    localparam REND_ON = 8'h1e;

    localparam WRITE_CTRL       =4'h0;
    localparam READ_CTRL        =4'h1;
    localparam MASK_REND_OFF    =4'h2;
    localparam WRITE_SCROLLX    =4'h3;
    localparam WRITE_SCROLLY    =4'h4;
    localparam OAM_DMA_INIT     =4'h5;
    localparam OAM_DMA_WAIT     =4'h6;
    localparam MASK_REND_ON     =4'h7;
    localparam IDLE             =4'h8;

    logic [7:0] xscroll, yscroll;
    logic [7:0] frame_cnt;

    logic nmi_r;
    wire nmi_re = nmi && ~nmi_r;

    logic left_r, right_r;
    wire left_re = left && ~left_r;
    wire right_re = right && ~right_r;

    logic [7:0] spx_addr = CTRL_SPRITE*4+3;
    logic [7:0] spx;

    logic [3:0] state, next_state;

    always_ff @(posedge clk) begin
        if(rst) begin
            nmi_r <= 0;
            xscroll <= START_X;
            yscroll <= START_Y;
            frame_cnt <= 0;
            left_r <= 0;
            right_r <= 0;
            state <= WRITE_CTRL;
            spx <= INITIAL_SPRITEX;
        end else begin

            nmi_r <= nmi;
            left_r <= left;
            right_r <= right;

            state <= next_state;

            xscroll <= xscroll;
            yscroll <= yscroll;

            spx <= left_re ? spx-1 : right_re ? spx+1 : spx;

            frame_cnt <= frame_cnt;

            if (nmi_re) begin
                if (frame_cnt == AUTOSCROLL_BG-1) begin
                    frame_cnt <= 0;
                    xscroll <= xscroll+1;
                end else begin
                    frame_cnt <= frame_cnt + 1;
                end
            end

        end
    end


    logic [7:0] cpu_data;
    logic [15:0] cpu_addr;
    logic rw;
    

    always_comb begin
        rw = 1;
        cpu_addr = 0;
        cpu_data = 0;
        next_state = WRITE_CTRL;
        case(state)
            WRITE_CTRL: begin
                            rw = 0;
                            cpu_addr = 16'h2000;
                            cpu_data = CTRL_NMI;
                            next_state = READ_CTRL;
                        end
            READ_CTRL: begin
                            rw = 1;
                            cpu_addr = 16'h2000;
                            next_state = (data_i == CTRL_NMI) ? IDLE : WRITE_CTRL;
                        end
            MASK_REND_OFF: begin
                            rw = 0;
                            cpu_addr = 16'h2001;
                            cpu_data = REND_OFF;
                            next_state = WRITE_SCROLLX;
                        end
            WRITE_SCROLLX: begin
                            rw = 0;
                            cpu_addr = 16'h2005;
                            cpu_data = xscroll;
                            next_state = WRITE_SCROLLY;
                        end
            WRITE_SCROLLY: begin
                            rw = 0;
                            cpu_addr = 16'h2005;
                            cpu_data = yscroll;
                            next_state = OAM_DMA_INIT;
                        end
            OAM_DMA_INIT: begin
                            rw = 0;
                            cpu_addr = 16'h4014;
                            cpu_data = 0;
                            next_state = OAM_DMA_WAIT;
                        end
            OAM_DMA_WAIT: begin
                            rw = 1;
                            next_state = dma_en ? OAM_DMA_WAIT : MASK_REND_ON;
                        end
            MASK_REND_ON: begin
                            rw = 0;
                            cpu_addr = 16'h2001;
                            cpu_data = REND_ON;
                            next_state = IDLE;
                        end
            IDLE:       begin
                            rw = 1;
                            next_state = nmi_re ? MASK_REND_OFF : IDLE;
                        end
        endcase
    end


    logic [15:0] cpu_addr_o;
    logic [7:0] cpu_data_o;
    logic [7:0] bus_data;

    logic dma_en;

    oam_dma  u_oam_dma(
        .clk        (clk        ),
        .rst        (rst        ),
        .rw_i       (rw     ),
        .cpu_addr_i (cpu_addr ),
        .cpu_data_i (cpu_data ),
        .bus_data_i (bus_data),
        .cpu_addr_o (addr_o ),
        .cpu_data_o (data_o),
        .rw_o       (rw_o     ),
        .dma_en     (dma_en     )
    );

    logic [7:0] oam_init  [0:255];
    initial $readmemh(OAM_INIT, oam_init);

    always @(posedge clk) bus_data <= oam_init[cpu_addr_o[7:0]];
    always @(posedge clk) oam_init[spx_addr] <= spx;
endmodule
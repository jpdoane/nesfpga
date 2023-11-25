`timescale 1ns/1ps
`include "ppudefs.vh"


module ppu  #(
    parameter EXTERNAL_FRAME_TRIGGER=0,
    parameter SKIP_CYCLE_ODD_FRAMES=1
    )
    (
    input logic clk, rst,
    input logic cpu_rw, cs,
    input logic [2:0] cpu_addr,
    input logic [7:0] cpu_data_i,
    input logic [7:0] ppu_data_i,

    output logic [7:0] cpu_data_o,
    output logic nmi,
    output logic [13:0] ppu_addr_o,
    output logic [7:0] ppu_data_o,
    output logic ppu_rd,ppu_wr,

    output logic [7:0] px_data,
    output logic px_out,
    input logic trigger_frame,
    output logic vblank
    );

    logic reg_re, reg_we, cs_r;

    // cs re detection
    always @(posedge clk) begin
        if (rst) begin
            cs_r <= 0;
        end else begin
            cs_r <= cs;
        end
    end
    assign reg_re = cs & ~cs_r & cpu_rw;
    assign reg_we = cs & ~cs_r & ~cpu_rw;


    // cpu/ppu read / write registers
    logic cpu_ppu_read;
    logic [7:0] cpu_data_io, cpu_readbuf;
    always @(posedge clk) begin
        if (rst) begin
            cpu_readbuf <= 0;
        end else begin
            cpu_readbuf <= cpu_ppu_read ? ppu_data_i : cpu_readbuf;
        end
    end

    logic wr;
    assign ppu_rd = ~wr;
    assign ppu_wr = wr;

    assign ppu_data_o = wr ? cpu_data_io : 0;
    assign cpu_data_o = cpu_data_io;

    // signals from render...
    logic fetch_tile, fetch_attr, fetch_chr;
    logic [12:0] pattern_idx;
    logic [4:0] palette_idx;
    logic vblank_r;
    logic render_incx, render_incy, resetx, resety;
    logic NMI_occured, NMI_output;
    logic sp0, sp_of;
    logic px_en, px_en_r;

    assign nmi = NMI_occured && NMI_output;

    wire vblank_re = vblank & ~vblank_r;
    wire vblank_fe = vblank_r & ~vblank;

    logic [14:0] v,t; // permanent and temporary address register
    logic [2:0] fine_x, fine_y;    // fine x,y
    assign fine_y = v[14:12];

    // v/t: registers
    // yyy NN YYYYY XXXXX
    // ||| || ||||| +++++-- coarse X scroll
    // ||| || +++++-------- coarse Y scroll
    // ||| ++-------------- nametable select
    // +++----------------- fine Y scroll
    // wire [7:0] xscroll_v = {v[4:0], fine_x};
    // wire [7:0] xscroll_t = {t[4:0], fine_x};
    // wire [7:0] yscroll_v = {v[9:5], v[14:12]};
    // wire [7:0] yscroll_t = {t[9:5], t[14:12]};


    logic [7:0] ppuctrl,ppumask, ppustatus;
    // assign ppustatus = {NMI_occured, sp0, sp_of, cpu_data_io[4:0]}; //bits 4:0 maintain latched data
    assign ppustatus = {NMI_occured || vblank_re, sp0, sp_of, cpu_data_io[4:0]}; //bits 4:0 maintain latched data


    logic w;          // 1st vs 2nd write toggle (for two byte registers)
    logic inc_v;                     // signal to increment v pointer
    logic rst_delay;

    wire oam_addr_wr = reg_we && (cpu_addr == OAMADDR_ADDR);
    wire oam_data_wr = reg_we && (cpu_addr == OAMDATA_ADDR);
    wire [7:0] oam_data_o;

    always @(posedge clk) begin
        if (rst) begin
            ppuctrl <= 0;
            ppumask <= 0;
            rst_delay <= 1;

            cpu_data_io <= 0;

            v <= 0;
            t <= 0;
            fine_x <= 0;
            w <= 0;
            inc_v<=0;
            wr <= 0;
            cpu_ppu_read <= 0;
            vblank_r <= 0;
            NMI_occured <= 0;
            NMI_output <= 0;
            pal_wr <= 0;
        end else begin
            wr <= 0;
            pal_wr <= 0;
            inc_v <= 0;
            vblank_r <= vblank;
            NMI_occured <= (NMI_occured || vblank_re) & ~vblank_fe;
            NMI_output <= NMI_output;
            cpu_ppu_read <= 0;
            if(reg_re) begin    // cpu read (ppu write back to cpu)
                case(cpu_addr)
                    PPUSTATUS_ADDR: begin
                                    cpu_data_io <= ppustatus; //bits 4:0 maintain latched data
                                    NMI_occured <= 0;            // clear vblank after read
                                    w <= 0;                     // reset write toggle
                                    end
                    OAMDATA_ADDR:   cpu_data_io <= oam_data_o;
                    PPUDATA_ADDR:   begin
                                    cpu_data_io <= vpal ? pal_data : cpu_readbuf;
                                    cpu_ppu_read <= 1;  // update cpu_readbuf with incoming data
                                    inc_v <= 1;
                                    end
                    default:        begin end
                endcase
            end

            if(reg_we) begin    // cpu write (ppu store or write to vram)
                cpu_data_io <= cpu_data_i;   //emulate latching io bus
                case(cpu_addr)
                    PPUCTRL_ADDR:   begin
                                        t[11:10] <= cpu_data_i[1:0];  // nametable select
                                        ppuctrl <= cpu_data_i;
                                        NMI_output <= cpu_data_i[7];
                                    end
                    PPUMASK_ADDR:   ppumask <= cpu_data_i;
                    PPUSCROLL_ADDR: begin
                                    if (~w) begin
                                        t[4:0] <= cpu_data_i[7:3];  // coarse x
                                        fine_x <= cpu_data_i[2:0];       // fine x
                                    end else begin
                                        t[9:5] <= cpu_data_i[7:3];   // coarse y
                                        t[14:12] <= cpu_data_i[2:0]; // fine y
                                    end
                                    w <= ~w;
                                    end
                    PPUADDR_ADDR:   begin
                                    if (~w) begin
                                        // high addr
                                        t[14:8] <= {1'b0, cpu_data_i[5:0]};
                                    end else begin
                                        // low addr
                                        t[7:0] <= cpu_data_i;
                                        v <= {t[14:8], cpu_data_i};
                                    end
                                    w <= ~w;
                                    end
                    PPUDATA_ADDR:   begin
                                    pal_wr <= vpal;
                                    wr <= ~vpal;
                                    inc_v <= 1;
                                    end
                    default:        begin end
                endcase
            end

            // these registers are held in delayed reset
            // if (rst_delay) begin
            //     ppuctrl <= 0;
            //     ppumask <= 0;
            //     t <= 0;
            //     fine_x <= 0;
            //     w <= 0;
            // end

            // increment from reg r/w
            if (inc_v) v <= ppuctrl[PPUCTRL_I] ? v + 'h20 : v + 1;

            // increment y from rendering
            if (render_incy) begin
                if (&v[14:12]) begin                //fine y will wrap
                    if (v[9:5] == 5'd29) begin      //coarse y will wrap                
                        v[9:5] <= 0;              
                        v[11] <= ~v[11];            //switch vertical nametable
                    end else if (&v[9:5]) begin     // coarse y is OOB
                        v[9:5] <= 0;                // wrap w/o flipping table                        
                    end else begin
                        v[9:5] <= v[9:5] + 1;       //inc coarse y
                    end
                end
                v[14:12] <= v[14:12] + 1;           //inc fine y
            end

            // increment coarse x
            if (render_incx) begin
                if(&v[4:0]) v[10] <= ~v[10];        //switch horizontal nametable
                v[4:0] <= v[4:0] + 1;               //inc coarse x
            end

            // reset v horizontal info
            if (resetx) begin
                v[10] <= t[10];
                v[4:0] <= t[4:0];
            end
            // reset v vertical info
            if (resety) begin
                v[11] <= t[11];
                v[14:12] <= t[14:12];
                v[9:5] <= t[9:5];
            end

        end
    end


    // address is generally taken from v unless fetch_attr or fetch_chr set
    logic [13:0] addr, attr_addr, chr_addr;
    assign chr_addr = {1'b0, pattern_idx};
    assign attr_addr = {2'h2, v[11:10], 4'b1111, v[9:7], v[4:2]};
    assign ppu_addr_o = fetch_attr ? attr_addr :
                        fetch_chr ? chr_addr :
                        fetch_tile ? {2'h2, v[11:0]}:
                        v[13:0];


    wire lower_tile = v[6];
    wire left_tile = v[1];
    wire [1:0] attr_decode = lower_tile ? left_tile ? ppu_data_i[7:6] : ppu_data_i[5:4]: //lower left / right tile
                                          left_tile ? ppu_data_i[3:2] : ppu_data_i[1:0]; //upper left / right tile

    render 
    #(
        .EXTERNAL_FRAME_TRIGGER (EXTERNAL_FRAME_TRIGGER ),
        .SKIP_CYCLE_ODD_FRAMES (SKIP_CYCLE_ODD_FRAMES)
    )
    u_render(
        .clk           (clk           ),
        .rst           (rst           ),
        .trigger_frame (trigger_frame ),
        .fine_x        (fine_x        ),
        .fine_y        (fine_y        ),
        .ppuctrl       (ppuctrl       ),
        .ppumask       (ppumask       ),
        .data_i        (ppu_data_i        ),
        .attr_i        (attr_decode        ),
        .oam_addr_i    (cpu_data_i),
        .oam_addr_wr   (oam_addr_wr),
        .oam_data_i    (cpu_data_i),
        .oam_data_wr   (oam_data_wr),
        .oam_data_o    (oam_data_o),
        .fetch_tile     (fetch_tile     ),
        .fetch_attr    (fetch_attr    ),
        .fetch_chr     (fetch_chr     ),
        .pattern_idx   (pattern_idx   ),
        .palette_idx   (palette_idx   ),
        .px_en         (px_en         ),
        .vblank        (vblank        ),
        .v_incx        (render_incx        ),
        .v_incy        (render_incy        ),
        .v_resetx      (resetx      ),
        .v_resety      (resety      ),
        .sp0           (sp0           ),
        .sp_of         (sp_of         )
    );


    // palette memory
    // palette index is generally obtained from render unless v is pointing to pallete address
    logic pal_wr, vpal;
    logic [4:0] pal_addr;
    logic [7:0] pal_data;
    assign vpal = (v[13:8] == 6'h3f);
    assign pal_addr = px_en ? palette_idx : v[4:0];
    
    palette u_palette(
        .clk    (clk    ),
        .rst    (rst    ),
        .addr   (pal_addr   ),
        .wr     (pal_wr   ),
        .data_i (cpu_data_io ),
        .data_o (pal_data )
    );

    always @(posedge clk) px_en_r <= px_en;

    localparam PIXEL_BLACK = 8'h3f;
    assign px_data = px_en_r ? pal_data : PIXEL_BLACK;
    assign px_out = px_en_r;


endmodule
`timescale 1ns/1ps

module render #(
    parameter EXTERNAL_FRAME_TRIGGER=0,
    parameter SKIP_CYCLE_ODD_FRAMES=1
    )
    (
    input logic clk, rst,
    input logic trigger_frame,
    input logic [2:0] fine_x,fine_y,
    input logic [7:0] ppuctrl,
    input logic [7:0] ppumask,

    input logic [7:0] data_i,
    input logic [1:0] attr_i,

    input logic [7:0] oam_addr_i,
    input logic       oam_addr_wr,
    input logic [7:0] oam_data_i,
    input logic       oam_data_wr,
    output logic [7:0] oam_data_o,

    output logic fetch_tile, fetch_attr, fetch_chr,
    output logic [12:0] pattern_idx,
    output logic [4:0] palette_idx,

    output logic px_en, vblank,
    output logic v_incx, v_incy, v_resetx, v_resety,
    output logic sp0, sp_of
    );


    localparam PRERENDER           = 3'h0;
    localparam RENDER           = 3'h1;
    localparam V_RESETX         = 3'h2;
    localparam SPRITE_EVAL      = 3'h3;
    localparam PREP_NEXT_LINE   = 3'h4;
    localparam GARBAGE_FETCH    = 3'h5;
    localparam POST_RENDER      = 3'h6;
    localparam VBLANK           = 3'h7;

    logic odd_frame;

    wire render_bg_left = ppumask[1];
    wire render_sp_left = ppumask[2];
    wire render_bg = ppumask[3] & ~vblank;
    wire render_sp = ppumask[4] & ~vblank;
    wire render_en = render_bg | render_sp;
            
    logic [7:0] nt, at, pat0, pat1;
    logic [8:0] y, cycle;
    logic [1:0] pal;

    wire [2:0] cycle8 = cycle[2:0];
    // cycle specific triggers
    wire cycle0 = (cycle == 0);
    assign v_incy = render_en && cycle == 255;
    wire fetch_sprites = (cycle == 256);
    wire fetch_nextline = (cycle == 320);
    wire fetch_garbage = (cycle == 336);

    logic prerender, skip_cycle0, next_line,next_frame, next_prerender;
    logic [8:0] y_next;
    logic [8:0] cycle_next;
    always_comb begin

        prerender = &y; //y==-1

        skip_cycle0 = SKIP_CYCLE_ODD_FRAMES && render_en && odd_frame && prerender;
        if (skip_cycle0) next_line = cycle == 9'd339;
        else             next_line = cycle == 9'd340;

        if (EXTERNAL_FRAME_TRIGGER) begin
            next_prerender = trigger_frame;
            cycle_next = (next_line || trigger_frame) ? 0 : cycle + 1;
        end else begin
            next_prerender = next_line && (y==9'd260);
            cycle_next = next_line ? 0 : cycle + 1;
        end

        y_next = next_prerender ? -1 :  // prerender line
                 next_line ? y + 1 :    // next line
                 y;                     // same line

        next_frame = prerender && next_line;
    end

    logic vblank_r;
    assign vblank = vblank_r;

    logic [2:0] state, state_next;

    always @(posedge clk) begin
        if (rst) begin
            nt <= 0;
            pal <= 0;
            pat0 <= 0;
            pat1 <= 0;
            vblank_r <= 0;
            y <= 0; //prerender
            cycle <= 0;
            state <= RENDER;
            sp0 <= 0;
            odd_frame <= 1;
        end
        else begin
            nt <=   save_nt ? data_i : nt;
            pal <=  save_attr ? attr_i : pal;
            pat0 <= save_pat0 ? data_i : pat0;
            pat1 <= save_pat1 ? data_i : pat1;

            state <= state_next;
            y <= y_next;
            cycle <= cycle_next;

            sp0 <= prerender ? 0 : (sp0_opaque && bg_opaque && render_bg && render_sp) || sp0;
            vblank_r <= prerender ? 0 : set_vblank || vblank;
            odd_frame <= set_vblank ? ~odd_frame : odd_frame;
        end
    end

    logic set_vblank, rendering, sr_en, sp_eval, load_sp_sr;
    logic load_sr, save_nt, save_attr, save_pat0, save_pat1;

    // rendering state machine
    always_comb begin

        v_resetx = 0;
        v_resety = 0;
        set_vblank = 0;
        rendering = render_en;
        px_en = 0;
        sr_en = 1;
        sp_eval = 0;
        load_sp_sr = 0;
        v_incx = render_en && cycle8==7;
        state_next = VBLANK;

        // tile fetch cycle
        load_sr = 0;
        save_nt = 0;
        fetch_attr = 0;
        fetch_chr = 0;
        save_attr = 0;
        save_pat0 = 0;
        save_pat1 = 0;
        if (rendering) begin
            case(cycle8)
                3'h0:   load_sr = 1;
                3'h1:   save_nt = 1;
                3'h2:   fetch_attr = 1;
                3'h3:   save_attr = 1;
                3'h4:   fetch_chr = 1;
                3'h5:   save_pat0 = 1;
                3'h6:   fetch_chr = 1;
                3'h7:   save_pat1 = ~cycle0;
            endcase
        end

        case(state)
            PRERENDER:
            begin
                px_en = 0;
                v_resety = render_en && (cycle >= 279 && cycle <= 303);
                state_next = next_line ? RENDER : PRERENDER;
            end
            RENDER:
            begin
                sr_en = ~cycle0;
                px_en = render_en && ~cycle0;
                state_next = fetch_sprites ? V_RESETX : RENDER;
            end
            V_RESETX:
            begin
                sp_eval = 1;
                v_resetx = render_en;
                state_next = SPRITE_EVAL;
            end
            SPRITE_EVAL:
            begin
                sp_eval = 1;
                v_incx = 0;
                load_sp_sr = fetch_nextline;
                state_next = fetch_nextline ? PREP_NEXT_LINE : SPRITE_EVAL;
            end
            PREP_NEXT_LINE:
            begin
                state_next = fetch_garbage ? GARBAGE_FETCH : PREP_NEXT_LINE;
            end
            GARBAGE_FETCH:
            begin
                sr_en = 0;
                fetch_attr = 0;
                save_nt = 0;
                save_attr = 0;
                state_next = !next_line ? GARBAGE_FETCH :
                                (y == SCREEN_HEIGHT-1) ? POST_RENDER :
                                RENDER;
            end
            POST_RENDER:
            begin
                rendering = 0;
                sr_en = 0;
                v_incx = 0;
                state_next = next_line ? VBLANK : POST_RENDER;
            end
            VBLANK:
            begin
                rendering = 0;
                sr_en = 0;
                v_incx = 0;
                set_vblank = 1;
                state_next = next_prerender ? PRERENDER : VBLANK;
            end
        endcase

        fetch_tile = render_en && !(fetch_attr || fetch_chr);

    end


    // decode index into pattern table
    logic pat_bitsel;
    assign pat_bitsel = cycle[1]; //fetch pattern bit 0 on cycle 4 (mod8), and pattern bit 1 on cycle 6 (mod8)
    assign pattern_idx = sp_eval ? sp_pattern_idx : {ppuctrl[PPUCTRL_B], nt, pat_bitsel, fine_y};

    // assign pattern_idx = pattern_sp | pattern_bg;

    // background shift registers
    logic [1:0]  pal_dat;          //palette
    logic [7:0]  pal_sr1, pal_sr0;          //palette
    logic [15:0] tile_sr1, tile_sr0;        //tile data
    always @(posedge clk) begin
        if (rst) begin
            tile_sr0 <= 0;
            tile_sr1 <= 0;
            pal_sr0 <= 0;
            pal_sr1 <= 0;
            pal_dat <= 0;
        end else begin
            if (sr_en) begin
                tile_sr0 <=  {tile_sr0[14:0], 1'b0};
                tile_sr1 <=  {tile_sr1[14:0], 1'b0};
                pal_sr0 <=  {pal_sr0[6:0], pal_dat[0]};
                pal_sr1 <=  {pal_sr1[6:0], pal_dat[1]};
                if (load_sr) begin
                    // shift in new tile
                    tile_sr0[7:0] <= pat0;
                    tile_sr1[7:0] <= pat1;
                    pal_dat <= pal;
                end
            end else begin
                tile_sr0 <= tile_sr0;
                tile_sr1 <= tile_sr1;
                pal_sr0 <=  pal_sr0;
                pal_sr1 <=  pal_sr1;
            end
        end
    end

    // fine_x=0 selects MSB, 7 selects LSB, so flip bit order for SR output
    // wire [0:7] tile_sr0_flip = tile_sr0[15:8];
    // wire [0:7] tile_sr1_flip = tile_sr1[15:8];
    // wire [0:7] pal_sr0_flip = pal_sr0[7:0];
    // wire [0:7] pal_sr1_flip = pal_sr1[7:0];

    wire [7:0] tile_sr0_flip, tile_sr1_flip, pal_sr0_flip, pal_sr1_flip;
    generate for(genvar i=0; i<8; i++) begin
        assign tile_sr0_flip[i]=tile_sr0[15-i];
        assign tile_sr1_flip[i]=tile_sr1[15-i];
        assign pal_sr0_flip[i]=pal_sr0[7-i];
        assign pal_sr1_flip[i]=pal_sr1[7-i];
        end
    endgenerate

    wire [1:0] bg_px = {tile_sr1_flip[fine_x], tile_sr0_flip[fine_x]};
    wire [1:0] bg_pal = {pal_sr1_flip[fine_x], pal_sr0_flip[fine_x]};


    logic [12:0] sp_pattern_idx;
    logic [7:0] sp_attribute;
    logic [7:0] sp_x;
    logic sp0_line, sp0_opaque;
    
    
    wire sprite_rendering = rendering && render_sp;
    // sprite object memory
    oam u_oam(
        .clk         (clk         ),
        .rst         (rst         ),
        .rend        (sprite_rendering),
        .cycle       (cycle        ),
        .scan        (y_next),
        .oam_addr_i  (oam_addr_i  ),
        .oam_addr_wr (oam_addr_wr ),
        .oam_din     (oam_data_i     ),
        .oam_wr      (oam_data_wr      ),
        .ppuctrl     (ppuctrl     ),
        .oam_dout    (oam_data_o    ),
        .pattern_idx (sp_pattern_idx ),
        .attribute   (sp_attribute   ),
        .overflow    (sp_of    ),
        .sp0         (sp0_line     ),
        .x           (sp_x           )
    );

    // sprite rendering
    generate
        for (genvar i=0;i<8;i=i+1) begin : sp
            logic [3:0] px;
            logic pri;
            sprite #(.index (i) ) u_sprite(
                .clk       (clk       ),
                .rst       (rst       ),
                .cycle     (cycle     ),
                .eval      (sp_eval   ),
                .px_en      (px_en),
                .save_pat0 (save_pat0 ),
                .save_pat1 (save_pat1 ),
                .load_sr   (load_sp_sr  ),
                .at_i      (sp_attribute ),
                .pat_i     (data_i      ),
                .x_i       (sp_x        ),
                .px        (px   ),
                .pri       (pri  )
            );
        end
    endgenerate

    // final sprite mux (highest priority non transparent sprite)
    logic sp_pri;
    logic [3:0] sp_px;
    always @(*) begin
        sp_px = 4'h0;
        sp_pri = 1;
        sp0_opaque = 0;
        if (|sp[7].px[1:0]) begin sp_px = sp[7].px; sp_pri = sp[7].pri; end
        if (|sp[6].px[1:0]) begin sp_px = sp[6].px; sp_pri = sp[6].pri; end
        if (|sp[5].px[1:0]) begin sp_px = sp[5].px; sp_pri = sp[5].pri; end
        if (|sp[4].px[1:0]) begin sp_px = sp[4].px; sp_pri = sp[4].pri; end
        if (|sp[3].px[1:0]) begin sp_px = sp[3].px; sp_pri = sp[3].pri; end
        if (|sp[2].px[1:0]) begin sp_px = sp[2].px; sp_pri = sp[2].pri; end
        if (|sp[1].px[1:0]) begin sp_px = sp[1].px; sp_pri = sp[1].pri; end
        if (|sp[0].px[1:0]) begin sp_px = sp[0].px; sp_pri = sp[0].pri; sp0_opaque = sp0_line; end
    end

    // final pixel mux
    // draw sprite if it has priority or bg is transparent
    // else draw opaque bg, or zero for transparent bg
    wire bg_opaque = |bg_px && render_bg;
    wire sp_opaque = |sp_px[1:0] && render_sp;
    wire draw_sprite = sp_opaque && !(sp_pri && bg_opaque);
    assign palette_idx = draw_sprite ? {1'b1, sp_px} : {1'b0, bg_pal & {2{bg_opaque}}, bg_px};   

    // final pixel color: PAL[palette_idx] (done elsewhere)

endmodule
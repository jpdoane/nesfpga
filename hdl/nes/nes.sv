`timescale 1ns/1ps

module nes #(
    parameter EXTERNAL_FRAME_TRIGGER=0,
    parameter SKIP_CYCLE_ODD_FRAMES=1,
    parameter AUDIO_DEPTH=16
    )(
    // clocks
    input logic clk_master,rst_master,
    output logic clk_cpu, rst_cpu,
    output logic clk_ppu, rst_ppu,

    // video
    input logic frame_trigger,
    output logic [7:0] pixel,
    output logic pixel_en,
    output logic vblank,

    // audio
    output logic [AUDIO_DEPTH-1:0] audio,
    output logic audio_en,

    // controller
    output logic [2:0] ctrl_strobe,
    output logic [1:0] ctrl_out,
    input logic [1:0] ctrl_data,

    //cartridge
    output logic cart_m2,
    output logic [14:0] cart_cpu_addr,
    input logic [7:0] cart_cpu_data_i,
    output logic [7:0] cart_cpu_data_o,
    output logic cart_cpu_rw,
    output logic cart_romsel,
    input logic cart_ciram_ce,
    input logic cart_ciram_a10,
    output logic [13:0] cart_ppu_addr,
    input logic [7:0] cart_ppu_data_i,
    output logic [7:0] cart_ppu_data_o,
    output logic cart_ppu_rd,
    output logic cart_ppu_wr,
    input logic cart_irq
);


    logic clk_ppu8;
    (* mark_debug = "true" *)  logic m2;
    nes_clocks u_nes_clocks(
        .clk_master (clk_master ),
        .rst_master (rst_master ),
        .clk_ppu8    (clk_ppu8    ),
        .clk_ppu    (clk_ppu    ),
        .clk_cpu    (clk_cpu    ),
        .rst_ppu    (rst_ppu    ),
        .rst_cpu    (rst_cpu    ),
        .m2         (m2         )
    );


    (* mark_debug = "true" *)  logic [7:0] data_from_cpu;
    (* mark_debug = "true" *)  logic [7:0] cpu_bus_data;
    (* mark_debug = "true" *)  logic [7:0] data_ppu_to_cpu;
    (* mark_debug = "true" *)  logic [15:0] cpu_addr;
    (* mark_debug = "true" *)  logic cpu_rw;
    (* mark_debug = "true" *)  logic nmi;
    (* mark_debug = "true" *)  logic ctrl_data_dbg;
    (* mark_debug = "true" *)  logic ctrl_strobe_dbg;
    (* mark_debug = "true" *)  logic ctrl_out_dbg;

    assign ctrl_data_dbg = ctrl_data[0];
    assign ctrl_strobe_dbg = ctrl_strobe[0];
    assign ctrl_out_dbg = ctrl_out[0];
    
    assign cart_m2 = m2;

    // (* mark_debug = "true" *)  logic [31:0] cpu_cycle=0;
    // localparam RST_CPU_DELAY = 4;
    // logic [RST_CPU_DELAY-1:0] rst_cpu_sr;
    // always @(posedge clk_cpu ) begin
    //     if (rst_cpu) begin
    //         // cpu_cycle <= 0;
    //         rst_cpu_sr <= 1;
    //     end else begin
    //         cpu_cycle <= cpu_cycle+1;
    //         rst_cpu_sr <= {1'b0, rst_cpu_sr[RST_CPU_DELAY-1:1]};
    //     end
    // end
    // wire rst_cpu_delay = rst_cpu_sr[0];

    apu #(.AUDIO_DEPTH(AUDIO_DEPTH)) u_apu(
    	.clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .data_i (cpu_bus_data ),
        .rdy    (1'b1    ),
        .nmi    (nmi    ),
        .irq    (cart_irq),
        .addr_o (cpu_addr ),
        .data_o (data_from_cpu ),
        .rw     (cpu_rw     ),
        .ctrl_strobe    (ctrl_strobe),
        .ctrl_out    (ctrl_out),
        .ctrl_data    (ctrl_data),
        .audio          (audio),
        .audio_en      (audio_en)
    );


    logic ppu_cs;
    logic rom_cs;
    cpu_bus u_cpu_bus(
        .clk        (clk_cpu        ),
        .rst        (rst_cpu        ),
        .rw         (cpu_rw         ),
        .bus_addr   (cpu_addr ),
        .cpu_data_i (data_from_cpu ),
        .ppu_data_i (data_ppu_to_cpu ),
        .cart_data_i(cart_cpu_data_i ),
        .data_o     (cpu_bus_data ),
        .ppu_cs     (ppu_cs     ),
        .rom_cs     (rom_cs)
    );
    assign cart_cpu_rw = cpu_rw;
    assign cart_romsel = rom_cs; // & m2;
    assign cart_cpu_addr = cpu_addr[14:0];
    assign cart_cpu_data_o = data_from_cpu;


    (* mark_debug = "true" *)  logic [13:0] ppu_addr;
    (* mark_debug = "true" *)  logic [7:0] ppu_bus_data;
    (* mark_debug = "true" *)  logic [7:0] data_from_ppu;
    (* mark_debug = "true" *)  logic ppu_rd;
    (* mark_debug = "true" *)  logic ppu_wr;
    
    wire ppu_cs_m2 = ppu_cs & m2;
    ppu #(
        .EXTERNAL_FRAME_TRIGGER (EXTERNAL_FRAME_TRIGGER),
        .SKIP_CYCLE_ODD_FRAMES (SKIP_CYCLE_ODD_FRAMES)
        )
    u_ppu(
        .clk        (clk_ppu        ),
        .rst        (rst_ppu        ),
        .cpu_rw     (cpu_rw     ),
        .cs         (ppu_cs_m2     ),
        .cpu_addr   (cpu_addr[2:0]   ),
        .cpu_data_i (data_from_cpu ),
        .ppu_data_i (ppu_bus_data ),
        .cpu_data_o (data_ppu_to_cpu ),
        .nmi        (nmi        ),
        .ppu_addr_o (ppu_addr   ),
        .ppu_data_o (data_from_ppu ),
        .ppu_rd     (ppu_rd     ),
        .ppu_wr     (ppu_wr     ),
        .px_data    (pixel    ),
        .px_out    (pixel_en    ),
        .trigger_frame (frame_trigger ),
        .vblank (vblank )
    );

    ppu_bus u_ppu_bus(
        .clk    (clk_ppu    ),
        .rst    (rst_ppu    ),
        .addr   (ppu_addr   ),
        .rd     (ppu_rd     ),
        .wr     (ppu_wr     ),
        .vram_cs (cart_ciram_ce),
        .vram_a10 (cart_ciram_a10),
        .ppu_data_i ( data_from_ppu ),
        .cart_data_i (cart_ppu_data_i ),
        .data_o (ppu_bus_data )
    );

    assign cart_ppu_addr = ppu_addr[13:0];
    assign cart_ppu_data_o = data_from_ppu;
    assign cart_ppu_rd = ppu_rd;
    assign cart_ppu_wr = ppu_wr;


    `include "nes_logger.svi"
endmodule
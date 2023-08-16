`timescale 1ns/1ps

module nes #(
    parameter EXTERNAL_FRAME_TRIGGER=1
    )(
    input logic clk_cpu, rst_cpu,
    input logic clk_ppu, rst_ppu,
    input logic frame_trigger,
    input logic [1:0] cpu_phase,
    output logic [7:0] pixel,
    output logic pixel_en,
    output logic vblank,
    output logic [2:0] ctrl_strobe,
    output logic [1:0] ctrl_rd,
    input logic [1:0] ctrl_data
);

    logic [7:0] data_from_cpu, data_to_cpu, data_from_ppu;
    logic [15:0] cpu_addr;
    logic cpu_rw;
    logic nmi, irq, rdy;
    assign rdy=1;
    assign irq=0;

    apu u_apu(
    	.clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .data_i (data_to_cpu ),
        .rdy    (rdy    ),
        .nmi    (nmi    ),
        .irq    (irq    ),
        .addr_o (cpu_addr ),
        .data_o (data_from_cpu ),
        .rw     (cpu_rw     ),
        .ctrl_strobe    (ctrl_strobe),
        .ctrl_rd    (ctrl_rd),
        .ctrl_data    (ctrl_data)
    );

    logic [15:0] cpu_bus_addr;
    logic ppu_cs;
    cpu_bus u_cpu_bus(
        .clk        (clk_cpu        ),
        .rst        (rst_cpu        ),
        .rw         (cpu_rw         ),
        .bus_addr_i (cpu_addr ),
        .cpu_data_i (data_from_cpu ),
        .ppu_data_i (data_from_ppu ),
        .bus_data_o (data_to_cpu ),
        .ppu_cs     (ppu_cs     )
    );

    logic [13:0] ppu_addr;
    logic [7:0] ppu_data_i, ppu_data_o;
    logic [7:0] px_data;
    logic ppu_rw;
    
    logic px_out;
    wire ppu_cs_m2 = ppu_cs & cpu_phase==2;
    ppu #(
        .EXTERNAL_FRAME_TRIGGER (EXTERNAL_FRAME_TRIGGER)
        )
    u_ppu(
        .clk        (clk_ppu        ),
        .rst        (rst_ppu        ),
        .cpu_rw     (cpu_rw     ),
        .cpu_cs     (ppu_cs_m2     ),
        .cpu_addr   (cpu_addr[2:0]   ),
        .cpu_data_i (data_from_cpu ),
        .ppu_data_i (ppu_data_i ),
        .cpu_data_o (data_from_ppu ),
        .nmi        (nmi        ),
        .ppu_addr_o (ppu_addr   ),
        .ppu_data_o (ppu_data_o ),
        .ppu_rw     (ppu_rw     ),
        .px_data    (pixel    ),
        .px_out    (pixel_en    ),
        .trigger_frame (frame_trigger ),
        .vblank (vblank )
    );

    ppu_bus u_ppu_bus(
        .clk    (clk_ppu    ),
        .rst    (rst_ppu    ),
        .addr   (ppu_addr   ),
        .rw     (ppu_rw     ),
        .data_i (ppu_data_o ),
        .data_o (ppu_data_i )
    );



endmodule
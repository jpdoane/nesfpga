`timescale 1ns/1ps

parameter real FRAME_TIME = 1e9/60.0;

module nes_tb #(
    parameter EXTERNAL_FRAME_TRIGGER=0
)
(
    input CLK_125MHZ, rst_clocks
);
    logic [15:0] pc_init = 16'hc004;

    `ifndef START_FRAME
    initial $display("START_FRAME not defined");
    `define START_FRAME 1
    `endif

    `ifndef STOP_FRAME
    initial $display("STOP_FRAME not defined");
    `define STOP_FRAME 5
    `endif

    `ifndef MAX_SIM_TIME
    initial $display("MAX_SIM_TIME not defined");
    `define MAX_SIM_TIME 0
    `endif

    initial begin
        CLK_125MHZ = 0;
        rst_clocks=1;
        #20;
        // u_nes.u_cpu_bus.PRG[15'h7ffd] = pc_init[15:8];
        // u_nes.u_cpu_bus.PRG[15'h7ffc] = pc_init[7:0];
        rst_clocks=0;

        if (`MAX_SIM_TIME>0) begin
            #`MAX_SIM_TIME;
            $finish;
        end
    end

    logic record_en;

    initial begin
        @(posedge record_en);
        $dumpfile(`DUMP_WAVE_FILE);
        $dumpvars(0, nes_tb);
    end

    wire clk_ppu, clk_cpu;
    wire rst_ppu, rst_cpu;
    wire [1:0] cpu_phase;
    clocks u_clocks(
        .CLK_125MHZ (CLK_125MHZ ),
        .rst_clocks  (rst_clocks    ),
        .clk_ppu    (clk_ppu    ),
        .clk_cpu    (clk_cpu    ),
        .cpu_phase    (cpu_phase    ),
        .rst_ppu    (rst_ppu    ),
        .rst_cpu    (rst_cpu    )
    );

    logic [7:0] pixel;
    logic vblank, pixel_en;

    logic [2:0] ctrl_strobe;
    logic [1:0] ctrl_rd, ctrl_data;

    nes 
    #(
        .EXTERNAL_FRAME_TRIGGER (EXTERNAL_FRAME_TRIGGER )
    )
    u_nes(
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (1'b0 ),
        .cpu_phase     (cpu_phase     ),
        .pixel         (pixel         ),
        .pixel_en      (pixel_en      ),
        .vblank    (vblank    ),
        .ctrl_strobe   (ctrl_strobe),
        .ctrl_rd       (ctrl_rd),
        .ctrl_data       (ctrl_data)
    );


    frame_record #(
        .START_FRAME (`START_FRAME),
        .STOP_FRAME (`STOP_FRAME)
    )
    u_frame_record(
        .clk      (clk_ppu      ),
        .rst      (rst_ppu ),
        .pixel    (pixel  ),
        .pixel_en (pixel_en ),
        .frame    (vblank),
        .record_en (record_en)
    );

    wire [7:0] btns = 8'b00000100; //select

    controller_sim u_controller_sim(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .strobe (ctrl_strobe[0] ),
        .rd     (ctrl_rd[0]     ),
        .btns   (btns   ),
        .data   (ctrl_data[0]   )
    );


endmodule
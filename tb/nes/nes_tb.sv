`timescale 1ns/1ps

parameter real FRAME_TIME = 1e9/60.0;

module nes_tb #(
    parameter EXTERNAL_FRAME_TRIGGER=0
)
(
    input clk_ppu, rst_ppu,
    output logic [7:0] pixel,
    output logic pixel_en,
    output logic vblank
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

    // `ifndef MAX_SIM_TIME
    // initial $display("MAX_SIM_TIME not defined");
    // `define MAX_SIM_TIME 0
    // `endif

    // initial begin
    //     if (`MAX_SIM_TIME>0) begin
    //         #`MAX_SIM_TIME;
    //         $finish;
    //     end
    // end

    logic record_en;

    initial begin
        // @(posedge record_en);
        $dumpfile("logs/nes_tb.fst");
        $dumpvars(0, nes_tb);
    end

    logic clk_cpu, rst_cpu;

    logic [1:0] cpu_cnt3, cpu_phase;
    wire cpu_en = (cpu_cnt3 == 2'd2 );
    assign cpu_phase = cpu_cnt3;
	always_ff @(posedge clk_ppu)
	begin
        if (rst_ppu) cpu_cnt3 <= 0;
        else cpu_cnt3 <= cpu_en ? 0 : cpu_cnt3 + 1;
        clk_cpu <= cpu_en;
	end

    logic [7:0] rst_cpu_sr;
	always_ff @(posedge clk_ppu) begin
        if (rst_ppu) rst_cpu_sr <= 8'hff;
        else rst_cpu_sr <= rst_cpu_sr << 1;
    end
    wire rst_cpu = rst_cpu_sr[7];

    // logic [7:0] pixel;
    // logic vblank, pixel_en;

    logic [2:0] strobe;
    logic [1:0] ctrl_out, ctrl_data, ctrl_strobe;
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
        .ctrl_strobe   (strobe),
        .ctrl_out       (ctrl_out),
        .ctrl_data       (ctrl_data)
    );
    assign ctrl_strobe = {strobe[0], strobe[0]};
    // assign pixel = 0;
    // assign pixel_en = 0;
    // assign ctrl_out = 0;
    // assign ctrl_strobe = 0;
    // assign strobe = 0;
    // assign vblank = 0;
    
    // frame_record #(
    //     .START_FRAME (`START_FRAME),
    //     .STOP_FRAME (`STOP_FRAME)
    // )
    // u_frame_record(
    //     .clk      (clk_ppu      ),
    //     .rst      (rst_ppu ),
    //     .pixel    (pixel  ),
    //     .pixel_en (pixel_en ),
    //     .frame    (vblank),
    //     .record_en (record_en)
    // );

    wire [7:0] btns = 8'b00000100; //select

    controller_sim u_controller_sim(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .strobe (ctrl_strobe[0] ),
        .rd     (ctrl_out[0]     ),
        .btns   (btns   ),
        .data   (ctrl_data[0]   )
    );


endmodule
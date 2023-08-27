`timescale 1ns/1ps

module nes_tb
(
    input clk, rst,
    output logic [7:0] pixel,
    output logic pixel_en,
    output logic vblank
);
    logic [15:0] pc_init = 16'hc004;

    initial begin
        $dumpfile("logs/nes_tb.fst");
        $dumpvars(0, nes_tb);
    end

    logic clk_cpu, rst_cpu;
    logic clk_ppu, rst_ppu;
    logic [4:0] clk_phase;

    clocks_sim u_clocks_sim(
    	.clk_ppu8  (clk  ),
        .rst       (rst       ),
        .clk_ppu   (clk_ppu   ),
        .clk_cpu   (clk_cpu   ),
        .clk_phase (clk_phase ),
        .rst_ppu   (rst_ppu   ),
        .rst_cpu   (rst_cpu   )
    );

    logic [2:0] strobe;
    logic [1:0] ctrl_out, ctrl_data, ctrl_strobe;

    logic frame_trigger;
    hdmi_trigger  u_hdmi_trigger(
        .clk_p     (clk_ppu     ),
        .rst_p     (rst_ppu     ),
        .new_frame (frame_trigger )
    );

    nes  u_nes(
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (frame_trigger ),
        .clk_phase     (clk_phase     ),
        .pixel         (pixel         ),
        .pixel_en      (pixel_en      ),
        .vblank    (vblank    ),
        .ctrl_strobe   (strobe),
        .ctrl_out       (ctrl_out),
        .ctrl_data       (ctrl_data)
    );
    assign ctrl_strobe = {strobe[0], strobe[0]};

    // always u_nes.u_cpu_bus.PRG[15'h0fdd] = 0; // no demo wait

    int cycle;
    always_ff @(posedge clk_cpu) begin
        if(rst_cpu) cycle <= 0;
        else cycle <= cycle+1;
    end

    logic [7:0] btns = 0;
            // 0 - A
            // 1 - B
            // 2 - Select
            // 3 - Start
            // 4 - Up
            // 5 - Down
            // 6 - Left
            // 7 - Right
    
    // always_comb begin
    //     if(cycle < 800_000) btns = 0;
    //     else if(cycle < 2_000_000) btns = 8'b00001000; //start
    //     else if(cycle < 2_200_000) btns = 8'b00000001; //A
    //     else btns = 8'b10000000; //right
    // end


    controller_sim u_controller_sim(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .strobe (ctrl_strobe[0] ),
        .rd     (ctrl_out[0]     ),
        .btns   (btns   ),
        .data   (ctrl_data[0]   )
    );


endmodule
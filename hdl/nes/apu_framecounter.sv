`timescale 1ns/1ps

module apu_framecounter
    (
    input  logic clk, rst,
    input  logic mode,
    input  logic interrupt_en,
    input logic update,
    input logic clrint,
    output logic apu_cycle, qtrframe, halfframe,
    output logic irq
    );

logic [12:0] frame_counter;

logic frame_tick = frame_counter == 13'd7456;

logic [2:0] mode_ctr;
logic interrupt_set;
always_ff @(posedge clk) begin
    if(rst) begin
        frame_counter <= 0;
        apu_cycle <= 0;
        mode_ctr <= 0;
        irq <= 0;
    end else begin

        apu_cycle <= ~apu_cycle;
        irq <= (interrupt_set || irq) && !clrint;

        if(update) begin
            frame_counter <= 0;
            mode_ctr <= 0;
            irq <= 0;
        end else begin
            mode_ctr <= mode_ctr;

            if (frame_tick) begin
                frame_counter <= 0;
                if (!mode && mode_ctr==3'd3) mode_ctr <= 0;
                else if (mode && mode_ctr==3'd4) mode_ctr <= 0;
                else mode_ctr <= mode_ctr+1;
            end else begin
                frame_counter <= frame_counter + 1;
            end
        end
    end
end

always_comb begin
    qtrframe =  update && mode; //clock qtrframe on mode 1 update
    halfframe = 0;
    interrupt_set = 0;

    if(frame_tick) begin    
        if(mode) begin
            // 5-step
            qtrframe = mode_ctr != 3'd3;
            halfframe = (mode_ctr == 3'd1 || mode_ctr == 3'd4);
        end else begin
            // 4-step
            qtrframe = 1;
            halfframe = mode_ctr[0];
            interrupt_set = &mode_ctr[1:0] && interrupt_en;
        end
    end
end

endmodule
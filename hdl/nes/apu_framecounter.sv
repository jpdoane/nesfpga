`timescale 1ns/1ps

module apu_framecounter
    (
    input  logic clk, rst,
    input  logic mode,
    input  logic noint,
    input logic update,
    input logic clrint,
    output logic apu_cycle, qtrframe, halfframe,
    output logic irq
    );

logic [15:0] frame_counter;
logic reset_frame;
logic interrupt_set, interrupt_set_r, interrupt_set_rr;
logic update_r;
always_ff @(posedge clk) begin
    if(rst) begin
        frame_counter <= 0;
        apu_cycle <= 0;
        irq <= 0;
        interrupt_set_r <= 0;
        interrupt_set_rr <= 0;
        update_r <= 0;
    end else begin
        interrupt_set_r <= interrupt_set;
        interrupt_set_rr <= interrupt_set_r;
        apu_cycle <= ~apu_cycle;
        update_r <= update;
        if (clrint || noint) irq <= 0;
        else if (interrupt_set || interrupt_set_r || interrupt_set_rr) irq <= 1;
        frame_counter <= reset_frame ? 0 : frame_counter + 1;
    end
end

// logic [15:0] frame_counter;
// logic reset_frame;
// logic interrupt_set, interrupt_set_r, interrupt_set_rr;
// logic update_r;
// logic irq_reg;
// always_ff @(posedge clk) begin
//     if(rst) begin
//         frame_counter <= 0;
//         apu_cycle <= 0;
//         irq_reg <= 0;
//         interrupt_set_r <= 0;
//         interrupt_set_rr <= 0;
//         update_r <= 0;
//     end else begin
//         interrupt_set_r <= interrupt_set;
//         interrupt_set_rr <= interrupt_set_r;
//         apu_cycle <= ~apu_cycle;
//         update_r <= update;
//         irq_reg <= (interrupt_set || interrupt_set_r || interrupt_set_rr) ? 1 : irq;
//         frame_counter <= reset_frame ? 0 : frame_counter + 1;
//     end
// end
// assign irq = irq_reg && !(clrint || noint);


always_comb begin
    qtrframe =  0;
    halfframe = 0;
    interrupt_set = 0;
    reset_frame = (update||update_r) && ~apu_cycle;
    case(frame_counter)
        16'd7456:   begin
                    qtrframe = 1;
                    end
        16'd14913:   begin
                    qtrframe = 1;
                    halfframe = 1;
                    end
        16'd22371:   begin
                    qtrframe = 1;
                    end
        16'd29828:   if (!mode) begin
                        interrupt_set = 1;
                    end
        16'd29829:   if (!mode) begin
                        qtrframe = 1;
                        halfframe = 1;
                        reset_frame = 1;
                    end
        16'd37281:   begin
                    qtrframe = 1;
                    halfframe = 1;
                    reset_frame = 1;
                    end
        default:    begin
                    //clock on mode 1 update
                    qtrframe =  mode && reset_frame;
                    halfframe = mode && reset_frame;
                    interrupt_set = 0;
                    end
    endcase
end




// always_comb begin
//     qtrframe =  update && mode; //clock on mode 1 update
//     halfframe = update && mode;
//     interrupt_set = 0;

//     if(frame_tick) begin    
//         if(mode) begin
//             // 5-step
//             qtrframe = mode_ctr != 3'd3;
//             halfframe = (mode_ctr == 3'd1 || mode_ctr == 3'd4);
//         end else begin
//             // 4-step
//             qtrframe = 1;
//             halfframe = mode_ctr[0];
//             interrupt_set = &mode_ctr[1:0];
//         end
//     end
// end

endmodule
`timescale 1ns/1ps

module apu_framecounter
    (
    input  logic clk, rst,
    input  logic [4:0] apu_addr,
    input  logic [7:0] data_in,
    input  logic apu_rd,
    input  logic apu_wr,
    output logic apu_cycle, qtrframe, halfframe,
    output logic irq
    );


    wire update = (apu_addr == 5'h17) && apu_wr;
    wire clrirq = (apu_addr == 5'h15) && apu_rd;
    logic mode, maskirq;

    logic [15:0] frame_counter;
    logic update_timer;

    // based on way irq is set for 3 consequtive clocks, we will wrap frame_counter in 3-cycle process
    // [T-2]: set timer_wrap_flag, set irq if mode 0
    // [T-1]: set timer_wrap_cycle, reset frame_counter, set irq if mode 0
    // [T]:   set timer_wrap_cycle_r, frame_counter is now 0, set irq if mode 0
    logic timer_wrap_flag, timer_wrap_cycle, timer_wrap_cycle_r;
    wire irq_set = (timer_wrap_flag || timer_wrap_cycle || timer_wrap_cycle_r) && !mode;
    wire update_timer_cycle = apu_cycle && update_timer;
    always_ff @(posedge clk) begin
        if(rst) begin
            apu_cycle <= 1;
            update_timer <= 0;
            frame_counter <= 0;
            irq <= 0;
            mode <= 0;
            maskirq <= 0;
            timer_wrap_cycle <= 0;
            timer_wrap_cycle_r <= 0;
        end else begin

            apu_cycle <= ~apu_cycle;
            timer_wrap_cycle <= timer_wrap_flag;
            timer_wrap_cycle_r <= timer_wrap_cycle;

            if(update) begin
                mode <= data_in[7];
                maskirq <= data_in[6];
                update_timer <= 1;
            end
            if( update_timer_cycle || timer_wrap_cycle) begin
                frame_counter <= 0;
                update_timer <= 0;
            end else begin
                frame_counter <= frame_counter + 1;
            end

            if (irq_set) irq <= 1;      
            else if (clrirq) irq <= 0;  // dont clear if set on same cycle

            if (maskirq) irq <= 0;      // always clear if mask is set

        end
    end

    always_comb begin
        // trigger clocks on cycle following setting timer_wrap_flag, and on mode 1 update
        qtrframe =  timer_wrap_cycle || mode && update_timer_cycle;
        halfframe = timer_wrap_cycle || mode && update_timer_cycle;
        timer_wrap_flag = 0;
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
            16'd29828:  timer_wrap_flag = !mode;
            16'd37280:  timer_wrap_flag = 1;
            default:    begin
                        end
        endcase
    end




// always_comb begin
//     qtrframe =  update && mode; //clock on mode 1 update
//     halfframe = update && mode;
//     irq_set = 0;

//     if(frame_tick) begin    
//         if(mode) begin
//             // 5-step
//             qtrframe = mode_ctr != 3'd3;
//             halfframe = (mode_ctr == 3'd1 || mode_ctr == 3'd4);
//         end else begin
//             // 4-step
//             qtrframe = 1;
//             halfframe = mode_ctr[0];
//             irq_set = &mode_ctr[1:0];
//         end
//     end
// end

endmodule
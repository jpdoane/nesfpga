`timescale 1ns/1ps

module apu_dmc
    (
    input  logic clk, rst, apu_cycle,
    input  logic [4:0] apu_addr,
    input  logic [7:0] data_from_cpu,
    input  logic [7:0] data_from_ram,
    input  logic apu_wr,
    output logic active,
    output logic [6:0] sample,
    output logic irq,
    // dma control
    output logic dma_init,
    output logic dma_req,
    input logic  dmc_read
    );

    logic reg4010wr, reg4011wr, reg4013wr, reg4015wr;
    always_comb begin
        reg4010wr = 0;
        reg4011wr = 0;
        reg4013wr = 0;
        reg4015wr = 0;
        case(apu_addr)
            5'h10: reg4010wr = apu_wr;
            5'h11: reg4011wr = apu_wr;
            5'h13: reg4013wr = apu_wr;
            5'h15: reg4015wr = apu_wr;
            default: begin end
        endcase
    end
    wire en_set = reg4015wr && data_from_cpu[4];
    wire en_clr = reg4015wr && !data_from_cpu[4];

    logic [7:0] reg4010, reg4013;
    wire dmc_bit;
    logic sync, silence;
    logic [6:0] level_out;
    assign sample = level_out;

    wire irq_en = reg4010[7]; 
    wire loop = reg4010[6]; 
    wire [3:0] rate = reg4010[3:0]; 
    logic [8:0] period[0:15] = '{427, 379, 339, 319, 285, 253, 225, 213, 189, 159, 141, 127, 105,  83,  71,  53};

    logic [7:0] sample_buffer;
    logic [11:0] bytes_remaining;
    wire dma_empty = bytes_remaining==0; 
    assign active = !dma_empty; // "0x4015 DMC status bit will read as 1 if the DMC bytes remaining is more than 0."

    logic load_sample;
    assign dma_init = (en_set && dma_empty) || (load_sample && dma_empty && loop);
    assign dma_req = new_cycle && !dma_empty; // request next dma sample

    always_ff @(posedge clk) begin
        if(rst) begin
            bytes_remaining <= 0;
            sample_buffer <= 0;
            irq <= 0;
            reg4010 <= 0;
            load_sample <= 0;
        end else begin

            if(reg4010wr) reg4010 <= data_from_cpu;
            if(reg4013wr) reg4013 <= data_from_cpu;

            if( dma_init ) bytes_remaining <= {reg4013, 4'h1}; // (L * 16) + 1 bytes
            
            if(dmc_read) begin //read new sample into sample_buffer
                bytes_remaining <= bytes_remaining-1;
                sample_buffer <= data_from_ram;
                load_sample <= 1;
            end else begin
                load_sample <= 0;
            end

            if (en_clr) bytes_remaining <= 0;

            // if enabled, trigger irq at end of non-looped playback 
            if(load_sample && dma_empty && ~loop) irq <= irq_en;

            // writing to 4015 or clearing interrupt enable will clear irq
            if (reg4015wr || !irq_en) irq <= 0;

        end
    end

    // Output unit
    // [implemented above] The output unit continuously outputs a 7-bit value to the mixer. It contains an 8-bit right shift register, a bits-remaining counter, a 7-bit output level (the same one that can be loaded directly via $4011), and a silence flag.
    // The bits-remaining counter is updated whenever the timer outputs a clock, regardless of whether a sample is currently playing.
    logic [7:0] sr;
    assign dmc_bit = sr[0];
    logic [3:0] bits_remaining;
    wire new_cycle = bits_remaining==0;  // When this counter reaches zero, we say that the output cycle ends. The DPCM unit can only transition from silent to playing at the end of an output cycle.
    logic buffer_full;

    always_ff @(posedge clk) begin
        if(rst) begin
            sr <= 0;
            bits_remaining <= 0;
            silence <= 1;
            level_out <= 0;
            buffer_full <= 0;
        end else begin

            if (new_cycle) begin
                // When an output cycle ends, a new cycle is started as follows:
                // The bits-remaining counter is loaded with 8.
                // if the sample buffer is dma_empty, then the silence flag is set; otherwise, the silence flag is cleared and the sample buffer is emptied into the shift register.
                silence <= !buffer_full;
                sr <= sample_buffer;
                buffer_full <= 0;
                bits_remaining <= 4'h8;
            end
            // mark buffer full when new sample is loaded from dma
            if(load_sample) buffer_full<=1;

            if (sync) begin
                // When the timer outputs a clock, the following actions occur in order:
                // If the silence flag is clear, the output level changes based on bit 0 of the shift register. If the bit is 1, add 2; otherwise, subtract 2. But if adding or subtracting 2 would cause the output level to leave the 0-127 range, leave the output level unchanged. This means subtract 2 only if the current level is at least 2, or add 2 only if the current level is at most 125.
                // The right shift register is clocked.
                // The bits-remaining counter is decremented. If it becomes zero, a new output cycle is started.
                // Nothing can interrupt a cycle; every cycle runs to completion before a new cycle is started.
                if (!silence) begin
                    // delta modulation
                    if (dmc_bit && |level_out[6:1]) level_out <= level_out - 2;         // decrement only if level >= 2
                    else if (~dmc_bit && ~&level_out[6:1]) level_out <= level_out + 2;  // increment only if level <= 125
                end        
                sr <= sr >> 1;
                bits_remaining <= bits_remaining-1;
            end

            // direct load
            if(reg4011wr) level_out <= data_from_cpu[6:0]; 
        end
    end

    // timer unit
    logic [8:0] cnt;
    wire [8:0] current_period = period[rate];
    always_ff @(posedge clk) begin
        sync <= 0;
        if(rst) begin
            cnt <= 0;
        end else begin
            if(cnt == 0) begin                
                cnt <= current_period;
                sync <= 1;
            end else begin
                cnt <= cnt - 1;
            end
        end
    end


endmodule
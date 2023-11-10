`timescale 1ns/1ps

module apu_dmc
    (
    input  logic clk, rst, apu_cycle,
    input  logic [4:0] apu_addr,
    input  logic [7:0] data_in,
    input  logic apu_wr,
    output logic active,
    output logic [6:0] sample,
    output logic irq,
    // dma
    output logic dma_req,
    input logic dma_active,
    output logic [15:0] dma_address
    );


    logic reg4010wr, reg4011wr, reg4012wr, reg4013wr, reg4015wr;
    always_comb begin
        reg4010wr = 0;
        reg4011wr = 0;
        reg4012wr = 0;
        reg4013wr = 0;
        reg4015wr = 0;
        case(apu_addr)
            5'h10: reg4010wr = apu_wr;
            5'h12: reg4012wr = apu_wr;
            5'h11: reg4011wr = apu_wr;
            5'h13: reg4013wr = apu_wr;
            5'h15: reg4015wr = apu_wr;
            default: begin end
        endcase
    end
    wire en_set = reg4015wr && data_in[4];
    wire en_clr = reg4015wr && !data_in[4];

    logic [7:0] reg4010, reg4012, reg4013;
    wire dmc_bit;
    logic sync, silence;
    logic [6:0] level_out;
    assign sample = level_out;

    wire irq_en = reg4010[7]; 
    wire loop = reg4010[6]; 
    wire [3:0] rate = reg4010[3:0]; 
    logic [8:0] period[0:15] = '{428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106,  84,  72,  54};

    logic [7:0] sample_buffer;
    logic buffer_empty;

    logic [11:0] bytes_remaining;
    wire some_bytes_remaining = |bytes_remaining; // bytes_remaining>0
    assign active = some_bytes_remaining; //"0x4015 DMC status bit will read as 1 if the DMC bytes remaining is more than 0."

    // dma
    wire init_dma = en && ~some_bytes_remaining; //if the DMC bit is set, the DMC sample will be restarted only if its bytes remaining is 0...
    assign dma_req = buffer_empty && some_bytes_remaining; // request next dma sample when buffer is empty and samples remain
    logic buffer_play;
    logic [14:0] dma_address_short;
    logic dma_fetch, dma_read;
    logic en;
    wire restart = (en_set || (en && loop) ) && ~some_bytes_remaining; //if the DMC bit is set, the DMC sample will be restarted only if its bytes remaining is 0...
    always_ff @(posedge clk) begin
        if(rst) begin
            dma_address_short <= 0;
            bytes_remaining <= 0;
            sample_buffer <= 0;
            buffer_empty <= 1;
            irq <= 0;
            dma_read <= 0;
            dma_fetch <= 0;
            en <= 0;
            reg4010 <= 0;
            // reg4012 <= 0;
            // reg4013 <= 0;
            level_out <= 0; 
        end else begin

            if(reg4010wr) reg4010 <= data_in;
            if(reg4011wr) level_out <= data_in[6:0]; // direct load 0x4011
            if(reg4012wr) reg4012 <= data_in;
            if(reg4013wr) reg4013 <= data_in;

            if( restart ) begin
                // (re)start the DMA engine
                dma_address_short <= {1'b1, reg4012, 6'b0}; // $C000 + (sample_address * 64), with bit 15 always = 1
                bytes_remaining <= {reg4013, 4'h1}; // (L * 16) + 1 bytes
                // buffer_empty <= 1;
                en <= 1;
            end else if(dma_read) begin //fetch new dma sample into sample_buffer
                //The sample buffer is filled with the next sample byte read from the current address
                sample_buffer <= data_in;
                // The address is incremented; if it exceeds $FFFF, it is wrapped around to $8000.
                dma_address_short <= dma_address_short+1;
                //The bytes remaining counter is decremented;
                bytes_remaining <= bytes_remaining-1;
                buffer_empty <= 0;
            end else if(new_cycle) begin // sample has been played, empty buffer and fetch new sample
                buffer_empty <= 1;
            end

            // end of non-looped playback 
            if(en && ~some_bytes_remaining && ~loop) begin
                en <= 0;        //disable channel
                irq <= irq_en;  //trigger irq if enabled
            end

            if (en_clr) begin
                bytes_remaining <= 0; //If the DMC bit is clear, the DMC bytes remaining will be set to 0 and the DMC will silence when it empties.
                en <= 0;
            end

            // writing to 4015 or clearing interrupt enable will clear irq
            if (reg4015wr || !irq_en) irq <= 0;

            // 
            dma_fetch <= dma_active && apu_cycle && !(dma_fetch || dma_read);
            dma_read <= dma_fetch;


            if (sync && !silence) begin
                // delta modulation
                if (dmc_bit && |level_out[6:1]) level_out <= level_out - 2;         // decrement only if level >= 2
                else if (~dmc_bit && ~&level_out[6:1]) level_out <= level_out + 2;  // increment only if level <= 125
            end        

        end
    end
    assign dma_address = {1'b1, dma_address_short};

    // Output unit
    // [implemented above] The output unit continuously outputs a 7-bit value to the mixer. It contains an 8-bit right shift register, a bits-remaining counter, a 7-bit output level (the same one that can be loaded directly via $4011), and a silence flag.
    // The bits-remaining counter is updated whenever the timer outputs a clock, regardless of whether a sample is currently playing.
    logic [7:0] sr;
    assign dmc_bit = sr[0];
    logic [3:0] bits_remaining;
    wire new_cycle = bits_remaining==0;  // When this counter reaches zero, we say that the output cycle ends. The DPCM unit can only transition from silent to playing at the end of an output cycle.

    always_ff @(posedge clk) begin
        if(rst) begin
            sr <= 0;
            bits_remaining <= 0;
            silence <= 1;
        end else begin
            if (new_cycle) begin
                // When an output cycle ends, a new cycle is started as follows:
                // The bits-remaining counter is loaded with 8.
                // if the sample buffer is empty, then the silence flag is set; otherwise, the silence flag is cleared and the sample buffer is emptied into the shift register.
                bits_remaining <= 4'h8;
                silence <= buffer_empty;
                sr <= sample_buffer;
            end
            if (sync) begin
                // When the timer outputs a clock, the following actions occur in order:
                // [implemented above] If the silence flag is clear, the output level changes based on bit 0 of the shift register. If the bit is 1, add 2; otherwise, subtract 2. But if adding or subtracting 2 would cause the output level to leave the 0-127 range, leave the output level unchanged. This means subtract 2 only if the current level is at least 2, or add 2 only if the current level is at most 125.
                // The right shift register is clocked.
                // As stated above, the bits-remaining counter is decremented. If it becomes zero, a new output cycle is started.
                // Nothing can interrupt a cycle; every cycle runs to completion before a new cycle is started.
                sr <= sr >> 1;
                bits_remaining <= bits_remaining-1;
            end
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
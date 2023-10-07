`timescale 1ns/1ps

module controller_monitor
    #( parameter RETRIGGER_DELAY=16,    //trigger controller read after 2**RETRIGGER_DELAY clocks.
                                        //counter resets on strobe_in, so isnt used unless cpu stops polling.
                                        // RETRIGGER_DELAY=16 is slightly more than 2 frames

        parameter READ_DELAY=4         //after internal strobe, read buttons every 2**READ_DELAY clocks.
    )
    (
    input logic clk,rst,
    input logic strobe_in,
    input logic rd_in,
    input logic data_in,
    output logic strobe_out,
    output logic rd_out,
    output logic [7:0] btns
    );

    logic [RETRIGGER_DELAY-1:0] ctr;

    // if counter rolls over, read controller manually
    // this should only happen if game has stopped polling controller (or no game loaded)
    wire internal_poll_start = &ctr;      
    wire poll_start = internal_poll_start || strobe_in;      

    logic internal;
    wire internal_pulse = internal && !ctr[READ_DELAY];

    logic [8:0] read_btn;  // which button are we reading (one hot)
    wire sample_out = rd_out || strobe_out;
    logic sample_r;
    wire sample_fe = sample_r && !sample_out;
    always_ff @(posedge clk) begin
        if(rst) begin
            ctr <= 0;
            read_btn <= 0;
            btns <= 0;
            internal <= 0;
            sample_r <= 0;
        end else begin

            sample_r <= sample_out;

            ctr <= strobe_in ? 0 : ctr+1;  //reset counter on strobe

            if(internal_poll_start) internal <= 1;
            if(poll_start) read_btn <= 9'h1;

            if (sample_fe) begin
                // sample the controller data and increment which button we are reading
                for (int i=0;i<8;i++)
                    if (read_btn[i]) btns[i] <= ~data_in; // data from controllers is inverted

                read_btn <= read_btn << 1;

                // internal polling is over once after we read last button
                if (read_btn[8]) internal <= 0;
            end
        end

    end

    wire internal_strobe = internal_pulse && read_btn[0];
    wire internal_rd = internal_pulse && !read_btn[0];

    assign rd_out = internal ? internal_rd : rd_in; 
    assign strobe_out = internal ? internal_strobe : strobe_in;                
    
endmodule
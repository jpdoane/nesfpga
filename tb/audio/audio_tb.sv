`timescale 1ns/1ps

module audio_tb ();

    logic clk, rst;
    logic uptone, downtone;

    initial begin
        clk = 0;
        rst=1;
        uptone = 0;
        downtone = 0;
        #50;
        rst=0;
        #1000000;
        uptone = 1;
        #100;
        uptone = 0;
        #1000000;
        uptone = 1;
        #100;
        uptone = 0;
        #1000000;
        $finish;
    end
    initial begin
        $dumpfile(`DUMP_WAVE_FILE);
        $dumpvars(0, audio_tb);
    end

    always clk = #21 ~clk;


    logic pwm;
    playtones u_playtones(
        .clk      (clk      ),
        .rst      (rst      ),
        .en       (1'b1       ),
        .uptone   (uptone   ),
        .downtone (downtone ),
        .pwm      (pwm      )
    );


endmodule
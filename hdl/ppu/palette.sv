`timescale 1ns/1ps

module palette #(
        parameter PAL_INIT=""
    )(
    input logic clk, rst,
    input logic [4:0] addr,
    input logic wr,
    input logic [7:0] data_i,
    output logic [7:0] data_o
    );

    logic [7:0] PAL [0:31];

`ifdef RESET_RAM
        initial begin
            $display("Clearing Pallete RAM...");
            for(int j = 0; j < 32; j = j+1) PAL[j] = 8'h0;
        end
`endif

`ifdef PAL_FILE
    initial begin
        $display("Loading pallete memory: %s ", `PAL_FILE);
        $readmemh(PAL_FILE, PAL);
    end
`endif
`ifdef SAVERAMS
        final begin
            $display("Saving palette RAM");
            $writememh("logs/pal.mem", PAL);
        end
`endif

    
     //Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C.
     // if 2 lsbs are zero, then msb is 0 
    logic [4:0] addr_m;
    assign addr_m = {addr[4] & |addr[1:0], addr[3:0]};

    always @(posedge clk) begin
        if (wr) PAL[addr_m] <= data_i;
        data_o <= PAL[addr_m];
    end

endmodule
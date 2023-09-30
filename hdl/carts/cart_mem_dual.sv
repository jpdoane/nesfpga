// True-Dual-Port BRAM with Byte-wide Write Enable
// Read-First mode
// bytewrite_tdp_ram_rf.v
//

module cart_mem_dual
#(
//--------------------------------------------------------------------------
parameter ADDR_WIDTHA,
parameter MEM_FILE="",
parameter ADDR_WIDTHB = ADDR_WIDTHA-2
//----------------------------------------------------------------------
) (
//byte access
input clkA,
input enaA,
input weA,
input [ADDR_WIDTHA-1:0] addrA,
input [7:0] dinA,
output reg [7:0] doutA,
//32b word access
input clkB,
input enaB,
input [3:0] weB,
input [ADDR_WIDTHB-1:0] addrB,
input [31:0] dinB,
output reg [31:0] doutB
);


(* mark_debug = "true" *)  wire [ADDR_WIDTHB-1:0] addra_word = addrA[ADDR_WIDTHA-1:2];
wire [1:0] addra_byte = addrA[1:0];
wire [3:0] weA_word = {3'b0,weA} << addra_byte;

logic [1:0] addra_byte_r;
always_ff @(posedge clkA) addra_byte_r <= addra_byte;

(* mark_debug = "true" *) logic [31:0] doutA_word;
(* mark_debug = "true" *) logic [31:0]  dinA_word;
always_comb begin
    case(addra_byte_r)
        2'h0: doutA = doutA_word[7:0];
        2'h1: doutA = doutA_word[15:8];
        2'h2: doutA = doutA_word[23:16];
        2'h3: doutA = doutA_word[31:24];
    endcase
    case(addra_byte)
        2'h0: dinA_word = {24'h0, dinA};
        2'h1: dinA_word = {16'h0, dinA, 8'h0};
        2'h2: dinA_word = {8'h0, dinA, 16'h0};
        2'h3: dinA_word = {dinA, 24'h0};
    endcase
end


dual_port_bram #( .ADDR_WIDTH(ADDR_WIDTHB), .MEM_FILE(MEM_FILE))
u_dual_port_bram
(
    .clkA(clkA),
    .enaA(enaA),
    .weA(weA_word),
    .addrA(addra_word),
    .dinA(dinA_word),
    .doutA(doutA_word),
    .clkB(clkB),
    .enaB(enaB),
    .weB(weB),
    .addrB(addrB),
    .dinB(dinB),
    .doutB(doutB)
);


endmodule // bytewrite_tdp_ram_rf

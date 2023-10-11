`timescale 1ns/1ps

module apu_mixer
#(parameter AUDIO_DEPTH=16)
    (
    input  logic clk, rst,
    input  logic [3:0] pulse0,
    input  logic [3:0] pulse1,
    input  logic [3:0] triangle,
    input  logic [3:0] noise,
    input  logic [6:0] dmc,
    output logic [AUDIO_DEPTH-1:0] mix
    );


logic [15:0] pulse_table[0:31] = '{
16'h0000, 16'h02f9, 16'h05df, 16'h08b4, 16'h0b78, 16'h0e2c, 16'h10cf, 16'h1364,
16'h15e9, 16'h1860, 16'h1aca, 16'h1d26, 16'h1f75, 16'h21b8, 16'h23ee, 16'h2619,
16'h2838, 16'h2a4c, 16'h2c56, 16'h2e55, 16'h304a, 16'h3235, 16'h3416, 16'h35ef,
16'h37be, 16'h3985, 16'h3b43, 16'h3cf9, 16'h3ea7, 16'h404d, 16'h404d, 16'h404d
};

logic [AUDIO_DEPTH-1:0] tnd_table[0:255] = '{
16'h0000, 16'h01b7, 16'h036b, 16'h051b, 16'h06c7, 16'h0870, 16'h0a16, 16'h0bb8,
16'h0d57, 16'h0ef2, 16'h108b, 16'h1220, 16'h13b2, 16'h1541, 16'h16cc, 16'h1855,
16'h19db, 16'h1b5d, 16'h1cdd, 16'h1e5a, 16'h1fd4, 16'h214b, 16'h22bf, 16'h2430,
16'h259f, 16'h270b, 16'h2874, 16'h29db, 16'h2b3e, 16'h2ca0, 16'h2dfe, 16'h2f5b,
16'h30b4, 16'h320b, 16'h3360, 16'h34b2, 16'h3602, 16'h374f, 16'h389a, 16'h39e3,
16'h3b29, 16'h3c6d, 16'h3daf, 16'h3eee, 16'h402c, 16'h4167, 16'h42a0, 16'h43d6,
16'h450b, 16'h463d, 16'h476e, 16'h489c, 16'h49c8, 16'h4af3, 16'h4c1b, 16'h4d41,
16'h4e66, 16'h4f88, 16'h50a8, 16'h51c7, 16'h52e4, 16'h53fe, 16'h5517, 16'h562e,
16'h5744, 16'h5857, 16'h5969, 16'h5a79, 16'h5b87, 16'h5c93, 16'h5d9e, 16'h5ea7,
16'h5fae, 16'h60b4, 16'h61b8, 16'h62ba, 16'h63bb, 16'h64ba, 16'h65b8, 16'h66b4,
16'h67ae, 16'h68a7, 16'h699f, 16'h6a95, 16'h6b89, 16'h6c7c, 16'h6d6d, 16'h6e5d,
16'h6f4c, 16'h7039, 16'h7124, 16'h720e, 16'h72f7, 16'h73df, 16'h74c5, 16'h75aa,
16'h768d, 16'h776f, 16'h7850, 16'h792f, 16'h7a0d, 16'h7aea, 16'h7bc5, 16'h7ca0,
16'h7d79, 16'h7e50, 16'h7f27, 16'h7ffc, 16'h80d0, 16'h81a3, 16'h8275, 16'h8345, 
16'h8415, 16'h84e3, 16'h85b0, 16'h867c, 16'h8746, 16'h8810, 16'h88d8, 16'h89a0,
16'h8a66, 16'h8b2b, 16'h8bef, 16'h8cb2, 16'h8d74, 16'h8e35, 16'h8ef5, 16'h8fb4, 
16'h9072, 16'h912e, 16'h91ea, 16'h92a5, 16'h935f, 16'h9418, 16'h94cf, 16'h9586, 
16'h963c, 16'h96f1, 16'h97a5, 16'h9858, 16'h990a, 16'h99bb, 16'h9a6b, 16'h9b1b, 
16'h9bc9, 16'h9c77, 16'h9d23, 16'h9dcf, 16'h9e7a, 16'h9f24, 16'h9fcd, 16'ha075, 
16'ha11d, 16'ha1c3, 16'ha269, 16'ha30e, 16'ha3b2, 16'ha455, 16'ha4f8, 16'ha59a, 
16'ha63a, 16'ha6da, 16'ha77a, 16'ha818, 16'ha8b6, 16'ha953, 16'ha9ef, 16'haa8a, 
16'hab25, 16'habbf, 16'hac58, 16'hacf0, 16'had88, 16'hae1f, 16'haeb5, 16'haf4b, 
16'hafe0, 16'hb074, 16'hb107, 16'hb19a, 16'hb22c, 16'hb2bd, 16'hb34e, 16'hb3de, 
16'hb46d, 16'hb4fb, 16'hb589, 16'hb617, 16'hb6a3, 16'hb72f, 16'hb7bb, 16'hb845, 
16'hb8cf, 16'hb959, 16'hb9e1, 16'hba6a, 16'hbaf1, 16'hbb78, 16'hbbfe, 16'hbc84, 
16'hbd09, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e,
16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e,
16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e,
16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e,
16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e,
16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e,
16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e, 16'hbd8e
};
// initial $readmemh(`TND_TABLE_FILE, tnd_table);

wire [7:0] tnd_lookup_tri = {4'b0, triangle} + {3'b0, triangle<<1}; //tri * 3
wire [7:0] tnd_lookup_noisedmc = {3'b0, noise<<1} + {1'b0, dmc};   //noise*2 + dmc

logic [4:0] pulse_lookup;
logic [7:0] tnd_lookup;
logic [AUDIO_DEPTH-1:0] pulse_r;
logic [AUDIO_DEPTH-1:0] tnd_r;
always_ff @(posedge clk) begin
    if(rst) begin
        pulse_lookup <= 0;
        tnd_lookup <= 0;
        pulse_r <= 0;
        tnd_r <= 0;
        mix <= 0;
    end else begin
        pulse_lookup <= pulse0 + pulse1;
        tnd_lookup <= tnd_lookup_tri + tnd_lookup_noisedmc;
        pulse_r <= pulse_table[pulse_lookup];
        tnd_r <= tnd_table[tnd_lookup];
        mix <= pulse_r + tnd_r;
    end
end


endmodule
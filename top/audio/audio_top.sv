module audio_top (
  input CLK_125MHZ,
  input [1:0] SW,
  input [3:0] btn,
  output [3:0] LED,

  //audio
  output aud_sd,
  output aud_pwm
);

    wire clk;
    wire rst;

    wire rst_clocks = btn[0];
    wire rst_global = btn[1];

clocks  u_clocks(
    .CLK_125MHZ  (CLK_125MHZ  ),
    .rst_clocks  (rst_clocks  ),
    .rst_global  (rst_global),
    .clk_tmds (),
    .clk_hdmi    (    ),
    .clk_ppu     (     ),
    .clk_nes     (clk     ),
    .clk_cpu     (     ),
    .clk_phase    (    ),
    .locked      (      ),
    .rst_tdms    (    ),
    .rst_hdmi    (    ),
    .rst_ppu     (rst     ),
    .rst_cpu     (     )
);

wire audio_en = SW[0];

logic u,d; 
assign u = btn[2];
assign d = btn[3];
playtones u_playtones(
    .clk      (clk      ),
    .rst      (rst      ),
    .en       (1'b1       ),
    .uptone   (u   ),
    .downtone (d ),
    .pwm      (aud_pwm      )
);

assign aud_sd = audio_en;

assign  LED[3] = aud_pwm; 
assign  LED[2] = aud_sd; 

endmodule

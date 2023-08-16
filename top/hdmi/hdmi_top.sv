module hdmi_top #(
    parameter ISCREEN_WIDTH =   9'd256,
    parameter ISCREEN_HEIGHT =  9'd240,
    parameter IFRAME_WIDTH =  9'd341,
    parameter IFRAME_HEIGHT =  9'd262,
    parameter OSCREEN_WIDTH =  10'd720,
    parameter OSCREEN_HEIGHT =  10'd480,
    parameter OFRAME_WIDTH =  10'd858,
    parameter OFRAME_HEIGHT =  10'd525,
    parameter PPU_LATENCY = 3
)
(
  input CLK_125MHZ,

  input [1:0] SW,
  input [3:0] btn,
  output [3:0] LED,

  // HDMI output
  output [2:0] HDMI_TX,
  output [2:0] HDMI_TX_N,
  output HDMI_CLK,
  output HDMI_CLK_N
);

    wire rst_clocks = btn[0];

    wire clk_ppu, clk_cpu;
    wire clk_hdmi_x5, clk_hdmi;
    wire rst_ppu, rst_cpu, rst_tdms, rst_hdmi;
    wire locked;
    wire [1:0] cpu_phase;

clocks  u_clocks(
    .CLK_125MHZ  (CLK_125MHZ  ),
    .rst_clocks  (rst_clocks  ),
    .clk_hdmi_x5 (clk_hdmi_x5 ),
    .clk_hdmi    (clk_hdmi    ),
    .clk_ppu     (clk_ppu     ),
    .clk_cpu     (clk_cpu     ),
    .cpu_phase    (cpu_phase    ),
    .locked      (locked      ),
    .rst_tdms    (rst_tdms    ),
    .rst_hdmi    (rst_hdmi    ),
    .rst_ppu     (rst_ppu     ),
    .rst_cpu     (rst_cpu     )
);

    assign  LED[3] = locked; 
    assign  LED[2] = frame_trigger; 

    logic [23:0] rgb_p;
    wire override_video = btn[3] && btn[2];
    logic [23:0] rgb_pattern = 0; 
    always @(posedge clk_ppu) begin
        if (rst_ppu) rgb_pattern <= 24'hff00ff;
        else rgb_pattern <= ~rgb_pattern;
    end

    always @(posedge clk_ppu) rgb_p <= rgb_pattern;

    logic [9:0] hx, hy;
    logic [23:0] rgb_h;
    logic frame_trigger;
    hdmi_upscaler
    #(
        .ISCREEN_WIDTH (ISCREEN_WIDTH),
        .ISCREEN_HEIGHT (ISCREEN_HEIGHT),
        .IFRAME_WIDTH (IFRAME_WIDTH),
        .IFRAME_HEIGHT (IFRAME_HEIGHT),
        .OSCREEN_WIDTH (OSCREEN_WIDTH),
        .OSCREEN_HEIGHT (OSCREEN_HEIGHT),
        .OFRAME_WIDTH (OFRAME_WIDTH),
        .OFRAME_HEIGHT (OFRAME_HEIGHT),
        .IPIXEL_LATENCY (IFRAME_WIDTH + PPU_LATENCY)
    )
    u_hdmi_upscaler (
        .clk_p     (clk_ppu     ),
        .rst_p     (rst_ppu       ),
        .clk_h     (clk_hdmi     ),
        .rst_h     (rst_hdmi       ),
        .rgb_p     (rgb_p     ),
       .new_frame (frame_trigger),
         .hx        (hx        ),
        .hy        (hy        ),
        .rgb_h     (rgb_h     )
    );


    ///
    /// hmdi
    ///
    logic [2:0] tmds;
    logic tmds_clock;

    hdmi_noaudio 
    #(
        .VIDEO_ID_CODE(2),
        .BIT_WIDTH  (10),
        .BIT_HEIGHT (10),
        .VIDEO_REFRESH_RATE ( 59.94 )
    )
    u_hdmi(
        .clk_pixel_x5      (clk_hdmi_x5      ),
        .clk_pixel         (clk_hdmi         ),
        .reset             (rst_hdmi             ),
        .rgb               (rgb_h               ),
        .tmds              (tmds              ),
        .tmds_clock        (tmds_clock        ),
        .cx                 (hx        ),
        .cy                 (hy        )
    );

    genvar i;
    generate
        for (i = 0; i < 3; i++)
        begin: obufds_gen
            OBUFDS #(.IOSTANDARD("TMDS_33")) obufds (.I(tmds[i]), .O(HDMI_TX[i]), .OB(HDMI_TX_N[i]));
        end
        OBUFDS #(.IOSTANDARD("TMDS_33")) obufds_clock(.I(tmds_clock), .O(HDMI_CLK), .OB(HDMI_CLK_N));
    endgenerate


endmodule

module nes_top #(
    parameter ISCREEN_WIDTH =   9'd256,
    parameter ISCREEN_HEIGHT =  9'd240,
    parameter IFRAME_WIDTH =  9'd341,
    parameter IFRAME_HEIGHT =  9'd262,
    parameter OSCREEN_WIDTH =  10'd720,
    parameter OSCREEN_HEIGHT =  10'd480,
    parameter OFRAME_WIDTH =  10'd858,
    parameter OFRAME_HEIGHT =  10'd525,
    parameter PPU_LATENCY = 4
)
(
  input CLK_125MHZ,

  input [1:0] SW,
  input [3:0] btn,
  input [1:0] ctrl_data,
  output [1:0] ctrl_out,
  output [1:0] ctrl_strobe,
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

    assign  LED[2] = vblank; 
    assign  LED[3] = locked; 

    logic [7:0] pixel;
    logic frame_trigger, vblank, pixel_en;
    logic [2:0] strobe;
    nes 
    #(
        .EXTERNAL_FRAME_TRIGGER (1 )
    )
    u_nes(
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (frame_trigger),
        .cpu_phase     (cpu_phase     ),
        .pixel         (pixel         ),
        .pixel_en      (pixel_en      ),
        .vblank    (vblank    ),
        .ctrl_strobe   (strobe),
        .ctrl_out       (ctrl_out),
        .ctrl_data       (~ctrl_data)
    );

    assign ctrl_strobe = {strobe[0],strobe[0]};
    assign LED[1] = ctrl_data[0];

    // wire btn_select = btn[1] && SW[0];
    // wire btn_start = btn[1] && !SW[0];
    // wire btn_u = btn[2] && (SW==2'h0);
    // wire btn_d = btn[2] && (SW==2'h1);
    // wire btn_l = btn[2] && (SW==2'h2);
    // wire btn_r = btn[2] && (SW==2'h3);
    // wire btn_A = btn[3] && SW[1];
    // wire btn_B = btn[3] && !SW[1];
    // wire [7:0] controller1 = {btn_r, btn_l, btn_d, btn_u, btn_start, btn_select, btn_B, btn_A};

    // controller_sim u_controller_sim(
    //     .clk    (clk_cpu    ),
    //     .rst    (rst_cpu    ),
    //     .strobe (ctrl_strobe[0] ),
    //     .rd     (ctrl_out[0]     ),
    //     .btns   (controller1   ),
    //     .data   (ctrl_data[0]   )
    // );



    logic [23:0] pal [63:0];
    initial $readmemh(`PALFILE, pal);

    logic [23:0] rgb_p;
    wire override_video = btn[3] && btn[1];
    logic [23:0] rgb_pattern = 0; 
    always @(posedge clk_ppu) begin
        if (rst_ppu) rgb_pattern <= 24'hff00ff;
        else rgb_pattern <= ~rgb_pattern;
    end

    always @(posedge clk_ppu) rgb_p <= override_video ? rgb_pattern : pal[pixel[5:0]];


    logic [9:0] hx, hy;
    logic [23:0] rgb_h;
    
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

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
  output HDMI_CLK_N,

  //audio
  output aud_sd,
  output aud_pwm
);

    wire rst_clocks = btn[0];

    wire clk_ppu, clk_cpu;
    wire clk_tmds, clk_hdmi;
    wire locked;
    wire [4:0] clk_phase;

    wire rst_tdms;
    wire rst_hdmi;
    wire rst_ppu;
    wire rst_cpu;
    wire clk_ppu8, m2;

    wire rst_global = btn[1];

clocks  u_clocks(
    .CLK_125MHZ  (CLK_125MHZ  ),
    .rst_clocks  (rst_clocks  ),
    .rst_global  (rst_global),
    .clk_tmds (clk_tmds ),
    .clk_hdmi    (clk_hdmi    ),
    .clk_ppu     (clk_ppu     ),
    .clk_ppu8     (clk_ppu8     ),
    .clk_cpu     (clk_cpu     ),
    .m2    (m2    ),
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
    assign ctrl_strobe = {strobe[0],strobe[0]};


    logic cart_m2;
    logic [14:0] cart_cpu_addr;
    logic [7:0] cart_cpu_data_i;
    logic [7:0] cart_cpu_data_o;
    logic cart_cpu_rw;
    logic cart_romsel;
    logic cart_ciram_ce;
    logic cart_ciram_a10;
    logic [13:0] cart_ppu_addr;
    logic [7:0] cart_ppu_data_i;
    logic [7:0] cart_ppu_data_o;
    logic cart_ppu_rd;
    logic cart_ppu_wr;
    logic cart_irq;

    nes  u_nes(
        .clk_cpu       (clk_cpu       ),
        .rst_cpu       (rst_cpu       ),
        .m2       (m2       ),
        .clk_ppu       (clk_ppu       ),
        .rst_ppu       (rst_ppu       ),
        .frame_trigger (frame_trigger ),
        .pixel         (pixel         ),
        .pixel_en      (pixel_en      ),
        .audio    (),
        .vblank    (vblank    ),
        .ctrl_strobe   (strobe),
        .ctrl_out       (ctrl_out),
        .ctrl_data       (ctrl_data),
        .cart_m2          (cart_m2),
        .cart_cpu_addr    (cart_cpu_addr),
        .cart_cpu_data_i  (cart_cpu_data_i),
        .cart_cpu_data_o  (cart_cpu_data_o),
        .cart_cpu_rw      (cart_cpu_rw),
        .cart_romsel      (cart_romsel),
        .cart_ciram_ce    (cart_ciram_ce),
        .cart_ciram_a10   (cart_ciram_a10),
        .cart_ppu_addr    (cart_ppu_addr),
        .cart_ppu_data_i  (cart_ppu_data_i),
        .cart_ppu_data_o  (cart_ppu_data_o),
        .cart_ppu_rd      (cart_ppu_rd),
        .cart_ppu_wr      (cart_ppu_wr),
        .cart_irq         (cart_irq)
    );

    cart_000 
    #(
        .MIRRORV       (1)
    )
    u_cart_000 (
        .clk_cpu    (clk_cpu    ),
        .m2         (cart_m2         ),
        .cpu_addr   (cart_cpu_addr   ),
        .cpu_data_i (cart_cpu_data_i ),
        .cpu_data_o (cart_cpu_data_o ),
        .cpu_rw     (cart_cpu_rw     ),
        .romsel     (cart_romsel     ),
        .ciram_ce   (cart_ciram_ce   ),
        .ciram_a10  (cart_ciram_a10  ),
        .clk_ppu    (clk_ppu    ),
        .ppu_addr   (cart_ppu_addr   ),
        .ppu_data_i (cart_ppu_data_i ),
        .ppu_data_o (cart_ppu_data_o ),
        .ppu_rd     (cart_ppu_rd     ),
        .ppu_wr     (cart_ppu_wr     ),
        .irq        (cart_irq        )
    );

    assign LED[1] = ctrl_data[0];

    logic [23:0] pal [63:0];
    initial $readmemh(`PALFILE, pal);

    logic [23:0] rgb_p;
    always @(posedge clk_ppu) rgb_p <= pal[pixel[5:0]];

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
        .clk_pixel_x5      (clk_tmds      ),
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

    wire audio_en = 0;

    // pdm 
    // #(
    //     .DEPTH (DEPTH )
    // )
    // u_pdm(
    //     .clk    (clk_ppu8    ),
    //     .rst    (rst_ppu    ),
    //     .en     (audio_en     ),
    //     .sample (sample ),
    //     .pdm    (aud_pwm    )
    // );
    assign aud_pwm = 0;
    assign aud_sd = audio_en;

endmodule

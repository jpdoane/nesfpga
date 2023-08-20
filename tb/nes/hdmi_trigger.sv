module hdmi_trigger #(
    parameter  ISCREEN_WIDTH = 256,
    parameter  ISCREEN_HEIGHT = 240,
    parameter  IFRAME_WIDTH = 341,
    parameter  IFRAME_HEIGHT = 262,
    parameter  OSCREEN_WIDTH = 720,
    parameter  OSCREEN_HEIGHT = ISCREEN_HEIGHT*SUB_Y,
    parameter  OFRAME_WIDTH = 858,
    parameter  OFRAME_HEIGHT = 525,
    parameter  SUB_X = 2,
    parameter  SUB_Y = 2,
    parameter  OSCREEN_SHIFT = (OSCREEN_WIDTH - ISCREEN_WIDTH*SUB_X) >> 1,
    parameter  IPIXEL_LATENCY = 4                 // first pixel of new frame will be IPIXEL_LATENCY clocks after new_frame is asserted
    )
(
  input logic clk_p,                // ppu pixel clock
  input logic rst_p,                // clk_p domain reset
  output logic new_frame           // signals start of each frame, first pixel should arrive IPIXEL_LATENCY clocks later
);

    // icycles per frame
    localparam ICYCLES_MULTIFRAME = OFRAME_HEIGHT*IFRAME_WIDTH;
    localparam ICYCLES_EVEN = ICYCLES_MULTIFRAME >> 1;                  //icycles per even frame
    localparam ICYCLES_ODD = ICYCLES_MULTIFRAME[0] ? ICYCLES_EVEN + 1 : ICYCLES_EVEN;      //icycles per odd frame

    // parity bit to track even/odd frames
    logic frame_odd = 0;
    logic [17:0] pcnt = 0;
    
    // signal external rendering system
    assign new_frame = frame_odd ? pcnt == ICYCLES_ODD-IPIXEL_LATENCY : pcnt == ICYCLES_EVEN-IPIXEL_LATENCY;
    // signal internal counter to roll over
    wire new_pframe = frame_odd ? pcnt == ICYCLES_ODD-1 : pcnt == ICYCLES_EVEN-1;

    // manage p coutner and buffer incoming pixels
    always_ff @(posedge clk_p) begin
        if (rst_p) begin
            pcnt<= 0;
            frame_odd <= 0;
        end else begin
            //count cycles (for triggering new frame)
            pcnt <= new_pframe ? 0 : pcnt + 1;
            //track even/odd frames (due to different in cycles/frame)
            frame_odd <= new_pframe ? ~frame_odd : frame_odd;
        end
    end
    
endmodule

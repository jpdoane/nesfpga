`timescale 1ns/1fs

module clocks
    (
    input         CLK_125MHZ,
    input         rst_clocks,
    input         rst_global,
    output        clk_tmds,    
    output        clk_hdmi,    
    output        clk_ppu8,     
    output        clk_ppu,     
    output        clk_cpu,     
    output  reg   m2,     
    output        locked,
    output        rst_tdms,
    output        rst_hdmi,
    output        rst_ppu,
    output        rst_cpu
    );

logic locked1;
logic rst_ppu8;

logic [4:0] ppu8_cnt;   // 0-23 counter for clock divide

wire ppu_en = (ppu8_cnt[2:0] == 3'h0 );
wire cpu_en = (ppu8_cnt == 5'h0 );
always_ff @(posedge clk_ppu8)
begin
    if (rst_ppu8) begin
        ppu8_cnt <= 0;
    end else begin
        ppu8_cnt <= ppu8_cnt == 5'd23 ? 0 : ppu8_cnt + 1;
    end
end


mmcm_hdmi u_mmcm_hdmi
(
.clk_hdmi_px(clk_hdmi),
.clk_hdmi_px5(clk_tmds),
.reset(rst_clocks), 
.locked(locked1),
.clk_125(CLK_125MHZ)
);

mmcm_ppu_from_hdmi u_mmcm_ppu_from_hdmi(
    .clk_ppu8  (clk_ppu8  ),
    .reset    (~locked1    ),
    .locked   (locked   ),
    .clk_hdmi (clk_hdmi )
);

BUFGCE BUFGCE_ppu (
.O(clk_ppu),
.CE(ppu_en),
.I(clk_ppu8)
);

BUFGCE BUFGCE_cpu (
.O(clk_cpu),
.CE(cpu_en),
.I(clk_ppu8)
);

assign rst_tdms = ~locked1 | rst_global;
assign rst_hdmi = ~locked1 | rst_global;
assign rst_ppu8 = ~locked | rst_global;

logic [15:0] rst_ppu_sr;
always_ff @(posedge clk_ppu8) begin
    if (rst_ppu8) rst_ppu_sr <= 16'hffff;
    else rst_ppu_sr <= rst_ppu_sr << 1;
end
assign rst_ppu = rst_ppu_sr[15];

logic [7:0] rst_cpu_sr;
always_ff @(posedge clk_ppu) begin
    if (rst_ppu) begin
        rst_cpu_sr <= 8'hff;
        m2 <= 0;
    end else begin
        rst_cpu_sr <= rst_cpu_sr << 1;
        m2 <= ppu8_cnt[4];
    end
end
assign rst_cpu = rst_cpu_sr[7];

endmodule
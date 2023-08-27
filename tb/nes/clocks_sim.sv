`timescale 1ns/1fs

module clocks_sim
    (
    input         clk_ppu8,
    input         rst,
    output        clk_ppu,     
    output        clk_cpu,     
    output        [4:0] clk_phase,
    output        rst_ppu,
    output        rst_cpu
    );

logic [4:0] ppu8_cnt;   // 0-23 counter for clock divide
wire ppu_en = (ppu8_cnt[2:0] == 3'h0 );
wire cpu_en = (ppu8_cnt == 5'h0 );
always_ff @(posedge clk_ppu8)
begin
    if (rst) begin
        ppu8_cnt <= 0;
    end else begin
        ppu8_cnt <= ppu8_cnt == 5'd23 ? 0 : ppu8_cnt + 1;
    end
end
assign clk_phase = ppu8_cnt;

logic [15:0] rst_ppu_sr;
always_ff @(posedge clk_ppu8) begin
    if (rst) rst_ppu_sr <= 16'hffff;
    else rst_ppu_sr <= rst_ppu_sr << 1;
end
assign clk_ppu = ppu_en;
assign rst_ppu = rst_ppu_sr[15];

logic [7:0] rst_cpu_sr;
always_ff @(posedge clk_ppu) begin
    if (rst_ppu) rst_cpu_sr <= 8'hff;
    else rst_cpu_sr <= rst_cpu_sr << 1;
end
assign clk_cpu = cpu_en;
assign rst_cpu = rst_cpu_sr[7];

endmodule
`timescale 1ns/1fs

module clocks_sim
    (
    input         clk_ppu8,
    input         rst,
    output  reg   clk_ppu,     
    output  reg   clk_cpu,     
    output  reg   m2,
    output        rst_ppu,
    output        rst_cpu
    );

logic [4:0] ppu8_cnt;   // 0-23 counter for clock divide
always_ff @(posedge clk_ppu8)
begin
    if (rst) begin
        ppu8_cnt <= 0;
        clk_ppu <= 0;
        clk_cpu <= 0;
    end else begin
        ppu8_cnt <= ppu8_cnt == 5'd23 ? 0 : ppu8_cnt + 1;
        clk_ppu <= ppu8_cnt[2:0] == 3'h0;
        clk_cpu <= ppu8_cnt == 5'h0;
    end
end

logic [15:0] rst_ppu_sr;
always_ff @(posedge clk_ppu8) begin
    if (rst) rst_ppu_sr <= 16'hffff;
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
        m2 <= ppu8_cnt==5'h9;
    end
end
assign rst_cpu = rst_cpu_sr[7];

endmodule
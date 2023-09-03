`timescale 1ns/1fs

module nes_clocks
    (
    input         clk_master,
    input         rst_master,
    output        clk_ppu8,
    output        clk_ppu,     
    output        clk_cpu,     
    output        rst_ppu,
    output   reg     rst_cpu,
    output        m2
    );


`ifdef SYNTHESIS
    BUFG BUFG_ppu8 (
    .O(clk_ppu8),
    .I(clk_master)
    );
`else
    assign clk_ppu8 = clk_master;
`endif 

logic [4:0] cnt;   // 0-23 counter for clock divide
logic [6:0] rst_ctr = 0;
logic rst_ppu_r = 1;
logic rst_cpu_r = 1;
always_ff @(posedge clk_ppu8) begin
    if (rst_master) begin
        cnt <= 0;
        rst_ctr <= 7'h7f;
        rst_ppu_r <= 1;
        rst_cpu_r <= 1;
    end else begin
        cnt <= cnt == 5'd23 ? 0 : cnt + 1;
        rst_ppu_r <= !(rst_ctr[6:5] == 0); //start ppu earlier than cpu (to match mesen counters...)
        if (rst_ctr == 0) begin
            rst_ctr <= 0;
            rst_cpu_r <= 0;
        end else begin
            rst_ctr <= rst_ctr - 1;
            rst_cpu_r <= 1;
        end
    end
end

always_ff @(posedge clk_cpu) rst_cpu <= rst_cpu_r;
// always_ff @(posedge clk_ppu) rst_ppu <= rst_ppu_r;
assign rst_ppu = rst_ppu_r;

logic ppu_en, cpu_en;

`ifdef SYNTHESIS

    assign ppu_en = (cnt[2:0] == 3'h7 );
    assign cpu_en = (cnt == 5'h7 );

    BUFGCE BUFGCE_ppu (
    .O(clk_ppu),
    .CE(ppu_en),
    .I(clk_master)
    );

    BUFGCE BUFGCE_cpu (
    .O(clk_cpu),
    .CE(cpu_en),
    .I(clk_master)
    );

`else

    always_ff @(negedge clk_ppu8) ppu_en <= (cnt[2:0] == 3'h7 );
    always_ff @(negedge clk_ppu8) cpu_en <= (cnt == 5'h7 );

    assign clk_ppu = ppu_en & clk_master; 
    assign clk_cpu = cpu_en & clk_master;
`endif

logic m2_r;
always_ff @(posedge clk_ppu) begin
    if (rst_master) begin
        m2_r <= 0;
    end else begin
        m2_r <= cnt[3]; // m2 should not overlap with cpu and should overlap with exactly one ppu clock
    end
end
assign m2 = m2_r;

endmodule
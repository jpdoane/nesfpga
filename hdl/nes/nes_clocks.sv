`timescale 1ns/1fs



module nes_clocks
    (
    input    logic     clk_master,
    input    logic     rst_master,
    input    logic     en,
    output   logic     clk_nes,
    output   logic     clk_ppu,     
    output   logic     clk_cpu,     
    output   logic     rst_ppu,
    output   logic     rst_cpu,
    output   logic     m2
    );


`ifdef SYNTHESIS
    BUFG BUFG_nes (
    .O(clk_nes),
    .I(clk_master)
    );
`else
    assign clk_nes = clk_master;
`endif 

logic [4:0] cnt;   // 0-23 counter for clock divide
logic [6:0] rst_ctr = 0;
logic rst_ppu_r = 1;
logic rst_cpu_r = 1;


always_ff @(posedge clk_nes) begin
    if (rst_master) begin
        cnt <= 0;
        rst_ctr <= 7'h47;
        rst_ppu_r <= 1;
        rst_cpu_r <= 1;
    end else begin
        if (en) cnt <= cnt == 5'd23 ? 0 : cnt + 1;
        // rst_ppu_r <= rst_ctr > 7'h27; //start ppu earlier than cpu (to match mesen counters...)
        rst_ppu_r <= rst_ctr > 7'h37; //start ppu earlier than cpu (to match mesen counters...)
        if (rst_ctr == 0) begin
            rst_ctr <= 0;
            rst_cpu_r <= 0;
        end else begin
            rst_ctr <= rst_ctr - 1;
            rst_cpu_r <= 1;
        end
    end
end

// always_ff @(posedge clk_cpu) rst_cpu <= rst_cpu_r;
// always_ff @(posedge clk_ppu) rst_ppu <= rst_ppu_r;
always_ff @(posedge clk_cpu) rst_cpu <= rst_cpu_r;
assign rst_ppu = rst_ppu_r;

logic ppu_en, cpu_en;

`ifdef SYNTHESIS

    assign ppu_en = cnt[2:0] == 3'h7;
    assign cpu_en = cnt == 5'h7;

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

    always_ff @(negedge clk_nes) ppu_en <= cnt[2:0] == 3'h7;
    always_ff @(negedge clk_nes) cpu_en <= cnt == 5'h7;

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
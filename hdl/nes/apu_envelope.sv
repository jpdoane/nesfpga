`timescale 1ns/1ps

module apu_envelope
    (
    input  logic        clk,
    input  logic        rst,
    input  logic        qtrframe,
    input  logic [3:0]  period, //actual period is period+1
    input  logic        start,
    input  logic        loop,
    input  logic        use_const_vol,
    input  logic [3:0]  const_vol,
    output logic [3:0]  env_level
    );

    logic [3:0] decay;
    logic start_flag, reload_div, div_sync;

    apu_divider u_apu_divider(
        .clk    (clk    ),
        .rst    (rst    ),
        .en     (qtrframe && !start_flag ),
        .period (period ),
        .reload (reload_div ),
        .sync   (div_sync   )
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            decay <= 0;
            start_flag <= 0;
            reload_div <= 0;
        end else begin
            decay <= decay;
            start_flag <= start_flag | start;
            reload_div <= 0;

            if (qtrframe && start_flag) begin
                decay <= 4'hf;
                start_flag <= 0;
                reload_div <= 1;
            end else if (div_sync) begin
                if (decay==0) decay <= loop ? 4'hf : 0;
                else decay <= decay - 1;
            end
        end
    end

    assign env_level = use_const_vol ? const_vol : decay;

endmodule
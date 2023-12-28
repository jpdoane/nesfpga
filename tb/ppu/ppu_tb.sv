`timescale 1ns/1ps

module ppu_tb #(
    // sim timing
    parameter real FRAME_TIME = 1e9/60.0,
    parameter SIM_LENGTH = 2.1*FRAME_TIME

)();

    logic CLK_125MHZ, rst_clocks;

    initial begin
        CLK_125MHZ = 0;
        rst_clocks=1;
        #20;
        rst_clocks=0;
        #SIM_LENGTH;
        $finish;
    end
    initial begin
        $dumpfile(`DUMP_WAVE_FILE);
        $dumpvars(0, ppu_tb);
    end

    logic trigger_frame;
    generate 
        if (EXTERNAL_FRAME_TRIGGER) begin
            logic [16:0] frame_ctr = 17'd88000;
            always_ff @(posedge clk_ppu) frame_ctr <= (frame_ctr == 17'd90000) ? 0 : frame_ctr + 1;
            assign trigger_frame = (frame_ctr == 0);
        end else begin
            assign trigger_frame = 0;
        end
    endgenerate


    wire clk_ppu, clk_cpu;
    wire rst_ppu, rst_cpu;
    wire [1:0] cpu_phase;
    clocks u_clocks(
        .CLK_125MHZ (CLK_125MHZ ),
        .rst_clocks  (rst_clocks    ),
        .clk_ppu    (clk_ppu    ),
        .clk_cpu    (clk_cpu    ),
        .cpu_phase    (cpu_phase    ),
        .rst_ppu    (rst_ppu    ),
        .rst_cpu    (rst_cpu    )
    );

    logic nmi, cpu_rw;
    logic [15:0] cpu_addr;
    wire [7:0] cpu_data_o;
    wire [7:0] cpu_data_i;

    cpu_sim 
    #(
    )
    u_cpu_sim(
        .clk    (clk_cpu    ),
        .rst    (rst_cpu    ),
        .nmi    (nmi    ),
        .left (1'b0),
        .right (1'b0),
        .rw_o     (cpu_rw     ),
        .addr_o   (cpu_addr   ),
        .data_o (cpu_data_o ),
        .data_i (cpu_data_i )
    );

    // pulse cs for one ppu clock on tail end of cpu cycle
    wire cpu_ppu_cs = (cpu_phase==2) & (cpu_addr[15:13] == 3'h1);

    wire [2:0] cpu_ppu_addr = cpu_addr[2:0];
    logic [7:0] ppu_data_rd,ppu_data_wr;
    logic ppu_rw;

    logic [13:0] ppu_addr;
    logic [7:0] px_data;
    logic px_out, vblank;
    ppu #(
        .EXTERNAL_FRAME_TRIGGER (EXTERNAL_FRAME_TRIGGER)
        )
    u_ppu(
        .clk        (clk_ppu        ),
        .rst        (rst_ppu        ),
        .cpu_rw     (cpu_rw     ),
        .cpu_cs     (cpu_ppu_cs     ),
        .cpu_addr   (cpu_ppu_addr   ),
        .cpu_data_i (cpu_data_o ),
        .ppu_data_i (ppu_data_rd ),
        .cpu_data_o (cpu_data_i ),
        .nmi        (nmi        ),
        .ppu_addr_o   (ppu_addr   ),
        .ppu_data_o (ppu_data_wr ),
        .ppu_rw     (ppu_rw     ),
        .px_data    (px_data    ),
        .px_out    (px_out    ),
        .trigger_frame (trigger_frame ),
        .vblank (vblank )
    );

    ppu_bus u_ppu_bus(
        .clk    (clk_ppu    ),
        .rst    (rst_ppu    ),
        .addr   (ppu_addr   ),
        .rw     (ppu_rw     ),
        .data_i (ppu_data_wr ),
        .data_o (ppu_data_rd )
    );

    video u_video(
        .clk      (clk_ppu      ),
        .rst      (rst_ppu      ),
        .pixel    (px_data  ),
        .pixel_en (px_out ),
        .frame    (vblank)
    );

endmodule
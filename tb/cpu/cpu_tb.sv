`timescale 1us/1ns

module cpu_tb();


    logic [15:0] pc_init = 16'hc000;

    logic clk, rst;
    initial begin
        u_cpu_mmap.PRG[15'h7ffd] = pc_init[15:8];
        u_cpu_mmap.PRG[15'h7ffc] = pc_init[7:0];
        clk = 0;
        rst = 1;
        #4
        rst = 0; 
        #10000
        $display("error code 0x%h", err);
        $finish;
    end

    logic [15:0] err;
    always @(posedge clk) begin
        err[15:8] <= u_cpu_mmap.RAM[3];
        err[7:0] =< u_cpu_mmap.RAM[2];
    end


    always #1 clk = ~clk;

    logic [7:0] data_i, data_o;
    logic [15:0] addr;
    logic rw, sync, jam;
    logic rdy = 0;
    wire nmi = 0;
    wire irq = 0;
    wire sv = 0;

    core u_core(
        .i_clk  (clk  ),
        .i_rst  (rst  ),
        .i_data (data_i ),
        .READY  (rdy  ),
        .SV    (sv    ),
        .NMI    (nmi    ),
        .IRQ    (irq    ),
        .addr   (addr   ),
        .dor    (data_o    ),
        .RW     (rw)
    );

    logic ppu_cs, apu_cs;
    cpu_mmap u_cpu_mmap(
        .clk              (clk              ),
        .rst              (rst              ),
        .cpu_addr         (addr         ),
        .data_from_cpu    (data_o    ),
        .rw               (rw               ),
        .data_from_memory (data_i ),
        .ppu_cs           (ppu_cs           ),
        .apu_cs           (apu_cs           )
    );

    initial begin
        $dumpfile(`DUMP_WAVE_FILE);
        $dumpvars(0, cpu_tb);
    end    

endmodule

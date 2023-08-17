`timescale 1ns/1ps

module apu
    (
    input  logic clk, rst,
    input  logic [7:0] data_i,
    input  logic rdy, nmi, irq,
    output logic [15:0] addr_o,
    output logic [7:0] data_o,
    output logic rw,
    output logic [2:0] ctrl_strobe,
    output logic [1:0] ctrl_out,
    input logic [1:0] ctrl_data
    );

    logic [7:0] data_from_cpu, data_to_cpu;
    logic [15:0] addr_from_cpu;

    logic dma_en, cpu_rw;

    // OAM dma
    // once enabled, this temporarily disables cpu and takes over the bus
    oam_dma u_oam_dma(
        .clk    (clk        ),
        .rst    (rst        ),
        .rw_i       (cpu_rw         ),
        .cpu_addr_i (addr_from_cpu ),   // addr from cpu
        .cpu_data_i (data_from_cpu ),   // data from cpu
        .bus_data_i (data_i ),          // data from bus
        .cpu_addr_o (addr_o ),          // cpu addr with dma ctrl
        .cpu_data_o (data_o ),          // cpu data with dma ctrl
        .rw_o       (rw     ),
        .dma_en     (dma_en)
    );

    wire cpu_rdy = rdy & !dma_en;
    logic sync, jam;
    core_6502 u_core_6502(
        .i_clk  (clk  ),
        .i_rst  (rst  ),
        .i_data (data_to_cpu ),
        .READY  (cpu_rdy  ),
        .SV     (1'b0     ),
        .NMI    (nmi    ),
        .IRQ    (irq    ),
        .addr   (addr_from_cpu   ),
        .dor    (data_from_cpu    ),
        .RW     (cpu_rw     ),
        .sync   (sync   ),
        .jam    (jam    )
    );

    // APU register space 0x4000-0x401f
    wire apu_cs               = (addr_from_cpu & 16'hffe0) == 16'h4000;
    wire [4:0] apu_addr       = addr_from_cpu[4:0];

    logic [7:0] apu_data_rd;
    logic apu_cs_r; 

    // logic [7:0] APU_REG[0:31];
    // `ifdef RESET_RAM
    //         initial begin
    //             $display("Clearing APU Regs...");
    //             for(int j = 0; j < 32; j = j+1)  APU_REG[j] = 8'h0;
    //         end
    // `endif
    // logic apu_cs_r;    
    // always @(posedge clk) begin
    //     if (rst) begin
    //         apu_cs_r <= 0;
    //         apu_rd <= 0;
    //     end else begin
    //         apu_cs_r <= ;
    //         apu_rd <= APU_REG[apu_addr];
    //         if (apu_cs && !cpu_rw) APU_REG[apu_addr] <= data_from_cpu;
    //     end
    // end

    always @(posedge clk) begin
        if (rst) begin
            ctrl_strobe <= 0;
            ctrl_out <= 0;
            apu_data_rd <= 0;
            apu_cs_r <= 0;
        end else begin

            apu_cs_r <= apu_cs;
            ctrl_strobe <= ctrl_strobe;
            ctrl_out <= 0;
            apu_data_rd <= 0;

            // write to controller
            if (!cpu_rw && apu_cs && apu_addr==5'h16)
                ctrl_strobe <= data_from_cpu[2:0];

            // read from controller1
            if (cpu_rw && apu_cs && apu_addr==5'h16) begin
                ctrl_out[0] <= 1;
                apu_data_rd <= {7'h0, ctrl_data[0]};
            end
            // read from controller2
            if (cpu_rw && apu_cs && apu_addr==5'h17) begin
                ctrl_out[1] <= 1;
                apu_data_rd <= {7'h0, ctrl_data[1]};
            end
        end
    end

    assign data_to_cpu = apu_cs_r ? apu_data_rd : data_i;


endmodule
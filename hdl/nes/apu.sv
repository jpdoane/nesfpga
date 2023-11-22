`timescale 1ns/1ps

module apu
#(parameter AUDIO_DEPTH=16)
    (
    input  logic clk, rst,
    input  logic [7:0] data_i,
    input  logic rdy, nmi, irq,
    output logic [15:0] addr_o,
    output logic [7:0] data_o,
    output logic rw,
    output logic [2:0] ctrl_strobe,
    output logic [1:0] ctrl_out,
    input logic [1:0] ctrl_data,
    output logic [AUDIO_DEPTH-1:0] audio,
    output logic audio_en
    );


    // APU register space 0x4000-0x401f
    wire apu_cs               = (addr_from_cpu & 16'hffe0) == 16'h4000;
    wire apu_rd = apu_cs && cpu_rw;
    wire apu_wr = apu_cs && !cpu_rw;
    wire [4:0] apu_addr       = addr_from_cpu[4:0];
    logic [7:0] data_from_cpu, data_to_cpu;
    logic [15:0] addr_from_cpu;
    logic dma_en, cpu_rw;

    logic [7:0] reg_apu_enable;
    wire pulse0_en = reg_apu_enable[0];
    wire pulse1_en = reg_apu_enable[1];
    wire triangle_en = reg_apu_enable[2];
    wire noise_en = reg_apu_enable[3];
    wire dmc_en = reg_apu_enable[4];

    logic frame_irq, dmc_irq;
    logic pulse1_active, pulse0_active;
    logic triangle_active;
    logic noise_active;
    logic dmc_active;
    wire [7:0] reg_apu_status_rd = {dmc_irq, frame_irq, 1'b0, dmc_active, noise_active, triangle_active, pulse1_active, pulse0_active};

    logic [7:0] apu_data_rd;
    logic apu_cs_r;

    logic reg4012wr, reg4014wr, reg4015wr, reg4016wr;
    logic reg4015rd, reg4016rd, reg4017rd;
    always_comb begin
        reg4012wr = 0;
        reg4014wr = 0;
        reg4015wr = 0;
        reg4016wr = 0;
        reg4015rd = 0;
        reg4016rd = 0;
        reg4017rd = 0;
        case(apu_addr)
            5'h12:  begin reg4012wr = apu_wr; end
            5'h14:  begin reg4014wr = apu_wr; end
            5'h15:  begin reg4015wr = apu_wr; reg4015rd = apu_rd; end
            5'h16:  begin reg4016wr = apu_wr; reg4016rd = apu_rd; end
            5'h17:  begin reg4017rd = apu_rd; end
            default: begin end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            apu_data_rd <= 0;
            reg_apu_enable <= 0;
            ctrl_strobe <= 0;
            ctrl_out <= 0;
            apu_cs_r <= 0;
        end else begin
            apu_data_rd <= 0;
            
            apu_cs_r <= apu_cs;
            if(reg4015rd) apu_data_rd <= reg_apu_status_rd;    
            if(reg4016rd) apu_data_rd <= {7'b0100000, ctrl_data[0]};
            if(reg4017rd) apu_data_rd <= {7'b0100000, ctrl_data[1]};
            
            if(reg4015wr) reg_apu_enable <= data_from_cpu;
            if(reg4016wr) ctrl_strobe <= data_from_cpu[2:0];
            ctrl_out <= {reg4017rd, reg4016rd};
        end
    end

    // dma code
    // bus is routed through here to allow dma to take control
    logic dma_halt;
    logic dmc_dma_init, dmc_dma_req, dmc_dma_read;
    apu_dma u_apu_dma(
        .clk    (clk        ),
        .rst    (rst        ),
        .apu_cycle (apu_cycle),
        .rw_i       (cpu_rw         ),
        .cpu_addr_i (addr_from_cpu ),   // addr from cpu
        .cpu_data_i (data_from_cpu ),   // data from cpu
        .bus_data_i (data_i ),          // data from bus
        .cpu_data_o (data_o ),          // cpu data with dma ctrl
        .cpu_addr_o (addr_o ),          // cpu addr with dma ctrl
        .rw_o       (rw     ),
        .halt       (dma_halt),         // halts cpu during dma transfer
        .oam_init   (reg4014wr),
        .dmc_addr_wr(reg4012wr),
        .dmc_init   (dmc_dma_init),
        .dmc_req    (dmc_dma_req),
        .dmc_read   (dmc_dma_read)
    );

    wire cpu_rdy = rdy & !dma_halt;
    logic sync, jam;
    core_6502 u_core_6502(
        .i_clk  (clk  ),
        .i_rst  (rst  ),
        .i_data (data_to_cpu ),
        .READY  (cpu_rdy  ),
        .SV     (1'b0     ),
        .NMI    (nmi    ),
        .IRQ    (irq || frame_irq || dmc_irq  ),
        .addr   (addr_from_cpu   ),
        .dor    (data_from_cpu    ),
        .RW     (cpu_rw     ),
        .sync   (sync   ),
        .jam    (jam    )
    );

    assign data_to_cpu = apu_cs_r ? apu_data_rd : data_i;

    logic apu_cycle, qtrframe, halfframe;
    apu_framecounter u_apu_framecounter(
        .clk          (clk          ),
        .rst          (rst          ),
        .apu_addr       (apu_addr ),
        .data_in       (data_from_cpu ),
        .apu_rd        (apu_rd),
        .apu_wr        (apu_wr),
        .apu_cycle    (apu_cycle    ),
        .qtrframe     (qtrframe     ),
        .halfframe    (halfframe    ),
        .irq          (frame_irq          )
    );

    logic [3:0] pulse0_sample;
    apu_pulse #(.id (0)) u_apu_pulse0(
        .clk              (clk              ),
        .rst              (rst              ),
        .apu_cycle        (apu_cycle        ),
        .qtrframe         (qtrframe         ),
        .halfframe        (halfframe        ),
        .en               (pulse0_en               ),
        .apu_addr         (apu_addr         ),
        .data_in          (data_from_cpu        ),
        .apu_wr           (apu_wr      ),
        .active           (pulse0_active),
        .sample           (pulse0_sample )
    );

    logic [3:0] pulse1_sample;
    apu_pulse #(.id (1)) u_apu_pulse1(
        .clk              (clk              ),
        .rst              (rst              ),
        .apu_cycle        (apu_cycle        ),
        .qtrframe         (qtrframe         ),
        .halfframe        (halfframe        ),
        .en               (pulse1_en              ),
        .apu_addr         (apu_addr         ),
        .data_in          (data_from_cpu        ),
        .apu_wr           (apu_wr      ),
        .active           (pulse1_active),
        .sample           (pulse1_sample )
    );

    logic [3:0] triangle_sample;
    apu_triangle u_apu_triangle(
        .clk             (clk             ),
        .rst             (rst             ),
        .qtrframe        (qtrframe        ),
        .halfframe       (halfframe       ),
        .en              (triangle_en),
        .apu_addr         (apu_addr         ),
        .data_in          (data_from_cpu        ),
        .apu_wr           (apu_wr      ),
        .active          (triangle_active          ),
        .sample          (triangle_sample          )
    );

    logic [3:0] noise_sample;
    apu_noise u_apu_noise(
        .clk              (clk              ),
        .rst              (rst              ),
        .apu_cycle        (apu_cycle        ),
        .qtrframe         (qtrframe         ),
        .halfframe        (halfframe        ),
        .en               (noise_en              ),
        .apu_addr         (apu_addr         ),
        .data_in          (data_from_cpu        ),
        .apu_wr           (apu_wr      ),
        .active           (noise_active),
        .sample           (noise_sample )
    );

    logic [6:0] dmc_sample;
    apu_dmc u_apu_dmc(
        .clk                (clk),
        .rst                (rst),
        .apu_cycle          (apu_cycle),
        .apu_addr           (apu_addr),
        .data_from_cpu      (data_from_cpu),
        .data_from_ram      (data_i),
        .apu_wr             (apu_wr),
        .active             (dmc_active),
        .sample             (dmc_sample),
        .irq                (dmc_irq),
        .dma_init            (dmc_dma_init),
        .dma_req         (dmc_dma_req),
        .dmc_read        (dmc_dma_read)
        );


    apu_mixer #(.AUDIO_DEPTH(AUDIO_DEPTH)) u_apu_mixer(
        .clk(clk),
        .rst(rst),
        .pulse0   (pulse0_sample   ),
        .pulse1   (pulse1_sample   ),
        .triangle (triangle_sample),
        .noise    (noise_sample    ),
        .dmc      (dmc_sample      ),
        .mix      (audio      )
    );

    assign audio_en = pulse0_en | pulse1_en | triangle_en | noise_en | dmc_en;

endmodule
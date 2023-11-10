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
    always_ff @(posedge clk) begin
        ctrl_out <= 0;
        apu_data_rd <= 0;
        if (rst) begin
            reg_apu_enable <= 0;
            ctrl_strobe <= 0;
            apu_cs_r <= 0;
        end else begin
            apu_cs_r <= apu_cs;        
            if(apu_cs) begin
                if (cpu_rw) begin
                    // reg read
                    case(apu_addr)
                    5'h15:  begin
                            apu_data_rd <= reg_apu_status_rd;
                            end
                    5'h16:  begin
                            ctrl_out[0] <= 1;
                            apu_data_rd <= {7'b0100000, ctrl_data[0]};
                            end
                    5'h17:  begin    
                            ctrl_out[1] <= 1;
                            apu_data_rd <= {7'b0100000, ctrl_data[1]};
                            end
                    default: begin end
                    endcase
                end else begin
                    // reg write
                    case(apu_addr)
                        5'h15: reg_apu_enable <= data_from_cpu;    
                        5'h16: ctrl_strobe <= data_from_cpu[2:0];
                        default: begin end
                    endcase
                end
            end
        end
    end

    logic dma_halt;
    logic dmc_dma_req;
    logic dmc_dma_active;
    logic [15:0] dmc_dma_address;

    // OAM dma
    // once enabled, this temporarily disables cpu and takes over the bus
    apu_dma u_apu_dma(
        .clk    (clk        ),
        .rst    (rst        ),
        .apu_cycle (apu_cycle),
        .rw_i       (cpu_rw         ),
        .cpu_addr_i (addr_from_cpu ),   // addr from cpu
        .cpu_data_i (data_from_cpu ),   // data from cpu
        .bus_data_i (data_i ),          // data from bus
        .cpu_addr_o (addr_o ),          // cpu addr with dma ctrl
        .cpu_data_o (data_o ),          // cpu data with dma ctrl
        .rw_o       (rw     ),
        .halt       (dma_halt),
        .dmc_dma_req    (dmc_dma_req),
        .dmc_dma_active (dmc_dma_active),
        .dmc_dma_address (dmc_dma_address)    
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
        .data_in            (data_from_cpu),
        .apu_wr             (apu_wr),
        .active             (dmc_active),
        .sample             (dmc_sample),
        .irq                (dmc_irq),
        .dma_req            (dmc_dma_req),
        .dma_active         (dmc_dma_active),
        .dma_address        (dmc_dma_address)
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
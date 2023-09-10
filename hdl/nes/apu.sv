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
    wire [4:0] apu_addr       = addr_from_cpu[4:0];


logic [7:0] reg_pulse0_ctrl;
logic [7:0] reg_pulse0_sweep;
logic [7:0] reg_pulse0_timelow;
logic [7:0] reg_pulse0_timehigh;
logic [7:0] reg_pulse1_ctrl;
logic [7:0] reg_pulse1_sweep;
logic [7:0] reg_pulse1_timelow;
logic [7:0] reg_pulse1_timehigh;
logic [7:0] reg_triangle_ctrl;
logic [7:0] reg_triangle_timelow;
logic [7:0] reg_triangle_timehigh;
logic [7:0] reg_noise_ctrl;
logic [7:0] reg_noise_timelow;
logic [7:0] reg_noise_timehigh;
logic [7:0] reg_dmc_ctrl;
logic [7:0] reg_dmc_direct;
logic [7:0] reg_dmc_addr;
logic [7:0] reg_dmc_length;
logic [7:0] reg_apu_enable;
logic framectr_mode;
logic framectr_int;

logic pulse0_ctrl_update;
logic pulse0_sweep_update;
logic pulse0_length_update;
logic pulse1_ctrl_update;
logic pulse1_sweep_update;
logic pulse1_length_update;
logic triangle_ctrl_update;
logic triangle_length_update;
logic noise_ctrl_update;
logic noise_timelow_update;
logic noise_timehigh_update;
logic dmc_ctrl_update;
logic dmc_direct_update;
logic dmc_addr_update;
logic dmc_length_update;
logic framectr_update;
logic dmc_clrint;
logic framectr_clrint;


logic [7:0] apu_data_rd;
logic apu_cs_r;
always_ff @(posedge clk) begin

    pulse0_ctrl_update <= 0;
    pulse0_sweep_update <= 0;
    pulse0_length_update <= 0;
    pulse1_ctrl_update <= 0;
    pulse1_sweep_update <= 0;
    pulse1_length_update <= 0;
    triangle_ctrl_update <= 0;
    triangle_length_update <= 0;
    noise_ctrl_update <= 0;
    noise_timelow_update <= 0;
    noise_timehigh_update <= 0;
    dmc_ctrl_update <= 0;
    dmc_direct_update <= 0;
    dmc_addr_update <= 0;
    dmc_length_update <= 0;
    framectr_update <= 0;

    dmc_clrint <= 0;
    framectr_clrint <= 0;

    ctrl_out <= 0;
    apu_data_rd <= 0;

    if (rst) begin
        reg_pulse0_ctrl <= 0;
        reg_pulse0_sweep <= 0;
        reg_pulse0_timelow <= 0;
        reg_pulse0_timehigh <= 0;
        reg_pulse1_ctrl <= 0;
        reg_pulse1_sweep <= 0;
        reg_pulse1_timelow <= 0;
        reg_pulse1_timehigh <= 0;
        reg_triangle_ctrl <= 0;
        reg_triangle_timelow <= 0;
        reg_triangle_timehigh <= 0;
        reg_noise_ctrl <= 0;
        reg_noise_timelow <= 0;
        reg_noise_timehigh <= 0;
        reg_dmc_ctrl <= 0;
        reg_dmc_direct <= 0;
        reg_dmc_addr <= 0;
        reg_dmc_length <= 0;
        reg_apu_enable <= 0;
        framectr_mode <= 0;
        framectr_int <= 0;

        ctrl_strobe <= 0;
        apu_cs_r <= 0;


    end else begin

        reg_pulse0_ctrl <= reg_pulse0_ctrl;
        reg_pulse0_sweep <= reg_pulse0_sweep;
        reg_pulse0_timelow <= reg_pulse0_timelow;
        reg_pulse0_timehigh <= reg_pulse0_timehigh;
        reg_pulse1_ctrl <= reg_pulse1_ctrl;
        reg_pulse1_sweep <= reg_pulse1_sweep;
        reg_pulse1_timelow <= reg_pulse1_timelow;
        reg_pulse1_timehigh <= reg_pulse1_timehigh;
        reg_triangle_ctrl <= reg_triangle_ctrl;
        reg_triangle_timelow <= reg_triangle_timelow;
        reg_triangle_timehigh <= reg_triangle_timehigh;
        reg_noise_ctrl <= reg_noise_ctrl;
        reg_noise_timelow <= reg_noise_timelow;
        reg_noise_timehigh <= reg_noise_timehigh;
        reg_dmc_ctrl <= reg_dmc_ctrl;
        reg_dmc_direct <= reg_dmc_direct;
        reg_dmc_addr <= reg_dmc_addr;
        reg_dmc_length <= reg_dmc_length;
        reg_apu_enable <= reg_apu_enable;
        framectr_mode <= framectr_mode;
        framectr_int <= framectr_int;

        ctrl_strobe <= ctrl_strobe;
        apu_cs_r <= apu_cs;
        
        if(apu_cs) begin
            if (cpu_rw) begin
                // reg read
                case(apu_addr)
                5'h15:  begin
                        apu_data_rd <= reg_apu_status_rd;
                        framectr_clrint <= 0;
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
                    5'h0: begin     
                            reg_pulse0_ctrl <= data_from_cpu;      
                            pulse0_ctrl_update<=1;
                        end
                    5'h1: begin     
                            reg_pulse0_sweep <= data_from_cpu;     
                            pulse0_sweep_update<=1;
                        end
                    5'h2: begin     
                            reg_pulse0_timelow <= data_from_cpu;   
                        end
                    5'h3: begin     
                            reg_pulse0_timehigh <= data_from_cpu;  
                            pulse0_length_update<=1;
                        end
                    5'h4: begin     
                            reg_pulse1_ctrl <= data_from_cpu;      
                            pulse1_ctrl_update<=1;
                        end
                    5'h5: begin     
                            reg_pulse1_sweep <= data_from_cpu;     
                            pulse1_sweep_update<=1;
                        end
                    5'h6: begin     
                            reg_pulse1_timelow <= data_from_cpu;   
                        end
                    5'h7: begin     
                            reg_pulse1_timehigh <= data_from_cpu;  
                            pulse1_length_update<=1;
                        end
                    5'h8: begin     
                            reg_triangle_ctrl <= data_from_cpu;    
                            triangle_ctrl_update<=1;
                        end
                    5'ha: begin     
                            reg_triangle_timelow <= data_from_cpu;  
                        end
                    5'hb: begin     
                            reg_triangle_timehigh <= data_from_cpu; 
                            triangle_length_update<=1;
                        end
                    5'hc: begin     
                            reg_noise_ctrl <= data_from_cpu;       
                            noise_ctrl_update<=1;
                        end
                    5'he: begin     
                            reg_noise_timelow <= data_from_cpu;    
                            noise_timelow_update<=1;
                        end
                    5'hf: begin     
                            reg_noise_timehigh <= data_from_cpu;   
                            noise_timehigh_update<=1;
                        end
                    5'h10: begin    
                            reg_dmc_ctrl <= data_from_cpu;         
                            dmc_ctrl_update<=1;
                        end
                    5'h11: begin    
                            reg_dmc_direct <= data_from_cpu;       
                            dmc_direct_update<=1;
                        end
                    5'h12: begin    
                            reg_dmc_addr <= data_from_cpu;         
                            dmc_addr_update<=1;
                        end
                    5'h13: begin    
                            reg_dmc_length <= data_from_cpu;       
                            dmc_length_update<=1;
                        end
                    5'h15: begin    
                            reg_apu_enable <= data_from_cpu;    
                            dmc_clrint <= 0;
                        end
                    5'h16: begin    
                        ctrl_strobe <= data_from_cpu[2:0];
                        end
                    5'h17: begin    
                        framectr_mode <= data_from_cpu[7];
                        framectr_int <= data_from_cpu[6];
                        framectr_update<=1;
                        end
                    default: begin end
                endcase
            end
        end



    end
end

wire pulse0_en = reg_apu_enable[0];
wire pulse1_en = reg_apu_enable[1];
wire triangle_en = reg_apu_enable[2];
wire noise_en = reg_apu_enable[3];
wire dmc_en = reg_apu_enable[4];

wire frame_irq;
wire dmc_irq = 0;
wire dmc_active = 0;
wire noise_active=0;
wire triangle_active;
wire pulse1_active, pulse0_active;
wire [7:0] reg_apu_status_rd = {dmc_irq, frame_irq, 1'b0, dmc_active, noise_active, triangle_active, pulse1_active, pulse0_active};

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
    .IRQ    (irq || frame_irq || dmc_irq  ),
    .addr   (addr_from_cpu   ),
    .dor    (data_from_cpu    ),
    .RW     (cpu_rw     ),
    .sync   (sync   ),
    .jam    (jam    )
);

assign data_to_cpu = apu_cs_r ? apu_data_rd : data_i;

logic apu_cycle, qtrframe, halfframe, frame_irq;
apu_framecounter u_apu_framecounter(
    .clk          (clk          ),
    .rst          (rst          ),
    .mode       (framectr_mode ),
    .interrupt_en       (framectr_int ),
    .update        (framectr_update),
    .clrint        (framectr_clrint),
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
    .reg_ctrl         (reg_pulse0_ctrl         ),
    .reg_sweep        (reg_pulse0_sweep        ),
    .reg_timelow      (reg_pulse0_timelow      ),
    .reg_timehigh     (reg_pulse0_timehigh     ),
    .reg_ctrl_update  (pulse0_ctrl_update  ),
    .reg_sweep_update (pulse0_sweep_update ),
    .reg_len_update   (pulse0_length_update),
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
    .reg_ctrl         (reg_pulse1_ctrl         ),
    .reg_sweep        (reg_pulse1_sweep        ),
    .reg_timelow      (reg_pulse1_timelow      ),
    .reg_timehigh     (reg_pulse1_timehigh     ),
    .reg_ctrl_update  (pulse1_ctrl_update  ),
    .reg_sweep_update (pulse1_sweep_update ),
    .reg_len_update   (pulse1_length_update),
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
    .reg_ctrl        (reg_triangle_ctrl        ),
    .reg_timelow     (reg_triangle_timelow     ),
    .reg_timehigh    (reg_triangle_timehigh    ),
    .reg_ctrl_update (triangle_ctrl_update ),
    .reg_len_update  (triangle_length_update  ),
    .active          (triangle_active          ),
    .sample          (triangle_sample          )
);

wire [3:0] noise_sample = 4'h0;
wire [6:0] dmc_sample = 7'h0;
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
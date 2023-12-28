`timescale 1ns/1ps

module mapper_004 #(
    parameter PRG_ROM_DEPTH=17,
    parameter CHR_ROM_DEPTH=15,
    parameter PRG_RAM_DEPTH=13
    )(
    input logic rst,
    input logic clk_cpu,m2,
    input logic clk_ppu,
    input logic [14:0] cpu_addr,
    input logic [7:0] cpu_data_i,
    input logic [13:0] ppu_addr,
    input logic cpu_rw,
    input logic romsel,
    input logic [1:0] mirroring,
    input logic chr_ram,
    input logic prg_ram,
    input logic [PRG_ROM_DEPTH-1:0] prg_mask,
    input logic [CHR_ROM_DEPTH-1:0] chr_mask,
    input logic [PRG_RAM_DEPTH-1:0] prgram_mask,

    output logic [PRG_ROM_DEPTH-1:0] prg_addr,
    output logic [CHR_ROM_DEPTH-1:0] chr_addr,
    output logic [PRG_RAM_DEPTH-1:0] prgram_addr,
    output logic prg_cs,
    output logic chr_cs,
    output logic prgram_cs,
    output logic [7:0] mapper_reg_o,

    output logic ciram_ce,
    output logic ciram_a10,
    output logic irq
);

    assign mapper_reg_o = 0;

    logic [7:0] bank_sel, irq_latch;
    logic mirrorv, ram_en, ram_protect, irq_enable, irq_reload;
    wire [2:0] reg_sel = bank_sel[2:0];
    wire rom_bank_mode = bank_sel[6];
    wire chr12_inv = bank_sel[7];

    assign ciram_ce = ppu_addr[13];
    assign ciram_a10 = mirrorv ? ppu_addr[11] : ppu_addr[10];


    logic [7:0] Rbanks[0:7];
    always_ff @(posedge clk_cpu) begin
        if (rst) begin
            for (int i=0; i<8; i++) Rbanks[i] <= 0;
            bank_sel <= 0;
            mirrorv <= 0;
            ram_en <= 0;
            ram_protect <= 0;
            irq_latch <= 0;
            irq_enable <= 0;
            irq_reload <= 0;
        end else begin
            irq_reload <= 0;
            if(romsel && !cpu_rw) begin
                if(cpu_addr[0]) begin
                    //odd registers
                    case(cpu_addr[14:13])
                        2'h0: Rbanks[reg_sel] <= cpu_data_i;
                        2'h1: {ram_en, ram_protect} <= cpu_data_i[7:6];
                        2'h2: irq_reload <= 1;
                        2'h3: irq_enable <= 1;
                    endcase
                end else begin
                    //even registers
                    case(cpu_addr[14:13])
                        2'h0: bank_sel <= cpu_data_i;
                        2'h1: mirrorv <= cpu_data_i[0];
                        2'h2: irq_latch <= cpu_data_i;
                        2'h3: irq_enable <= 0;
                    endcase
                end
            end
        end
    end

    logic [7:0] chr_bank;
    wire [2:0] ppu_addr_high = {chr12_inv ^ ppu_addr[12], ppu_addr[11:10]};
    always_comb begin
        case(ppu_addr_high)
            3'h0: chr_bank = {Rbanks[0][7:1],1'b0};
            3'h1: chr_bank = {Rbanks[0][7:1],1'b1};
            3'h2: chr_bank = {Rbanks[1][7:1],1'b0};
            3'h3: chr_bank = {Rbanks[1][7:1],1'b1};
            3'h4: chr_bank = Rbanks[2];
            3'h5: chr_bank = Rbanks[3];
            3'h6: chr_bank = Rbanks[4];
            3'h7: chr_bank = Rbanks[5];
        endcase

        chr_addr = CHR_ROM_DEPTH'({chr_bank, ppu_addr[9:0]}) & chr_mask;
        chr_cs = ~ciram_ce;
    end

    logic [5:0] prg_bank;
    always_comb begin
        case(cpu_addr[14:13])
            2'h0: prg_bank = rom_bank_mode ? 6'h3e : Rbanks[6][5:0];
            2'h1: prg_bank = Rbanks[7][5:0];
            2'h2: prg_bank = rom_bank_mode ? Rbanks[6][5:0] : 6'h3e;
            2'h3: prg_bank = 6'h3f;
        endcase

        prg_addr = PRG_ROM_DEPTH'({prg_bank, cpu_addr[12:0]}) & prg_mask;
        prg_cs = romsel;
    end

    assign prgram_cs = ram_en && prg_ram && ~romsel && (cpu_addr[14:13] == 2'b11);
    assign prgram_addr = prgram_mask & PRG_RAM_DEPTH'(cpu_addr[12:0]);

    logic [7:0] irq_cnt;
    wire irq_cnt0 = irq_cnt == 0;
    wire a12 = ppu_addr[12];
    logic [2:0] a12_reg;
    wire a12_re = a12 && ~|a12_reg;
    logic reload_flag;

    always_ff @(posedge clk_cpu) begin
        if (rst) begin
            irq <= 0;
            irq_cnt <= 0;
            a12_reg <= 0;
            reload_flag <= 0;
        end else begin
            a12_reg <= {a12_reg[1:0], a12};

            if(irq_reload) begin
                irq_cnt <= 0;
                reload_flag <= 1;
            end

            if(irq_enable)
                if ( irq_cnt0 && !reload_flag ) irq <= 1;
            else irq <= 0;

            if(a12_re) begin
                if ( irq_cnt0 ) begin
                    irq_cnt <= irq_latch;
                    reload_flag <= 0;
                end
                else irq_cnt <=  irq_cnt - 1;                
            end
        end
    end

endmodule
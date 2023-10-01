`timescale 1ns/1ps

module mapper_001 #(
    parameter PRG_ROM_DEPTH=17,
    parameter CHR_ROM_DEPTH=15,
    parameter PRG_RAM_DEPTH=13
    )(
    input logic rst,
    input logic clk_cpu,
    input logic [14:0] cpu_addr,
    input logic [7:0] cpu_data_i,
    input logic [13:0] ppu_addr,
    input logic cpu_rw,
    input logic romsel,
    input logic mirrorv,
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


// https://www.nesdev.org/wiki/MMC1#SNROM
// Unlike almost all other mappers, the MMC1 is configured through a serial
// port in order to reduce its pin count. CPU $8000-$FFFF is connected to a
// common shift register. Writing a value with bit 7 set ($80 through $FF) 
// to any address in $8000-$FFFF clears the shift register to its initial 
// state. To change a register's value, the CPU writes five times with bit 7 
// clear and one bit of the desired value in bit 0 (starting with the low bit 
// of the value). On the first four writes, the MMC1 shifts bit 0 into a shift
// register. On the fifth write, the MMC1 copies bit 0 and the shift register
// contents into an internal register selected by bits 14 and 13 of the address,
// and then it clears the shift register. Only on the fifth write does the
// address matter, and even then, only bits 14 and 13 of the address matter 
// because the mapper doesn't see the lower address bits (similar to the
// mirroring seen with PPU registers). After the fifth write, the shift
// register is cleared automatically, so writing again with bit 7 set to 
// clear the shift register is not needed.


    logic [4:0] sr;
    logic [4:0] ctrl_reg, chr0_reg, chr1_reg, prg_reg;
    wire [1:0] reg_sel = cpu_addr[14:13];

    wire [1:0] mirroring = ctrl_reg[1:0];
    wire [1:0] prgbankmode = ctrl_reg[3:2];
    wire chr_4k_banks = ctrl_reg[4];

    assign ciram_ce = ppu_addr[13];
    assign ciram_a10 = ~mirroring[1] ? mirroring[0] :
                        mirroring[0] ? ppu_addr[11] : ppu_addr[10];
    assign irq = 0;
    assign chr_cs = ~ciram_ce;

    wire [4:0] sr_in = {cpu_data_i[0], sr[4:1]};
    logic reg_wr;
    always_ff @(posedge clk_cpu) begin
        if (rst) begin
            sr <= 0;
            ctrl_reg <= 5'h0c; //powerup in mode 3: fix last prgrom bank at $C000 and switch 16 KB bank at $8000
            chr0_reg <= 0;
            chr1_reg <= 0;
            prg_reg <= 0;
            reg_wr <= 0;
        end else begin
            sr <= sr;
            ctrl_reg <= ctrl_reg;
            chr0_reg <= chr0_reg;
            chr1_reg <= chr1_reg;
            prg_reg <= prg_reg;
            reg_wr <= 0;
            if (romsel && !cpu_rw) begin
                // writing to control shift reg
                if (cpu_data_i[7]) begin
                    sr <= 5'b10000;         // reset sr
                    ctrl_reg <= ctrl_reg | 5'h0c;   // set prg rom mode 3
                end else if(!reg_wr) begin
                    // shift in bit (ignore consecutive writes)
                    if (sr[0]) begin
                        // 1 has reached lsb so this is last write
                        case(reg_sel)
                            2'h0: ctrl_reg <= sr_in;
                            2'h1: chr0_reg <= sr_in;
                            2'h2: chr1_reg <= sr_in;
                            2'h3: prg_reg <= sr_in;
                            default: begin end
                        endcase
                        sr <= 5'b10000;     
                    end else begin
                        sr <= sr_in;
                    end
                end
                reg_wr <= 1;
            end
        end
    end

    // PRG ROM
    assign prg_cs = romsel;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_bank16k = PRG_ROM_DEPTH'({prg_reg,cpu_addr[13:0]});
    wire [PRG_ROM_DEPTH-1:0] prg_rom_bank32k = PRG_ROM_DEPTH'({prg_reg[4:1],cpu_addr[14:0]});

    //    mode 0/1: switch 32 KB at $8000, ignoring low bit of bank number;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr_mode1 = prg_rom_bank32k;
    //     mode 2: fix first bank at $8000 and switch 16 KB bank at $C000;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr_mode2 = cpu_addr[14] ? prg_rom_bank16k : PRG_ROM_DEPTH'(cpu_addr[13:0]);
    //     mode 3: fix last bank at $C000 and switch 16 KB bank at $8000)    
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr_mode3 = cpu_addr[14] ? { {(PRG_ROM_DEPTH-14){1'b1}},cpu_addr[13:0]} : prg_rom_bank16k;

    wire [PRG_ROM_DEPTH-1:0] prg_addr_full = ~prgbankmode[1] ? prg_rom_addr_mode1 :
                                                prgbankmode[0] ? prg_rom_addr_mode3 :
                                                                prg_rom_addr_mode2 ;
    assign prg_addr = prg_mask & prg_addr_full;

    // CHR ROM
    assign chr_cs = ~ciram_ce;
    wire [4:0] chr_bank = ppu_addr[12] ? chr1_reg : chr0_reg;
    wire [CHR_ROM_DEPTH-1:0]  chr4k_addr = CHR_ROM_DEPTH'({chr_bank,ppu_addr[11:0]});
    wire [CHR_ROM_DEPTH-1:0]  chr8k_addr = CHR_ROM_DEPTH'({chr0_reg[4:1],ppu_addr[12:0]});
    assign  chr_addr = chr_mask & (chr_4k_banks ? chr4k_addr : chr8k_addr);

    // PRG RAM
    assign prgram_cs = prg_ram && ~(romsel || prg_reg[4]) && (cpu_addr[14:13] == 2'b11);
    assign prgram_addr = prgram_mask & PRG_RAM_DEPTH'(cpu_addr[12:0]);

    assign mapper_reg_o = 0;

endmodule
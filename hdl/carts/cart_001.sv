`timescale 1ns/1ps

module cart_001 #(
    parameter PRG_FILE,
    parameter CHR_FILE="",
    parameter PRG_ROM_DEPTH=17,
    parameter PRG_RAM_DEPTH=13,
    parameter CHR_ROM_DEPTH=13,
    parameter CHR_RAM=1,
    parameter PRG_RAM=1
    )(
    input logic rst,
    input logic clk_cpu, m2,
    input logic [14:0] cpu_addr,
    input logic [7:0] cpu_data_i,
    output logic [7:0] cpu_data_o,
    input logic cpu_rw,
    input logic romsel,
    output logic ciram_ce,
    output logic ciram_a10,

    input logic clk_ppu,
    input logic [13:0] ppu_addr,
    input logic [7:0] ppu_data_i,
    output logic [7:0] ppu_data_o,
    input logic ppu_rd,
    input logic ppu_wr,

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
    wire prg_ram_en = ~(romsel || prg_reg[4]);

    wire [1:0] mirroring = ctrl_reg[1:0];
    wire [1:0] prgbankmode = ctrl_reg[3:2];
    wire chr_4k_banks = ctrl_reg[4];

    assign ciram_a10 = ~mirroring[1] ? mirroring[0] :
                        mirroring[0] ? ppu_addr[10] : ppu_addr[11];
    assign ciram_ce = ppu_addr[13];
    assign irq = 0;
    wire chr_cs = ~ciram_ce;

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
    localparam PRG_ROM_BANK_DEPTH = PRG_ROM_DEPTH-14;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_bank16k = {prg_reg[PRG_ROM_BANK_DEPTH-1:0],cpu_addr[13:0]};
    wire [PRG_ROM_DEPTH-1:0] prg_rom_bank32k = {prg_reg[PRG_ROM_BANK_DEPTH-1:1],cpu_addr[14:0]};

    //    mode 0/1: switch 32 KB at $8000, ignoring low bit of bank number;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr_mode1 = prg_rom_bank32k;
    //     mode 2: fix first bank at $8000 and switch 16 KB bank at $C000;
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr_mode2 = cpu_addr[14] ? prg_rom_bank16k : {{PRG_ROM_BANK_DEPTH{1'b0}},cpu_addr[13:0]};
    //     mode 3: fix last bank at $C000 and switch 16 KB bank at $8000)    
    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr_mode3 = cpu_addr[14] ? { {PRG_ROM_BANK_DEPTH{1'b1}},cpu_addr[13:0]} : prg_rom_bank16k;

    wire [PRG_ROM_DEPTH-1:0] prg_rom_addr = ~prgbankmode[1] ? prg_rom_addr_mode1 :
                                            prgbankmode[0] ? prg_rom_addr_mode3 : prg_rom_addr_mode2 ;

    logic [7:0] prg_rom[0:2**PRG_ROM_DEPTH-1];
    initial begin
        $display("Loading PRG ROM: %s", PRG_FILE);
        $readmemh(PRG_FILE, prg_rom);
    end

    logic [7:0] prg_rom_rd;
    always @(posedge clk_cpu) begin
        if (romsel) begin
            prg_rom_rd <= prg_rom[prg_rom_addr];
        end
    end

    // CHR ROM
    localparam CHR_BANK_DEPTH = CHR_ROM_DEPTH-12;
    wire [CHR_BANK_DEPTH-1:0] chr_bank = ppu_addr[12] ? chr1_reg[CHR_BANK_DEPTH-1:0] : chr0_reg[CHR_BANK_DEPTH-1:0];
    wire [CHR_ROM_DEPTH-1:0]  chr4k_addr = {chr_bank,ppu_addr[11:0]};
    wire [CHR_ROM_DEPTH-1:0]  chr8k_addr;
    generate
        if(CHR_BANK_DEPTH>1) assign chr8k_addr = {chr0_reg[CHR_BANK_DEPTH-1:1],ppu_addr[12:0]};
        else                 assign chr8k_addr = ppu_addr[12:0];
    endgenerate
    wire [CHR_ROM_DEPTH-1:0]  chr_addr = chr_4k_banks ? chr4k_addr : chr8k_addr;

    logic [7:0] chr  [0:2**CHR_ROM_DEPTH-1];
    initial begin
        if (!CHR_RAM) begin
            $display("Loading CHR ROM: %s ", CHR_FILE);
            $readmemh(CHR_FILE, chr);
        end
    end

    logic [7:0] chr_rd;
    wire chr_we = CHR_RAM && !cpu_rw;
    always @(posedge clk_ppu) begin
        if (chr_cs) begin
            if (chr_we) chr[chr_addr] <= ppu_data_i;
            else chr_rd <= chr[chr_addr];
        end
    end
    `ifdef SAVERAMS
            final begin
                if(CHR_RAM) begin
                    $display("Saving CHR RAM");
                    $writememh("logs/chr_ram.mem", chr);
                end
            end
    `endif

    // PRG RAM and final mux
    logic [7:0] prg_ram_rd;
    generate
        if(PRG_RAM) begin
            logic [7:0] prg_ram[0:2**PRG_RAM_DEPTH-1];
            wire prg_ram_cs = prg_ram_en && (cpu_addr[14:13] == 2'b11);
            wire [PRG_RAM_DEPTH-1:0] prg_ram_addr = cpu_addr[12:0];        
            always @(posedge clk_cpu) begin
                if (prg_ram_cs) begin
                    if (!cpu_rw) prg_ram[prg_ram_addr] <= cpu_data_i;
                    else prg_ram_rd <= prg_ram[prg_ram_addr];
                end
            end

            `ifdef SAVERAMS
                final begin
                    $display("Saving PRG RAM");
                    $writememh("logs/prg_ram.mem", prg_ram);
                end
            `endif

        end else begin
            assign prg_ram_rd = 0;
        end
    endgenerate

    logic romsel_r;
    always @(posedge clk_cpu) romsel_r <= romsel;
    assign cpu_data_o = romsel_r ? prg_rom_rd : prg_ram_rd;

    logic chr_cs_r;
    always @(posedge clk_ppu) chr_cs_r <= chr_cs;
    assign ppu_data_o = chr_cs_r ? chr_rd : 0;


endmodule
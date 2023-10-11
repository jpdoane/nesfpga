
; NES header
.segment "HEADER"

.byt $4E, $45, $53, $1A     ; "NES" + EOL
.byt $2                     ; 32k PRG
.byt $1                     ; 8k CHR
.byt $0                     ; mappor0, mirrorH
.res 9                      ; pad to 16B

;----------------
.segment "CODE"

; address constants
PPU_CTRL_REG1         = $2000
PPU_CTRL_REG2         = $2001
PPU_STATUS            = $2002
PPU_SPR_ADDR          = $2003
PPU_SPR_DATA          = $2004
PPU_SCROLL_REG        = $2005
PPU_ADDRESS           = $2006
PPU_DATA              = $2007
SND_REGISTER          = $4000
SND_SQUARE1_REG       = $4000
SND_SQUARE2_REG       = $4004
SND_TRIANGLE_REG      = $4008
SND_NOISE_REG         = $400c
SND_DELTA_REG         = $4010
SND_MASTERCTRL_REG    = $4015

SPR_DMA               = $4014
JOYPAD_PORT           = $4016

JOY_A                = $80
JOY_B                = $40
JOY_SELECT           = $20
JOY_START            = $10
JOY_UP               = $08
JOY_DOWN             = $04
JOY_LEFT             = $02
JOY_RIGHT            = $01

; list of roms and final selection is stored in WRAM
WRAM_ROMTITLES        = $6000
WRAM_SELECTION       = $7ffe
WRAM_COMPLETE        = $7fff


; value constants
TITLE_X            = 3
TITLE_Y            = 3
FILELIST_X         = 8
FILELIST_Y         = 6
POINTER            = 1

; zero page variables (1 bytes)
SELECTION               = $0
SELECTION_MADE          = $1
NUMROMS                = $2
XCOORD                  = $3
YCOORD                  = $4
CONTROLLER_STATE        = $5
BUTTON_PRESS            = $6    ;initial press (rising edge)


; zero page pointers (2 bytes)
STRING_PTR           = $10



Start:
             sei                          ;pretty standard 6502 type init here
             cld
             lda #%00000000               ;init PPU control register 1 
             sta PPU_CTRL_REG1
             ldx #$ff                     ;reset stack pointer
             txs
VBlank1:     lda PPU_STATUS               ;wait a frame
             bpl VBlank1
VBlank2:     lda PPU_STATUS               ;wait a frame
             bpl VBlank2

             jsr InitializeLoader

            jsr DrawMenu
            lda NUMROMS
            beq skip_ptr
            jsr DrawPointer
skip_ptr:            
            jsr ResetNameTable

             lda #%00001000               ;enable BG rendering
              sta PPU_CTRL_REG2

             lda #%10000000               ;enable NMIs
              sta PPU_CTRL_REG1

EndlessLoop: jmp EndlessLoop              ;endless loop, need I say more?


InitializeLoader:

            ; zero scroll
            bit PPU_STATUS
            lda #$0
            sta SELECTION
            sta PPU_SCROLL_REG
            lda #$0
            sta PPU_SCROLL_REG


InitializePalette:
            lda #$3f
            sta PPU_ADDRESS
            lda #$00
            sta PPU_ADDRESS
            lda #$11            ;blue
            sta PPU_DATA
            lda #$30            ;white
            sta PPU_DATA
            lda #$1d            ;black
            sta PPU_DATA
;            lda #$16            ;red
            lda #$30            ;red
            sta PPU_DATA

InitializeNameTables:
              lda PPU_STATUS            ;reset flip-flop
              lda #0            ;use first pattern table
              sta PPU_CTRL_REG1
              lda #$24                  ;set vram address to start of name table 1
              jsr WriteNTAddr
              lda #$20                  ;and then set it to name table 0
WriteNTAddr:  sta PPU_ADDRESS
              lda #$00
              sta PPU_ADDRESS
              ldx #$04                  ;clear name table with blank tile #0
              ldy #$c0
              lda #$00
InitNTLoop:   sta PPU_DATA              ;count out exactly 768 tiles (x*y)
              dey
              bne InitNTLoop
              dex
              bne InitNTLoop
              ldy #64                   ;now to clear the attribute table (with zero this time)
              txa
;              sta VRAM_Buffer1_Offset   ;init vram buffer 1 offset
;              sta VRAM_Buffer1          ;init vram buffer 1
InitATLoop:   lda #$0
              sta PPU_DATA
              dey
              bne InitATLoop

              lda #$0
                sta PPU_SCROLL_REG       
               sta PPU_SCROLL_REG        

               rts

NonMaskableInterrupt:
                lda NUMROMS
                beq nmi_return
                jsr readjoy
                lda BUTTON_PRESS
                and #JOY_UP
                bne press_up
                lda BUTTON_PRESS
                and #JOY_DOWN
                bne press_down
                lda CONTROLLER_STATE ;
                and #JOY_A
                bne make_selection
nmi_return:     jsr ResetNameTable
                rti

press_up:       jsr PointerPrev
                jmp nmi_return

press_down:     jsr PointerNext
                jmp nmi_return

make_selection: 
                lda SELECTION
                sta WRAM_SELECTION    ; write result
                lda #$1
                sta WRAM_COMPLETE     ; signal that we are done
                jmp nmi_return

ResetNameTable:
                lda #$20
                sta PPU_ADDRESS
                lda #$00
                sta PPU_ADDRESS
                rts

title_string:
.ASCIIZ "*******NES on FPGA*******"
.ASCIIZ "Select ROM:"
empty_string:
.ASCIIZ "No ROMs Found :("

DrawMenu:
                lda #0
                sta NUMROMS
                LDA #<title_string
                STA STRING_PTR
                LDA #>title_string
                STA STRING_PTR + 1
                lda #TITLE_X
                sta XCOORD
                lda #TITLE_Y
                sta YCOORD
                jsr GotoXY
                jsr WriteText       ;write title
                inc YCOORD
                jsr GotoXY
                jsr WriteText       ;write instructions
                lda #FILELIST_X
                sta XCOORD
                lda #FILELIST_Y
                sta YCOORD
                lda WRAM_ROMTITLES      ; check for empty table
                beq empty_table
                LDA #<WRAM_ROMTITLES
                STA STRING_PTR
                LDA #>WRAM_ROMTITLES
                STA STRING_PTR + 1


DrawMenuLoop:   jsr GotoXY
                inc YCOORD
                inc NUMROMS
                jsr WriteText
                bne DrawMenuLoop
                rts

empty_table:    jsr GotoXY
                LDA #<empty_string
                STA STRING_PTR
                LDA #>empty_string
                STA STRING_PTR + 1
                jsr WriteText
                rts

PointerNext:    lda SELECTION
                jsr ClearPointer 
                inc SELECTION
                lda SELECTION
                cmp NUMROMS
                bne DrawPointer     
                lda #0
                sta SELECTION
                jmp DrawPointer

PointerPrev:    lda SELECTION
                jsr ClearPointer 
                lda SELECTION
                bne PointerDec      ; wrap to end if we are at position 0
                lda NUMROMS   
                sta SELECTION
PointerDec:     dec SELECTION
                jmp DrawPointer
                sta SELECTION
                jmp DrawPointer


ClearPointer:   jsr GotoPointer 
                lda #$0
                sta PPU_DATA
                rts

DrawPointer:    jsr GotoPointer 
                lda #POINTER
                sta PPU_DATA
                rts

GotoPointer:
                lda #FILELIST_X
                sta XCOORD
                dec XCOORD
                dec XCOORD
                lda #FILELIST_Y
                clc
                adc SELECTION
                sta YCOORD
                jsr GotoXY
                rts

GotoXY:
                lda YCOORD          ; load y coord
                lsr
                lsr
                lsr                 ; y >> 3 = y/8
                clc
                adc #$20            ; $20 + y/8
                sta PPU_ADDRESS     ; high ppu_addr byte
                lda YCOORD          ; load y coord
                asl
                asl
                asl
                asl
                asl                 ; y << 5 = y*$20
                clc
                adc XCOORD          ; y*$20 + x
                sta PPU_ADDRESS     ; low ppu_addr byte
                rts



; WriteText
;   copy zero terminated string with address stored at STRING_PTR to ppu memory
;   on return, STRING_PTR will point at the subsequent string, with str_next[0] in A

WriteText:
    ldy #0    
WriteText_Loop:
    lda (STRING_PTR),y  ; load str[y]
    beq WriteText_NextString      ; if 0, then string is over
    sta PPU_DATA        ; store character in nametable
    iny
    jmp WriteText_Loop
WriteText_NextString:
    iny
    tya                 ; update STRING_PTR with addr of next string
    clc
    adc STRING_PTR
    sta STRING_PTR
    bcc WriteText_Done  ; carry ?
    inc STRING_PTR+1    ; carry address increment
WriteText_Done:
    ldy #$0
    lda (STRING_PTR),y    ; load first char of next string
    rts


readjoy:
    ldx CONTROLLER_STATE; store previous state in x
    lda #$01
    sta JOYPAD_PORT
    sta CONTROLLER_STATE
    lsr          ; now A is 0
    ; By storing 0 into JOYPAD_PORT, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD_PORT.
    sta JOYPAD_PORT
readjoy_loop:
    lda JOYPAD_PORT
    lsr 	       ; bit 0 -> Carry
    rol CONTROLLER_STATE  ; Carry -> bit 0; bit 7 -> Carry
    bcc readjoy_loop

    ; mark new button press
    txa                     ; load old state
    eor #$FF                ; which buttons were not pressed last frame (bitwise not)
    and CONTROLLER_STATE    ; .. but are currently being pressed
    sta BUTTON_PRESS        ; store new presses
    rts

brk

; ;-----------------------------
; ; ROM TABLE
; .segment "ROMS"

; ROM_Table:
; .ASCIIZ "SMB.NES"
; .ASCIIZ "ZELDA.NES"
; .ASCIIZ "METROID.NES"
; .ASCIIZ "TETRIS.NES"
; .byt  0

;-------------------------------------------------------------------------------------
;INTERRUPT VECTORS
.segment "VECTORS"
    .addr NonMaskableInterrupt
    .addr $8000
    .addr $fff0


; CHR
.segment "TILES"
.INCBIN "font_chr.bin"
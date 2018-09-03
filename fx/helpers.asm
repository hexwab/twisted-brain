\ ******************************************************************
\ *	FX Helper functions
\ ******************************************************************

_DONT_HIDE_SCREEN = FALSE		; for debugging FX init
_REAL_HARDWARE = FALSE			; emu

.helpers_start

\\ During script update a new FX was requested so we're being killed
\\ This took place somewhere around vsync (during flyback) so CRTC cycle
\\ might well be malformed.  We need to let next frame complete properly

.crtc_reset
{
IF 1

	LDX #13
	.crtcloop
	STX &FE00
	LDA crtc_regs_high,X
	STA &FE01
	DEX
	BPL crtcloop
	RTS

ELSE

	LDX #9:STX &FE00:LDA #7:STA &FE01
	LDX #4:STX &FE00:LDA #38:STA &FE01
	LDX #6:STX &FE00:LDA #32:STA &FE01
	LDX #7:STX &FE00:LDA #35:STA &FE01
	LDX #8:STX &FE00:LDA #&30:STA &FE01
	LDX #5:STX &FE00:LDA #0:STA &FE01
	LDX #12:STX &FE00:LDA #HI(screen_base_addr/8):STA &FE01
	LDX #13:STX &FE00:LDA #LO(screen_base_addr/8):STA &FE01
	LDX #0:STX &FE00:LDA #127:STA &FE01
	LDX #1:STX &FE00:LDA #80:STA &FE01
	LDX #2:STX &FE00:LDA #98:STA &FE01
	LDX #3:STX &FE00:LDA #&28:STA &FE01
	RTS

ENDIF
}

.crtc_reset_from_single
\{
	\\ We lose a scanline here because R4=0

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00

	.crtc_reset_from_single_hardware_SM
	LDA #6:	STA &FE01		; 7 scanlines or 8? Do you feel lucky punk?

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #38: STA &FE01		; 312

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #35: STA &FE01		; 280 - 256 = 24 scanlines - was +1
	
	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #32: STA &FE01			; was +1
	
	\\ Wait 7 scanlines so next character row
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128
	JSR cycles_wait_128

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #7:	STA &FE01		; 8 scanlines?

	LDA #12: STA &FE00
	LDA #HI(screen_base_addr/8): STA &FE01
	LDA #13: STA &FE00
	LDA #LO(screen_base_addr/8): STA &FE01

	\\ Horizontal values
	LDA #0: STA &FE00
	LDA #127: STA &FE01

	LDA #1: STA &FE00
	LDA #80: STA &FE01

	LDA #2: STA &FE00
	LDA #98: STA &FE01

	RTS
\}

.crtc_regs_high
{
	EQUB 127			; R0  horizontal total
	EQUB 80				; R1  horizontal displayed
	EQUB 98				; R2  horizontal position
	EQUB &28			; R3  sync width 40 = &28
	EQUB 38				; R4  vertical total
	EQUB 0				; R5  vertical total adjust
	EQUB 32				; R6  vertical displayed
	EQUB 35				; R7  vertical position; 35=top of screen
	EQUB &30			; R8  interlace = HIDE SCREEN
	EQUB 7				; R9  scanlines per row
	EQUB 32				; R10 cursor start
	EQUB 8				; R11 cursor end
	EQUB HI(screen_base_addr/8)		; R12 screen start address, high
	EQUB LO(screen_base_addr/8)		; R13 screen start address, low
}

.crtc_hide_screen
{
IF _DONT_HIDE_SCREEN=FALSE
	LDA #8:STA &FE00
	LDA #&30:STA &FE01
ENDIF
	RTS
}

.crtc_show_screen
{
IF _DONT_HIDE_SCREEN=FALSE
	LDA #8:STA &FE00
	LDA #0:STA &FE01
ENDIF
	RTS
}

.wait_vsync
{
	lda #2
	.vsync1
	bit &FE4D
	beq vsync1 \ wait for vsync
	sta &FE4D \ 4(stretched), ack vsync
	rts	
}

.music_poll_if_vsync
{
	RTS \ this gets turned into PHA later

	lda #2
	.vsync1
	bit &FE4D
	beq return
	sta &FE4D \ 4(stretched), ack vsync

	LDA &F4:PHA

	LDA #SLOT_MUSIC:JSR swr_select_slot

	PHX:PHY
	JSR vgm_poll_player
	PLY:PLX

	PLA:JSR swr_select_slot

	.return
	PLA
	rts	
}

.ula_pal_reset
{
	LDX #LO(ula_pal_defaults)
	LDY #HI(ula_pal_defaults)
}
\\ Fall through!
.ula_set_palette
{
	STX palloop+1
	STY palloop+2
	LDX #15
	.palloop
	LDA ula_pal_defaults, X
	STA &FE21
	DEX
	BPL palloop
	RTS	
}

.ula_pal_defaults
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_red
	EQUB &20 + PAL_green
	EQUB &30 + PAL_yellow
	EQUB &40 + PAL_blue
	EQUB &50 + PAL_magenta
	EQUB &60 + PAL_cyan
	EQUB &70 + PAL_white
	EQUB &80 + PAL_black
	EQUB &90 + PAL_red
	EQUB &A0 + PAL_green
	EQUB &B0 + PAL_yellow
	EQUB &C0 + PAL_blue
	EQUB &D0 + PAL_magenta
	EQUB &E0 + PAL_cyan
	EQUB &F0 + PAL_white
}

.ula_control_reset
{
    LDA #ULA_Mode2
}
\\ Fall through!
.ula_set_mode
{
    STA &FE20
    STA &248            ; Tell the OS or it will mess with ULA settings at vsync
    RTS
}

.screen_clear_all
{
  ldx #HI(SCREEN_SIZE_BYTES)
  lda #HI(screen_base_addr)

  sta loop+2

  JSR music_poll_if_vsync

  lda #0
  ldy #0
  .loop
  sta &3000,Y
  iny
  bne loop
  inc loop+2

  JSR music_poll_if_vsync

  dex
  bne loop
  rts
}

.screen_clear_line_0X
{
	LDA #0
	FOR n,0,79
	STA screen_base_addr + n * 8, X
	NEXT
	RTS
}

.screen_calc_addr_lineX
{
	TXA
    LSR A:LSR A: LSR A
    TAY

    LDA picture_screen_addr_LO, Y
    STA writeptr

    LDA picture_screen_addr_HI, Y
    STA writeptr+1

    TXA
    AND #&7
    CLC
    ADC writeptr
    STA writeptr
    STA readptr
    LDA writeptr+1
    ADC #0
    STA writeptr+1
    STA readptr+1

	RTS
}

.cycles_wait_128		; JSR to get here takes 6c
{
	FOR n,1,58,1		; 58x
	NOP					; 2c
	NEXT				; = 116c
	RTS					; 6c
}						; = 128c

.pal_set_mode1_colour2
	ORA #&80
	BRA pal_set_mode1

.pal_set_mode1_colour3
	ORA #&A0
	BRA pal_set_mode1

.pal_set_mode1_colour1
	ORA #&20
	\\ fall through
	
.pal_set_mode1
{
	STA &FE21
	EOR #&10
	STA &FE21
	EOR #&40
	STA &FE21
	EOR #&10
	STA &FE21
	RTS
}

.pal_set_mode0_colour0
{
	STA &FE21						; 4c
	AND #&F:ORA #&10:STA &FE21		; 8c
	AND #&F:ORA #&20:STA &FE21		; 8c
	AND #&F:ORA #&30:STA &FE21		; 8c
	AND #&F:ORA #&40:STA &FE21		; 8c
	AND #&F:ORA #&50:STA &FE21		; 8c
	AND #&F:ORA #&60:STA &FE21		; 8c
	AND #&F:ORA #&70:STA &FE21		; 8c
	RTS	
}

.pal_set_mode0_colour1
{
	AND #&F:ORA #&80:STA &FE21		; 8c
	AND #&F:ORA #&90:STA &FE21		; 8c
	AND #&F:ORA #&A0:STA &FE21		; 8c
	AND #&F:ORA #&B0:STA &FE21		; 8c
	AND #&F:ORA #&C0:STA &FE21		; 8c
	AND #&F:ORA #&D0:STA &FE21		; 8c
	AND #&F:ORA #&E0:STA &FE21		; 8c
	AND #&F:ORA #&F0:STA &FE21		; 8c
	RTS
}

.twister_crtc_r1
EQUB 80

.twister_set_displayed
{
	STA twister_crtc_r1
	RTS
}

.twister_crtc_r2
EQUB 98

.twister_set_position
{
	STA twister_crtc_r2
	RTS
}

.helpers_end

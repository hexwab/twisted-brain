\ ******************************************************************
\ *	Logo glitch
\ ******************************************************************

logo_charrow = locals_start + 0
logo_bottom_scanline = locals_start + 1
logo_scroll = locals_start + 2
logo_speed = locals_start + 3

BLANKLINE_ADDR = $2200


narrow_screen_base_addr = &2400 - 39
narrow_screen_real = &2400
NARROW_CHARS = 61 ; 6845 chars

MACRO SCREEN_ADDR_ROW_NARROW row
	EQUW ((narrow_screen_base_addr + row*NARROW_CHARS*8) DIV 8)
ENDMACRO

MACRO SCREEN_ADDR_LO_NARROW row
      IF LO((narrow_screen_base_addr + row*NARROW_CHARS*8) DIV 8)==LO(BLANKLINE_ADDR DIV 8)
            ERROR "oops"
      ENDIF
	EQUB LO((narrow_screen_base_addr + row*NARROW_CHARS*8) DIV 8)
ENDMACRO

MACRO SCREEN_ADDR_HI_NARROW row
	EQUB HI((narrow_screen_base_addr + row*NARROW_CHARS*8) DIV 8)
ENDMACRO

BLANK = 25

MACRO BLANKLO
      EQUB LO(BLANKLINE_ADDR DIV 8)
      ;SCREEN_ADDR_LO_NARROW BLANK
ENDMACRO

MACRO BLANKHI 
      EQUB HI(BLANKLINE_ADDR DIV 8)
      ;SCREEN_ADDR_HI_NARROW BLANK
      ;EQUB 123
ENDMACRO

.logo_start
unpack_buffer = &7c00
	;; pack/unpack 8-byte-aligned bytes from 8 pages to/from 1
	;; page. packed format is undefined

IF 0 ; currently unused
.copypagetopacked
{
	STX srcloc+2
	STY dstloc+2
	LDY #0
.loop
	LDX mul8,Y
.srcloc
	LDA $FF00,X
.dstloc
	STA $FF00,Y
	INY
	TXA
	BNE loop
.zero
	INC srcloc+2
	TYA
	BNE loop
	RTS
}
ENDIF
.restorepagefrompacked
{
	STX srcloc+2
	STY dstloc+2
	LDY #0
.loop
	LDX mul8,Y
.srcloc
	LDA $FF00,Y
.dstloc
	STA $FF00,X
	INY
	TXA
	BNE loop
.zero
	INC dstloc+2
	TYA
	BNE loop
	RTS
}
.copyandshiftlines
{
	;; X is src line number, Y is dst line number, A is nlines
	STA temp
.linesloop
	LDA linelocslo,X
	STA srcloc+1
	LDA linelocshi,X
	STA srcloc+2
	LDA linelocslo,Y
	STA dstloc+1
	LDA linelocshi,Y
	STA dstloc+2
	PHX
	PHY
	JSR copyandshiftline
	PLY
	PLX
	INX
	INY
	DEC temp
	BNE linesloop
	RTS

.copyandshiftline
	CLC
	LDY #<mul8
	STY loop+1
	LDY #31
	JSR loop
	INC srcloc+2
	INC dstloc+2
	LDY #<mul8+3
	STY loop+1
	LDY #28
.loop
	LDX mul8,Y
.srcloc
	LDA $FF00,X
	ROR A
.dstloc
	STA $FF00,X
	DEY
	BPL loop
	RTS
}
;PAGE_ALIGN ;FIXME: why is this needed?
.logo_init
{
    LDA #0
    CLC
    .loop
    TAX
    STZ BLANKLINE_ADDR,X
    STZ BLANKLINE_ADDR+$100,X
    STZ &D200,X
    STZ &D300,X ; if we ever end up using shadow RAM
    ADC #8
    BNE loop
    LDX #LO(logo_screen_data)
    LDY #HI(logo_screen_data)
    LDA #HI(unpack_buffer)
    JSR PUCRUNCH_UNPACK
    LDX #HI(unpack_buffer)
    LDY #HI(narrow_screen_real)
    JSR restorepagefrompacked
    LDX #HI(unpack_buffer+$100)
    LDY #HI(narrow_screen_real+$800)
    JSR restorepagefrompacked
    LDX #HI(unpack_buffer+$200)
    LDY #HI(narrow_screen_real+$1000)
    JSR restorepagefrompacked

    LDX #0
    LDY #12
    TYA
    JSR copyandshiftlines
    LDX #12
    LDY #12
    TYA
    JSR copyandshiftlines

    LDX #12
    LDY #24
    LDA #12
    JSR copyandshiftlines
    LDX #24
    LDY #24
    LDA #12
    JSR copyandshiftlines

    LDX #24
    LDY #36
    LDA #12
    JSR copyandshiftlines
    LDX #36
    LDY #36
    LDA #12
    JSR copyandshiftlines

    SET_ULA_MODE ULA_Mode0
	LDX #LO(logo_pal)
	LDY #HI(logo_pal)
	JSR ula_set_palette

	STZ logo_scroll

	\\ R9=1 - displayed chars
	LDA #1: STA &FE00
	LDA #NARROW_CHARS: STA &FE01
	LDA #2: STA &FE00
	LDA #89: STA &FE01

	LDA #0
	JSR logo_set_anim

	LDA #255
	STA logo_bottom_scanline

    RTS
}
ALIGN $100 ; FIXME
.logo_update
{
	\\ Which line in the table is the bottom?
	LDX logo_bottom_scanline
	INX
	STX logo_bottom_scanline

	\\ Update our index into sine table

	CLC
	LDA logo_scroll
	ADC logo_speed
	STA logo_scroll
	BCC no_carry

	\\ Larger than one page

	INC logo_set_charrow_smLO+2
	INC logo_set_charrow_smHI+2

	\\ Wrap table

	LDA logo_set_charrow_smLO+2
	CMP #HI(logo_sinewave_HI)
	BCC no_carry

	\\ Reset to beginning

	LDA #HI(logo_sinewave_LO)
	STA logo_set_charrow_smLO+2
	LDA #HI(logo_sinewave_HI)
	STA logo_set_charrow_smHI+2

	.no_carry

	\\ Take new entry from sine table and move bottom scanline

	LDY logo_scroll
	.logo_set_charrow_smLO
	LDA logo_sinewave_LO, Y
	STA logo_scanline_offset_LO, X
	.logo_set_charrow_smHI
	LDA logo_sinewave_HI, Y
	STA logo_scanline_offset_HI, X
	
\\ Set the address & palette for first screen row

	LDA logo_bottom_scanline
	INC A
	STA logo_charrow

	LDX #0
	JSR logo_set_white		; 46c

    RTS
}

.logo_draw
{
	\\ R9=3 - character row = 1 scanline
	LDA #9: STA &FE00
	LDA #0:	STA &FE01

	\\ R4=0 - CRTC cycle is one row
	LDA #4: STA &FE00
	LDA #0: STA &FE01

	\\ R7=&FF - no vsync
	LDA #7:	STA &FE00
	LDA #&FF: STA &FE01

	\\ R6=0 - one row displayed
	LDA #6: STA &FE00
	LDA #1: STA &FE01		; 8 * 6c = 48c

	\\ Set up second charrow

	LDX #1
	LDY logo_charrow	; 5c
	JSR blankline2 ;logo_set_charrow	; 46c

	\\ Cycle count to end of charrow

;	FOR n,1,4,1
;	NOP
;	NEXT

	.start_of_charrow_1

	.here

;	INC logo_charrow		; 5c
	INY
	JSR logo_set_charrow		; 46c

	\\ Cycle count to end of charrow

;	FOR n,1,5,1
;	NOP
;	NEXT
	
	INX							; 2c
	CPX #255					; 2c
	BNE here					; 3c

	\\ Should arrive here on scanline 255 = last row but scanline 3
	.start_of_charrow_255

	\\ R9=7 - character row = 8 scanlines
	LDA #9: STA &FE00
	LDA #1-1:	STA &FE01		; 1 scanline

	\\ R4=6 - CRTC cycle is 32 + 7 more rows = 312 scanlines
	LDA #4: STA &FE00
	LDA #56-1+1: STA &FE01		; 312 - 256 = 56 scanlines

	\\ R7=3 - vsync is at row 35 = 280 scanlines
	LDA #7:	STA &FE00
	LDA #24+1: STA &FE01		; 280 - 256 = 24 scanlines

	\\ R6=1 - got to display just one row
	LDA #6: STA &FE00
	LDA #1: STA &FE01

	\\ Don't set anything else here - will happen in update for charrow 0

    RTS
}

.logo_kill
{
\\ Will need a kill fn if in MODE 0
    ;LDX #HI($1800)
    ;LDY #HI($2700)
    ;JSR restorepagefrompacked

    JSR crtc_reset_from_single
    SET_ULA_MODE ULA_Mode2
    JMP ula_pal_reset
}

.blankline2
	LDA #13: STA &FE00				; 6c
	LDA #LO((BLANKLINE_ADDR DIV 8))
.blankline
{
	STA &FE01					; 4c
   	LDA #12: STA &FE00				; 6c
	LDA #HI((BLANKLINE_ADDR DIV 8))
	STA &FE01

	PHX
	TXA:ROL A:ROL A:ROL A:AND #3:TAX ;16c
	LDA logo_colour, X ; 4c
	STA logo_set_white+1
	PLX
IF 0
	TXA: ROL A ; 4c
	BCS bit7set
.bit7clear
	BMI bit7clear_bit6set
.bit7clear_bit6clear
	LDA logo_colour+0
	BRA done
.bit7clear_bit6set
	LDA logo_colour+1
	BRA done
.bit7set
	BMI bit7set_bit6set
.bit7set_bit6clear
	LDA logo_colour+2
	BRA done
.bit7set_bit6set
	LDA logo_colour+3
;	BRA done
.done
;	ORA #&10:STA &FE21				; 6c
;	ORA #&20:STA &FE21				; 6c
;	AND #&EF:STA &FE21				; 6c
;	ORA #&40:STA &FE21				; 6c
;	ORA #&10:STA &FE21				; 6c
;	AND #&DF:STA &FE21				; 6c
;	AND #&EF:STA &FE21				; 6c
;	STA logo_set_white+1
ENDIF

;	FOR n,0,20,1

;FOR n,0,34,1
FOR n,0,20,1


;	FOR n,0,5,1
	NOP
	NEXT
	RTS
}

.logo_set_charrow
{
;	LDY logo_charrow				; 3c

	LDA #13: STA &FE00				; 6c
	LDA logo_default_LO, X			; 4c
	CMP #LO((BLANKLINE_ADDR DIV 8))
	BEQ blankline
	CLC							; 2c
	ADC logo_scanline_offset_LO, Y				; 4c
	STA &FE01						; 4c

	\\ Set screen row to this
   	LDA #12: STA &FE00				; 6c
	LDA logo_default_HI, X			; 4c
	ADC logo_scanline_offset_HI, Y				; 4c
	STA &FE01						; 4c
.*logo_set_accon
	LDA #&18
	STA &FE34
	FOR n,0,1,1
	NOP
	NEXT
;	RTS
	\\ Total time = 12c + 6c + 14c + 14c = 46c
}
.logo_set_white
{
	LDA #$83				; 2c
	STA &FE21				; 6c
	ORA #&10:STA &FE21				; 6c
	ORA #&20:STA &FE21				; 6c
	AND #&EF:STA &FE21				; 6c
	ORA #&40:STA &FE21				; 6c
	ORA #&10:STA &FE21				; 6c
	AND #&DF:STA &FE21				; 6c
	AND #&EF:STA &FE21				; 6c
	;NOP:NOP:NOP:NOP:NOP
	RTS
;	LDA #1 ; 2c
.trb_or_tsb
;	TRB $FE34 ; 6c
}	\\ Total time = 12c + 14c + 40c = 66c
\\ Fall through!

.logo_set_anim
{
	STA logo_speed
	RTS

IF 0
	ASL A:ASL A
	TAX

	LDA logo_anim_table, X
	STA logo_set_charrow_smLO+1
	LDA logo_anim_table+1, X
	STA logo_set_charrow_smLO+2

	LDA logo_anim_table+2, X
	STA logo_set_charrow_smHI+1
	LDA logo_anim_table+3, X
	STA logo_set_charrow_smHI+2

	RTS
ENDIF
}

.logo_pal
{
	EQUB &00 + PAL_black
	EQUB &10 + PAL_black
	EQUB &20 + PAL_black
	EQUB &30 + PAL_black
	EQUB &40 + PAL_black
	EQUB &50 + PAL_black
	EQUB &60 + PAL_black
	EQUB &70 + PAL_black
	EQUB &80 + PAL_white
	EQUB &90 + PAL_white
	EQUB &A0 + PAL_white
	EQUB &B0 + PAL_white
	EQUB &C0 + PAL_white
	EQUB &D0 + PAL_white
	EQUB &E0 + PAL_white
	EQUB &F0 + PAL_white
}

.logo_screen_data
INCBIN "data/shift.pu"

PAGE_ALIGN
.logo_colour
{
;FOR n,0,63,1
	EQUB $80+PAL_red
;NEXT
;FOR n,0,63,1
	EQUB $80+PAL_green
;NEXT
;FOR n,0,63,1
	EQUB $80+PAL_yellow
;NEXT
;FOR n,0,63,1
	EQUB $80+PAL_blue
;NEXT
}

.logo_default_LO
{
FOR a,0,3,1
	FOR n,1,7,1
	BLANKLO
	NEXT

	SCREEN_ADDR_LO_NARROW 0
	SCREEN_ADDR_LO_NARROW 0
	BLANKLO
	SCREEN_ADDR_LO_NARROW 0
	SCREEN_ADDR_LO_NARROW 0
	SCREEN_ADDR_LO_NARROW 0
	BLANKLO
	SCREEN_ADDR_LO_NARROW 1
	SCREEN_ADDR_LO_NARROW 1
	BLANKLO
	SCREEN_ADDR_LO_NARROW 2
	SCREEN_ADDR_LO_NARROW 2
	BLANKLO
	SCREEN_ADDR_LO_NARROW 3
	SCREEN_ADDR_LO_NARROW 3
	SCREEN_ADDR_LO_NARROW 3
	BLANKLO
	SCREEN_ADDR_LO_NARROW 4
	SCREEN_ADDR_LO_NARROW 4
	BLANKLO
	SCREEN_ADDR_LO_NARROW 5
	SCREEN_ADDR_LO_NARROW 5
	BLANKLO
	SCREEN_ADDR_LO_NARROW 6
	SCREEN_ADDR_LO_NARROW 6
	SCREEN_ADDR_LO_NARROW 6
	BLANKLO
	SCREEN_ADDR_LO_NARROW 7
	SCREEN_ADDR_LO_NARROW 7
	BLANKLO
	SCREEN_ADDR_LO_NARROW 7
	SCREEN_ADDR_LO_NARROW 7
	BLANKLO
	SCREEN_ADDR_LO_NARROW 8
	SCREEN_ADDR_LO_NARROW 8
	SCREEN_ADDR_LO_NARROW 8
	BLANKLO
	SCREEN_ADDR_LO_NARROW 9
	SCREEN_ADDR_LO_NARROW 9
	BLANKLO
	SCREEN_ADDR_LO_NARROW 9
	SCREEN_ADDR_LO_NARROW 9
	BLANKLO
	SCREEN_ADDR_LO_NARROW 10
	SCREEN_ADDR_LO_NARROW 10
	SCREEN_ADDR_LO_NARROW 10
	BLANKLO
	SCREEN_ADDR_LO_NARROW 11
	SCREEN_ADDR_LO_NARROW 11
	SCREEN_ADDR_LO_NARROW 11

	FOR n,1,7,1
	BLANKLO
	NEXT
NEXT
}

.logo_default_HI
{
FOR a,0,3,1
	FOR n,1,7,1
	BLANKHI
	NEXT

	SCREEN_ADDR_HI_NARROW 0
	SCREEN_ADDR_HI_NARROW 0
	BLANKHI
	SCREEN_ADDR_HI_NARROW 0
	SCREEN_ADDR_HI_NARROW 0
	SCREEN_ADDR_HI_NARROW 0
	BLANKHI
	SCREEN_ADDR_HI_NARROW 1
	SCREEN_ADDR_HI_NARROW 1
	BLANKHI
	SCREEN_ADDR_HI_NARROW 2
	SCREEN_ADDR_HI_NARROW 2
	BLANKHI
	SCREEN_ADDR_HI_NARROW 3
	SCREEN_ADDR_HI_NARROW 3
	SCREEN_ADDR_HI_NARROW 3
	BLANKHI
	SCREEN_ADDR_HI_NARROW 4
	SCREEN_ADDR_HI_NARROW 4
	BLANKHI
	SCREEN_ADDR_HI_NARROW 5
	SCREEN_ADDR_HI_NARROW 5
	BLANKHI
	SCREEN_ADDR_HI_NARROW 6
	SCREEN_ADDR_HI_NARROW 6
	SCREEN_ADDR_HI_NARROW 6
	BLANKHI
	SCREEN_ADDR_HI_NARROW 7
	SCREEN_ADDR_HI_NARROW 7
	BLANKHI
	SCREEN_ADDR_HI_NARROW 7
	SCREEN_ADDR_HI_NARROW 7
	BLANKHI
	SCREEN_ADDR_HI_NARROW 8
	SCREEN_ADDR_HI_NARROW 8
	SCREEN_ADDR_HI_NARROW 8
	BLANKHI
	SCREEN_ADDR_HI_NARROW 9
	SCREEN_ADDR_HI_NARROW 9
	BLANKHI
	SCREEN_ADDR_HI_NARROW 9
	SCREEN_ADDR_HI_NARROW 9
	BLANKHI
	SCREEN_ADDR_HI_NARROW 10
	SCREEN_ADDR_HI_NARROW 10
	SCREEN_ADDR_HI_NARROW 10
	BLANKHI
	SCREEN_ADDR_HI_NARROW 11
	SCREEN_ADDR_HI_NARROW 11
	SCREEN_ADDR_HI_NARROW 11

	FOR n,1,7,1
	BLANKHI
	NEXT
NEXT
}

.logo_offset_none
{
	FOR n,0,255,1
	EQUB 0
	NEXT
}

OFFSET1 = NARROW_CHARS * 12
OFFSET2 = NARROW_CHARS * 24
OFFSET3 = NARROW_CHARS * 36

smoothsize = 64

.logo_sinewave_LO
{
	FOR n,0,255,1
	IF 0
	IF (n < smoothsize)
	   smoothstep = 3*(n/smoothsize)*(n/smoothsize)-2*(n/smoothsize)*(n/smoothsize)*(n/smoothsize)
	ELSE
	   IF (n > 255-smoothsize)
	       smoothstep = 3*((255-n)/smoothsize)*((255-n)/smoothsize)-2*((255-n)/smoothsize)*((255-n)/smoothsize)*((255-n)/smoothsize)
	   ELSE
	       smoothstep = 1
	   ENDIF
	ENDIF
	x = INT(10 * SIN(4 * PI * n / 256) * smoothstep)
	ELSE
	x = INT(20 * SIN(4 * PI * n / 256))
	ENDIF
	IF (x AND 3) = 1
		IF x < 0
		a = OFFSET1 - ((x-1) DIV 4)
		ELSE
		a = OFFSET1 - (x DIV 4)
		ENDIF
	ELSE
	IF (x AND 3) = 2
		IF x < 0
		a = OFFSET2 - ((x-2) DIV 4)
		ELSE
		a = OFFSET2 - (x DIV 4)
		ENDIF
	ELSE
	IF (x AND 3) = 3
		IF x < 0
		a = OFFSET3 - ((x-3) DIV 4)
		ELSE
		a = OFFSET3 - (x DIV 4)
		ENDIF
	ELSE
	a = -(x DIV 4)
	ENDIF
	ENDIF
	ENDIF
	EQUB LO(a)
	NEXT
}

.logo_sinewave_HI
{
	FOR n,0,255,1
	IF 0
	IF (n < smoothsize)
	   smoothstep = 3*(n/smoothsize)*(n/smoothsize)-2*(n/smoothsize)*(n/smoothsize)*(n/smoothsize)
	ELSE
 	   IF (n > 255-smoothsize)
	       smoothstep = 3*((255-n)/smoothsize)*((255-n)/smoothsize)-2*((255-n)/smoothsize)*((255-n)/smoothsize)*((255-n)/smoothsize)
	   ELSE
	       smoothstep = 1
	   ENDIF
	ENDIF
	PRINT "smoothstep=",smoothstep
	x = INT(10 * SIN(4 * PI * n / 256) * smoothstep)
	ELSE
	x = INT(20 * SIN(4 * PI * n / 256))
	ENDIF
	IF (x AND 3) = 1
		IF x < 0
		a = OFFSET1 - ((x-1) DIV 4)
		ELSE
		a = OFFSET1 - (x DIV 4)
		ENDIF
	ELSE
	IF (x AND 3) = 2
		IF x < 0
		a = OFFSET2 - ((x-2) DIV 4)
		ELSE
		a = OFFSET2 - (x DIV 4)
		ENDIF
	ELSE
	IF (x AND 3) = 3
		IF x < 0
		a = OFFSET3 - ((x-3) DIV 4)
		ELSE
		a = OFFSET3 - (x DIV 4)
		ENDIF
	ELSE
	a = -(x DIV 4)
	ENDIF
	ENDIF
	ENDIF
IF 0
IF (x AND 1) = 1
		IF x < 0
		a = OFFSET1 - ((x-1) DIV 2)
		ELSE
		a = OFFSET1 - (x DIV 2)
		ENDIF
	ELSE
	a = -(x DIV 2)
	ENDIF
ENDIF
	PRINT "x=",x," a=",~a
	EQUB HI(a)
	NEXT
}

.logo_scanline_offset_LO
{
	FOR n,0,255,1
	EQUB 0
	NEXT
}

.logo_scanline_offset_HI
{
	FOR n,0,255,1
	EQUB 0
	NEXT
}
ALIGN &100
.mul8
	FOR m,0,7,1
	FOR n,0,31,1
	EQUB (31-n)*8
	NEXT
	NEXT

.linelocslo
	FOR n,0,63,1
	EQUB LO($2400+n*61*8)
	NEXT
.linelocshi
	FOR n,0,63,1
	EQUB HI($2400+n*61*8)
	NEXT



.logo_anim_table
{
	EQUW logo_offset_none, logo_offset_none
	EQUW logo_sinewave_LO, logo_sinewave_HI
	\\ static
	\\ glitch
	\\ flip
	\\ etc.
}

.logo_end

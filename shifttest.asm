	CPU 1
	ORG &2000
.start
.table
	EQUW copypagetopacked
	EQUW restorepagefrompacked
	EQUW copyandshiftlines

	;; pack/unpack 8-byte-aligned bytes from 8 pages to/from 1
	;; page. packed format is undefined

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

	
temp = &70
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
.count
	EQUB 0
}
	
	ALIGN &20
.mul8
	FOR m,0,7,1
	FOR n,0,31,1
	EQUB (31-n)*8
	NEXT
	NEXT

.linelocslo
	FOR n,0,31,1
	EQUB LO(&3000+n*61*8)
	NEXT
.linelocshi
	FOR n,0,31,1
	EQUB HI(&3000+n*61*8)
	NEXT
.end
	SAVE "SHIFTST",start,end

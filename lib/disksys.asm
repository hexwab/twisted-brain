.beeb_disksys_start

disksys_loadto_addr = screen_base_addr

\*-------------------------------
\*  DISKSYS OSFILE PARAMS
\*-------------------------------

.osfile_params
.osfile_nameaddr
EQUW 0
; file load address
.osfile_loadaddr
EQUD 0
; file exec address
.osfile_execaddr
EQUD 0
; start address or length
.osfile_length
EQUD 0
; end address of attributes
.osfile_endaddr
EQUD 0

;--------------------------------------------------------------
; Load a file from disk to memory (SWR supported)
; Loads in sector granularity so will always write to page aligned address
;--------------------------------------------------------------
; A=memory address MSB (page aligned)
; X=filename address LSB
; Y=filename address MSB

.disksys_load_file
{
    STA write_to+2

    \ Load to screen if can't load direct
    LDA #HI(disksys_loadto_addr)
    STA osfile_loadaddr+1
    STA read_from+2
    \ Load the file
    STX osfile_nameaddr
    STY osfile_nameaddr+1

    \ Ask OSFILE to load our file
    LDX #LO(osfile_params)
    LDY #HI(osfile_params)
    LDA #&FF
    JSR osfile

    \ Get filesize 
    LDY osfile_length+1
    LDA osfile_length+0
    BEQ no_extra_page

    INY             ; always copy a whole number of pages
    .no_extra_page

    LDX #0
    .read_from
    LDA disksys_loadto_addr, X
    .write_to
    STA &FF00, X
    INX
    BNE read_from
    INC read_from+2
    INC write_to+2
    DEY
    BNE read_from
}
.print_loading_string
{
	DEC loadstr+3
	LDX #4
	.loop
	LDA loadstr,X
	JSR oswrch
	DEX
	BPL loop
	RTS
.loadstr
	EQUS "...6 "
}

.beeb_disksys_end

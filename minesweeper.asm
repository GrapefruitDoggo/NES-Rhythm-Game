prg_npage = 1 ; program size in 16KiB chunks
chr_npage = 1 ; texture file size in 8KiB chunks
mapper = 0 ; INES mapper number
mirroring = 1 ; screen mirroring (0 = horizontal, 1 = vertical)

;;; PPU registers.
PPUCTRL		= $2000
PPUMASK		= $2001
PPUSTATUS	= $2002
OAMADDR		= $2003
OAMDATA		= $2004
PPUSCROLL	= $2005
PPUADDR		= $2006
PPUDATA		= $2007

;;; Other IO registers.
OAMDMA		= $4014
APUSTATUS	= $4015
JOYPAD1		= $4016
JOYPAD2		= $4017

.segment "INES"
	.byte $4e, $45, $53, $1a
	.byte prg_npage
	.byte chr_npage
	.byte ((mapper & $0f) << 4) | (mirroring & 1)
	.byte mapper & $f0

.segment "VECTOR"
	.addr nmi
	.addr reset
	.addr irq

	.code
		.proc nmi
				rti
		.end_proc

		.proc reset
				sei ; disable interrupts
				cld ; clear decimal mode flag
				ldx #$ff
				txs ; transfer x (#$ff) to the stack
				inx
				stx PPUCTRL ; PPUCTRL = 0
				stx PPUMASK ; PPUMASK = 0
				stx APUSTATUS ; APUSTATUS = 0

				;; PPU warmup, wait two frames, plus a third later.
				bit PPUSTATUS
				bpl :-
				bit PPUSTATUS
				bpl :-

				;; Zero ram
				txa
				sta $000, x
        sta $100, x
        sta $200, x
        sta $300, x
        sta $400, x
        sta $500, x
        sta $600, x
        sta $700, x
        inx
        bne :-

				;; Third frame mentioned earlier
				bit PPUSTATUS
				bpl :-

				;; Beeping program
				lda #$01		; enable pulse 1
				sta $4015
				lda #$08		; period
				sta $4002
				lda #$02
				sta $4003
				lda #$bf		; volume
				sta $4000
				forever:
					jmp forever
		.end_proc

		.proc irq
				rti
		.end_proc

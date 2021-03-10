 processor 6502
	org $8000
	incbin "/Users/student/Documents/GitHub/NES-Rhythm-Game/Rhythm Game//music/_zelda.dat"
	ORG $c000
	jmp block1
i	=	$10
j	=	$11
k	=	$12
palette
	incbin "/Users/student/Documents/GitHub/NES-Rhythm-Game/Rhythm Game///tiles/game_tiles.pal"
	; NodeProcedureDecl -1
	; ***********  Defining procedure : init16x8mul
	;    Procedure type : Built-in function
	;    Requires initialization : no
mul16x8_num1Hi = $4c
mul16x8_num1 = $4e
mul16x8_num2 = $50
mul16x8_procedure
	lda #$00
	ldy #$00
	beq mul16x8_enterLoop
mul16x8_doAdd
	clc
	adc mul16x8_num1
	tax
	tya
	adc mul16x8_num1Hi
	tay
	txa
mul16x8_loop
	asl mul16x8_num1
	rol mul16x8_num1Hi
mul16x8_enterLoop  ; accumulating multiply entry point (enter with .A=lo, .Y=hi)
	lsr mul16x8_num2
	bcs mul16x8_doAdd
	bne mul16x8_loop
	rts
	; NodeProcedureDecl -1
	; ***********  Defining procedure : initeightbitmul
	;    Procedure type : Built-in function
	;    Requires initialization : no
multiplier = $4c
multiplier_a = $4e
multiply_eightbit
	cpx #$00
	beq mul_end
	dex
	stx $4e
	lsr
	sta multiplier
	lda #$00
	ldx #$08
mul_loop
	bcc mul_skip
mul_mod
	adc multiplier_a
mul_skip
	ror
	ror multiplier
	dex
	bne mul_loop
	ldx multiplier
	rts
mul_end
	txa
	rts
initeightbitmul_multiply_eightbit2
	rts
	
; // NMI will automatically be called on every vblank. 
; //
	; NodeProcedureDecl -1
	; ***********  Defining procedure : NMI
	;    Procedure type : User-defined procedure
 ; Temp vars section
 ; Temp vars section ends
NMI
	; StartIRQ
	pha
	txa
	pha
	tya
	pha
	
; // Plays the song
	jsr $8803
	; CloseIRQ
	pla
	tay
	pla
	tax
	pla
	rti
	
; // Empty
	; NodeProcedureDecl -1
	; ***********  Defining procedure : IRQ
	;    Procedure type : User-defined procedure
IRQ
	rti
	
; //	Sets up the background screen by filling 32x30 rows with
; //    Afterwards, creating 64 random attribute(color) values and dumping them to the attribute 
; //
; //
; // use $0400 as temp storage area
	; NodeProcedureDecl -1
	; ***********  Defining procedure : InitScreen
	;    Procedure type : User-defined procedure
InitScreen
	
; //	zp:=1024;
; // fill 30 lines with same value i+50
	lda #$20
	sta $2006
	lda #$0
	sta $2006;keep
	; Assigning single variable : i
	; Calling storevariable
	sta i
InitScreen_forloop6
	; Assigning single variable : j
	lda #$0
	; Calling storevariable
	sta j
InitScreen_forloop23
	; 8 bit binop
	; Add/sub right value is variable/expression
	; Right is PURE NUMERIC : Is word =0
	; 8 bit mul of power 2
	; 8 bit binop
	; Add/sub where right value is constant number
	lda i
	and #$1
	 ; end add / sub var with constant
	asl
	asl
	asl
	asl
InitScreen_rightvarAddSub_var31 = $84
	sta InitScreen_rightvarAddSub_var31
	; 8 bit binop
	; Add/sub where right value is constant number
	; 8 bit binop
	; Add/sub where right value is constant number
	lda j
	and #$1
	 ; end add / sub var with constant
	clc
	adc #$2
	 ; end add / sub var with constant
	clc
	adc InitScreen_rightvarAddSub_var31
	sta $2007;keep
InitScreen_forloopcounter25
InitScreen_loopstart26
	; Compare is onpage
	inc j
	lda #$20
	cmp j ;keep
	bne InitScreen_forloop23
InitScreen_loopdone32: ;keep
InitScreen_forloopend24
InitScreen_loopend27
InitScreen_forloopcounter8
InitScreen_loopstart9
	; Compare is onpage
	inc i
	lda #$1e
	cmp i ;keep
	bne InitScreen_forloop6
InitScreen_loopdone33: ;keep
InitScreen_forloopend7
InitScreen_loopend10
	
; // Fill nametable with : Palette 0(00), 1(01), 2(10) and 3(11)
	lda #$1e
	ldx #0
InitScreen_fill34
	sta $400,x
	inx
	cpx #$40
	bne InitScreen_fill34
	
; // Dump 64 bytes from storage to PPU nametable 0 color ram($2000 + $3C0);
	lda #$23
	sta $2006;keep
	lda #$c0
	sta $2006;keep
	ldx #0
InitScreen_PPUDump35
	lda $400+$00,x
	sta $2007
	inx
	cpx #$40
	bne InitScreen_PPUDump35
	rts
block1
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40  
  STX $4017    ; disable APU frame IRQ
  LDX #$FF  
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs
vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1
clrmem:
  LDA #$00
  STA $0000,x
  STA $0100,x
  STA $0400,x
  STA $0500,x
  STA $0600,x
  STA $0700,x
  LDA #$FE
  STA $0300,x
  STA $0200,x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2
	
; // Starting point after resetting the NES
; // Load palette
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00
MainProgram_LoadPalette36
	LDA palette,x
	STA $2007
	INX
	CPX #$20
	BNE MainProgram_LoadPalette36
	
; // Set up background & color values
	jsr InitScreen
	lda #$0
	ldx #1
	jsr $8800
	
; // Turn on background
	lda $2001
	ora #%1000
	sta $2001
	
; // Display background in border 0
	ora #%10
	sta $2001
	
; // Press F1 on PPUCTRL for detailed info	
	lda $2000
	ora #%10000
	sta $2000
	
; // set nametable 0 = $2000(where we dumped the background data)
	and #%11111100
	ora #$0
	sta $2000
	
; // Turn on NMI
	ora #%10000000
	sta $2000
	
; // Halt!(this is where non-drawing gamelogic should happen)
	jmp * ; loop like (�/%
	; End of program
	; Ending memory block
	org $fffa
	; Starting new memory block at $FFFA
StartBlockFFFA
;    org $FFFA     ;first of the three vectors starts here
;  org $BFF8     ;first of the three vectors starts here
  .word NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .word RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .word IRQ          ;external interrupt IRQ is not used in this tutorial
	; Ending memory block
EndBlockFFFA

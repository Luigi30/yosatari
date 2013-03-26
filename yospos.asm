	processor 6502
	include "vcs.h"
	include "macro.h"

	SEG.U vars ;variables
	ORG $80
SpriteXPosition ds 0
	ORG $81
SpriteYPosition ds 0
	ORG $82
P0Inputs ds 0
	ORG $83
SpriteHeight ds 0
	ORG $84
ColorCycleIndex ds 0
	ORG $85
TitlePFColor ds 0
	ORG $86
P0PFCollided
	ORG $87
P0LastMovement
	ORG $88
IntroFrameIndex
	ORG $89
DrawSpriteNextScanline
	ORG $8A
SpriteToDraw ; 0 = P0, 1 = P1
	ORG $8B
SpriteDataPtr ds 2
	ORG $8D
SpriteXPositionPtr ds 2
	ORG $90
SpriteYPositionPtr ds 2
	ORG $92
EnemyXPosition
	ORG $93
EnemyYPosition
	ORG $94
PlayerXPosition
	ORG $95
PlayerYPosition
		
	SEG
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bank 0 - Title and intro ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ORG $E000 ; Bank 0 - "$E000"
	RORG $F000
	
	nop ; $E000 - (continued from below) We've advanced the PC 3 bytes with our LDA to $F003.
	nop ; $E001 - And if we somehow reset while in this bank, the CPU always resets to $F000.
	nop ; $E002 - So we don't want the game program to start until $E003/$F003.
	
Reset

	ldx #$FF
	txs

	lda #<PlayerXPosition ;put address of player X position into a pointer
	sta SpriteXPositionPtr
	
	lda #>PlayerXPosition
	sta SpriteXPositionPtr+1
	
	lda #<PlayerYPosition ;put address of player Y position into a pointer
	sta SpriteYPositionPtr
	
	lda #>PlayerYPosition
	sta SpriteYPositionPtr+1

	lda #80 ;$E003 - set playfield color to 80
	sta COLUPF

	lda #56 ;set player 0 sprite color to 56
	sta COLUP0

	lda #%00000000 ; clear out sprite graphics
	sta GRP0
	
	lda #%00000000 ; don't reflect playfield
	sta CTRLPF
	
	ldx #0 ;black
	stx COLUBK ;background to black
	
	lda #96 ; default sprite X position is 96
	sta PlayerXPosition
	sta EnemyYPosition
	
	lda #64 ; default sprite Y position is 64
	sta PlayerYPosition

	lda #40
	sta EnemyXPosition
	
	lda #0 ;starting color cycle index
	sta ColorCycleIndex
	sta IntroFrameIndex
	
	sta SpriteHeight

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Title sequence begins when game is turned on    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TitleStartOfFrame ; we go back here when we start a new frame

;	lda #64 ;set playfield color to red
;	sta COLUPF

	inc ColorCycleIndex
	ldx ColorCycleIndex
	stx COLUPF ;one color increase per frame
	stx COLUBK

	;reset some variables
	ldx #8 ;8 scanlines of sprite
	stx SpriteHeight
	
	dex ; iterator

	lda #0
	sta GRP0
	
TitleDecreaseP0Y
	;read the joystick port to
	;since we need to know if a switch is 0, we OR it against #%00000000.
	;if a switch is pressed, its bit in A will be off.
	
	lda SWCHA ;SWCHA = joystick port input
	sta P0Inputs ;store it for later use

	; is the reset button switched? if so, abort the title screen and go into the game

TitleCheckReset ;video magic to check if the reset switch is flipped
	lda #%00000001 ; D0 = RESET
	and SWCHB ; AND A against P0Inputs

	cmp #%00000000 ; compare that to off. if the switch is pressed, everything will be 0.
	bne TitleDrawFrame

	jmp IntroDrawFrame ;go straight to the intro
	
TitleRepositionSprite ; no sprites in the title screen dammit!

TitleDrawFrame

; Start of vertical blank processing
	lda #0
	sta VBLANK
		
	lda #2
	sta VSYNC
 
	; 3 scanlines of VSYNCH signal
	sta WSYNC
	sta WSYNC
	sta WSYNC
		
	lda #0
	sta VSYNC   
        
	; 37 scanlines of vertical blank
	ldx #0
		
TitleVerticalBlank
	sta WSYNC
	inx
	cpx #37
	bne TitleVerticalBlank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 192 scanlines of picture...

TitleDrawBackground ;set up the next frame

	ldy #192
	
TitleDrawToEnd	;Now do it all in 72 cycles or less!!!

	sta WSYNC ; @0 - wait for TIA to reach next scanline
		
	lda ColorCycleIndex ;@2 get the color cycling index
	sty $87 ;@5 save Y to RAM
	adc $87 ;@8 add Y to our index
	sta COLUPF ;@11 and store that in COLUPF
	
TitleDrawingSprite ; no sprites in the title screen
	
TitleStartDrawingSprite ; no sprites in the title screen
	
TitleContinueDrawing ; draw our logo

	lda yos2_STRIP_0,y ; @15 - fetch graphic part 0
	sta PF0 ; @18 - write it to PF0 - between 0 and 22

	lda yos2_STRIP_1,y ; @22 - fetch graphic part 1
	sta PF1 ; @25 - write it to PF1 - between 0 and 28

	lda yos2_STRIP_2,y ; @29 - fetch graphic part 2
	sta PF2 ; @32 - write it to PF2 - between 0 and 38

	;now we're drawing the right side of the screen
	
	lda yos2_STRIP_3,y ; @36 - fetch graphic part 3
	sta PF0 ; @39 - write it to PF0 - between 28 and 49
	
	lda yos2_STRIP_4,y ; @43 - fetch graphic part 4
	sta PF1 ; @46 - write it to PF1 - between 39 and 54
	
	lda yos2_STRIP_5,y ; @50 - fetch graphic part 5
	sta PF2 ; @53 - write it to PF2 - between 50 and 64
	
	dey ;@55
	
	bne TitleDrawToEnd ; @58 <---- go start a new scanline
	
;30 lines of overscan	

	ldx #0 ;blank
	
	stx PF0 ;reset PF registers to blank
	stx PF1
	stx PF2 
	
	ldy #0 ;line counter
	
TitleOverscanLine
	iny
	sta WSYNC
	cpy #30 ;have we had 30 lines of overscan yet?
	bne TitleOverscanLine

	jmp TitleStartOfFrame ;back to scanline 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Insert cool intro screen here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
IntroStartOfFrame ; we go back here when we start a new frame

;	lda #64 ;set playfield color to red
;	sta COLUPF

	ldx #0
	stx COLUBK

	lda #0
	sta GRP0 ;reset our graphics for the intro
	
	sta PF0
	sta PF1
	sta PF2
	
IntroDecreaseP0Y
	;read the joystick port to move the sprite.
	;since we need to know if a switch is 0, we OR it against #%00000000.
	;if a switch is pressed, its bit in A will be off.
	
	lda SWCHA ;SWCHA = joystick port input
	sta P0Inputs ;store it for later use

	; is the reset button switched? if so, abort the title screen and go into the game

IntroCheckReset ;255 frames of black, then go to next part
	inc IntroFrameIndex
	lda IntroFrameIndex
	cmp #255
	
	bne IntroDrawFrame
	
IntroSwitchBank	
	jmp SwitchToBank1 ;switch to the other bank and execute from FFF0

IntroDrawFrame

; Start of vertical blank processing
	lda #0
	sta VBLANK
		
	lda #2
	sta VSYNC
 
	; 3 scanlines of VSYNCH signal
	sta WSYNC
	sta WSYNC
	sta WSYNC
		
	lda #0
	sta VSYNC   
	; 37 scanlines of vertical blank minus 4 scanlines when coming from the other program
	
	ldx #0
		
IntroVerticalBlank
	sta WSYNC
	inx
	cpx #33
	bne IntroVerticalBlank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 192 scanlines of picture...

IntroDrawBackground ;set up the next frame

	ldy #0
	ldx #0
	
IntroDraw032 ; The blue sky.
	sta WSYNC ;@0
	
	lda #48 ; orange @2
	sta COLUBK ; @5
	
	iny ;increase scanline counter @7
	
	cpy #32 ;have we drawn this for 32 scanlines?
	bne IntroDraw032
	
IntroDraw3340 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #246 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%00011000
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #40 ;have we drawn this for 32 scanlines?
	bne IntroDraw3340
	
IntroDraw4148 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #246 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%00111100
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #48 ;have we drawn this for 32 scanlines?
	bne IntroDraw4148
	
IntroDraw4956 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #246 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%01111110
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #56 ;have we drawn this for 32 scanlines?
	bne IntroDraw4956
	
IntroDraw5764 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #244 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%00011000
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #64 ;have we drawn this for 32 scanlines?
	bne IntroDraw5764
	
IntroDraw6572 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #244 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%00111100
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #72 ;have we drawn this for 32 scanlines?
	bne IntroDraw6572
	
IntroDraw7380 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #244 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%00111100
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #80 ;have we drawn this for 32 scanlines?
	bne IntroDraw7380
	
IntroDraw8188 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; orange @2
	sta COLUPF ; @5
	
	sleep 34 ;@39
	
	lda #244 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%11111111
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #88 ;have we drawn this for 32 scanlines?
	bne IntroDraw8188
	
IntroDraw8996 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #50 ; orange @2
	sta COLUBK ; @5
	
	sleep 34
	
	lda #%11111111
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #96 ;have we drawn this for 4 scanlines?
	bne IntroDraw8996
	
IntroDraw96100 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #52 ; orange @2
	sta COLUBK ; @5
	
	sleep 34
	
	lda #%11111111
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #100 ;have we drawn this for 4 scanlines?
	bne IntroDraw96100
	
IntroDraw100104 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #54 ; orange @2
	sta COLUBK ; @5
	
	sleep 34 ;@49
	
	lda #%10111101 ;@51
	sta PF1 ;@54
	
	lda #242 ;@62
	sta COLUPF ;@65
	
	iny ;increase scanline counter @67
	
	cpy #104 ;have we drawn this for 4 scanlines?
	bne IntroDraw100104
	
IntroDraw104108 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #56 ; orange @2
	sta COLUBK ; @5
	
	sleep 34
	
	lda #%11111111
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #108 ;have we drawn this for 4 scanlines?
	bne IntroDraw104108
	
IntroDraw108112 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #58 ; orange @2
	sta COLUBK ; @5
	
	sleep 34
	
	lda #%11111111
	sta PF1
	
	iny ;increase scanline counter @7
	
	cpy #112 ;have we drawn this for 4 scanlines?
	bne IntroDraw108112
	
IntroDraw112116 ; The blue sky.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #60 ; orange @2
	sta COLUBK ; @5
	
	sleep 34 ;@49
	
	lda #%10111101 ;@51
	sta PF1 ;@54
	
	lda #242 ;@62
	sta COLUPF ;@65
	
	iny ;increase scanline counter @67
	
	cpy #116 ;have we drawn this for 4 scanlines? @69
	bne IntroDraw112116 ; @72
	
IntroDraw116120 ; The yellow sun.
	sta WSYNC ;@0
	
	stx PF1 ;@3
	
	lda #28 ; @5 yellow
	sta COLUPF ;@8

	lda #%00011000 ;@10
	sta PF1 ;@13
	
	lda #62 ;@15
	sta COLUBK ;@18
	
	sleep 22 ;@40
	
	lda #244 ;@42 ;tan
	sta COLUPF ;@45
	
	lda #%11111111 ;@51
	sta PF1 ;@54
	
	iny ;increase scanline counter
	cpy #120 ;have we drawn this for 12 scanlines?
	bne IntroDraw116120
	
IntroDraw120124 ; The yellow sun.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; yellow
	sta COLUPF

	lda #%00111100 ;@2
	sta PF1 ;@5
	
	lda #62
	sta COLUBK
	
	sleep 16 ;@41
	
	lda #244 ;tan
	sta COLUPF
	
	lda #%11111111 ;@47
	sta PF1 ;@50
	
	sleep 14 ;@60
	
	lda #242 ;@62
	sta COLUPF ;@65
	
	iny ;increase scanline counter
	cpy #124 ;have we drawn this for 12 scanlines?
	bne IntroDraw120124
	
IntroDraw124128 ; The yellow sun.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; yellow
	sta COLUPF

	lda #%01111110 ;@2
	sta PF1 ;@5
	
	lda #62
	sta COLUBK
	
	sleep 16 ;@41
	
	lda #244 ;tan
	sta COLUPF
	
	lda #%11111111 ;@47
	sta PF1 ;@50
	
	iny ;increase scanline counter
	cpy #128 ;have we drawn this for 12 scanlines?
	bne IntroDraw124128
	
IntroDraw128132 ; The yellow sun.
	sta WSYNC ;@0
	
	stx PF1
	
	lda #28 ; yellow
	sta COLUPF

	lda #%11111111 ;@2
	sta PF1 ;@5
	
	lda #62
	sta COLUBK
	
	sleep 16 ;@39
	
	lda #244 ;tan
	sta COLUPF
	
	lda #%11111111 ;@47
	sta PF1 ;@50
	
	sleep 14 ;@60
	
	lda #242 ;@62
	sta COLUPF ;@65
	
	iny ;increase scanline counter @67
	cpy #132 ;have we drawn this for 12 scanlines? @69
	bne IntroDraw128132 ;@72
	
IntroDraw132136 ; The yellow sun.
	sta WSYNC ;@0
	
	stx PF1 ;@3
	
	lda #28 ; yellow @5
	sta COLUPF ;@8

	lda #%11111111 ;@10
	sta PF1 ;@13
	
	lda #62 ;@15
	sta COLUBK ;@18
	
	sleep 18 ;@36
	
	lda #244 ;tan @38
	sta COLUPF ;@41
	
	lda #%11100111 ;@43
	sta PF1 ;@46
	
	sleep 6 ;@52
	lda #0 ;@54
	sta COLUBK ;@56
	
	lda #62 ;@58
	sta COLUBK ;@61
	
	iny ;increase scanline counter ;@63
	cpy #136 ;have we drawn this for 12 scanlines? ;@66
	bne IntroDraw132136 ;@69
	
IntroDraw136144 ; The grass.
	sta WSYNC
	
	stx PF1
	
	lda #0
	sta PF1
	
	lda #192 ; green
	sta COLUBK
	
	iny ;increase scanline counter
	cpy #144 ;have we drawn this for 16 scanlines?
	bne IntroDraw136144
	
IntroDraw144192 ; More grass
	sta WSYNC
	
	stx PF1
	
	lda #194 ; brown
	sta COLUBK
	
	iny ;increase scanline counter
	cpy #192 ;have we drawn this for 48 scanlines?
	bne IntroDraw144192
	
;30 lines of overscan	

	ldx #0 ;blank
	
	stx PF0 ;reset PF registers to blank
	stx PF1
	stx PF2 
	
	ldy #0 ;line counter
	
IntroOverscanLine
	iny
	sta WSYNC
	cpy #30 ;have we had 30 lines of overscan yet?
	bne IntroOverscanLine

	jmp IntroStartOfFrame ;back to scanline 0
	
;our background graphic

	ORG $EA00
	RORG $FA00

	include "yos2.asm"
	;include "greatest2.asm"
	
	ORG $ED00
	RORG $FD00
	
	ORG $EFE0 ; Bank 0 is $E000-EFFF...
	RORG $FFE0 ; ...but when this bank is enabled, it's $F000-FFFF.
	
SwitchToBank1 ; What if we want to switch banks?
	lda $fff9 ; $FFF9 is a strobed hotspot that makes the ROM that's really at $F000-$FFFF active.
	
	ORG $EFFA ; Reset vectors
	RORG $EFFA
	.word Reset ; NMI
	.word Reset ; RESET
	.word Reset ; IRQ

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	BANK 1 - Main game				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ORG $F000	; On initial power-up, we always boot to *the official* $F000
	
JumpToBank0 	; But we don't want to start here
	lda $FFF8	; So strobe the bank selector and switch to Bank 0 (continued above)
	
BeginGame

	ldy #%00000001 ;make sure we have a reflecting playfield
	sty CTRLPF
	
StartOfFrame ; we go back here when we start a new frame

	ldx #0 ;reset line counter
	
;	ldy #0
;	sty SpriteToDraw

	lda #80 ;set playfield color to red
	sta COLUPF

	;set some variables
	
	;which sprite are we drawing this frame? whichever one we didn't draw last frame
	lda SpriteToDraw
	cmp #0
	beq DrawPlayerSprite ; generic development enemy of death
	
DrawEnemySprite ; if SpriteToDraw is 1

	lda #<EnemySprite ;put address of enemy data in the pointer
	sta SpriteDataPtr
	
	lda #>EnemySprite
	sta SpriteDataPtr+1
	
	lda #<EnemyYPosition ;put address of enemy data in the pointer
	sta SpriteYPositionPtr
	
	lda #>EnemyXPosition
	sta SpriteXPositionPtr+1
	
	lda #<EnemyXPosition ;put address of enemy data in the pointer
	sta SpriteXPositionPtr
	
	lda #>EnemyXPosition
	sta SpriteXPositionPtr+1
	
	lda (SpriteXPositionPtr),y ;now get the data and load it for the next frame
	sta SpriteXPosition
	
	lda (SpriteYPositionPtr),y
	sta SpriteYPosition
	
	lda #0
	sta SpriteToDraw
	jmp LoadHeight
	
DrawPlayerSprite ; if SpriteToDraw is 0

	lda #<PlayerSprite ;put address of player data in the pointer
	sta SpriteDataPtr
	
	lda #>PlayerSprite
	sta SpriteDataPtr+1
	
	lda #<PlayerYPosition ;put address of player data in the pointer
	sta SpriteYPositionPtr
	
	lda #>PlayerXPosition
	sta SpriteXPositionPtr+1
	
	lda #<PlayerXPosition ;put address of player data in the pointer
	sta SpriteXPositionPtr
	
	lda #>PlayerXPosition
	sta SpriteXPositionPtr+1
	
	lda (SpriteXPositionPtr),y ;now get the data and load it for the next frame
	sta SpriteXPosition
	
	lda (SpriteYPositionPtr),y
	sta SpriteYPosition

	lda #1
	sta SpriteToDraw
	
	; now continue with the program
	
LoadHeight
	
	ldx #15 ;8 scanlines of sprite
	stx SpriteHeight
	
	dex ; iterator
	
DecreaseP0Y
	dec SpriteYPosition ;move the sprite up by 8 to counter the effect of what we did below
	dex ; iterator
	cpx #0 ;is the iterator 0?
	bne DecreaseP0Y ;if not, keep doing your thing
	
	;read the joystick port to move the sprite.
	;since we need to know if a switch is 0, we OR it against #%00000000.
	;if a switch is pressed, its bit in A will be off.
	
	lda SWCHA ;SWCHA = joystick port input
	sta P0Inputs ;store it for later use

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; is the player the active sprite?
	
	lda SpriteToDraw
	cmp #1 ;if it's not
	bne RepositionSprite ; then don't check the inputs
	
	jsr CheckInputs ;if it is, then check the inputs
	
	lda P0PFCollided ;did we note a collision?
	cmp #%10000000
	bne RepositionSprite

	jsr P0PFCollisionHandler
	
RepositionSprite

;	inc SpriteXPosition ;increase sprite X position variable
	lda SpriteXPosition ;move it to A
	ldx #0 ;iterator
	cpx #160 ;count to 160
	bcc LT160 ;keep counting until we hit 160
	ldx #0 ;move object 0
LT160
	jsr PositionSprite ;A = horizontal position (0-159), X = P0/P1

DrawFrame

; Start of vertical blank processing
	lda #0
	sta VBLANK
		
	lda #2
	sta VSYNC
 
	; 3 scanlines of VSYNCH signal
	sta WSYNC
	sta WSYNC
	sta WSYNC
		
	lda #0
	sta VSYNC   
        
	; 37 scanlines of vertical blank
	ldx #0
		
VerticalBlank
	sta WSYNC
	inx
	cpx #33
	bne VerticalBlank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawBackground ;set up the next frame
	ldx #0 ;black
	stx COLUBK ;background to black
	ldx #0 ;scanline counter starts at 0

TopOfBoxGraphic

DrawTopOfPlayfieldBox ;draw 16 solid background scanlines at the top of the screen
	sta WSYNC ;@0
	inx ;@2
	
	lda #%11000000 ;@4
	sta PF0 ;@7
	
	lda #%11111111 ;@9
	sta PF1 ;@12
	
	sta PF2 ;@17
	
	sleep 12 ;@33
	
	cpx #15	;@70

	bne DrawTopOfPlayfieldBox ;@70
	
	lda #%11110000
	sta PF0
	
	lda #%00000000
	sta PF1
	sta PF2

	ldy #15
	
	sta WSYNC ;balance out the counter
	inx
	
	lda SpriteToDraw
	cmp #0
	beq DrawToEnd
	
DrawToEnd	;Now do it all in 72 cycles or less!!!
	sta WSYNC ; @0 - wait for TIA to reach next scanline
	
	lda #0
	sta GRP0
	
	cpx SpriteYPosition ; @2 - are we on the scanline where the sprite starts?
	bne ContinueDrawing ; @5 - if not, continue drawing the background
	
DrawingSprite ; if we are...

	;all sprites are 16 scanlines high and we've preloaded X - amazing!
	
	dey ;@7 will hit 0 and trip the branch when we've drawn the sprite for 16 scanlines
	beq ContinueDrawing ;@10 - if so, don't draw it anymore
	
StartDrawingSprite ; draw one line of sprite

	inc SpriteYPosition ; @12 - increase SpriteYPosition so we draw the sprite on the next scanline too
	lda (SpriteDataPtr),y ;@17 (pointer to sprite data + sprite line index)
	sta GRP0 ; @20 - put the sprite data into a register
	
ContinueDrawing
	
	;;;;;;
	; 45 cycles to use here
	;;;;;;
	
	inx ;x = scanline count @11/25 (no sprite/with sprite)
	cpx #160 ;@13/27		
	bne DrawToEnd ; @16/30 go start a new scanline
	
BottomOfBoxGraphic

DrawBottomOfPlayfieldBox ;draw 16 solid background scanlines at the top of the screen
	sta WSYNC ;@0
	inx ;@2
	
	lda #%11000000 ;@4
	sta PF0 ;@7
	
	lda #%11111111 ;@9
	sta PF1 ;@12
	
	sta PF2 ;@17
	
	sleep 12 ;@33
		
	cpx #176	;@68 - line counter = 176?
	bne DrawBottomOfPlayfieldBox ;@71	
		
BeginGetOut
	
	sta WSYNC
	inx ; x = line counter

	ldy #0
	sty PF0
	sty PF1
	sty PF2

	ldy #40
	sty COLUPF
	
	ldy #0

DrawGetOut ;draw 16 solid background scanlines at the top of the screen
	sta WSYNC ; @0 - wait for TIA to reach next scanline
	
	iny; @2 ; index of getout.asm
	
	sleep 10; @12

	lda getout_STRIP_0,y ; @16 - fetch graphic part 0
	sta PF0 ; @19 - write it to PF0 - between 0 and 22

	lda getout_STRIP_1,y ; @23 - fetch graphic part 1
	sta PF1 ; @26 - write it to PF1 - between 0 and 28

	lda getout_STRIP_2,y ; @30 - fetch graphic part 2
	sta PF2 ; @33 - write it to PF2 - between 0 and 38
	
	sleep 8

	;now we're drawing the right side of the screen
	
	;reflected - so reverse the loading order
	
	lda getout_STRIP_5,y ; @51 - fetch graphic part 5
	sta PF2 ; @54 - write it to PF2 - between 50 and 64

	lda getout_STRIP_4,y ; @44 - fetch graphic part 4
	sta PF1 ; @47 - write it to PF1 - between 39 and 54
	
	lda getout_STRIP_3,y ; @37 - fetch graphic part 3
	sta PF0 ; @40 - write it to PF0 - between 28 and 49
		
	inx ;x = scanline count @58
	
	cpx #192 ;are we at line 192 yet? - @68

	bne DrawGetOut ;@71
	
;30 lines of overscan	

	ldx #0 ;blank
	
	stx PF0 ;reset PF registers to blank
	stx PF1
	stx PF2 
	
	ldy #0 ;line counter
	
OverscanLine
	iny
	sta WSYNC
	cpy #30 ;have we had 30 lines of overscan yet?
	bne OverscanLine
	
	ldy #0
	lda SpriteXPosition
	sta (SpriteXPositionPtr),y
	
	lda SpriteYPosition
	sta (SpriteYPositionPtr),y

	jmp StartOfFrame ;back to scanline 0
	
; I didn't write any of this stuff below
	
PositionSprite

	sec				;doing this before so that I have more time
					;during the next scanline.
	sta WSYNC		;begin line 1

DivideLoop
	sbc #15
	bcs DivideLoop                 ;+4/5    4/9.../54

	tay                            ;+2      6
	lda FineAdjustTableEnd,Y       ;+5      11
	
	nop
	nop            ;+4     15/20/etc.   - 4 free cycles!

	sta HMP0,X     ;+4     19/24/...
	sta RESP0,X    ;+4     23/28/33/38/43/48/53/58/63/68/73
	sta WSYNC      ;+3      0       begin line 2
	sta HMOVE      ;+3
	rts            ;+6      9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check the inputs subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInputs subroutine

	;Check for player-playfield collisions. if we have one, reset, note, and don't let the player move.
	
;	lda #%10000000 ;check D7
	lda CXP0FB ; D7 = P0/PF collision 
	and #%10000000
	cmp #%10000000
	bne .CheckP0Right ;if it's not set, process inputs
	
	sta CXCLR ;if it is set, clear it and return to sender
	sta P0PFCollided
	
	;what input led to a collision?
	lda P0Inputs ;get inputs
	cmp #%11111111 ;if nothing is pressed, it was a previous frame's input
	beq .CollisionGoHome ;so don't record it
	
	sta P0LastMovement ;if it was this frame, record it
	
.CollisionGoHome

	rts ;if we have a collision, don't bother with inputs this frame
	
	;Check the joysticks, 1 = off, 0 = on. thanks atari
	
.CheckP0Right ;video magic to check if we're going right
	lda #%10000000 ; D7 = P0 right
	and P0Inputs ; AND A against P0Inputs

	cmp #%00000000 ; compare that to off. if the switch is pressed, everything will be 0.
	bne .CheckP0Left
	inc SpriteXPosition ;increase the sprite's X position by 1.
	
.CheckP0Left
	lda #%01000000 ; D6 = P0 left
	and P0Inputs ; AND A against P0Inputs
	
	cmp #%00000000 ; see if it's pressed
	bne .CheckP0Down
	dec SpriteXPosition ;decrease sprite's X position by 1.
	
.CheckP0Down
	lda #%00100000 ; D5 = P0 down.
	and P0Inputs ; AND A against P0Inputs

	cmp #%00000000 ; see if it's pressed
	bne .CheckP0Up
	inc SpriteYPosition ;increase sprite's Y position by 1 to move it down a scanline.

.CheckP0Up
	lda #%00010000 ; D4 = P0 up.
	and P0Inputs ; AND A against P0Inputs

	cmp #%00000000 ; see if it's pressed
	bne .CheckResetSwitch
	dec SpriteYPosition ;decrease sprite's Y position by 1 to move it up a scanline.
	
.CheckResetSwitch
	lda #%00000001 ; D0 = RESET
	and SWCHB ; AND A against P0Inputs

	cmp #%00000000 ; compare that to off. if the switch is pressed, everything will be 0.
	bne .MoveSprite

	jmp OutroInitialize ;if it is, go to outro

.MoveSprite
; 192 scanlines of picture.
; We want a buffer zone on the left and right of our 160-wide screen. So...

.CheckOver128 ;are we moving the sprite to the right of 128?
	ldx SpriteXPosition
	cpx #136 ;compare X position to 128
	bne .CheckUnder0
		
.SpriteRightBound ;if so, move us left one unit
	ldx #135 ;set our Y to 127.
	;stx SpriteXPosition ;ignoring for now
	jmp .CheckUpperBound ;if we're right, we're not left
	
.CheckUnder0 ;are we moving the sprite to the left of 32?
	;x should be SpriteXPosition
	cpx #16 ;compare X position to 32.
	bne .CheckUpperBound
	
.SpriteLeftBound ;if so, move us right one unit
	ldx #17 ;set our X to 33.
	stx SpriteXPosition
	jmp .CheckUpperBound ;if we're left, we're not right
	
.CheckUpperBound ;are we too high?
	ldy SpriteYPosition
	cpy #16 ;are we on scanline 16?
	bne .CheckLowerBound ;if not too high, are we too low?

.SpriteUpperBound ;if so, lower us
	ldx #17 ;set our Y pos to 17.
	stx SpriteYPosition
	rts ;if we're too high, we're not too low
	
.CheckLowerBound ;are we too low?
	;y should be SpriteYPosition
	cpy #145 ;are we on scanline 145?
	beq .SpriteLowerBound
	rts ; end of routine
	
.SpriteLowerBound ;if so, raise us
	ldx #144 ;set our Y pos to 144
	stx SpriteYPosition
	rts ; end of player positioning routine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; P0/PF collision handler

P0PFCollisionHandler subroutine
	;okay, so we collided with the playfield. which way were we going?

	lda #0 ;clear the collision bit
	sta P0PFCollided
	
;	lda P0Inputs ;get our last frame's input
	
.CheckP0Right ;was this collision caused by going right?
	lda #%10000000
	and P0LastMovement
	cmp #%00000000 ;did we go right?
	bne .CheckP0Left ;if not, did we go left?
	dec SpriteXPosition ;if so, go left
	dec SpriteXPosition
	jsr P0AdjustForCollision
	rts

.CheckP0Left ;was this collision caused by going left?
	lda #%01000000
	and P0LastMovement
	cmp #%00000000 ;did we go left?
	bne .CheckP0Up ;if not, did we go up?
	inc SpriteXPosition ;if so, go right
	inc SpriteXPosition
	jsr P0AdjustForCollision
	rts
	
.CheckP0Up ;was this collision caused by going up?
	lda #%00100000
	cmp P0LastMovement ;did we go up?
	bne .CheckP0Down ;if not, did we go down?
	inc SpriteYPosition ;if so, go down
	jsr P0AdjustForCollision
	rts
	
.CheckP0Down ;was this collision caused by going down?
	;we must have gone down then
	dec SpriteYPosition ;so go up
	jsr P0AdjustForCollision
	rts ;and go home
	
P0AdjustForCollision subroutine ;now adjust the sprite location post-collision

;	inc SpriteXPosition ;increase sprite X position variable
	lda SpriteXPosition ;move it to A
	ldx #0 ;iterator
	cpx #160 ;count to 160
	bcc .LT160 ;keep counting until we hit 160
	ldx #0 ;move object 0
.LT160
	jsr PositionSprite ;A = horizontal position (0-159), X = P0/P1
	rts ;and go back home
	
;:frogout:
	
	include "getout.asm"
	include "greatest2.asm"
	
;Greatest Moment screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Outro sequence begins when game is turned on    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutroInitialize
	lda #80 ;$E003 - set playfield color to 80
	sta COLUPF

	lda #56 ;set player 0 sprite color to 56
	sta COLUP0

	lda #%00000000 ; clear out sprite graphics
	sta GRP0
	
	lda #%00000000 ; don't reflect playfield
	sta CTRLPF
	
	ldx #0 ;black
	stx COLUBK ;background to black
	
	lda #96 ; default sprite X position is 96
	sta PlayerXPosition
	sta EnemyYPosition
	
	lda #64 ; default sprite Y position is 64
	sta PlayerYPosition

	lda #40
	sta EnemyXPosition
	
	lda #0 ;starting color cycle index
	sta ColorCycleIndex
	sta IntroFrameIndex
	
	sta SpriteHeight

OutroStartOfFrame ; we go back here when we start a new frame

;	lda #64 ;set playfield color to red
;	sta COLUPF

	inc ColorCycleIndex
	ldx ColorCycleIndex
	stx COLUPF ;one color increase per frame
	stx COLUBK

	;reset some variables
	ldx #8 ;8 scanlines of sprite
	stx SpriteHeight
	
	dex ; iterator

	lda #0
	sta GRP0
	
OutroDecreaseP0Y
	;read the joystick port to move the sprite.
	;since we need to know if a switch is 0, we OR it against #%00000000.
	;if a switch is pressed, its bit in A will be off.
	
	lda SWCHA ;SWCHA = joystick port input
	sta P0Inputs ;store it for later use

	; is the reset button switched? if so, abort the Outro screen and go into the game

OutroCheckReset ;video magic to check if we're going right
	lda #%00000001 ; D0 = RESET
	and SWCHB ; AND A against P0Inputs

;	cmp #%00000000 ; compare that to off. if the switch is pressed, everything will be 0.
;	bne OutroDrawFrame

	;jmp IntroDrawFrame ;go straight to the intro

	jmp OutroDrawFrame
	
OutroRepositionSprite ; no sprites in the Outro screen dammit!

OutroDrawFrame

; Start of vertical blank processing
	lda #0
	sta VBLANK
		
	lda #2
	sta VSYNC
 
	; 3 scanlines of VSYNCH signal
	sta WSYNC
	sta WSYNC
	sta WSYNC
		
	lda #0
	sta VSYNC   
        
	; 37 scanlines of vertical blank
	ldx #0
		
OutroVerticalBlank
	sta WSYNC
	inx
	cpx #37
	bne OutroVerticalBlank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 192 scanlines of picture...

OutroDrawBackground ;set up the next frame

	ldy #192
	
OutroDrawToEnd	;Now do it all in 72 cycles or less!!!

	sta WSYNC ; @0 - wait for TIA to reach next scanline
		
	lda ColorCycleIndex ;@2 get the color cycling index
	sty $87 ;@5 save Y to RAM
	adc $87 ;@8 add Y to our index
	sta COLUPF ;@11 and store that in COLUPF
	
OutroDrawingSprite ; no sprites in the Outro screen
	
OutroStartDrawingSprite ; no sprites in the Outro screen
	
OutroContinueDrawing ; draw our logo

	lda greatest2_STRIP_0,y ; @15 - fetch graphic part 0
	sta PF0 ; @18 - write it to PF0 - between 0 and 22

	lda greatest2_STRIP_1,y ; @22 - fetch graphic part 1
	sta PF1 ; @25 - write it to PF1 - between 0 and 28

	lda greatest2_STRIP_2,y ; @29 - fetch graphic part 2
	sta PF2 ; @32 - write it to PF2 - between 0 and 38

	;now we're drawing the right side of the screen
	
	lda greatest2_STRIP_3,y ; @36 - fetch graphic part 3
	sta PF0 ; @39 - write it to PF0 - between 28 and 49
	
	lda greatest2_STRIP_4,y ; @43 - fetch graphic part 4
	sta PF1 ; @46 - write it to PF1 - between 39 and 54
	
	lda greatest2_STRIP_5,y ; @50 - fetch graphic part 5
	sta PF2 ; @53 - write it to PF2 - between 50 and 64
	
	dey ;@55
	
	bne OutroDrawToEnd ; @58 <---- go start a new scanline
	
;30 lines of overscan	

	ldx #0 ;blank
	
	stx PF0 ;reset PF registers to blank
	stx PF1
	stx PF2 
	
	ldy #0 ;line counter
	
OutroOverscanLine
	iny
	sta WSYNC
	cpy #30 ;have we had 30 lines of overscan yet?
	bne OutroOverscanLine

	jmp OutroStartOfFrame ;back to scanline 0	
	
FineAdjustTableBegin

		.byte %01100000 ;left 6
		.byte %01010000
		.byte %01000000
		.byte %00110000
		.byte %00100000
		.byte %00010000
		.byte %00000000 ;left/right 0
		.byte %11110000
		.byte %11100000
		.byte %11010000
		.byte %11000000
		.byte %10110000
		.byte %10100000
		.byte %10010000
		.byte %10000000 ;right 8

FineAdjustTableEnd      =       FineAdjustTableBegin - 241
	
PlayerSprite

	.byte %00011000
	.byte %00011000
	.byte %00111100
	.byte %00111100
	.byte %01100110
	.byte %01011010
	.byte %11111111
	.byte %11111111
	.byte %11111111	
	.byte %11111111
	.byte %01011010
	.byte %01011010
	.byte %00111100
	.byte %00111100
	.byte %00011000
	.byte %00011000

	
EnemySprite

	.byte %00011000
	.byte %00011000
	.byte %00111100
	.byte %00111100
	.byte %01011010
	.byte %01100110
	.byte %11111111
	.byte %11111111
	.byte %11111111	
	.byte %11111111
	.byte %01011010
	.byte %01011010
	.byte %00111100
	.byte %00111100
	.byte %00011000
	.byte %00011000
	
DigitZero

	.byte #%01111110;--
	.byte #%11000011;--
	.byte #%11000011;--
	.byte #%11000011;--
	.byte #%11000011;--
	.byte #%11000011;--
	.byte #%11000011;--
	.byte #%01111110;--
	
	ORG $F800 ; Test level data
	
TestLevel

	.byte %01010101
	.byte %00000000
	.byte %00000000
	.byte %10101010
	
	ORG $FFE0 ; We come here after a bank switch from Bank 0.
	
	nop
	nop
	nop ; 3 cycles for the lda $FFF9 to execute
	jmp BeginGame ;and start the part after the intro
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;			
;;              interrupt vectors                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG $FFFA

	.word JumpToBank0 ; NMI
	.word JumpToBank0 ; RESET
	.word JumpToBank0 ; IRQ
	
END
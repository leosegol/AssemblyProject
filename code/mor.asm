	; MAIN AUTHOR - LEO SEGOL GRADE 10
	;--------------------------------------------------------------------------------------------------------------
	; AUTHOR - MARYANOVSKY ALLA + LEO SEGOL
	; MY OWN KEYBOARD INTERRUPT + BUFFER
	; -------------------------------------------------------------------------------------------------------------
	; READ A BMP FILE 320X200 AND PRINT IT TO SCREEN
	; AUTHOR: SHMULIK, 666
	; CREDIT: DIEGO ESCALA, WWW.ECE.MSSTATE.EDU/~REESE/EE3724/LABS/LAB9/BITMAP.ASM
	; -------------------------------------------------------------------------------------------------------------
	
IDEAL
MODEL SMALL
STACK 100H

DATASEG
		FILENAME DB 'ARENAA.BMP',0
		FILENAME1 DB 'KEYS.BMP',0
		FILENAME2 DB 'STARTP.BMP',0
		FILENAME3 DB 'VICB.BMP',0
		FILENAME4 DB 'VICR.BMP',0
		FILEHANDLE DW ?
		HEADER DB 54 DUP (0)
		PALETTE DB 256*4 DUP (0)
		SCRLINE DB 320 DUP (0)
		ERRORMSG DB 'ERROR', 13, 10,'$'
		
		LAST_KEY_PRESSED DW 0
		
		;		BLUEPLAYER 
		BLUE_POSITION DW  41930
		BLUE_BACKGROUND DB 1880 DUP(?)
		EFFECTCLR DB 1880 DUP(?)
		BLUE_HP DW 10
		BLUE_LAST_HP DW ?
		BLUE_STAMINA DW 0
		BLUE_STARTING_HP DW ?
		
		;		REDPLAYER
		RED_POSITION DW 42240
		RED_BACKGROUND DB 1880 DUP(?)
		REDEFFECTCLR DB 1880 DUP(?)
		RED_HP DW 10
		RED_LAST_HP DW ?
		RED_STAMINA DW 0
		RED_STARTING_HP DW ?
			
		INCLUDE "DATA.ASM"

	SPECIAL_DAMAGE EQU 2	
	SPECIAL_STAMINA	EQU 5
	DEATH_HP EQU 0
	BUTTON_PRESSED EQU 1
	HP_BAR_POS_PLAYER1 EQU 650
	HP_BAR_POS_PLAYER2 EQU 860
	
	



	CODESEG
	
	;///////////////////////////////////////////////
	;THE NEW INTERRUPT
	;==============================================================
PROC MY_ISR               
 ; MY ISR FOR KEYBOARD   
	PUSH    AX
	PUSH    BX
    PUSH    CX
    PUSH    DX
	PUSH    DI
	PUSH    SI
        

                        ; READ KEYBOARD SCAN CODE
    IN      AL, 60H

                        ; UPDATE KEYBOARD STATE
    XOR     BH, BH
    MOV     BL, AL
    AND     BL, 7FH     ; BX = SCAN CODE
	CMP BL, 1FH         ; IF CLICK ON S (INDEX 1 IN ARRAY MINI_BUFF)
	JNE CHECK1
	MOV BL,0
	JMP END_CHECK
	
CHECK1:
	CMP BL, 1EH		    ; IF CLICK ON A (INDEX 0 IN ARRAY MINI_BUFF)
	JNE CHECK2
	MOV BL,1
	JMP END_CHECK
	
CHECK2:
	CMP BL, 11H	    ; IF CLICK ON W (INDEX 2 IN ARRAY MINI_BUFF)
	JNE CHECK3
	MOV BL,2
	JMP END_CHECK
	
CHECK3:
	CMP BL, 20H		    ; IF CLICK ON D (INDEX 3 IN ARRAY MINI_BUFF)
	JNE CHECK4
	MOV BL,3
	JMP END_CHECK
	
CHECK4:
	
	CMP BL, 17H	    ; IF CLICK ON I (INDEX 4 IN ARRAY MINI_BUFF)
	JNE CHECK5
	MOV BL, 4
	JMP END_CHECK
	
CHECK5:
	
	CMP BL, 25H    ; IF CLICK ON K (INDEX 5 IN ARRAY MINI_BUFF)
	JNE CHECK6
	MOV BL, 5
	JMP END_CHECK
	
CHECK6:
	
	CMP BL, 26H	    ; IF CLICK ON L (INDEX 6 IN ARRAY MINI_BUFF)
	JNE CHECK7
	MOV BL, 6
	JMP END_CHECK 
	
CHECK7:	

	CMP BL, 36H	    ; IF CLICK ON RIGHT_SHIFT (INDEX 7 IN ARRAY MINI_BUFF)
	JNE CHECK8
	MOV BL, 7
	JMP END_CHECK
	
CHECK8:
	
	CMP BL, 2AH	    ; IF CLICK ON LEFT_SHIFT (INDEX 8 IN ARRAY MINI_BUFF)
	JNE CHECK9
	MOV BL, 8
	JMP END_CHECK
	
CHECK9:
	
	CMP BL, 24H	    ; IF CLICK ON J (INDEX 7 IN ARRAY MINI_BUFF)
	JNE CHECK
	MOV BL, 9
	JMP END_CHECK
	
	
CHECK:

    CMP BL, 1H		    ; IF CLICK ON ESC
	JNE END_CHECK
	MOV [BYTE PTR CS:ESC_KEY], 1
	
END_CHECK:
    PUSH CX
	MOV CX, 7
    SHR AL, CL              ; AL = 0 IF PRESSED, 1 IF RELEASED
	POP CX
    XOR AL, 1               ; AL = 1 IF PRESSED, 0 IF RELEASED
    MOV     [CS:MINI_BUFF+BX], AL  ; SAVE PRESSED BUTTONS IN ARRAY MINI_BUFF
	
	
                                ; SEND EOI TO XT KEYBOARD
    IN      AL, 61H
    MOV     AH, AL
    OR      AL, 80H
    OUT     61H, AL
    MOV     AL, AH
    OUT     61H, AL

                                ; SEND EOI TO MASTER PIC
    MOV     AL, 20H
    OUT     20H, AL
	
    POP     SI
    POP     DI                       ;
    POP     DX
    POP     CX
    POP     BX
    POP     AX
   
    IRET
ENDP MY_ISR
;==========================================================
 ; NUMBERS VALUE 1 - KEY PRESSED
;==========================================================
MINI_BUFF      DB 10 DUP (0)
ESC_KEY  DB 0
;======================================================

;======================================================================	
PROC CHANGE_HANDLER
    XOR     AX, AX
    MOV     ES, AX

    CLI                              ; INTERRUPTS DISABLED
    PUSH    [WORD PTR ES:9*4+2]      ; SAVE OLD KEYBOARD (9) ISR ADDRESS - INTERRUPT SERVICE ROUTINE(ISR)
    PUSH    [WORD PTR ES:9*4]
	                                 ; PUT MY KEYBOARD (9) ISR ADDRESS: PROCEDURE IRQ1ISR
    MOV     [WORD PTR ES:9*4], OFFSET MY_ISR
	                                 ; PUT CS IN ISR ADDRESS
    MOV     [ES:9*4+2],        CS
    STI                               ; INTERRUPTS ENABLED

    CALL    MY_PROGRAM                     ; PROGRAM THAT USE THE INTERRUPT

    CLI                               ; INTERRUPTS DISABLED
    POP     [WORD PTR ES:9*4]         ; RESTORE ISR ADDRESS
    POP     [WORD PTR ES:9*4+2]
    STI                               ; INTERRUPTS ENABLED

    RET
ENDP CHANGE_HANDLER	
;=====================================================================	
	
	;//////////////////////////////////////////////
	;MAIN
	
	PROC MAIN
	PUSH AX CX BX 
					; PROCESS BMP FILE
				MOV CX, OFFSET FILENAME
				PUSH [FILEHANDLE]
				PUSH CX
				CALL OPENFILE
				POP CX
				POP [FILEHANDLE]
				
				CALL READHEADER
				
				MOV CX, OFFSET PALETTE
				PUSH CX
				CALL READPALETTE
				CALL COPYPAL
				POP CX
				MOV CX, OFFSET SCRLINE
				PUSH CX
				CALL COPYBITMAP
				POP CX
				;============================
				;INITIALIZES THE MOUSE

					MOV AX,0H
					INT 33H
				;SHOW MOUSE
					MOV AX,1H
					INT 33H
						MOUSELP:
						MOV AH,1
						INT 16H
						JNZ PRESSANYBUTTON
						MOV AX,3H
						INT 33H
						CMP BX, 01H ;LEFT CLICK
						JNZ MOUSELP
						PRESSANYBUTTON:
						MOV AX,2
						INT 33H
				;================================
						
						
				; PROCESS BMP FILE
				MOV CX, OFFSET FILENAME1
				PUSH [FILEHANDLE]
				PUSH CX
				CALL OPENFILE
				POP CX
				POP [FILEHANDLE]
				
				CALL READHEADER
				
				MOV CX, OFFSET PALETTE
				PUSH CX
				CALL READPALETTE
				CALL COPYPAL
				POP CX
				MOV CX, OFFSET SCRLINE
				PUSH CX
				CALL COPYBITMAP
				POP CX
					MOV AX,1H
					INT 33H
							MOV BX ,00H
						MOUSELP1:
						MOV AX,3H
						INT 33H
							CMP	 	[BYTE PTR CS:ESC_KEY], 0       ; IF CLICKED ?
							JZ 		 OUT_OF_GAME    	; YES ---> END THE PROGRAM
								MOV	 	AH, 0
								MOV 	AL, 3
								INT 	10H
							POP BX CX AX
								RET
							OUT_OF_GAME:
		
						CMP BX, 02H ;LEFT CLICK
						JNZ MOUSELP1
						SHR CX,1
						MOV AX,2
						INT 33H
						
							
							; PROCESS BMP FILE
				MOV CX, OFFSET FILENAME2
				PUSH [FILEHANDLE]
				PUSH CX
				CALL OPENFILE
				POP CX
				POP [FILEHANDLE]
				
				CALL READHEADER
				
				MOV CX, OFFSET PALETTE
				PUSH CX
				CALL READPALETTE
				CALL COPYPAL
				POP CX
				MOV CX, OFFSET SCRLINE
				PUSH CX
				CALL COPYBITMAP
				POP CX
				
				PUSH HP_BAR_POS_PLAYER1
				PUSH OFFSET HEART
				PUSH [BLUE_HP]
				CALL HP_BAR 
				
				PUSH HP_BAR_POS_PLAYER2
				PUSH OFFSET HEART
				PUSH [RED_HP]
				CALL HP_BAR 
				
				MOV AX,[BLUE_HP]
				MOV [BLUE_STARTING_HP], AX
				MOV [BLUE_LAST_HP], AX
				
				MOV AX,[RED_HP]
				MOV [RED_STARTING_HP], AX
				MOV [RED_LAST_HP], AX
				
			POP BX CX AX
			RET
			ENDP MAIN
	;//////////////////////////////////////////////////////

PROC OPENFILE
; OPEN FILE
	PUSH BP
	MOV BP, SP
	PUSH AX
	PUSH DX
	
	MOV AH, 3DH
	XOR AL, AL
	MOV DX, [BP+4]	;OFFSET FILENAME
	INT 21H
	MOV [BP+6], AX 	;[FILEHANDLE]
	 
	POP DX
	POP AX
	POP BP
	RET
ENDP OPENFILE

PROC READHEADER
; READ BMP FILE HEADER, 54 BYTES
	
	MOV AH, 3FH
	MOV BX, [FILEHANDLE]
	MOV CX, 54
	MOV DX, OFFSET HEADER
	INT 21H
	
	RET
ENDP READHEADER

PROC READPALETTE
; READ BMP FILE COLOR PALETTE, 256 COLORS * 4 BYTES (400H)
	PUSH BP
	MOV BP, SP
	PUSH AX
	PUSH CX
	PUSH DX
	
	MOV AH, 3FH
	MOV CX, 400H
	MOV DX, [BP+4]	;OFFSET PALETTE
	INT 21H
	
	POP DX
	POP CX
	POP AX
	POP BP
	RET
ENDP READPALETTE

PROC COPYPAL
; COPY THE COLORS PALETTE TO THE VIDEO MEMORY
; THE NUMBER OF THE FIRST COLOR SHOULD BE SENT TO PORT 3C8H
; THE PALETTE IS SENT TO PORT 3C9H
	PUSH BP
	MOV BP, SP
	PUSH AX
	PUSH CX
	PUSH DX
	PUSH SI
	
	MOV SI, [BP+4]	;OFFSET PALETTE
	MOV CX, 256
	MOV DX, 3C8H
	MOV AL, 0
	; COPY STARTING COLOR TO PORT 3C8H
	OUT DX, AL
	; COPY PALETTE ITSELF TO PORT 3C9H
	INC DX
	PALLOOP:
		; NOTE: COLORS IN A BMP FILE ARE SAVED AS BGR VALUES RATHER THAN RGB.
		MOV AL, [SI+2] ; GET RED VALUE.
		SHR AL, 2 ; MAX. IS 255, BUT VIDEO PALETTE MAXIMAL
		; VALUE IS 63. THEREFORE DIVIDING BY 4.
		OUT DX, AL ; SEND IT.
		MOV AL, [SI+1] ; GET GREEN VALUE.
		SHR AL, 2
		OUT DX, AL ; SEND IT.
		MOV AL, [SI] ; GET BLUE VALUE.
		SHR AL, 2
		OUT DX, AL ; SEND IT.
		ADD SI, 4 ; POINT TO NEXT COLOR.
		; (THERE IS A NULL CHR. AFTER EVERY COLOR.)
	LOOP PALLOOP
	
	POP SI
	POP DX
	POP CX
	POP AX
	POP BP
	RET
ENDP COPYPAL

PROC COPYBITMAP
; BMP GRAPHICS ARE SAVED UPSIDE-DOWN.
; READ THE GRAPHIC LINE BY LINE (200 LINES IN VGA FORMAT),
; DISPLAYING THE LINES FROM BOTTOM TO TOP.
	PUSH BP
	MOV BP, SP
	PUSH AX
	PUSH CX
	PUSH DX
	PUSH DI
	PUSH SI
	
	MOV AX, 0A000H
	MOV ES, AX
	MOV CX,200
	PRINTBMPLOOP:
		PUSH CX
		; DI = CX*320, POINT TO THE CORRECT SCREEN LINE
		MOV DI,CX
		SHL CX,6
		SHL DI,8
		ADD DI,CX
		; READ ONE LINE
		MOV AH,3FH
		MOV CX,320
		MOV DX,	[BP+4]	;OFFSET SCRLINE
		INT 21H
		; COPY ONE LINE INTO VIDEO MEMORY
		CLD ; CLEAR DIRECTION FLAG, FOR MOVSB
		MOV CX,320
		MOV SI,	[BP+4]		;OFFSET SCRLINE 
		REP MOVSB ; COPY LINE TO THE SCREEN
		 ;REP MOVSB IS SAME AS THE FOLLOWING CODE:
		 ;MOV ES:DI, DS:SI
		 ;INC SI
		 ;INC DI
		 ;DEC CX
		;LOOP UNTIL CX=0
		POP CX
	LOOP PRINTBMPLOOP
	
	POP SI
	POP DI
	POP DX
	POP CX
	POP AX
	POP BP
	RET
ENDP COPYBITMAP
	;====================================



	PROC PRINTRED
	;WORKS LIKE PRINT RED ONLY IT MIRROS THE CHARECTERS
	PUSH BP
	MOV BP,SP
	PUSH DI AX SI DX CX
		MOV 	DI,	[BP+4]     
		MOV 	SI,	[BP+6]
		MOV 	DX,	0
		MOV 	CX,	0
	PRINTLOOP1:
		MOV 	AL,	[BYTE PTR DI]
		CMP 	AL,	255
	JZ WHITE1
		CMP 	AL, 55
	JNZ YELLOW
		SUB 	AL,	5 ; CHANGES THE COLOR YELLOW TO GREEN
	YELLOW:
		MOV [ES:SI], AL
	WHITE1:
		INC 	DI
		DEC 	SI
		INC 	DX
		CMP 	DX, 40
	JNZ PRINTLOOP1
		ADD 	SI, 360
		MOV 	DX,0
		INC 	CX
		CMP 	CX ,47
	JNZ PRINTLOOP1
	POP CX DX SI AX DI BP
	RET 4
	ENDP PRINTRED
	;==============================
	PROC LOWER_HP_BAR
	PUSH BP
	MOV BP, SP
	PUSH DI SI CX AX
		MOV 	CX, [BP+10]; HP 
		MOV 	AX, [BP+8];STARTING HP
		MOV 	SI, [BP+6]; PLACE ON SCREEN
		MOV 	DI, [BP+4]; OFFSET HEART
		AND  	CX, 1; EVERY HEART IS TWO HP, I LOWER DELETE
		CMP 	CX, 0; THE HEART IF THE HP IS DEVIDED BY TWO(IF THE LAST BIT EQUALS 0)
	JNE HALF_HEART
		MOV		CX, [BP+10]
		SHR 	CX, 1
		SHR 	AX, 1
		SUB 	AX, CX
		MOV 	CX, AX
	DELETE_HEART_LOOP:
		PUSH SI
		PUSH DI
		CALL DELETE_HEART
		ADD		SI, 21
	LOOP DELETE_HEART_LOOP
		
	HALF_HEART:
	POP AX CX SI DI BP
	RET 6
	ENDP LOWER_HP_BAR

	;=====================
	
	PROC PRINTBLUE
		PUSH BP
		MOV BP,SP
		PUSH DI AX SI DX CX
		MOV 	DI, [BP+4]		;POS IN DATASEG
		MOV 	SI, [BP+6]		;POS IN EXTRASEG
		MOV 	DX, 0
		MOV 	CX, 0
	PRINTLOOP:
		MOV 	AL, [BYTE PTR DI]     	;TAKES COLOR FROM DATA
		CMP 	AL, 51
	JNZ GREEN
		ADD 	AL,5
	GREEN:
		CMP 	AL, 255			;CHEKES IF THE COLOR IS WHITE
	JZ WHITE					;IF IT IS WHITE IT SKIPS IT 
		MOV		[ES:SI],AL		;PIXLES GETS CHANGED
	WHITE:						; SKIPS HERE^^^^^
		INC 	DI
		INC 	SI
		INC 	DX
		CMP 	DX, 40			; PRINTS UNTIL IT GETS TO 40
	JNZ PRINTLOOP
		ADD 	SI, 280	; 320-WEIDTH		; STARTS IN A NEW LINE 
		MOV 	DX, 0			; RESETS THE COUNTER
		INC 	CX
		CMP 	CX, 47			; PRINTS TILL IT IS FULL ON LENGTH
	JNZ PRINTLOOP
	POP CX DX SI AX DI BP
	RET 4
	ENDP PRINTBLUE
	;======================
	PROC DELAY
		PUSH CX AX
		XOR AX ,AX
	RUN:
		MOV CX, 0FFFFH
	DELA:
	LOOP DELA
		INC AX
		CMP AL,25
	JNZ RUN
		POP AX CX
		RET
	ENDP DELAY
;==============================
PROC PRINT_HEART
		PUSH BP
		MOV BP,SP
		PUSH DI AX SI DX CX
		MOV 	DI, [BP+4]		;POS IN DATASEG
		MOV 	SI, [BP+6]		;POS IN EXTRASEG
		MOV 	DX, 0
		MOV 	CX, 0
	PRINTLOOPHEART:
		MOV 	AL, [BYTE PTR DI]     	;TAKES COLOR FROM DATA
		CMP 	AL, 255			;CHEKES IF THE COLOR IS WHITE
	JZ WHITE4					;IF IT IS WHITE IT SKIPS IT 
		MOV		[ES:SI],AL		;PIXLES GETS CHANGED
	WHITE4:						; SKIPS HERE^^^^^
		INC 	DI
		INC 	SI
		INC 	DX
		CMP 	DX, 16			; PRINTS UNTIL IT GETS TO 16
	JNZ PRINTLOOPHEART
		ADD 	SI, 304	; 320-WEIDTH		; STARTS IN A NEW LINE 
		MOV 	DX, 0			; RESETS THE COUNTER
		INC 	CX
		CMP 	CX, 12		; PRINTS TILL IT IS FULL ON LENGTH
	JNZ PRINTLOOPHEART
	POP CX DX SI AX DI BP
	RET 4
	ENDP PRINT_HEART
;-=============================
PROC DELETE_HEART
		PUSH BP
		MOV BP,SP
		PUSH DI AX SI DX CX
		MOV 	DI, [BP+4]		;POS IN DATASEG
		MOV 	SI, [BP+6]		;POS IN EXTRASEG
		MOV 	DX, 0
		MOV 	CX, 0
	DELETELOOPHEART:
		MOV 	AL, [BYTE PTR DI]     	;TAKES COLOR FROM DATA
		CMP 	AL, 255			;CHEKES IF THE COLOR IS WHITE
	JZ WHITEHEART1					;IF IT IS WHITE IT SKIPS IT 
		MOV 	AL, 0			;PUTS ONLY BLACK THAT WAY IT REMOVES THE HEART
		MOV		[ES:SI],AL		;PIXLES GETS CHANGED
	WHITEHEART1:						; SKIPS HERE^^^^^
		INC 	DI
		INC 	SI
		INC 	DX
		CMP 	DX, 16			; PRINTS UNTIL IT GETS TO 40
	JNZ DELETELOOPHEART
		ADD 	SI, 304	; 320-WEIDTH		; STARTS IN A NEW LINE 
		MOV 	DX, 0			; RESETS THE COUNTER
		INC 	CX
		CMP 	CX, 12		; PRINTS TILL IT IS FULL ON LENGTH
	JNZ DELETELOOPHEART
	POP CX DX SI AX DI BP
	RET 4
	ENDP DELETE_HEART
;==============================
	PROC HP_BAR
	PUSH BP
	MOV BP,SP
	PUSH CX SI
		MOV 	CX, [BP+4]; THE HP IN NUMBERS
		MOV 	SI, [BP+8]; PLACE ON THE SCREEN
		MOV 	DI, [BP+6]; OFFSET OF HEART
		SHR CX,1
	PRINT_HP__BAR:
		PUSH SI
		PUSH DI
		CALL PRINT_HEART
		
		ADD 	SI, 21
	LOOP PRINT_HP__BAR
	POP SI CX BP
	RET 6
	ENDP HP_BAR
;==============================
	PROC BACKGROUND_SAVER
	PUSH BP
	MOV BP,SP
	PUSH DI AX SI DX CX
		MOV		DI, [BP+4]
		MOV 	SI, [BP+6]
		MOV 	DX, SI
		ADD 	DX, 40 ; NUMBER OF PIXLES WIDTH
		MOV 	CX, 0
	BOXLOOP:
		MOV 	AL, [ES:SI]
		MOV 	[DI], AL
		INC 	DI
		INC 	SI
		CMP 	SI,DX
	JNZ NNL
		ADD 	SI, 280 ;NEXT LINE (320-WIDTH)
		ADD 	DX, 320
		INC 	CX
	NNL:
		CMP CX ,47 ; NUMBER OF PIXLES ( LENFTH)
	JNZ BOXLOOP
	POP CX DX SI AX DI BP
	RET 4
	ENDP BACKGROUND_SAVER
	;=======================
	
	
	;RED PRINTS THE SAME CHRECTER AS BLUE BUT MIRRORED AND CHANGES YELLOW TO GREEN
	PROC RED_BACKGROUND_SAVER
	PUSH BP
	MOV BP,SP
	PUSH DI AX SI DX CX
		MOV 	DI ,[BP+4]	;HAS THE POS IN DATASEG
		MOV 	SI,[BP+6]	;HAS THE POS IN EXTRASEG
		MOV 	DX,0
		MOV		CX,0
	SAVE_SCREEN_LOOP:
		MOV 	AL , [ES:SI]	;PUTS THE COLOR FROM EXTRASEG IN POS SI TO AL
		MOV		[DI] , AL		;PUTS THE COLOR IN DATASEG
		INC 	DI
		DEC 	SI
		INC 	DX
		CMP 	DX, 40			;IT DOES IT TILL IT GETS TO THE WEIDTH OF THE CHRECTER
	JNZ SAVE_SCREEN_LOOP
		ADD 	SI, 360			;RESTETS IT TO THE START OF THE NEXT LINE
		MOV 	DX,0
		INC 	CX
		CMP 	CX ,47			;IT DOES IT TILL IT GETS TO THE LENGTH OF THE CHARECTER
	JNZ SAVE_SCREEN_LOOP
	POP CX DX SI AX DI BP
	RET 4
	ENDP RED_BACKGROUND_SAVER
	
	
	
	;=====================
	
	
	PROC PRINT_BLUE
	PUSH BP
	MOV BP ,SP	
		;--------------------------------
		PUSH [BP+4]	; OFFSET CHARCTER 	;
		PUSH [BP+8]			; POS IN ES	;
		CALL BACKGROUND_SAVER			;
		;--------------------------------
				
		;--------------------------------
		PUSH [BP+4] ; OFFSET BOX		;						WORKS LIKE PRINT RED VVVV (BELOW)
		PUSH [BP+6]	; POS IN ES			;
		CALL PRINTBLUE					;
		;-------------------------------	
		
		;-------------------------------
		CALL DELAY						;
		;-------------------------------

		;-------------------------------
		PUSH [BP+4] ; OFFSET BOX		;
		PUSH [BP+8]; POS IN ES			;
		CALL PRINTBLUE					;
		;-------------------------------
	POP BP
	RET 6
	ENDP PRINT_BLUE
		
	;=====================

	PROC PRINT_RED
	PUSH BP
	MOV BP ,SP	
		;-----------------------------
		PUSH [BP+4]	; OFFSET CHARCTER 	;
		PUSH [BP+8]			; POS IN ES	;        SAVES THE BACKGROUND ON THE LOCAATION
		CALL RED_BACKGROUND_SAVER		;
		;-----------------------------
		
		;-----------------------------
		PUSH [BP+4] ; OFFSET BOX		;
		PUSH [BP+6]	; POS IN ES			;		 PRINTS THE CHARECHTER
		CALL PRINTRED					;
		;-------------------------------
		
		;-------------------------------
		CALL DELAY					;         WAITS 
		;-------------------------------	
			
		;-------------------------------	
		PUSH [BP+4] ; OFFSET BOX		;
		PUSH [BP+8]; POS IN ES			;		PRINTS THE BACKGROUND ON THE CHRECTER THAT WAY IT GETS DELETED
		CALL PRINTRED					;
		;-------------------------------
	POP BP
	RET 6
	ENDP PRINT_RED	
		
		
	;====================
	PROC PUNCH
	PUSH BP
	MOV BP,SP
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+12];PUNCH1
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_BLUE
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+10];PUNCH2
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_BLUE
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+8];PUNCH3
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_BLUE
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+6];PUNCH4
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_BLUE
	POP BP
	RET 12
	ENDP PUNCH
	
	;=============================
	
	PROC RED_PUNCH
	PUSH BP
	MOV BP,SP
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+12];PUNCH1
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+10];PUNCH2
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+8];PUNCH3
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+6];PUNCH4
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	POP BP
	RET 12
	ENDP RED_PUNCH
	
	
	;============================
	
	PROC REDPUNCH
	PUSH BP
	MOV BP,SP
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+12];PUNCH1
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+10];PUNCH2
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+8];PUNCH3
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	
		PUSH [BP+14]; BLUE_BACKGROUND
		PUSH [BP+6];PUNCH4
		PUSH [BP+4] ; POS IN ES
		CALL PRINT_RED
	POP BP
	RET 12
	ENDP REDPUNCH
	
	
	;=============================
	
	PROC STEP
	PUSH BP
	MOV BP,SP
	PUSH AX
	MOV 	AX, [BP+18]
	
		ADD 	[BP+4], AX
		PUSH [BP+16] 
		PUSH [BP+6]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		ADD 	[BP+4], AX
		PUSH [BP+16] 
		PUSH [BP+8]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		ADD 	[BP+4], AX
		PUSH [BP+16] 
		PUSH [BP+10]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		ADD 	[BP+4], AX
		PUSH [BP+16] 
		PUSH [BP+12]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		ADD 	[BP+4], AX
		PUSH [BP+16] 
		PUSH [BP+14]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		MOV 	AX, [BP+4]	
		MOV 	[BP+18], AX
		
		
	POP AX BP
	RET 14
	ENDP STEP
	
	;===============================
	
	
		PROC REDSTEP
	PUSH BP
	MOV BP,SP
	PUSH AX
	MOV 	AX, [BP+18]
	
		ADD 	[BP+4], AX
		PUSH [BP+16] 
		PUSH [BP+6]
		PUSH [BP+4]
		CALL PRINT_RED
	
	ADD 	[BP+4], AX	
		PUSH [BP+16] 
		PUSH [BP+8]
		PUSH [BP+4]
		CALL PRINT_RED
	
	ADD 	[BP+4], AX	
		PUSH [BP+16] 
		PUSH [BP+10]
		PUSH [BP+4]
		CALL PRINT_RED
	
	ADD 	[BP+4], AX	
		PUSH [BP+16] 
		PUSH [BP+12]
		PUSH [BP+4]
		CALL PRINT_RED
	
	ADD 	[BP+4], AX	
		PUSH [BP+16] 
		PUSH [BP+14]
		PUSH [BP+4]
		CALL PRINT_RED
		
		MOV 	AX, [BP+4]	
		MOV 	[BP+18], AX
		
	POP AX BP
	RET 14
	ENDP REDSTEP
	
	;===============================
	PROC EFFECT
	PUSH BP
	MOV BP,SP
	
	
	EFPOS EQU [BP+4] 
	
	ADD EFPOS, 40			;ADDS 40 FROM THE POS OF THE PLAYER
	
	PUSH [BP+6] ;EFBOX 		;PRINTS THE ANIMATION WITH THE NEW POS
	PUSH [BP+8];OFFSET
	PUSH EFPOS;POS 
	CALL PRINT_BLUE
	
	PUSH [BP+6]
	PUSH [BP+10]
	PUSH EFPOS
	CALL PRINT_BLUE
	
	PUSH [BP+6]
	PUSH [BP+12]
	PUSH EFPOS
	CALL PRINT_BLUE
	
	ADD EFPOS,20 			;ADDS ANOTHER 20 SO THE ATTACK WILL HAVE RANGE
	
	PUSH [BP+6]
	PUSH [BP+14]
	PUSH EFPOS
	CALL PRINT_BLUE
	
	ADD EFPOS,10			;ADDS ANOTHER 10 SO THE ATTACK WILL HAVE RANGE
	
	PUSH [BP+6]				;ANIMATION OF THE EXPLOSION ON THE END
	PUSH [BP+16]
	PUSH EFPOS
	CALL PRINT_BLUE
	
	PUSH [BP+6]
	PUSH [BP+18]
	PUSH EFPOS
	CALL PRINT_BLUE
	
	POP BP 
	RET 16
	ENDP EFFECT
	
	
	;===========================
	
	PROC RED_EFFECT
	PUSH BP
	MOV BP,SP
	
	
	RED_EFFFECT_POSITION EQU [BP+4] 
	
	SUB RED_EFFFECT_POSITION, 80			;ADDS 50 FROM THE POS OF THE PLAYER
	
	PUSH [BP+6] ;EFBOX 		;PRINTS THE ANIMATION WITH THE NEW POS
	PUSH [BP+8];OFFSET
	PUSH RED_EFFFECT_POSITION;POS 
	CALL PRINT_BLUE
	
	SUB RED_EFFFECT_POSITION, 10
	
	PUSH [BP+6]
	PUSH [BP+10]
	PUSH RED_EFFFECT_POSITION
	CALL PRINT_BLUE
	
	SUB RED_EFFFECT_POSITION,10
	
	PUSH [BP+6]
	PUSH [BP+12]
	PUSH RED_EFFFECT_POSITION
	CALL PRINT_BLUE
	
	SUB RED_EFFFECT_POSITION,10 			;ADDS ANOTHER 10 SO THE ATTACK WILL HAVE RANGE
	
	PUSH [BP+6]
	PUSH [BP+14]
	PUSH RED_EFFFECT_POSITION
	CALL PRINT_BLUE
	
	SUB RED_EFFFECT_POSITION,10			;ADDS ANOTHER 10 SO THE ATTACK WILL HAVE RANGE
	
	PUSH [BP+6]			;ANIMATION OF THE EXPLOSION ON THE END
	PUSH [BP+16]
	PUSH RED_EFFFECT_POSITION
	CALL PRINT_BLUE
	
	POP BP 
	RET 14
	ENDP RED_EFFECT
	
	
	;===========================
	
	PROC SPECIALATTACK
	PUSH BP
	MOV BP,SP
	
		PUSH [BP+6]  		;PRINTS THE FIRST ANIMATION 
		PUSH [BP+8]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		PUSH [BP+6] 		; BLUE_BACKGROUND
		PUSH [BP+10]		; OOFFSET CHARECTER	
		PUSH [BP+4] 		;POS IN ES
		CALL PRINT_BLUE
		
		PUSH [BP+6] 
		PUSH [BP+12]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		
		
		POP BP
		RET 10
		ENDP SPECIALATTACK
		
	;===========================
	
	PROC RED_SPECIALATTACK
	PUSH BP
	MOV BP,SP
	
		PUSH [BP+6]  		;PRINTS THE FIRST ANIMATION 
		PUSH [BP+8]
		PUSH [BP+4]
		CALL PRINT_RED
		
		PUSH [BP+6] 		; BLUE_BACKGROUND
		PUSH [BP+10]		; OOFFSET CHARECTER	
		PUSH [BP+4] 		;POS IN ES
		CALL PRINT_RED
		
		PUSH [BP+6] 
		PUSH [BP+12]
		PUSH [BP+4]
		CALL PRINT_RED
		
		
		
		POP BP
		RET 10
		ENDP RED_SPECIALATTACK
	
	;===========================
	
	PROC BLUE_PARRY
	PUSH BP
	MOV BP,SP
		
		
		PUSH [BP+6]
		PUSH [BP+12]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
		PUSH [BP+6]
		PUSH [BP+10]
		PUSH [BP+4]
		CALL PRINT_BLUE
	
		PUSH [BP+6]
		PUSH [BP+8]
		PUSH [BP+4]
		CALL PRINT_BLUE
		
	POP BP
	RET 10
	ENDP BLUE_PARRY
	;===================================
	PROC RED_PARRY
	PUSH BP
	MOV BP,SP
		
		
		PUSH [BP+6]
		PUSH [BP+12]
		PUSH [BP+4]
		CALL PRINT_RED
		
		PUSH [BP+6]
		PUSH [BP+10]
		PUSH [BP+4]
		CALL PRINT_RED
	
		PUSH [BP+6]
		PUSH [BP+8]
		PUSH [BP+4]
		CALL PRINT_RED
		
	POP BP
	RET 10
	ENDP RED_PARRY
	
	
	;//////////////////////////////////////
	;			MAIN PROCS				  /
	;//////////////////////////////////////
	
	;===============================================================
	PROC BLUE_MOVES
	PUSH BP
	MOV BP,SP
	PUSH AX DX
		
		MOV 	DX, 0
		MOV 	AX, [BP+20]
		KEY_D EQU 3
		KEY_A EQU 1
		LEFT_BORDER EQU 41920
		;------------------------------
		CMP 	[BP+16], KEY_D
		JZ 		KEYD
		CMP 	[BP+16] , KEY_A
		JZ 		KEYA
		JMP 	NOTA
	KEYA:
		CMP		AX, LEFT_BORDER ;41920
		JZ 		ON_BORDER
		MOV		DX, 0FFFEH	; ACTUALY IT IS LIKE -2 THAT WAY WHEN YOU ADD IT TO THE POSITION IT SUBS THE POS
		JMP 	ON_BORDER
	KEYD:
		SUB		[BP+18], AX; SUBS THE POS OF THE TWO PLAYERS
		CMP 	[BP+18], 80; THE MINIMUM DISTANCE BEFOR COLLISION
	JNA 	ON_BORDER	
		MOV 	DX, 2
	ON_BORDER:
	
		PUSH 	AX
		PUSH 	[BP+14]			; BACKGROUND
		CALL 	PRINTBLUE

		;----------------------------------
		PUSH 	DX
		PUSH 	[BP+14]; OFFSET BACKGROUND
		PUSH 	[BP+12]	;OFFSET WALK2	
		PUSH 	[BP+10]	;^^^^^^^^^^^3	
		PUSH 	[BP+8]	;^^^^^^^^^^^4	
		PUSH 	[BP+6]; ^^^^^^^^^^^^5
		PUSH 	[BP+4]; ^^^^^^^^^^^^6
		PUSH 	AX; POS OF BLUE PLAYER
		CALL 	STEP
		POP 	AX
		;-----------------------------
		PUSH 	AX
		PUSH 	[BP+14] 			; BACKGROUND
		CALL	 BACKGROUND_SAVER
	NOTA:	
		MOV		[BP+20],AX
		POP DX AX BP
	RET 16
	ENDP BLUE_MOVES
	
;=================================================================
	
	PROC RED_MOVES
	PUSH BP
	MOV BP, SP
	PUSH AX DX SI
		MOV SI, 0
		MOV AX, [BP+20]		
		MOV DX, [BP+18]
		 KEY_L EQU 6
		 KEY_J EQU 9
		 RIGHT_BORDER EQU 42240
	;---------------------------------------------	 
		CMP 	[BP+16], KEY_L; THE BUTTON PRESSED
		JZ 		KEYL
		CMP 	[BP+16] , KEY_J; THE BUTTON PRESSED
		JZ 		KEYJ
		JMP 	NOTJ
	KEYJ:
	;-------------------
		PUSH	 AX		;
		PUSH 	[BP+14]	;THIS PART REMOVES THE DEFUALT STAND OF THE CHARCTER
		CALL 	PRINTRED;
	;-------------------
		SUB		[BP+20], DX; SUBS THE POS OF THE TWO PLAYERS
		CMP 	[BP+20], 80; THE MINIMUM DISTANCE BEFOR COLLISION
	JNA 	ON_BORDER1	
		MOV 	SI, 0FFFEH	   ;
		JMP 	ON_BORDER1 ;
	KEYL:
	;-------------------
		PUSH	 AX		;
		PUSH 	[BP+14]	;THIS PART REMOVES THE DEFUALT STAND OF THE CHARCTER
		CALL 	PRINTRED;
	;-------------------
		CMP		 AX, RIGHT_BORDER
		JZ 		ON_BORDER1
		MOV 	SI, 2
	ON_BORDER1:
	;---------------------------
		PUSH 	 SI	
		PUSH	 [BP+14]		;
		PUSH	 [BP+12]		;			
		PUSH	 [BP+10]		;			
		PUSH	 [BP+8]			;		
		PUSH	 [BP+6]			;		
		PUSH	 [BP+4]			;		
		PUSH     AX				;
		CALL	 REDSTEP		;
		POP 	AX
	;---------------------------	
	;-----------------------------------
		PUSH	 AX						;
		PUSH	 [BP+14]				;THIS PART SAVES THE BACKGROUND OF THE CHARCTER IN ITS NEW POSITION
		CALL	 RED_BACKGROUND_SAVER	;	 
	;-----------------------------------
	NOTJ:	
		MOV [BP+20], AX ; PUTS THE NEW POSITION IN THE STACK
	POP SI DX AX BX		;
	RET 16
	ENDP RED_MOVES
 
 ;=====================================================================
 
	PROC BLUE_PUNCHES
	PUSH BP
	MOV BP, SP
	PUSH AX CX DX
	;--------------------------------					
		HIT_DISTANCE EQU 90			;	SUBTRACTS THE POS OF THE TWO PLAYERS 		
		MOV 	CX, [BP+4]			;	CHECKS IF THE RESULT IS 90 OR BELOW 
		MOV 	DX, [BP+20]			;	
		SUB		DX, CX				;			
		CMP 	DX, HIT_DISTANCE	;
	;--------------------------------
	JNB DIDNT_HIT					;			
		DEC 	[BP+16]				;	^^^^^ IF IT IS BELOW ==> IT WILL INC THE STAMINA OF SET PLAYER AND DEC THE	
		INC 	[BP+18]				;	HEALTH POINTS OF THE SECOND PLAYER
	DIDNT_HIT:						;			
	;--------------------------------										
		PUSH 	[BP+4]				;
		PUSH 	[BP+14]				;	THIS PART REMOVES THE DEFUALT CHARECHTER
		CALL 	PRINTBLUE			;
	;--------------------------------											;
		PUSH 	[BP+14]				;	THIS MAKES THE PUNCHING ANIMATION
		PUSH 	[BP+12]				;	EVERY PUSH IS A DIFFERENT PICTURE
		PUSH 	[BP+10]				;
		PUSH 	[BP+8]				;
		PUSH 	[BP+6]				;
		PUSH 	[BP+4]				;
		CALL 	PUNCH				;
	;--------------------------------											
		PUSH 	[BP+4]				;
		PUSH 	[BP+14]				; 	SAVES THE BACKGROUND
		CALL 	BACKGROUND_SAVER	;
	;--------------------------------
				
	
	POP DX CX AX BP
	RET 12
	ENDP BLUE_PUNCHES
	
	;======================================================
	
	PROC RED_PUNCHES
	PUSH BP
	MOV BP, SP
	PUSH AX
					
		HIT_DISTANCE EQU 90						
	;-------------------------------
		MOV 	CX, [BP+4]			;
		MOV 	DX, [BP+20]			;	WORKS THE SAME AS THE BLUE PUNCH
		SUB		CX, DX				;
		CMP 	CX, HIT_DISTANCE	;
	;-------------------------------
	JNB DIDNT_HIT1					;
		DEC 	[BP+16]				;	SAME AS BLUE PUNCH
		INC 	[BP+18]				;
	DIDNT_HIT1:						;
	;-------------------------------
		PUSH 	[BP+4]				;
		PUSH 	[BP+14]				; 	REMOVES THE DEFUALT PLAYER
		CALL 	PRINTRED			;
	;-------------------------------											
		PUSH 	[BP+14]				;
		PUSH 	[BP+12]				;
		PUSH 	[BP+10]				;	SAME AS BLUE PUNCH
		PUSH 	[BP+8]				;
		PUSH 	[BP+6]				;
		PUSH 	[BP+4]				;
		CALL 	RED_PUNCH			;
	;-------------------------------
		PUSH 	[BP+4]				;
		PUSH 	[BP+14]				; 	SAVES HE BACKGROUND
		CALL 	RED_BACKGROUND_SAVER;
	;-------------------------------
				
	POP AX BP
	RET 12
	ENDP RED_PUNCHES
	
	;================================================
	
	PROC BLUE_SPECIAL_ATTACKS
	PUSH BP
	MOV BP, SP 
	PUSH AX CX DX	
	CMP 	[BP+30], SPECIAL_STAMINA	
	JNB	HAS_STAMINA 						
	JMP NO_STAMINA1	; TO LOW ON STAMINA 			
	HAS_STAMINA:
	;-------------------------------------										
		PUSH	 [BP+4]				
		PUSH	 [BP+20]		
		CALL	 PRINTBLUE						
	;-------------------------------------											
		PUSH 	[BP+26]					;
		PUSH 	[BP+24]					;
		PUSH 	[BP+22]					;
		PUSH 	[BP+20]					;
		PUSH 	[BP+4]					;	PRINTS THE MOVES OF THE CHARECTER
		CALL 	SPECIALATTACK			;		
										;		
		PUSH 	[BP+4]					;
		PUSH 	[BP+26]					;	PRINTS THE POS OF THE PLAYER FOR THE FIRE BALL
		CALL 	PRINTBLUE				;																				;
	;------------------------------------											
		PUSH 	[BP+18]					;
		PUSH 	[BP+16]					;
		PUSH 	[BP+14]					;
		PUSH 	[BP+12]					;
		PUSH 	[BP+10]					;	PRINTS THE EFECTS (FIRE BALL)
		PUSH 	[BP+8]					;
		PUSH 	[BP+6]					;
		PUSH 	[BP+4]					;
		CALL 	EFFECT					;
	;------------------------------------
		PUSH 	[BP+4]					;
		PUSH 	[BP+20]					;	REMOVES THE PLAYER
		CALL 	PRINTBLUE				;
										;
		PUSH 	[BP+4]					;
		PUSH 	[BP+20]					;	SAVES THE BACKGROUND
		CALL 	BACKGROUND_SAVER        ;
	;------------------------------------							
		MOV 	CX, [BP+4]				;	MOVES THE POSITION OF PLAYER1 TO CX 
		MOV 	DX, [BP+28]				;	MOVES THE POSITION OF PLAYER2 TO DX 
		SUB		DX, CX					;	GETS THE DISTANCE BETWEEN THE PLAYER
										;
		CMP 	DX, 140					;	IF THE DISTANCE IS BELOW 140
	JNB DIDNT_HIT_WITH_BLAST			;
		SUB [BP+32],SPECIAL_DAMAGE 		;	THE HP OF PLAYER2 WILL GET DOWN BY 2
	DIDNT_HIT_WITH_BLAST:				;
		SUB [BP+30], SPECIAL_STAMINA	;	LOWERS THE STAMINA OF THE PLAYER								;										;                              	;
	NO_STAMINA1:						;
	;------------------------------------
	POP DX CX AX BP
	RET 26
	ENDP BLUE_SPECIAL_ATTACKS
	
	;=======================================
	PROC RED_SPECIAL_ATTACKS
	PUSH BP
	MOV BP, SP
	PUSH AX CX DX
	
									;
												;
		CMP 	[BP+28]	, SPECIAL_STAMINA				;
	JNB	RED_HAS_STAMINA 							;
	JMP NO_STAMINA	; TO LOW ON STAMINA 			;
	RED_HAS_STAMINA:								;								;
												;
		PUSH	 [BP+4]				;
		PUSH	 [BP+18]		;
		CALL	 PRINTRED					;
												;
		PUSH 	[BP+24]					;
		PUSH 	[BP+22]				;
		PUSH 	[BP+20]				;
		PUSH 	[BP+18]			;
		PUSH 	[BP+4]				;
		CALL 	RED_SPECIALATTACK					;
												;
		PUSH 	[BP+4]					;
		PUSH 	[BP+24]						;
		CALL 	PRINTRED						;
												;
												;
												;
												;
												;
		PUSH 	[BP+16]				;
		PUSH 	[BP+14]				;
		PUSH 	[BP+12]				;
		PUSH 	[BP+10]				;
		PUSH 	[BP+8]			;
		PUSH 	[BP+6]				;
		PUSH 	[BP+4]					;
		CALL 	RED_EFFECT						;
												;
		PUSH 	[BP+4]				;
		PUSH 	[BP+18]		;
		CALL 	PRINTRED						;
												;
		PUSH 	[BP+4]					;
		PUSH 	[BP+18]			;	
		CALL 	RED_BACKGROUND_SAVER        

		MOV 	CX, [BP+26]				;
		MOV 	DX, [BP+4]				;
		SUB		DX, CX	
		
		CMP 	DX, 140
	JNB DIDNT_HIT_WITH_FIRE
		SUB [BP+30]	,SPECIAL_DAMAGE 
	DIDNT_HIT_WITH_FIRE:
												;
				                                ;
		SUB 	[BP+28], SPECIAL_STAMINA	;	
		NO_STAMINA:
	POP DX CX AX BP
	RET 24
	ENDP RED_SPECIAL_ATTACKS
	
	;==================================
	PROC RED_PARRYS
	PUSH BP
	MOV BP, SP
	PUSH AX
	
	
		PUSH	 [BP+4]
		PUSH 	[BP+6]
		CALL 	PRINTRED
		
		PUSH [BP+12]
		PUSH [BP+10]
		PUSH [BP+8]
		PUSH [BP+6]
		PUSH [BP+4]
		CALL RED_PARRY
		
		CMP 	[BP+14], KEY_S
	JNZ 	DIDNT_ATTACK
		MOV 	AX, [BP+4]
		SUB 	AX,	[BP+16]
		CMP 	AX, HIT_DISTANCE
		JB DIDNT_ATTACK
		INC [BP+18]
	DIDNT_ATTACK:
	
	POP AX BP
	RET 14
	ENDP RED_PARRYS
	
	;====================================
	
		PROC BLUE_PARRYS
	PUSH BP
	MOV BP, SP
	PUSH AX
	
	;---------------------------
		PUSH	 [BP+4]			;
		PUSH 	[BP+6]			;	DELETS THE DEFAULT PLAYER
		CALL 	PRINTBLUE		;
	;---------------------------	
		PUSH [BP+12]			;
		PUSH [BP+10]			;
		PUSH [BP+8]				;	PRINTS THE BLOCKING ANIMATION
		PUSH [BP+6]				;	
		PUSH [BP+4]				;
		CALL BLUE_PARRY			;
	;---------------------------	
		CMP 	[BP+14], KEY_K	; 	CHECKS IF THE OTHER PLAYER ATTACKED BY CHECKING WHAT WAS PRESSED
	JNZ 	DIDNT_ATTACK1		;
		MOV 	AX, [BP+16]		;	CHECKS THE DISTANCE BETWWEN THE PLAYERS 
		SUB 	AX,	[BP+4]		;
		CMP 	AX, HIT_DISTANCE;	IF THE DISTANCE IS IN RANGE OF AN ATTACK IT WILL BLOCK
		JNA DIDNT_ATTACK1		;
		INC [BP+18]				;	
	DIDNT_ATTACK1:				;
	;---------------------------
	POP AX BP
	RET 14
	ENDP BLUE_PARRYS
	
	
;=====================================================================
;   START CODE
;=====================================================================
;
START:
  	MOV AX, @DATA                    ; START ADDRESS OF SEGMENT DATA
	MOV DS, AX
	CALL CHANGE_HANDLER              ; PUT MY OWN KEYBOARD INTERRUPT
	JMP EXIT
;----------------------------------------------------------------------

	PROC MY_PROGRAM   
		MOV AX,0A00H
		MOV ES,AX
		;=============================
		; GRAPHIC MODE
		MOV AX, 13H
		INT 10H
		;============================
		
		
					
	;/////////////////////////////////////////////////////////////////////////////
					;			START OF MENU
	;///////////////////////////////////////////////////////
	CALL MAIN


	;//////////////////////////////////////////////
	;START OF MOVING
	;//////////////////////////////////////////////
		 MOV SI, 0
		
		PUSH	 [BLUE_POSITION]
		PUSH	 OFFSET BLUE_BACKGROUND ;SAVES THE STARTING POSITION OF 
		CALL	 BACKGROUND_SAVER		;PLAYER1
		
		PUSH	 [RED_POSITION]
		PUSH 	OFFSET RED_BACKGROUND	;SAVES THE STARTING POSITION OF 
		CALL 	RED_BACKGROUND_SAVER	;PLAYER2
	MAINLOOP:
	
		PUSH	[RED_POSITION]
		PUSH 	OFFSET WALK1			;PRINTS THE DEFUALT STANS
		CALL	 PRINTRED 
		
		PUSH	 [BLUE_POSITION]
		PUSH	 OFFSET WALK1			;PRINTS THE DEFUALT STANS
		CALL	 PRINTBLUE	
	;--------------------------------
	PUSH AX
		MOV	 	AX, [BLUE_LAST_HP]	;
		CMP 	AX, [BLUE_HP]		;		CMPS THE CURRENT HP TO THE LAST TIME HE WAS HIT
	POP AX
	JE DIDNT_GET_HIT				;		IF THE HP IS LOWER VVVVV
		PUSH [BLUE_HP]				;
		PUSH [BLUE_STARTING_HP]		;		IF THE HP IS LOWERED BY TWO IT WILL REDUCE ONE HEART
		PUSH HP_BAR_POS_PLAYER1		;
		PUSH OFFSET HEART			;
		CALL LOWER_HP_BAR			;
		POP [BLUE_LAST_HP]			;
	DIDNT_GET_HIT:					;		IF IT NOT LOWER IT WILL JUMP HERE
	;--------------------------------	
	;--------------------------------
	PUSH AX
		MOV	 	AX, [RED_LAST_HP]	;
		CMP 	AX, [RED_HP]		;		CMPS THE CURRENT HP TO THE LAST TIME HE WAS HIT
	POP AX
	JE DIDNT_GET_HIT1				;		IF THE HP IS LOWER VVVVV
		PUSH [RED_HP]				;
		PUSH [RED_STARTING_HP]		;		IF THE HP IS LOWERED BY TWO IT WILL REDUCE ONE HEART
		PUSH HP_BAR_POS_PLAYER2		;
		PUSH OFFSET HEART			;
		CALL LOWER_HP_BAR			;
		POP [RED_LAST_HP]			;
	DIDNT_GET_HIT1:					;		IF IT NOT LOWER IT WILL JUMP HERE
	;--------------------------------
		
		
	;------------------------	
			
		CMP	 	[BYTE PTR CS:ESC_KEY], 0       ; IF CLICKED ?
		JZ 		TORET1     	; YES ---> END THE PROGRAM
		JMP	 	TORET
	TORET1:

			
		
		MOV     AL, [CS:MINI_BUFF + SI]  ;IF ANY KEY IS PRESSED AL IS 0
		CMP	 	AL, BUTTON_PRESSED
		JZ 		PRESSED
		JMP 	NOTPRESSED
	PRESSED:
	;------------------------------------	
		PUSH 	[BLUE_POSITION]			;
		PUSH 	[RED_POSITION]			;
		PUSH 	SI 						;		MOVES PLATER1 IF "D" OR "A" WAS PRESSED
		PUSH 	OFFSET BLUE_BACKGROUND	;
		PUSH 	OFFSET WALK2			;		A WILL MOVE THE CHARCTER TO THE LEFT
		PUSH 	OFFSET WALK3			;		D WILL MOVE
		PUSH 	OFFSET WALK4			;
		PUSH 	OFFSET WALK5			;
		PUSH 	OFFSET WALK6			;		
		CALL BLUE_MOVES					;
		POP	[BLUE_POSITION]				;
	;------------------------------------
	;------------------------------------
		PUSH	 [RED_POSITION]			;
		PUSH	 [BLUE_POSITION]		;
		PUSH 	 SI						;		MOVES PLAYER2 IF "D" OR "A" WAS PRESSED
		PUSH	 OFFSET RED_BACKGROUND	;
		PUSH	 OFFSET WALK2			;
		PUSH	 OFFSET WALK3			;
		PUSH	 OFFSET WALK4			;
		PUSH	 OFFSET WALK5			;
		PUSH	 OFFSET WALK6			;
		CALL RED_MOVES					;
		POP [RED_POSITION]				;
	;------------------------------------
	;------------------------------------
		;////////////////////////////////
			;END OF MOVING
		;//////////////////////// ///////	
	;------------------------------------
		KEY_S EQU 0						;
		CMP	 	SI, KEY_S				;		CHECKS IF "S" WAS PRESSED 
	JNZ 	ATTACK						;
		PUSH 	[RED_POSITION]			;
		PUSH 	[BLUE_STAMINA]			;
		PUSH	[RED_HP] 				;		IF IT WAS PRESSED PLAYER1 WILL PUNCH
		PUSH 	OFFSET BLUE_BACKGROUND	;
		PUSH 	OFFSET PUNCH1			;
		PUSH 	OFFSET PUNCH2			;
		PUSH 	OFFSET PUNCH3			;
		PUSH 	OFFSET PUNCH4			;
		PUSH 	[BLUE_POSITION]			;
		CALL 	BLUE_PUNCHES			;
		POP 	[RED_HP]				;
		POP 	[BLUE_STAMINA]			;
		POP 	[RED_POSITION]			;
	ATTACK:								;
	;------------------------------------

	;------------------------------------
		KEY_K EQU 5						;
		CMP	 	SI, KEY_K				;		CHECKS IF "S" WAS PRESSED 
	JNZ 	ATTACK1						;
		PUSH 	[BLUE_POSITION]			;
		PUSH 	[RED_STAMINA]			;
		PUSH	[BLUE_HP] 				;		IF IT WAS PRESSED PLAYER1 WILL PUNCH
		PUSH 	OFFSET RED_BACKGROUND	;
		PUSH 	OFFSET PUNCH1			;
		PUSH 	OFFSET PUNCH2			;
		PUSH 	OFFSET PUNCH3			;
		PUSH 	OFFSET PUNCH4			;
		PUSH 	[RED_POSITION]			;
		CALL 	RED_PUNCHES				;
		POP 	[BLUE_HP]				;
		POP 	[RED_STAMINA]			;
		POP 	[BLUE_POSITION]			;
	ATTACK1:
	;--------------------------------

	;------------------------------------	
	;///////////////////////	
	; ULTIMATE	
	;///////////////////////
	;------------------------------------
	KEY_W EQU 2							;
		CMP 	SI, KEY_W				;		CHECKS IF "I" WAS PRESSED
	JZ 	IS_W							;
	JMP NOT_W							;
	IS_W:								;
		PUSH 	[RED_HP]				;
		PUSH 	[BLUE_STAMINA]			;
		PUSH 	[RED_POSITION]			;
		PUSH 	OFFSET SPECIAL3			;
		PUSH 	OFFSET SPECIAL2			;
		PUSH 	OFFSET SPECIAL1			;
		PUSH 	OFFSET BLUE_BACKGROUND	;		IF IT WAS PRESSED PLAYER2 WILL DO A SPECIAL ATTACK
		PUSH 	OFFSET EFFECT6			;		THE PLAYER HAS TO HAVE ENOUGH STAMINA
		PUSH 	OFFSET EFFECT5			;
		PUSH 	OFFSET EFFECT4			;
		PUSH 	OFFSET EFFECT3			;
		PUSH 	OFFSET EFFECT2			;
		PUSH 	OFFSET EFFECT1			;
		PUSH 	OFFSET EFFECTCLR		;
		PUSH 	[BLUE_POSITION]			;
		CALL 	BLUE_SPECIAL_ATTACKS	;
		POP		[BLUE_STAMINA]			;
		POP		[RED_HP]				;		
	NOT_W:
	;------------------------------------
	
	;------------------------------------
		KEY_I EQU 4						;
		CMP 	SI, KEY_I				;		CHECKS IF "I" WAS PRESSED				
	JNZ 	NOTI						;
		PUSH 	[BLUE_HP]				;
		PUSH 	[RED_STAMINA]			;
		PUSH 	[BLUE_POSITION]			;
		PUSH 	OFFSET SPECIAL3			;
		PUSH 	OFFSET SPECIAL2			;
		PUSH 	OFFSET SPECIAL1			;
		PUSH 	OFFSET RED_BACKGROUND	;		IF IT WAS PRESSED PLAYER2 WILL DO A SPECIAL ATTACK
		PUSH 	OFFSET RED_SPECIAL5		;		THE PLAYER HAS TO HAVE ENOUGH STAMINA
		PUSH 	OFFSET RED_SPECIAL4		;
		PUSH 	OFFSET RED_SPECIAL3		;
		PUSH 	OFFSET RED_SPECIAL2		;
		PUSH 	OFFSET RED_SPECIAL1		;
		PUSH 	OFFSET REDEFFECTCLR		;
		PUSH 	[RED_POSITION]			;
		CALL 	RED_SPECIAL_ATTACKS		;
		POP 	[RED_STAMINA]			;
		POP		[BLUE_HP]				;
	NOTI:								;
	;------------------------------------

	;------------------------------------
		LEFT_SHIFT EQU 8				;
		CMP 	SI, LEFT_SHIFT			; 		CHECKS IF "LEFT_SHIFT WAS PRESSED
	JNZ 	LEFT_NOT_PRESSED			;
		PUSH [BLUE_HP]					;
		PUSH [RED_POSITION]				;
		PUSH [LAST_KEY_PRESSED]			;		PLAYER1 WILL BLOCK THE ATTACK IF HE IS IN RAGE 
		PUSH OFFSET BLOCK3				;		AND RIGHT AFTER THE ATTACK
		PUSH OFFSET	BLOCK2				;
		PUSH OFFSET BLOCK1				;
		PUSH OFFSET BLUE_BACKGROUND		;
		PUSH [BLUE_POSITION]			;
		CALL BLUE_PARRYS				;
		POP [BLUE_HP]					;
	LEFT_NOT_PRESSED:					;
	;------------------------------------
	;------------------------------------
		RIGHT_SHIFT EQU 7				;
		CMP 	SI, RIGHT_SHIFT			; 		CHECKS IF "RIGHT_SHIFT WAS PRESSED
	JNZ 	RIGHT_NOT_PRESSED			;
		PUSH [RED_HP]					;
		PUSH [BLUE_POSITION]			;
		PUSH [LAST_KEY_PRESSED]			;		PLAYER1 WILL BLOCK THE ATTACK IF HE IS IN RAGE 
		PUSH OFFSET BLOCK3				;		AND RIGHT AFTER THE ATTACK
		PUSH OFFSET	BLOCK2				;
		PUSH OFFSET BLOCK1				;
		PUSH OFFSET RED_BACKGROUND		;
		PUSH [RED_POSITION]				;
		CALL RED_PARRYS					;
		POP [RED_HP]					;
	RIGHT_NOT_PRESSED:					;
	;------------------------------------
		MOV 	[LAST_KEY_PRESSED], SI
	NOTPRESSED:
		INC		SI
		CMP 	SI,10
	JNZ 	ON_BUTTONS
		MOV 	SI,0
	ON_BUTTONS:
		CMP		[BLUE_HP], 0
	JZ BLUE_IS_DEAD
		CMP 	[RED_HP], 0
	JZ RED_IS_DEAD
	;------------------------------	
	JMP 	MAINLOOP
		; BACK TO TEXT MODE
		
	TORET:
	JMP END_GAME
	
	BLUE_IS_DEAD:
	MOV CX, OFFSET FILENAME4
	PUSH [FILEHANDLE]
	PUSH CX
	CALL OPENFILE
	POP CX	
	POP [FILEHANDLE]			
	CALL READHEADER				;this code shows the blue wins picture
	MOV CX, OFFSET PALETTE
	PUSH CX
	CALL READPALETTE
	CALL COPYPAL
	POP CX
	MOV CX, OFFSET SCRLINE
	PUSH CX
	CALL COPYBITMAP
	POP CX
	MOV AX,1H
	INT 33H
	MOV BX ,00H
	MOUSELP_DEAD:
	MOV AX,3H
	INT 33H
	CMP BX, 01H ;LEFT CLICK
	JNZ MOUSELP_DEAD
	SHR CX,1			
	MOV AX,2
	INT 33H
	JMP END_GAME
	
	RED_IS_DEAD:
	MOV CX, OFFSET FILENAME3
	PUSH [FILEHANDLE]
	PUSH CX
	CALL OPENFILE
	POP CX	
	POP [FILEHANDLE]			
	CALL READHEADER				
	MOV CX, OFFSET PALETTE
	PUSH CX
	CALL READPALETTE
	CALL COPYPAL
	POP CX
	MOV CX, OFFSET SCRLINE			; if red wins it shows the red wins picture
	PUSH CX
	CALL COPYBITMAP
	POP CX
	MOV AX,1H
	INT 33H
	MOV BX ,00H
	MOUSELP_RDEAD:
	MOV AX,3H
	INT 33H
	CMP BX, 01H ;LEFT CLICK
	JNZ MOUSELP_RDEAD	
	SHR CX,1			
	MOV AX,2
	INT 33H
	
	
	END_GAME:
	MOV	 	AH, 0
	MOV 	AL, 3
	INT 	10H
		RET
		
	ENDP MY_PROGRAM
;==============================================================


EXIT:	
	MOV AX, 4C00H
	INT 21H
END START


						; _..GGGGGPPPPP.._                       
                  ; _.GD$$$$$$$$$$$$$$$$$$BP._                  
               ; .G$$$$$$P^^""J$$B""""^^T$$$$$$P.               
            ; .G$$$P^T$$B    D$P T;       ""^^T$$$P.            
          ; .D$$P^"  :$; `  :$;                "^T$$B.          
        ; .D$$P'      T$B.   T$B                  `T$$B.        
       ; D$$P'      .GG$$$$BPD$$$P.D$BPP.           `T$$B       
      ; D$$P      .D$$$$$$$$$$$$$$$$$$$$BP.           T$$B      
     ; D$$P      D$$$$$$$$$$$$$$$$$$$$$$$$$B.          T$$B     
    ; D$$P      D$$$$$$$$$$$$$$$$$$P^^T$$$$P            T$$B    
   ; D$$P    '-'T$$$$$$$$$$$$$$$$$$BGGPD$$$$B.           T$$B   
  ; :$$$      .D$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$P._.G.     $$$;  
  ; $$$;     D$$$$$$$$$$$$$$$$$$$$$$$P^"^T$$$$P^^T$$$;    :$$$  
 ; :$$$     :$$$$$$$$$$$$$$:$$$$$$$$$_    "^T$BPD$$$$,     $$$; 
 ; $$$;     :$$$$$$$$$$$$$$BT$$$$$P^^T$P.    `T$$$$$$;     :$$$ 
; :$$$      :$$$$$$$$$$$$$$P `^^^'    "^T$P.    LB`TP       $$$;
; :$$$      $$$$$$$$$$$$$$$              `T$$P._;$B         $$$;
; $$$;      $$$$$$$$$$$$$$;                `T$$$$:TB        :$$$
; $$$;      $$$$$$$$$$$$$$$                        TB    _  :$$$
; :$$$     D$$$$$$$$$$$$$$$.                        $B.__TB $$$;
; :$$$  .G$$$$$$$$$$$$$$$$$$$P...______...GP._      :$`^^^' $$$;
 ; $$$;  `^^'T$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$P.    TB._, :$$$ 
 ; :$$$       T$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B.   "^"  $$$; 
  ; $$$;       `$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B      :$$$  
  ; :$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$;     $$$;  
   ; T$$B    _  :$$`$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$;   D$$P   
    ; T$$B   T$G$$; :$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$  D$$P    
     ; T$$B   `^^'  :$$ "^T$$$$$$$$$$$$$$$$$$$$$$$$$$$ D$$P     
      ; T$$B        $P     T$$$$$$$$$$$$$$$$$$$$$$$$$;D$$P      
       ; T$$B.      '       $$$$$$$$$$$$$$$$$$$$$$$$$$$$P       
        ; `T$$$P.   BUG    D$$$$$$$$$$$$$$$$$$$$$$$$$$P'        
          ; `T$$$$P..__..G$$$$$$$$$$$$$$$$$$$$$$$$$$P'          
            ; "^$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$^"            
               ; "^T$$$$$$$$$$$$$$$$$$$$$$$$$$P^"               
                   ; """^^^T$$$$$$$$$$P^^^"""



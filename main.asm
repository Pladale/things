
.include "m2560def.inc"

.def temp = r16
.def temp1 = r18 
.def temp2 = r19
.def counter = r17
.def lcd = r20				; lcd handle
.def digit = r21			; used to display decimal numbers digit by digit
.def digitCount = r22		; how many digits do we have to display?
.def row = r23 ; current row number
.def col = r24 ; current column number
.def rmask = r25 ; mask for current row during scan
.def cmask = r26 ; mask for current column during scan


.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro clear
    ldi YL, low(@0)     ; load the memory address to Y
    ldi YH, high(@0)
    clr temp 
    st Y+, temp         ; clear the two bytes at @0 in SRAM
    st Y, temp
.endmacro
 
                        
.dseg
Timer1Counter:
   .byte 2              ; Temporary counter. Used to determine 
                        ; if one second has passed
.cseg
.org 0
	jmp RESET
	jmp DEFAULT
	jmp DEFAULT
.org OVF0addr
	jmp Timer0OVF
	jmp DEFAULT

DEFAULT: reti

RESET:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16
	
	sei

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '7'
	do_lcd_data 's'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'E'
	do_lcd_data '8'
	do_lcd_command 0b11000000
	do_lcd_data 'V'
	do_lcd_data 'e'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'M'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'h'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'e'

halt:
	rjmp halt

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
	nop
	nop
	nop
.endmacro
.macro lcd_clr
	cbi PORTA, @0
	nop
	nop
	nop
.endmacro


Timer0OVF: ; interrupt subroutine to Timer0
    in temp, SREG
    push temp       ; Prologue starts.
    push YH         ; Save all conflict registers in the prologue.
    push YL
    push r25
    push r24
	        ; Prologue ends.
                    ; Load the value of the temporary counter.

	newSecond:
	    lds r24, Timer1Counter
    	lds r25, Timer1Counter+1
    	adiw r25:r24, 1 ; Increase the temporary counter by one.

    	cpi r24, low(23436)      ; 23436 is what we need Check if (r25:r24) = 7812 ; 7812 = 10^6/128
    	ldi temp, high(23436)    ; 3 second
    	cpc r25, temp
    	brne NotSecond
		
		secondPassed: ; 3 second passed
			do_lcd_command 0b00000001 ; clear display
			do_lcd_command 0b00000110 ; increment, no display shift
			do_lcd_command 0b00001110 ; Cursor on, bar, no blink

			do_lcd_data 'S'
			do_lcd_data 'e'
			do_lcd_data 'l'
			do_lcd_data 'e'
			do_lcd_data 'c'
			do_lcd_data 't'
			do_lcd_data ' '
			do_lcd_data 'i'
			do_lcd_data 't'
			do_lcd_data 'e'
			do_lcd_data 'm'
			do_lcd_command 0b11000000

			do_lcd_digits counter
			clr counter
			clear Timer1Counter

    rjmp EndIF

NotSecond: ; Store the new value of the temporary counter.
    sts Timer1Counter, r24
    sts Timer1Counter+1, r25 

    
EndIF:
	;pop counter
	pop r24         ; Epilogue starts;
    pop r25         ; Restore all conflict registers from the stack.
    pop YL
    pop YH
    pop temp
    out SREG, temp
    reti            ; Return from the interrupt.

main:
    clear Timer1Counter       ; Initialize the temporary counter to 0
	
	ldi temp, (2 << ISC20)      ; set INT2 as falling-
    sts EICRA, temp             ; edge triggered interrupt
    in temp, EIMSK              ; enable INT2
    ori temp, (1<<INT2)
    out EIMSK, temp

	; Timer0 initilaisation

    ldi temp, 0b00000000
    out TCCR0A, temp
    ldi temp, 0b00000010
    out TCCR0B, temp        ; Prescaling value=8
    ldi temp, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp        ; T/C0 interrupt enable

    sei                     ; Enable global interrupt
                            ; loop forever
    loop: rjmp loop

; function: displaying given number by digit in ASCII using stack
convert_digits:
	push digit
	
	checkHundreds:
		cpi temp, 100			; is the number still > 100?
		brsh hundredsDigit		; if YES - increase hundreds digit
		cpi digit, 0			
		brne pushHundredsDigit	; If digit ! 0 => this digit goes into stack
		
	checkTensInit:
		clr digit
	checkTens:
		ldi temp1, 10
		cp temp, temp1			; is the number still > 10? 
		brsh tensDigit			; if YES - increase tens digit
		cpi digitCount, 1		; were there hundred digits?
		breq pushTensDigit		; if YES i.e. digitCount==1 -> push the tens digit even if 0
								; otherwise: no hundreds are present
		cpi digit, 0			; is tens digit = 0?
		brne pushTensDigit		; if digit != 0 push it to the stack			 

	saveOnes:
		clr digit				; ones are always saved in stack
		mov digit, temp			; whatever is left in temp is the ones digit
		push digit				
		inc digitCount
	; now all digit temp data is in the stack
	; unload data into temp2, temp1, temp
	; and the do_lcd_rdata in reverse order
	; this will display the currentNumber value to LCD
	; it's not an elegant solution but will do for now
	cpi digitCount, 3
	breq dispThreeDigits
	cpi digitCount, 2
	breq dispTwoDigits
	cpi digitCount, 1
	breq dispOneDigit

	endDisplayDigits:
	
	pop digit
	ret

; hundreds digit
hundredsDigit:
	inc digit				; if YES increase the digit count
	subi temp, 100			; and subtract a 100 from the number
	rjmp checkHundreds		; check hundreds again

; tens digit
tensDigit:
	inc digit				; if YES increase the digit count
	subi temp, 10			; and subtract a 10 from the number
	rjmp checkTens			; check tens again

pushHundredsDigit:
	push digit
	inc digitCount
	rjmp checkTensInit

pushTensDigit:
	push digit
	inc digitCount
	rjmp saveOnes

dispThreeDigits:
	pop temp2
	pop temp1
	pop temp
	do_lcd_rdata temp
	do_lcd_rdata temp1
	do_lcd_rdata temp2
	rjmp endDisplayDigits

dispTwoDigits:
	pop temp2
	pop temp1
	do_lcd_rdata temp1
	do_lcd_rdata temp2
	rjmp endDisplayDigits

dispOneDigit:
	pop temp
	do_lcd_rdata temp
	rjmp endDisplayDigits

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	lcd_set LCD_E
	lcd_clr LCD_E
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	lcd_set LCD_E
	lcd_clr LCD_E
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	
	lcd_set LCD_E
	
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

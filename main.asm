; Timer0 interrupt
.include "m2560def.inc"
.include "header.asm"
.include "lcd.asm"

; The macro clears a word (2 bytes) in a memory
; the parameter @0 is the memory address for that word
.macro clear
    ldi YL, low(@0)     ; load the memory address to Y
    ldi YH, high(@0)
    clr temp1 
    st Y+, temp1         ; clear the two bytes at @0 in SRAM
    st Y, temp1
.endmacro

RESET: 
    ldi temp1, high(RAMEND) ; Initialize stack pointer
    out SPH, temp1
    ldi temp1, low(RAMEND)
    out SPL, temp1
	
	;initialize the Inventory
	ldi temp1, 1
	sts OneInventory, temp1
	ldi temp1, 2
	sts TwoInventory, temp1
	ldi temp1, 3
	sts ThreeInventory, temp1
	ldi temp1, 4
	sts FourInventory, temp1
	ldi temp1, 5	
	sts FiveInventory, temp1
	ldi temp1, 6
	sts SixInventory, temp1
	ldi temp1, 7
	sts SevenInventory, temp1
	ldi temp1, 8
	sts EightInventory, temp1
	ldi temp1, 9
 	sts NineInventory, temp1
	
	ldi temp1,(3 << REFS0) | (0 << ADLAR) | (0 << MUX0);
	sts ADMUX, temp1
	ldi temp1,(1 << MUX5);
	sts ADCSRB, temp1
	ldi temp1, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0);
	sts ADCSRA, temp1

	sei

	ldi temp1, PORTLDIR ; PL7:4/PL3:0, out/in
	sts DDRL, temp1
	ser temp1 ; PORTC is output
	out DDRC, temp1

	; LCD setup
	ser temp1
	out DDRF, temp1
	out DDRA, temp1
	clr temp1
	out PORTF, temp1
	out PORTA, temp1

	ldi temp1, 0b00000000
    out TCCR0A, temp1
    ldi temp1, 0b00000010
    out TCCR0B, temp1        ; Prescaling value=8
    ldi temp1, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp1        ; T/C0 interrupt enable

    sei  
	ldi flags,0 
	rcall setUpLcd
	rcall firstScreen

	potentio:
	lds temp1, ADCL
	lds temp2, ADCH
	out PORTC, temp1
	rjmp main


EXT_INT2:
	in temp1, SREG
	push temp1
	push temp2

	;inc counter
	
	;do_lcd_command 0b00000001 ; clear display
	;do_lcd_command 0b00000110 ; increment, no display shift
	;do_lcd_command 0b00001110 ; Cursor on, bar, no blink

END_INT2:
	pop temp2
	pop temp1
	out SREG, temp1
	reti


	;ADCH:ADCL

Timer0OVF: ; interrupt subroutine to Timer0
    in temp1, SREG
    push temp1       ; Prologue starts.
    push YH         ; Save all conflict registers in the prologue.
    push YL
    push r25
    push r24
;	push counter
	        ; Prologue ends.
                    ; Load the value of the temporary counter.

	newSecond:
	    lds r24, Timer1Counter
    	lds r25, Timer1Counter+1
    	adiw r25:r24, 1 ; Increase the temporary counter by one.

    	cpi r24, low(7812*3) ;not 3 sec yet     ; 1953 is what we need Check if (r25:r24) = 7812 ; 7812 = 10^6/128
    	ldi temp1, high(7812*3)  ;not 3 sec yet  ; 7812 = 10^6/128
    	cpc r25, temp1
    	brne NotSecond
		
		secondPassed: ; 1/4 of a second passed
			mov temp1, flags
			andi temp1, 0b00000100
			cpi temp1, 0b00000100
			brne secondScreenShowOnce


		;	out PORTC, counter

;			do_lcd_digits counter
		;	clr counter
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
    pop temp1
    out SREG, temp1
    reti            ; Return from the interrupt.
secondScreenShowOnce:
	ori flags, 0b00000101
	rcall SecondScreen
	rjmp EndIF
main:
    clear Timer1Counter       ; Initialize the temporary counter to 0
	;clear Timer3Counter
	ldi r26, 0
	sts VoltageFlag, r26	
	
	ldi temp1, (2 << ISC20)      ; set INT0 as falling-
    sts EICRA, temp1             ; edge triggered interrupt
    in temp1, EIMSK              ; enable INT2
    ori temp1, (1<<INT2)
    out EIMSK, temp1
	
keypad:

	ldi cmask, INITCOLMASK ; initial column mask
	clr col ; initial column
	clr row
	clr temp1 
	clr temp2

colloop:
	cpi col, 4
	breq keypad ; If all keys are scanned, repeat.
	sts PORTL, cmask ; Otherwise, scan a column.
	ldi temp1, 0xFF ; Slow down the scan operation.
delay:
	dec temp1
	brne delay
	lds temp1, PINL ; Read PORTL
	andi temp1, ROWMASK ; Get the keypad output value
	cpi temp1, 0xF ; Check if any row is low
	breq nextcol ; If yes, find which row is low
	ldi rmask, INITROWMASK ; Initialize for row check
	clr row
rowloop:
	cpi row, 4
	breq nextcol ; the row scan is over.
	mov temp2, temp1
	and temp2, rmask ; check un - masked bit
	breq convert ; if bit is clear, the key is pressed
	inc row ; else move to the next row
	lsl rmask
	jmp rowloop
nextcol:
	lsl cmask  ;1110 to 1100
;	inc cmask	;1101
	inc col ; increase column value
	jmp colloop ; go to the next column
convert:
	cpi digits,1
	breq keypad
	cpi col, 3 ; If the pressed key is in col.3
	;breq letters ; we have a letter
	; If the key is not in col.3 and
	cpi row, 3 ; If the key is in row3,
	;breq symbols ; we have a symbol or 0
	mov temp1, row ; Otherwise we have a number in 1 - 9
	lsl temp1
	add temp1, row
	add temp1, col ; temp1 = row*3 + col
	subi temp1, -1
	jmp convert_end

convert_end:
	;out PORTC, temp1 ; Write value to PORTC
	;out PORTC, flags
	andi temp1,0b00000001
	cpi temp1,0b00000001
	brne print_evenNumber
	out PORTC, temp1
	;do_lcd_rdata temp1
convert_end_end:
	mov temp2, flags
	andi temp2, 0b00000100
	cpi temp2, 0b00000100
	brne showSecondScreen
	

	mov temp2, flags
	andi temp2, 0b00000010
	cpi temp2, 0b00000010
	brne showCoinScreen
	
	ldi digits, 1
	rcall sleep_50ms
	rcall sleep_50ms
	rcall sleep_50ms
	rcall sleep_50ms
	rcall sleep_50ms
	ldi digits, 0
	
	jmp keypad

    loop: rjmp loop
print_evenNumber:
	ldi temp1,2 
	out PORTC, temp1
	rjmp convert_end_end
showSecondScreen:
	rcall SecondScreen
	ori flags,0b00000100   ; flag for keypad
	rcall sleep_50ms
	rcall sleep_50ms
	rcall sleep_50ms
	rcall sleep_50ms
	jmp keypad

showCoinScreen:
	rcall coinScreen
	ori flags,0b00000010
	jmp keypad
	
AfterDelivery:
	cpi temp1, 1
	breq One
	cpi temp1, 2
	breq Two
	cpi temp1, 3
	breq Three
	cpi temp1, 4
	breq Four
	cpi temp1, 5
	breq Five
	cpi temp1, 6
	breq Six
	cpi temp1, 7
	breq Seven
	cpi temp1, 8
	breq Eight
	cpi temp1, 9
	breq Nine
One:
	lds temp1, OneInventory
	dec temp1
	sts OneInventory, temp1
	jmp main
Two:
	lds temp1, TwoInventory
	dec temp1
	sts TwoInventory, temp1
	jmp main
Three:
	lds temp1, ThreeInventory
	dec temp1
	sts ThreeInventory, temp1
	jmp main
Four:
	lds temp1, FourInventory
	dec temp1
	sts FourInventory, temp1
	jmp main
Five:
	lds temp1, FourInventory
	dec temp1
	sts FourInventory, temp1
	jmp main
Six:
	lds temp1, SixInventory
	dec temp1
	sts SixInventory, temp1
	jmp main
Seven:
	lds temp1, SevenInventory
	dec temp1
	sts SevenInventory, temp1
	jmp main
Eight:
	lds temp1, EightInventory
	dec temp1
	sts EightInventory, temp1
	jmp main
Nine:
	lds temp1, NineInventory
	dec temp1
	sts NineInventory, temp1
	jmp main
	
;
; Send a command to the LCD (lcd register)
;


lcd_command:
	out PORTF, lcd
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, lcd
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push lcd
	clr lcd
	out DDRF, lcd
	out PORTF, lcd
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in lcd, PINF
	lcd_clr LCD_E
	sbrc lcd, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser lcd
	out DDRF, lcd
	pop lcd
	ret

;lcd

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro
.macro do_lcd_command
	ldi lcd, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi lcd, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_rdata
	mov lcd, @0
	subi lcd, -'0'
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_digits
	clr digit
	clr digitCount
	mov temp, @0			; temp is given number
;	rcall convert_digits	; call a function
.endmacro

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
sleep_50ms:
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret

setUpLcd:
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	ret

firstScreen:
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
	ret

secondScreen:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	do_lcd_data 'S';
	do_lcd_data 'e';
	do_lcd_data 'l';
	do_lcd_data 'e';
	do_lcd_data 'c';
	do_lcd_data 't';
	do_lcd_data ' ';
	do_lcd_data 'i';
	do_lcd_data 't';
	do_lcd_data 'e';
	do_lcd_data 'm';
	do_lcd_data ':';
	do_lcd_command 0b11000000
	ret

coinScreen:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	do_lcd_data 'I';
	do_lcd_data 'n';
	do_lcd_data 's';
	do_lcd_data 'e';
	do_lcd_data 'r';
	do_lcd_data 't';
	do_lcd_data ' ';
	do_lcd_data 'c';
	do_lcd_data 'o';
	do_lcd_data 'i';
	do_lcd_data 'n';
	do_lcd_data 's';
	do_lcd_command 0b11000000
	ret
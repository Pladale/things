;header
.def row = r16 ; current row number
.def col = r17 ; current column number
.def rmask = r18 ; mask for current row during scan
.def cmask = r19 ; mask for current column during scan
.def temp1 = r20
.def temp2 = r21
.def lcd = r22
.def flags = r23
.def digits = r24

.equ PORTLDIR = 0xF0 ; PD7-4: output, PD3-0, input
.equ INITCOLMASK = 0xEF ; scan from the rightmost column,
.equ INITROWMASK = 0x01 ; scan from the top row
.equ ROWMASK = 0x0F ; for obtaining input from Port D

.dseg
Timer1Counter:
   .byte 2              ; Temporary counter. Used to determine 
                        ; if one second has passed
DebounceCounter:
    .byte 2
VoltageFlag:
	.byte 1
OneInventory:
	.byte 1
TwoInventory:
	.byte 1
ThreeInventory:
	.byte 1
FourInventory:
	.byte 1
FiveInventory:
	.byte 1
SixInventory:
	.byte 1
SevenInventory:
	.byte 1
EightInventory:
	.byte 1
NineInventory:
	.byte 1

.cseg
.org 0x0000
   jmp RESET
   jmp DEFAULT          ; No handling for IRQ0.
   jmp DEFAULT          ; No handling for IRQ1.
.org INT2addr
    jmp EXT_INT2
.org OVF0addr
   jmp Timer0OVF        ; Jump to the interrupt handler for
;.org OVF3addr
;   jmp Timer3OVF        ; Jump to the interrupt handler for
jmp DEFAULT          ; default service for all other interrupts.
DEFAULT:  reti          ; no service

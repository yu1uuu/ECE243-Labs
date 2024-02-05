
.text

.global _start
_start:
	.equ LED, 0xFF200000 
	.equ KEY, 0xFF200050 
	.equ MAX_VAL, 255 
		
	movia r8, LED 
	movia r9, KEY 
	movi r10, MAX_VAL 
	
TURN_OFF_COUNTER:

		ldwio r11, 12(r9) # edge capture register is located 12 bytes from the start of the KEY register block
		
		beq r11, r0, TURN_OFF_COUNTER # no key is pressed
		
		stwio r11, 12(r9) # store a 1 to reset edge capture register
		
		br TURN_ON_COUNTER 
			
TURN_ON_COUNTER:

		call DELAY_LOOP

		ldwio r13, (r8) # stores state of LEDs in r13

		beq r13, r10, RESET_COUNTER # reset counter if it reached 255

		addi r13, r13, 1 # else add 1 to counter

		stwio r13, (r8) # store new counter value into LEDs
		
		br KEY_PRESSED 

RESET_COUNTER:

		stwio r0, (r8) # store 0 into LEDs

		br KEY_PRESSED # check if a key was pressed

KEY_PRESSED:
	
		ldwio r11, 12(r9) # store the edge state of keys in r11
		
		beq r11, r0, TURN_ON_COUNTER # no key is pressed
		
		stwio r11, 12(r9) # store 1 into the key that turned on to reset it
		
		br TURN_OFF_COUNTER 



DELAY_LOOP:
	
	movia r4, DELAY_VALUE # loads the address of the counter delay into r4
	
	ldw r3, 0(r4) # loads the value of the counter delay into r3
	
	SUB_LOOP:
		
		subi r3, r3, 1
		
		bne r3, r0, SUB_LOOP
	
	ret



.data

DELAY_VALUE: .word 3125000  /*change to 10,000,000 when running on the FPGA*/
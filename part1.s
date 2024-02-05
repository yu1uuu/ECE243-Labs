.text

.global _start
_start:

	.equ LED, 0xFF200000
	.equ KEY, 0xFF200050 
	.equ MAX_VAL, 15          
	.equ MIN_VAL, 1          
		
	movia r8, LED 
	movia r9, KEY 
	movi r16, MIN_VAL
	movi r15, MAX_VAL 
	
	/*
	NOTE:		r10: the state of the LEDs
			r11: state of the keys
			r12: a value to help find the value of the key that was pressed
			r14: the current state of the LEDs
	*/
	
		
	POLL:
		ldwio r11, 0(r9) # read the current state of the key into r11
		
		beq r11, r0, POLL # branches back to poll if button is not pushed
		
		ldwio r7, 0(r9) # read the current state of the key into r7
	
	KEY_PRESSED:
		ldwio r11, 0(r9) # read the current state of the key into r11
		
		bne r11, r0, KEY_PRESSED # if the current state of the key is not 0, go back to KEY_PRESSED
		
		movi r12, 1 # load 1 into r12
		
		beq r7, r12, handle_KEY0 # if the key is pressed, go to handle_KEY0
		
		slli r12, r12, 1 # shift to check for key1
		
		beq r7, r12, handle_KEY1 # if the key is pressed, go to handle_KEY1
		
		slli r12, r12, 2 # shift to check for key2
		
		beq r7, r12, handle_KEY2 # if the key is pressed, go to handle_KEY2
		
		slli r12, r12, 2 # shift to check for key3
		
		beq r7, r12, handle_KEY3 # if the key is pressed, go to handle_KEY3
	
	handle_KEY0:

		stwio r16, 0(r8) # set LED display to 1
		
		br POLL # branch back to POLL
			
	handle_KEY1:		
		ldwio r13, 0(r8) # stores the current state of LEDs in r13
		
		beq r13, r0, handle_KEY0 # if all LEDs are off, branch back to handle_KEY0
		
		beq r13, r15, POLL # if the value is already max, cant increment it anyware
		
		addi r13, r14, 1 # else increment LED by 1
		
		stwio r13, 0(r8) # update the LEDs
		
		br POLL # branch back to POLL
			
	handle_KEY2:
		ldwio r13, 0(r8) # stores the current state of LEDs in r13
		
		beq r13, r0, handle_KEY0 # if all LEDs are off, branch back to handle_KEY0
		
		beq r13, r16, POLL # if value is already min, cant decrement anymore
		
		subi r13, r13, 1 # else decrement by 1
		
		stwio r13, 0(r8) # update the LEDs
		
		br POLL # branch back to POLL
	
	handle_KEY3:
		stwio r0, 0(r8) # set LED display to 0
		
		br POLL # branch back to POLL
			

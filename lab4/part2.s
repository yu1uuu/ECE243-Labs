.global _start
    .equ KEY_BASE, 0xFF200050
    .equ LEDs, 0xFF200000
    .equ SW, 0xFF200040




#this only works if you set the first 4 switches to 1



_start:
    movia r8, KEY_BASE
    movia r9, LEDs
    movia r16, SW	# r10 is the switches
    movi r10, 1

    movia r17, Reset_Reg
    ldw r17, (r17)

    movia r13, Delay_val
    ldw r13, (r13) #r13 now holds delay

    movi r14, 0 #delay counter reg

    movi r15, 0 #counter reg

    movi r2, 255 #max reg

loop: 
    ldwio r11, 0xC(r8) #store edge in r11

    beq r15, r2, resetCounter #check if we are at 255 yet, reset if we are
    addi r15, r15, 1 #add 1 to the counter
    stwio r15, (r9) #store counter into led

    call delay #delay ~0.25 seconds

    ldwio r11, 0xC(r8) #store edge in r11

    beq r11, r0, loop #check if a button has been pressed

    br resetEdgeThenLoop

    br loop

delay:
    addi r14, r14, 1
    ble r14, r13, delay

    movi r14, 0
    ret

resetCounter:
    movi r15, 0
    br loop

resetEdgeThenLoop: #make edge register 0 again
    ldwio	r12,0(r16)			# get the switches
	stwio	r12,0xC(r8)			# copy that INTO edge capture reg

deadLoop:
    ldwio r11, 0xC(r8) #store edge in r11

    
    beq r11, r0, deadLoop

    
    ldwio	r12,0(r16)			# get the switches
	stwio	r12,0xC(r8)			# copy that INTO edge capture reg
	
	br loop
    

Delay_val: .word 0x00BEBC20
Reset_Reg: .word 0x0000000F
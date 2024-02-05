.global _start
    .equ KEY_BASE, 0xFF200050
    .equ LEDs, 0xFF200000

    .equ TIMER_BASE, 0xFF202000
    .equ COUNTER_DELAY, 100000000

    .equ SW, 0xFF200040




#this only works if you set the first 4 switches to 1



_start:


    movia r3, KEY_BASE
    movia r4, LEDs
    movia r16, SW	# r10 is the switches
    movi r10, 1
    movi r15, 0 #counter reg
    movi r2, 255 #max reg

    movia r20, TIMER_BASE # base address of timer in r20
	stwio r0, 0x0(r20) # clear the TO (Time Out) bit in case it is on
	movia r8, COUNTER_DELAY # load the delay value
	srli r9, r8, 16 # shift right by 16 bits
	andi r8, r8, 0xFFFF # mask to keep the lower 16 bits
	stwio r8, 0x8(r20) # write to the timer period register (low)
	stwio r9, 0xc(r20) # write to the timer period register (high)
	movi r8, 0b0110 # enable continuous mode and start timer
	stwio r8, 0x4(r20) # write to the timer control register to

loop: 
    ldwio r11, 0xC(r3) #store edge in r11

    beq r15, r2, resetCounter #check if we are at 255 yet, reset if we are
    addi r15, r15, 1 #add 1 to the counter
    stwio r15, (r4) #store counter into led
    
    call delay #delay ~0.25 seconds

    ldwio r11, 0xC(r3) #store edge in r11


    beq r11, r0, loop #check if a button has been pressed

    br resetEdgeThenLoop

    br loop

delay:
    ldwio r8, 0x0(r20) # read the timer status register
	andi r8, r8, 0b1 # mask the TO bit
	beq r8, r0, delay # if TO bit is 0, wait
	stwio r0, 0(r20) # clear the TO bit
	ret


resetCounter:
    movi r15, 0
    br loop

resetEdgeThenLoop: #make edge register 0 again
    ldwio	r12,0(r16)			# get the switches
	stwio	r12,0xC(r3)			# copy that INTO edge capture reg

deadLoop:
    ldwio r11, 0xC(r3) #store edge in r11

    
    beq r11, r0, deadLoop

    
    ldwio	r12,0(r16)			# get the switches
	stwio	r12,0xC(r3)			# copy that INTO edge capture reg
	
	br loop
    

Delay_val: .word 0x000F5E10
Reset_Reg: .word 0x0000000Fa
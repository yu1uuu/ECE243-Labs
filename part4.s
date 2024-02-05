.global _start
    .equ KEYS, 0xFF200050
    .equ LEDs, 0xFF200000

    .equ TIMER, 0xFF202000
    .equ DELAY, 500000

    .equ SW, 0xFF200040


_start:

    movia r3, KEYS
    movia r4, LEDs
    movia r5, SW	
   
    movi r15, 0 
    
    movi r6, 0 # mask last 7 temp
    movi r18, 0 # temp

    movi r7, 995 # max, should wrap around when reaching this

    movia r20, TIMER # stores address of timer 
	stwio r0, 0(r20) # clear the TO bit in case it is on
	movia r8, DELAY # load delay value
	srli r9, r8, 16 # shift right by 16 bits
	andi r8, r8, 0xFFFF # mask to keep the lower 16 bits
	stwio r8, 8(r20) # write to the timer period register (low)
	stwio r9, 12(r20) # write to the timer period register (high)
	movi r8, 0b0110 # enable continuous mode and start timer
	stwio r8, 4(r20) # write to the timer control register to

loop: 
    ldwio r11, 12(r3) # store the edge state of keys in r11
    andi r5, r15, 127 # mask first 3 bits, stopre temp in r5
    beq r5, r2, INCREMENT_SECONDS #check if we are at 255 yet, reset if we are


    addi r15, r15, 1 # increment the counter
    stwio r15, (r4) # store counter into led
    
    call DELAY 

    ldwio r11, 12(r3) # store the edge state of keys in r11


    beq r11, r0, loop # check if a button has been pressed

    br EDGE_RESET

    br loop

DELAY:
    ldwio r8, 0(r20) # read timer status register
	andi r8, r8, 0b1 # mask TO bit
	beq r8, r0, DELAY # if TO bit is 0, wait
	stwio r0, 0(r20) # clear  TO bit
	ret

INCREMENT_SECONDS:
    beq r15, r7, COUNTER_RESET
    addi r15, r15, 128 # increment second
    andi r15, r15, 896   #reset the first 7 bits
    br loop

COUNTER_RESET:
    movi r15, 0
    movi r18, 0

    stwio r15, (r4) #store counter into LEDs
    br loop

EDGE_RESET:
    ldwio	r12,0(r5)		
	stwio	r12,12(r3)	# copy that INTO edge capture reg

POLL:
    ldwio r11, 12(r3) # store the edge state of keys in r11

    
    beq r11, r0, POLL

    
    ldwio	r12,0(r5) # get the switches
	stwio	r12,12(r3)	# copy that INTO edge capture reg
	
	br loop
    

# DELAY_VALUE: .word 0x000F5E10
# RESET_REGISTER: .word 0x0000000Fa
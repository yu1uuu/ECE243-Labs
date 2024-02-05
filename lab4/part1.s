#functionality:
#KEY0: 1 base 10 
#KEY1: increment value iff < 15 base 10
#KEY2: decrement value iff > 1  
#KEY3: blank the display, anyth pressed after = 1
# address of parallel port connected to KEYs = 0xFF200050
#note: make sure that program waits until button released 

.global _start 
.equ LEDs, 0xFF200000 
.equ KEY_BASE, 0xFF200050 # base address of KEYS parallel port


_start:
    movia r25, LEDs
    movia r26, KEY_BASE # get that address into a register
    movia r15, 15 #constant 
    movia r1, 1 #constant 
    movia r2, 0 #currentValue

    #use polling loop to see if button has been pressed. 
    
poll_reset:
    ldwio r8, (r26) #load KEY 
    
    andi r8, r8, 0x1 #checks key1 by performing a bitwise AND operation
    beq r8, r0, poll_increment  # if not key 1 go to next stage 
    br reset # if key pressed, reset 

poll_increment: 
    ldwio r8, (r26)
    andi r8,r8, 0x2 #key2 
    beq r8,r0, poll_decrement
    br increment 

poll_decrement: 
    ldwio r8, (r26)
    andi r8,r8, 0x4 #key2 
    beq r8,r0, poll_blank 
    br decrement 

poll_blank:
    ldwio r8, (r26)
    andi r8,r8, 0x8 #key2 
    beq r8,r0, poll_reset 
    br blank     

reset: 
    movi r10, 1 
    br wait 

increment: 
    beq r15, r10, wait #make sure not more than 15
    addi r11, r11, 1 
    br wait

decrement: 
   beq r10, r11, wait #verify we are not too high

    subi r11, r11, 1

    br wait 
blank: 
    movia r11, 0

    br blankWait


wait: 
    ldwio r8, (r26) #load KEY value 
    beq r8, r0, poll_reset 
    br wait 

blankWait: 
    ldwio r8, (r26) #load KEY value

    andi r8, r8, 0x8
    bne r8, r0, blankDeadLoop #ensure key3 is not pressed down

    ldwio r8, (r26) #load KEY value
    bne r8, r0, reset #check if a key is pressed, not 3 tho

    br blankDeadLoop





.global _start

#initialize LEDs
.equ LEDs, 0xFF200000 

#initialize keys
.equ KEY_BASE, 0xFF200050


_start:
    movia r9, 15 #const reg
    movia r10, 1 #const reg
    movia r11, 0 #currentValue


	movia r25, LEDs
    movia r26, KEY_BASE

poll1:
    ldwio r8, (r26) #load KEY value
    
    andi r8, r8, 0x1 #check key 1
    beq r8, r0, poll2 #jump to next if not key1

    br reset

poll2:
    ldwio r8, (r26) #load KEY value

    andi r8, r8, 0x2 #check key 2
    beq r8, r0, poll3 #jump to next if not key1

    br increment

poll3:

    ldwio r8, (r26) #load KEY value

    andi r8, r8, 0x4 #check key 3
    beq r8, r0, poll4 #jump to next if not key1

    br decrement
poll4:

    ldwio r8, (r26) #load KEY value

    andi r8, r8, 0x8 #check key 4
    beq r8, r0, poll1 #jump to next if not key1


    br blank
    

reset:
    movi r11, 1
    
    br deadLoop

increment:
    beq r9, r11, deadLoop #verify we are not too high

    addi r11, r11, 1

    br deadLoop

decrement:
    beq r10, r11, deadLoop #verify we are not too high

    subi r11, r11, 1

    br deadLoop
blank: 
    movia r11, 0

    br blankDeadLoop

deadLoop:
    ldwio r8, (r26) #load KEY value
    beq r8, r0, poll1

    br deadLoop


blankDeadLoop:
    ldwio r8, (r26) #load KEY value

    andi r8, r8, 0x8
    bne r8, r0, blankDeadLoop #ensure key3 is not pressed down

    ldwio r8, (r26) #load KEY value
    bne r8, r0, reset #check if a key is pressed, not 3 tho

    br blankDeadLoop

resetToOne:
    movi r11, 1
    br poll1

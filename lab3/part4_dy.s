#Modify your program for Part III to do the following: it should display the low-order 10 bits of the two resulting numbers (LargestOnes and LargesZeroes) on the LEDs, in an infinite loop, one after the other.

.text
/* Program to Count the number of 1's and Zeroes in a sequence of 32-bit words,
and determines the largest of each */

.global _start
_start:

	/* Your code here  */
    movia sp, 0x20000   #stack pointer set to address 0x20000

    #initialized to point to memory locations
    movia r10, LargestOnes
    movia r12, LargestZeroes
	movia r11, TEST_NUM

    movi r15, 4294967295 #32-bit word where all bits are set to 1.
	ldw r4, (r11)   #loads a word from the memory location pointed to by r11 (which is TEST_NUM) into register r4.



    movi r7, 0 #r7 stores largest number of 1s, initialize to 0
    movi r14, 0 #r14 stores largest number of 0s, initialize to 0

    movia r22, 200000 #r22 is set to delay constant for use in delay subroutine 
    .equ    LEDs, 0xFF200000 
	movia r25, LEDs #memory address for LED is stored in r25
    
    br loop #jumps to loop label to start loop
    

    
loop:
    beq r4, r0, endiloop #check if we have reached 0 yet


    call ONES #ONES checks the number of 1's in the current word
    ble r2, r7, notMoreOne #If the count of ones (r2) is greater than the current largest count of ones (r7), it updates r7 and displays the low-order 10 bits of the count on the LEDs.
    
    call assignNewValone #update r14 with the new count and display the low-order 10 bits of the count on the LEDs.

    ldw  r4, (r11)  #reload r4 after previous ONES call messed it up

    xor r4, r4, r15

    #count the number of zeros in word
    call ONES
    ble r2, r14, notMoreZero  # If it's greater than the current largest count of zeroes (r14), it updates r14 and displays the low-order 10 bits of the count on the LEDs.

    call assignNewValzero
    

    addi r11, r11, 4   # add 4 to pointer to the numbers to point to the next one
    ldw  r4, (r11)  # load the next number into r14

    
    br loop

assignNewValone:
    subi sp, sp, 4   # save the return address (ra) onto the stack.
    stw ra,(sp)        # save the return address (ra) onto the stack.
    call delay #delay before updating LED
    ldw ra, 0(sp)   #restoring the return address (ra) from the stack.
    addi sp, sp, 4 #restoring the return address (ra) from the stack.
    
    andi r7, r7, 1023  # Mask to keep only the 10 least significant bits.
	stwio r7, (r25)  #used to display the low-order 10 bits of the counts of ones and zeroes on the LEDs.
    mov r7, r2 #copies the count of ones (r2) into r7 to update the largest count encountered so far.
    ret

assignNewValzero: 
    subi sp, sp, 4
    stw ra,(sp)
    call delay
    ldw ra, 0(sp)
    addi sp, sp, 4
    andi r14, r14, 1023  # Mask to keep only the 10 least significant bits.


	stwio r14, (r25)  #used to display the low-order 10 bits of the counts of ones and zeroes on the LEDs.
    mov r14, r2
    #addi r11, r11, 4   # add 4 to pointer to the numbers to point to the next one
    #ldw  r4, (r11)  # load the next number into r10
    ret
notMoreOne:
	#handles cases where there are no more ones to be processed.
    #reload r4 with the next word from the sequence (TEST_NUM), flip all its bits, and call the ONES subroutine to count the number of ones.
    ldw  r4, (r11)  
    xor r4, r4, r15
	call ONES

    ble r2, r14, notMoreZero #checks if the count of ones (r2) in the modified word is less than or equal to the largest count of zeroes encountered so far (r14). If it is, it jumps to the notMoreZero label.
    call assignNewValzero #if num of ones > largest count of zero, call assignNewValZero to update r14 with new count of zero and display the low-order 10 bits on the LED
	
    addi r11, r11, 4   # add 4 to pointer to the numbers to point to the next one
    ldw  r4, (r11)  # load the next number into r4
    
    br loop

notMoreZero:
    addi r11, r11, 4   # add 4 to pointer to the numbers to point to the next one
    ldw  r4, (r11)  # load the next number into r14
    br loop


#FUNCTION USES r4 AS INPUT AND r2 AS OUTPUT
#reserved registers: r2, r5, r6
ONES: # ounts the number of ones in a given 32-bit word and stores the count in r2.
	movi r5, 32 #counter reg
	movi r6, 1 #isolate each bit , TARGET REG reg
	movi r2, 0 #stores the count of ones encounteredRESULT REG
	br searchLoop

searchLoop:
	beq r5, r0, finished #checks if the counter r5 has reached zero. if so, branch to FINISHED
	and r3, r4, r6 #bitwise AND operation between the word in r4 and the mask r6, storing the result in r3. This isolates the least significant bit of the word.
	srli r4, r4, 1 #shifts the word in r4 one bit to the right. moving next bit to be processed into least sig
	beq r3, r6, incrementCount #check is least sig bit is set to 1. if so, branch to incrementCount
	subi r5, r5, 1 #decrement counter r5 to move to next bit 
	br searchLoop #loops back to the searchLoop label to continue processing the next bit.

incrementCount: 
	addi r2, r2, 1 #increments the count of ones stored in r2
	subi r5, r5, 1 #decrements the counter r5 to move to the next bit position
	br searchLoop

finished:
	ret

delay: #incrementing register r23 until it reaches the value stored in r22, causing a delay.
    addi r23, r23, 1 
    ble r23, r22, delay

    movi r23, 0 #resets register r23 to 0 after the delay loop has completed.
    ret 
endiloop: 
    ldw r7, (r10)
    ldw r14, (r12)
    br endiloop

TEST_NUM: .word 0x4a01fead, 0xF677D671,0xDC9758D5,0xEBBD45D2,0x8059519D
.word 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD
.word 0 # end of list
LargestOnes: .word 0
LargestZeroes: .word 0

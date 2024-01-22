.global _start
_start: 
	# .equ LEDs, 0xFF200000
	
	movia r8, result # the address of the result
	ldw r9,4(r8)	# the number of numbers is in r9
	
	movia r10, numbers  # the address of the numbers is in r10
	
	
/* keep smallest number so far in r11 */

	ldw	r11,(r10)
	
/* loop to search for smallest number */

loop: subi r9, r9, 1
       beq r9, r0, finished
	   
	   addi r10,r10,4   # add 4 to pointer to the numbers to point to next one
	   
	   ldw  r12, (r10)  # load the next number into r12
	   
	   ble  r11, r12, loop  # if the current smallest is still smallest, go to loop
	   
	   mov r11,r12   # otherwise new number is biggest, put it into r11
	   br  loop
	   


finished: stw r11,(r8)    # store the answer into result
	# movia r25, LEDs
    	# stwio r12, (r25)
	
iloop: br iloop

result: .word 0
n:	.word 7
numbers: .word 4,5,3,6
	.word 1, 8, 2
	
	

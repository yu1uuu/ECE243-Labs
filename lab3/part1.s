.global _start
_start:
    movia   r4, InputWord # r4 <- address of InputWord
    ldw     r5, (r4) # load value of InputWord in r5
    movi    r6, 0 # initialize count of 1's to zero
    movi    r7, 32	# set up a loop count for 32 bits

count_loop:
    andi    r8, r5, 1 # get the least significant bit of r5 and store it in r9.
    beq     r8, zero, skip # skip if bit in r8 is zero
    addi    r6, r6, 1 # increment count

skip:
    srai    r5, r5, 1 # right shift r5 by 1n
    subi    r7, r7, 1 # decrement loop counter 
    bne     r7, zero, count_loop # repeat the loop if we haven't checked all 32

    movia   r9, Answer # load address of Answer
    stw     r6, (r9) # store the count of 1's in Answer

endiloop: br endiloop

.section .data
InputWord: .word 0x4a01fead
Answer: .word 0

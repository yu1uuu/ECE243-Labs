.global _start
_start:
    movia   r3, InputWord  # r4 <- address of InputWord
    call    ONES     # call subroutine 
    movia   r8, Answer     # load the address of Answer into r8
    stw     r2, (r8)       # store the result in Answer
    br      done        

ONES:
    ldw     r5, (r3)      # load the input word from the address in r4 into r5.
    movi    r4, 0         # initialize the count of 1's to 0 
    movi    r7, 32        # set up a loop counter for 32 bits in r7

count_loop:
    andi    r9, r5, 1      # get the least significant bit of r5 and store it in r9
    beq     r9, zero, skip # skip if bit in r9 is zero
    addi    r4, r4, 1      # increment count

skip:
    srai    r5, r5, 1     # right shift r5 by 1n
    subi    r7, r7, 1     # decrement loop counter 
    bne     r7, zero, count_loop # repeat the loop if we haven't checked all 32

    mov     r2, r4       # move the final count from r6 into r2 to return it
    ret                  # return from the subroutine

done: 
    br done              

.section .data
InputWord: .word 0x4a01fead 
Answer: .word 0            

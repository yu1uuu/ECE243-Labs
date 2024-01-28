.text
.global _start
_start:
    movia   r10, TEST_NUM     # Load address of the first word in TEST_NUM
    movi    r11, 0            # Initialize counter for array index
    movi    r12, 0            # Initialize max count of ones
    movi    r13, 0            # Initialize max count of zeros

loop:
    ldw     r4, 0(r10)        # Load the next word from TEST_NUM into r4
    beq     r4, zero, done    # Check if the word is 0 (end of list), then end loop

    call    ONES              # Call the ONES subroutine for counting ones
    bgt     r2, r12, updateOnes
    br      countZeros

updateOnes:
    mov     r12, r2           # Update max count of ones

countZeros:
    movi    r14, 0xFFFFFFFF   # Load all 1's to r14
    xor     r4, r4, r14       # Invert bits in r4 to count zeros
    call    ONES              # Reuse ONES subroutine for counting zeros

    bgt     r2, r13, updateZeros
    br      nextWord

updateZeros:
    mov     r13, r2           # Update max count of zeros

nextWord:
    addi    r10, r10, 4       # Move to the next word in the array
    br      loop

done:
    movia   r8, LargestOnes
    stw     r12, 0(r8)        # Store the largest count of ones
    movia   r9, LargestZeroes
    stw     r13, 0(r9)        # Store the largest count of zeros
    br      endiloop

ONES:
    movi    r6, 0             # Initialize the counter in r6
    movi    r7, 32            # Set loop counter for 32 bits

count_loop:
    andi    r9, r4, 1         # Check the least significant bit of r4
    beq     r9, zero, skip    # If it is 0, skip the increment
    addi    r6, r6, 1         # Otherwise, increment the counter

skip:
    srai    r4, r4, 1         # Shift the input word right by 1 bit
    subi    r7, r7, 1         # Decrement the loop counter
    bne     r7, zero, count_loop # Repeat until all bits are checked

    mov     r2, r6            # Move the final count to r2
    ret                       # Return to the calling function

endiloop: br endiloop         

.data
TEST_NUM:  .word 0x4a01fead, 0xF677D671, 0xDC9758D5, 0xEBBD45D2, 0x8059519D
           .word 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD
           .word 0  

LargestOnes: .word 0
LargestZeroes: .word 0

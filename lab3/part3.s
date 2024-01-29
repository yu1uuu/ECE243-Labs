.text
.global _start
_start:

    movia sp, 0x20000   # Stack pointer set to address 0x20000

    movia r10, LargestOnes
    movia r12, LargestZeroes
    movia r11, TEST_NUM

    movi r7, 0          # Register to store largest number of 1s
    movi r14, 0         # Register to store largest number of 0s

    br loop

endiloop: 
    ldw r7, (r10)
    ldw r14, (r12)
    br endiloop

loop:
    beq r4, r0, endiloop   # Check if we have reached the end of the sequence

    call ONES              # Call subroutine to count ones
    ble r2, r7, notMoreOne # Compare with largest count of ones

    call assignNewValone   # Update largest count of ones

    xor r4, r4, r15        # Invert bits to count zeroes
    call ONES              # Call subroutine to count zeroes
    ble r2, r14, notMoreZero   # Compare with largest count of zeroes

    call assignNewValzero  # Update largest count of zeroes

    addi r11, r11, 4       # Move to the next number in the sequence
    ldw  r4, (r11)

    br loop

assignNewValone:
    stw r2, 0(r10)          # Store count of ones
    mov r7, r2              # Update largest count of ones
    ret

assignNewValzero:
    stw r2, 0(r12)          # Store count of zeroes
    mov r14, r2             # Update largest count of zeroes
    ret

notMoreOne:
    xor r4, r4, r15         # Invert bits to count zeroes
    call ONES               # Call subroutine to count zeroes
    ble r2, r14, notMoreZero   # Compare with largest count of zeroes

    call assignNewValzero   # Update largest count of zeroes

    addi r11, r11, 4        # Move to the next number in the sequence
    ldw  r4, (r11)
    br loop

notMoreZero:
    addi r11, r11, 4        # Move to the next number in the sequence
    ldw  r4, (r11)
    br loop

ONES:
    movi r5, 32             # Counter for number of bits
    movi r6, 1              # Mask for checking each bit
    movi r2, 0              # Resulting count of ones

searchLoop:
    beq r5, r0, finished    # If all bits processed, exit loop

    and r3, r4, r6          # Check if bit is set
    srli r4, r4, 1          # Shift to the next bit
    beq r3, r6, incrementCount   # If bit is set, increment count

    subi r5, r5, 1          # Decrement bit counter
    br searchLoop           # Continue loop

incrementCount:
    addi r2, r2, 1          # Increment count of ones
    subi r5, r5, 1          # Decrement bit counter
    br searchLoop           # Continue loop

finished:
    ret                     # Return from subroutine

TEST_NUM: .word 0x4a01fead, 0xF677D671,0xDC9758D5,0xEBBD45D2,0x8059519D
          .word 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD
          .word 0            # End of list

LargestOnes: .word 0        # Store largest count of ones
LargestZeroes: .word 0      # Store largest count of zeroes

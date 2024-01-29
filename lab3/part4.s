.text
.global _start
_start:
    movia sp, 0x20000   # Set stack pointer

    movia r10, LargestOnes
    movia r12, LargestZeroes
    movia r11, TEST_NUM
    movi r15, 4294967295 # All bits set to 1
    ldw r4, (r11)        # Load word from TEST_NUM

    movi r7, 0           # Largest number of 1s
    movi r14, 0          # Largest number of 0s
    movi r22, 10000      # Reduced delay
    .equ LEDs, 0xFF200000 
    movia r25, LEDs      # LED address

loop:
    beq r4, r0, exit_loop # Exit loop if r4 is 0

    call ONES
    ble r2, r7, check_zeroes

    mov r7, r2
    stwio r7, (r25)      # Update LEDs with LargestOnes
    call delay

check_zeroes:
    xor r4, r4, r15      # Invert bits
    call ONES
    ble r2, r14, load_next

    mov r14, r2
    stwio r14, (r25)     # Update LEDs with LargestZeroes
    call delay

load_next:
    addi r11, r11, 4     # Next word
    ldw  r4, (r11)
    br loop

exit_loop:
    # Handle exit logic, if any
    # For now, just hang
    br exit_loop

# ONES subroutine
ONES:
    movi r5, 32         # Initialize counter
    movi r6, 1          # Mask for isolating bits
    movi r2, 0          # Counter for ones
searchLoop:
    beq r5, r0, finished
    and r3, r4, r6
    srli r4, r4, 1
    beq r3, r0, decrement
    addi r2, r2, 1
decrement:
    subi r5, r5, 1
    br searchLoop
finished:
    ret

# Delay subroutine
delay:
    movi r23, 0
delay_loop:
    addi r23, r23, 1 
    ble r23, r22, delay_loop    
    ret

# Data definitions
TEST_NUM: .word 0x4a01fead, 0xF677D671, 0xDC9758D5, 0xEBBD45D2, 0x8059519D, 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD, 0
LargestOnes: .word 0
LargestZeroes: .word 0

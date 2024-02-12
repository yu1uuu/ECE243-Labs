.section .exceptions, "ax"  # Define an exception handling section, marked as allocatable and executable

IRQ_HANDLER:
    # Save the context on the stack
    subi sp, sp, 12         # Decrement the stack pointer to make room for 3 registers
    stw ra, (sp)            # Save the return address on the stack
    stw et, 0x4(sp)         # Save the exception temporary register 4 bytes into the stack
    stw r16, 0x8(sp)        # Save the r16 register 8 bytes into the stack

    # Check the exception type
    rdctl et, ctl4          # Read the exception type into et from control register 4
    beq et, r0, SKIP_EA_DEC # If the exception is not an external interrupt, skip the decrement
    subi ea, ea, 4          # Decrement the exception address if it was an external interrupt

SKIP_EA_DEC:

    # Check for push button interrupt
    andi r16, et, 0b10      # Check if the interrupt is caused by a push button (bit 1)
    beq r16, r0, NO_KEY     # If not, skip to NO_KEY
    call KEY_ISR            # Call the push button interrupt service routine

NO_KEY:
    # Check for timeout interrupt
    andi r16, et, 0b1       # Check if the interrupt is caused by a timeout (bit 0)
    beq r16, r0, NO_TIMEOUT # If not, skip to NO_TIMEOUT
    call TIMEOUT_ISR        # Call the timeout interrupt service routine

NO_TIMEOUT:
    # Restore the context from the stack
    ldw ra, (sp)            # Restore the return address from the stack
    ldw et, 0x4(sp)         # Restore the exception temporary register from the stack
    ldw r16, 0x8(sp)        # Restore the r16 register from the stack
    addi sp, sp, 12         # Adjust the stack pointer back
    eret                    # Return from the exception

.text  # Start of the program code section

# Define constants for memory-mapped IO
.equ TIMER_BASE, 0xff202000
.equ LED_BASE, 0xff200000
.equ KEY_BASE, 0xff200050
.equ COUNTER_VALUE, 25000000

# Timeout Interrupt Service Routine
TIMEOUT_ISR:
    # Save context
    subi sp, sp, 16         # Make room on the stack for 4 registers
    stw r16, (sp)           # Save r16
    stw r17, 0x4(sp)        # Save r17
    stw r18, 0x8(sp)        # Save r18
    stw r19, 0xC(sp)        # Save r19

    # Handle timeout
    movia r16, TIMER_BASE   # Load timer base address into r16
    stwio r0, (r16)         # Clear the timeout bit by writing 0 to the timer base address

    # Increment COUNT based on RUN
    movia r16, COUNT        # Load the address of COUNT into r16
    ldw r17, (r16)          # Load current value of COUNT into r17
    movia r18, RUN          # Load the address of RUN into r18
    ldw r19, (r18)          # Load the value of RUN into r19
    add r17, r17, r19       # Add RUN to COUNT
    stw r17, (r16)          # Store the new value of COUNT

    # Restore context
    ldw r16, (sp)           # Restore r16
    ldw r17, 0x4(sp)        # Restore r17
    ldw r18, 0x8(sp)        # Restore r18
    ldw r19, 0xC(sp)        # Restore r19
    addi sp, sp, 16         # Adjust the stack pointer back
    ret                     # Return from ISR

# Key Press Interrupt Service Routine
KEY_ISR:
    # Save context
    subi sp, sp, 8          # Make room on the stack for 2 registers
    stw r16, (sp)           # Save r16
    stw r17, 0x4(sp)        # Save r17

    # Check if a key has been pressed
    movia r16, KEY_BASE     # Load the base address of keys into r16
    ldwio r17, 0xC(r16)     # Load the edge capture register into r17
    beq r17, r0, END_KEY_ISR # If no key press is detected, jump to END_KEY_ISR

    # Clear edge capture and toggle RUN
    movi r17, 0b1111        # Prepare to clear edge capture register
    stwio r17, 0xC(r16)     # Clear edge capture by writing 0b1111 to it

    # Toggle RUN
    movia r16, RUN          # Load the address of RUN into r16
    ldw r17, (r16)          # Load current value of RUN into r17
    xori r17, r17, 1        # Toggle RUN using XOR with 1
    stw r17, (r16)          # Store the new value of RUN

END_KEY_ISR:
    # Restore context
    ldw r16, (sp)           # Restore r16
    ldw r17, 0x4(sp)        # Restore r17
    addi sp, sp, 8          # Adjust the stack pointer back
    ret                     # Return from ISR

.global  _start  # Declare the entry point of the program
_start:
    # Initial setup
    movia sp, 0x20000       # Initialize the stack pointer
    call CONFIG_TIMER       # Call subroutine to configure the timer
    call CONFIG_KEYS        # Call subroutine to configure the keys

    # Enable interrupts
    movi r9, 0b11           # Prepare to enable IRQ for keys and timer
    wrctl ctl3, r9          # Write to control register 3 to enable interrupts for keys and timer
    movi r9, 0b1            # Prepare to enable processor interrupt
    wrctl ctl0, r9          # Write to control register 0 to enable processor interrupt

    # Main loop: Update LEDs based on COUNT
    movia r8, LED_BASE      # Load LED base address into r8
    movia r9, COUNT         # Load the address of COUNT into r9
LOOP:
    ldw r10, 0(r9)          # Load the value of COUNT into r10
    stwio r10, 0(r8)        # Write the value of COUNT to the LEDs
    br LOOP                 # Loop indefinitely

# Timer configuration subroutine
CONFIG_TIMER:
    movia r8, TIMER_BASE    # Load the base address of the timer into r8

    # Stop and reset the timer
    movi r9, 0b1000         # Prepare to stop the timer
    stwio r9, 0x4(r8)       # Stop the timer
    stwio r0, (r8)          # Reset timer data

    # Set the timer period
    movia r9, COUNTER_VALUE  # Load the counter initialization value
    srli r10, r9, 16        # Shift right to get the upper 16 bits
    andi r9, r9, 0xffff     # Mask to get the lower 16 bits
    stwio r9, 0x8(r8)       # Set lower 16 bits of the period
    stwio r10, 0xC(r8)      # Set upper 16 bits of the period

    # Start the timer
    movi r9, 0b0111         # Prepare to start the timer, continuous mode, with interrupt on timeout
    stwio r9, 0x4(r8)       # Write to control register to start the timer
    ret                     # Return from subroutine

# Keys configuration subroutine
CONFIG_KEYS:
    movia r8, KEY_BASE      # Load the base address of the keys into r8
    movi r9, 0b1111         # Prepare to enable interrupts for all keys
    stwio r9, 0xC(r8)       # Clear edge capture register
    stwio r9, 0x8(r8)       # Enable interrupts for all keys
    ret                     # Return from subroutine

.data  # Start of the data section

# Global variables
.global  COUNT  # Declare COUNT as a global variable
COUNT:  .word    0x0  # Initialize COUNT, used by timer

.global  RUN     # Declare RUN as a global variable
RUN:    .word    0x1  # Initialize RUN, used to control whether to increment COUNT

.end  # End of the file

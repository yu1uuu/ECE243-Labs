.section .exceptions, "ax"    # Define a section named .exceptions, marking it as allocatable and executable

IRQ_HANDLER:                   # Label for the IRQ handler routine
    subi sp, sp, 12            # Allocate space on the stack for 3 words (12 bytes) to save registers
    stw ra, (sp)               # Save the return address on the stack
    stw et, 0x4(sp)            # Save the exception temporary register 4 bytes into the stack
    stw r16, 0x8(sp)           # Save register 16 8 bytes into the stack

    rdctl et, ctl4             # Read control register 4 into et to check the cause of the exception
    beq et, r0, SKIP_EA_DEC    # If et is equal to 0, branch to SKIP_EA_DEC (no hardware interrupt)
    subi ea, ea, 4             # If a hardware interrupt occurred, decrement the exception address by 4
SKIP_EA_DEC:

    andi r16, et, 0b10         # Check if the exception was caused by a push button interrupt
    beq r16, r0, NO_KEY        # If not, branch to NO_KEY
    call KEY_ISR               # Call the push button interrupt service routine
NO_KEY:
    andi r16, et, 0b1          # Check if the exception was caused by a timeout (timer interrupt)
    beq r16, r0, NO_TIMEOUT    # If not, branch to NO_TIMEOUT
    call TIMEOUT_ISR           # Call the timeout interrupt service routine
NO_TIMEOUT:

    ldw ra, (sp)               # Restore the return address from the stack
    ldw et, 0x4(sp)            # Restore the exception temporary register from the stack
    ldw r16, 0x8(sp)           # Restore register 16 from the stack
    addi sp, sp, 12            # Deallocate stack space by moving the stack pointer back
    eret                        # Return from exception

    .text                      # Start of the text (code) section

    .equ TIMER_BASE, 0xff202000 # Define TIMER_BASE as a constant with the address of the timer peripheral
    .equ LED_BASE, 0xff200000   # Define LED_BASE as a constant with the address of the LED peripheral
    .equ KEY_BASE, 0xff200050   # Define KEY_BASE as a constant with the address of the key peripheral

# Timeout interrupt service routine
TIMEOUT_ISR:
    subi sp, sp, 16            # Allocate space on the stack for 4 words (16 bytes) to save registers
    stw r16, (sp)              # Save register 16 on the stack
    stw r17, 0x4(sp)           # Save register 17 on the stack
    stw r18, 0x8(sp)           # Save register 18 on the stack
    stw r19, 0xC(sp)           # Save register 19 on the stack

    movia r16, TIMER_BASE      # Move the base address of the timer into r16
    stwio r0, (r16)            # Write 0 to the timer base address to clear the timeout bit

    movia r16, COUNT           # Move the address of the COUNT variable into r16
    ldw r17, (r16)             # Load the current value of COUNT into r17
    movia r18, RUN             # Move the address of the RUN variable into r18
    ldw r19, (r18)             # Load the current value of RUN into r19
    add r17, r17, r19          # Add the values of COUNT and RUN, updating COUNT
    stw r17, (r16)             # Store the updated COUNT back into memory

    ldw r16, (sp)              # Restore register 16 from the stack
    ldw r17, 0x4(sp)           # Restore register 17 from the stack
    ldw r18, 0x8(sp)           # Restore register 18 from the stack
    ldw r19, 0xC(sp)           # Restore register 19 from the stack
    addi sp, sp, 16            # Deallocate stack space by moving the stack pointer back
    ret                        # Return from subroutine

# Key interrupt service routine
KEY_ISR:
    subi sp, sp, 20            # Allocate space on the stack for 5 words (20 bytes) to save registers
    stw r16, (sp)              # Save register 16 on the stack
    stw r17, 0x4(sp)           # Save register 17 on the stack
    stw r18, 0x8(sp)           # Save register 18 on the stack
    stw r19, 0xC(sp)           # Save register 19 on the stack
    stw r20, 0x10(sp)          # Save register 20 on the stack

    movia r16, KEY_BASE        # Move the base address of the key peripheral into r16
    ldwio r17, 0xC(r16)        # Load the key peripheral status into r17

    andi r18, r17, 0b1         # Check if KEY0 was pressed
    beq r18, r0, NO_KEY0       # If not, branch to NO_KEY0
    stwio r18, 0xC(r16)        # Reset the edge capture bit for KEY0
    movia r18, RUN             # Move the address of the RUN variable into r18
    ldw r19, (r18)             # Load the current value of RUN into r19
    xori r19, r19, 1           # Toggle the value of RUN
    stw r19, (r18)             # Store the updated value of RUN back into memory
NO_KEY0:
    andi r18, r17, 0b10        # Check if KEY1 was pressed
    beq r18, r0, NO_KEY1       # If not, branch to NO_KEY1
    stwio r18, 0xC(r16)        # Reset the edge capture bit for KEY1

    movia r18, COUNT_INIT      # Move the address of COUNT_INIT into r18
    ldw r19, (r18)             # Load the current value of COUNT_INIT into r19
    srli r19, r19, 1           # Double the value of COUNT_INIT
    stw r19, (r18)             # Store the updated value of COUNT_INIT back into memory

    movia r18, TIMER_BASE      # Move the base address of the timer into r18
    movi r20, 0b1000           # Prepare the value to stop the timer
    stwio r20, 0x4(r18)        # Stop the timer by writing to its control register
    srli r20, r19, 16          # Prepare the high part of the new timer counter value
    andi r19, r19, 0xffff      # Prepare the low part of the new timer counter value
    stwio r19, 0x8(r18)        # Set the low part of the new timer counter value
    stwio r20, 0xC(r18)        # Set the high part of the new timer counter value
    movi r20, 0b0111           # Prepare the value to start the timer with its previous settings
    stwio r20, 0x4(r18)        # Restart the timer by writing to its control register
NO_KEY1:
    andi r18, r17, 0b100       # Check if KEY2 was pressed
    beq r18, r0, NO_KEY2       # If not, branch to NO_KEY2
    stwio r18, 0xC(r16)        # Reset the edge capture bit for KEY2

    movia r18, COUNT_INIT      # Move the address of COUNT_INIT into r18
    ldw r19, (r18)             # Load the current value of COUNT_INIT into r19
    slli r19, r19, 1           # Halve the value of COUNT_INIT
    stw r19, (r18)             # Store the updated value of COUNT_INIT back into memory

    movia r18, TIMER_BASE      # Move the base address of the timer into r18
    movi r20, 0b1000           # Prepare the value to stop the timer
    stwio r20, 0x4(r18)        # Stop the timer by writing to its control register
    srli r20, r19, 16          # Prepare the high part of the new timer counter value
    andi r19, r19, 0xffff      # Prepare the low part of the new timer counter value
    stwio r19, 0x8(r18)        # Set the low part of the new timer counter value
    stwio r20, 0xC(r18)        # Set the high part of the new timer counter value
    movi r20, 0b0111           # Prepare the value to restart the timer with its previous settings
    stwio r20, 0x4(r18)        # Restart the timer by writing to its control register
NO_KEY2:

    ldw r16, (sp)              # Restore register 16 from the stack
    ldw r17, 0x4(sp)           # Restore register 17 from the stack
    ldw r18, 0x8(sp)           # Restore register 18 from the stack
    ldw r19, 0xC(sp)           # Restore register 19 from the stack
    ldw r20, 0x10(sp)          # Restore register 20 from the stack
    addi sp, sp, 20            # Deallocate stack space by moving the stack pointer back
    ret                        # Return from subroutine

    .global  _start
_start:
    /* Set up stack pointer */
    movia sp, 0x20000
    call    CONFIG_TIMER        # configure the Timer
    call    CONFIG_KEYS         # configure the KEYs port
    /* Enable interrupts in the NIOS-II processor */

    movi r9, 0b11               # enable IRQ for keys and timer 1
    wrctl ctl3, r9 
    movi r9, 0b1
    wrctl ctl0, r9              # enable PIE bit

    movia   r8, LED_BASE        # LEDR base address (0xFF200000)
    movia   r9, COUNT           # global variable
LOOP:
    ldw     r10, 0(r9)          # global variable
    stwio   r10, 0(r8)          # write to the LEDR lights
    br      LOOP

# uses r8, r9, r10
CONFIG_TIMER:
    movia r8, TIMER_BASE

    movi r9, 0b1000          # STOP timer in case it was running
    stwio r9, 0x4(r8)
    stwio r0, (r8)           # reset timer data

    movia r10, COUNT_INIT
    ldw r9, (r10)            # move the counter value in
    srli r10, r9, 16
    andi r9, r9, 0xffff
    stwio r9, 0x8(r8)
    stwio r10, 0xC(r8)
    movi r9, 0b0111          # START, CONT, ITO
    stwio r9, 0x4(r8)
    ret

# uses r8, r9
CONFIG_KEYS: 
    movia r8, KEY_BASE
    movi r9, 0b1111
    stwio r9, 0xC(r8)   # clear edge capture
    stwio r9, 0x8(r8)   # enable interrupts for every key
    ret


    .data
/* Global variables */
    .global  COUNT
COUNT:  .word    0x0            # used by timer

    .global  RUN                 # used by pushbutton KEYs
RUN:    .word    0x1            # initial value to increment COUNT
    .global COUNT_INIT
COUNT_INIT:
    .word 25000000
    .end

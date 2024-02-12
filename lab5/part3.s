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

KEY_NOTPRESSED:
    # Check for timeout interrupt
    andi r16, et, 0b1       # Check if the interrupt is caused by a timeout (bit 0)
    beq r16, r0, NO_TIMEOUT # If not, skip to NO_TIMEOUT
    call TIMEOUT_ISR        # Call the timeout interrupt service routine

TIMEOUT_NOT:
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
TIMEOUT:
    # Save context
    subi sp, sp, 16         # Make room on the stack for 4 registers
    stw r16, (sp)           # Save r16
    stw r17, 0x4(sp)        # Save r17
    stw r19, 0x8(sp)        # Save r19
    stw r20, 0xC(sp)        # Save r20

    # Handle timeout
    movia r16, TIMER_BASE   # Load timer base address into r16
    stwio r0, (r16)         # Clear the timeout bit by writing 0 to the timer base address

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

   
    # Clear edge capture and toggle RUN
    movi r17, 0b1111        # Prepare to clear edge capture register
    stwio r17, 0xC(r16)     # Clear edge capture by writing 0b1111 to it

    ldw r15, 0(r16)         
    xori r15, r15, 1
    stw r15, 0(r16)

    stwio r12, 0xC(r13)      #clear edge register
    ret

END_KEY:
    ldw     et, 0(sp)           
    ldw     ra, 4(sp)
    ldw     r20, 8(sp)
    ldw     ea, 12(sp)
    ldw     r15, 16(sp)
    ldw     r16, 20(sp)
    ldw     r6, 24(sp)
    addi    sp, sp, 28          # restore pointer
    eret                        # return exception

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
CONFIG_TIMER:                   # code not shown

    
    movia r6, TIMER_BASE # base address of timer in r20
	stwio r0, 0x0(r6) # clear the TO (Time Out) bit in case it is on
	movia r4, COUNTER_DELAY # load the delay value
	srli r5, r4, 16 # shift right by 16 bits
	andi r4, r4, 0xFFFF # mask to keep the lower 16 bits
	stwio r4, 0x8(r6) # write to the timer period register (low)
	stwio r5, 0xc(r6) # write to the timer period register (high)
	movi r4, 0b0111 # enable continuous mode and start timer
	stwio r4, 0x4(r6) # write to the timer control register to

    ret
    
# Keys configuration subroutine
CONFIG_KEYS:                  
     
    movia r13, KEY_BASE #address of key pushbuttons in r2
    stwio r12, 0xC(r13) #reset the edge capture reg with 1111
    stwio r12, 8(r13)   

    ret
    

.data  # Start of the data section

# Global variables
.global  COUNT  # Declare COUNT as a global variable
COUNT:  .word    0x0  # Initialize COUNT, used by timer

.global  RUN     # Declare RUN as a global variable
RUN:    .word    0x1  # Initialize RUN, used to control whether to increment COUNT

.end 

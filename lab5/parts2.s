/******************************************************************************
 * Write an interrupt service routine
 *****************************************************************************/
.section .exceptions, "ax"  # Define a section for exception handling, marked as allocatable (a) and executable (x)

# ignored clobbering
IRQ_HANDLER:
        # save registers on the stack (et, ra, ea, others as needed)
        subi    sp, sp, 16          # Decrement stack pointer by 16 bytes to allocate space on the stack
        stw     et, 0(sp)           # Store the exception temporary register at the top of the stack
        stw     ra, 4(sp)           # Store the return address register 4 bytes into the stack
        stw     r20, 8(sp)          # Store general-purpose register r20 8 bytes into the stack

        rdctl   et, ctl4            # Read the exception type into the exception temporary register
        beq     et, r0, SKIP_EA_DEC # If the exception type is not external, skip the decrement of ea
        subi    ea, ea, 4           # Decrement the exception address by 4 for external interrupts

SKIP_EA_DEC:
        stw     ea, 12(sp)          # Store the exception address 12 bytes into the stack
        # also save r4, r5, r17, r18
        subi sp, sp, 16             # Allocate more space on the stack for additional registers
        stw r4, 0(sp)               # Store r6 at the new top of the stack
        stw r5, 4(sp)               # Store r5 4 bytes into the stack
        stw r17, 8(sp)              # Store r17 8 bytes into the stack
        stw r18, 12(sp)             # Store r18 12 bytes into the stack

        andi    r20, et, 0x2        # Check if the interrupt is from pushbuttons by masking et
        beq     r20, r0, END_ISR    # If the result is zero, not a pushbutton interrupt, end ISR
        call    KEY_ISR             # Call the pushbutton ISR function

END_ISR:
        ldw r7, 0(sp)               # Restore r6 from the stack
        ldw r5, 4(sp)               # Restore r5 from the stack
        ldw r17, 8(sp)              # Restore r17 from the stack
        ldw r18, 12(sp)             # Restore r18 from the stack
        addi sp, sp, 16             # Deallocate space from the stack for r4, r5, r17, r18
        ldw     et, 0(sp)           # Restore the exception temporary register from the stack
        ldw     ra, 4(sp)           # Restore the return address from the stack
        ldw     r20, 8(sp)          # Restore r20 from the stack
        ldw     ea, 12(sp)          # Restore the exception address from the stack
        addi    sp, sp, 16          # Deallocate space from the stack for et, ra, r20, ea
        eret                        # Return from exception

/******************************************************************************
 * set where to go upon reset
 ******************************************************************************/
.section .reset, "ax"         # Define a section for reset handling, marked as allocatable (a) and executable (x)
        movia   r8, _start    # Move the address of the _start label into r8
        jmp    r8             # Jump to the address in r8, effectively to _start

/******************************************************************************
 * Main program
 ******************************************************************************/
.text                          # Start of the text (code) section
.global  _start                # Declare _start as a global symbol, entry point

    .equ KEYS, 0xff200050      # Define KEYS as an address for the pushbuttons
    .equ HEX_BASE1, 0xff200020 # Define HEX_BASE1 as the base address for the first set of HEX displays
    .equ HEX_BASE2, 0xff200030 # Define HEX_BASE2 as the base address for the second set of HEX displays

_start:
    # Initialize the stack pointer
    movia sp, 0x20000	         # Set the stack pointer to the address 0x20000
    movi r16, 0b0000           # Initialize r16 to 0, used for display control

    # set up keys to generate interrupts
    movi r4, 0b1111            # Set r4 to 15 (0b1111), used to configure the keys
    movia r5, KEYS		         # Load the address of the pushbuttons into r5
    stwio r4, 12(r5)	         # Clear edge capture register by writing 0b1111
    stwio r4, 8(r5) 	         # Enable interrupts for all keys by writing 0b1111 to the interrupt mask

    # enable interrupts in NIOS II
    movi r4, 0b10	             # Load the value 2 into r6, to configure interrupt level
    wrctl ctl3, r4             # Write the value in r4 to control register 3, enabling interrupts for IRQ1 (buttons)
    movi r4, 0b1               # Load the value 1 into r4, to enable processor interrupt
    wrctl ctl0, r4             # Write the value in r6 to control register 0, enabling processor interrupt enable (PIE) bit

IDLE:   
    br  IDLE                   # Infinite loop to keep the processor idle

# Interrupt Service Routine for Key Press
KEY_ISR:
    subi sp, sp, 4             # Allocate space on the stack for the return address
    stw ra, 0(sp)              # Store the return address on the stack

    # Process each key press with a call to KEY_HANDLER
    movi r4, 0b1               # Prepare to check key 0
    movi r5, 0                 # Key index 0
    call KEY_HANDLER           # Call handler for key 0
    movi r4, 0b10              # Prepare to check key 1
    movi r5, 1                 # Key index 1
    call KEY_HANDLER           # Call handler for key 1
    movi r4, 0b100             # Prepare to check key 2
    movi r5, 2                 # Key index 2
    call KEY_HANDLER           # Call handler for key 2
    movi r4, 0b1000            # Prepare to check key 3
    movi r5, 3                 # Key index 3
    call KEY_HANDLER           # Call handler for key 3

    ldw ra, 0(sp)              # Restore the return address from the stack
    addi sp, sp, 4             # Deallocate space from the stack
    ret                        # Return from ISR

# Key handler subroutine
KEY_HANDLER:
    # r4 - bitmask for the key we're checking
    # r5 - the key index (e.g., 0-3)
    movia r17, KEYS            # Load the address of the keys into r17
    ldwio r18, 12(r17)         # Load the edge capture register value into r18
    and r18, r18, r4           # Check if the specific key is pressed
    bne r18, r0, KEY_PRESSED   # If the key is pressed, handle the press
    ret                        # Return if the key is not pressed

KEY_PRESSED:
    stwio r4, 12(r17) 	       # Clear the edge capture bit for the pressed key
    xor r16, r16, r4           # Toggle the display on/off status for the pressed key
    and r17, r16, r4	         # Check if the key is on or off
    beq r17, r0, BLANK         # If key is off, go to BLANK to clear the display
    mov r4, r5                 # Prepare the key index for display
	
    # Call HEX_DISP to display the key index
    subi sp, sp, 4             # Allocate space on the stack for the return address
    stw ra, (sp)               # Store the return address on the stack
    call HEX_DISP              # Call the HEX display subroutine
    ldw ra, (sp)               # Restore the return address from the stack
    addi sp, sp, 4             # Deallocate space from the stack
    ret                        # Return from the subroutine

BLANK:
    movi r4, 0b10000           # Prepare to clear the display

    subi sp, sp, 4             # Allocate space on the stack for the return address
    stw ra, (sp)               # Store the return address on the stack
    call HEX_DISP              # Call the HEX display subroutine to clear the display
    ldw ra, (sp)               # Restore the return address from the stack
    addi sp, sp, 4             # Deallocate space from the stack
    ret                        # Return from the subroutine

# uses r8, r6, r7
# uses r4, r2, r5
HEX_DISP:   movia    r8, BIT_CODES         # starting address of the bit codes
	    andi     r6, r4, 0x10	   # get bit 4 of the input into r6
	    beq      r6, r0, not_blank 
	    mov      r2, r0
	    br       DO_DISP
not_blank:  andi     r4, r4, 0x0f	   # r4 is only 4-bit
            add      r4, r4, r8            # add the offset to the bit codes
            ldb      r2, 0(r4)             # index into the bit codes

#Display it on the target HEX display
DO_DISP:    
			movia    r8, HEX_BASE1         # load address
			movi     r6,  4
			blt      r5,r6, FIRST_SET      # hex4 and hex 5 are on 0xff200030
			sub      r5, r5, r6            # if hex4 or hex5, we need to adjust the shift
			addi     r8, r8, 0x0010        # we also need to adjust the address
FIRST_SET:
			slli     r5, r5, 3             # hex*8 shift is needed
			addi     r7, r0, 0xff          # create bit mask so other values are not corrupted
			sll      r7, r7, r5 
			addi     r4, r0, -1
			xor      r7, r7, r4  
    		sll      r4, r2, r5            # shift the hex code we want to write
			ldwio    r5, 0(r8)             # read current value       
			and      r5, r5, r7            # and it with the mask to clear the target hex
			or       r5, r5, r4	           # or with the hex code
			stwio    r5, 0(r8)		       # store back
END:			
			ret
			
BIT_CODES:  .byte     0b00111111, 0b00000110, 0b01011011, 0b01001111
			.byte     0b01100110, 0b01101101, 0b01111101, 0b00000111
			.byte     0b01111111, 0b01100111, 0b01110111, 0b01111100
			.byte     0b00111001, 0b01011110, 0b01111001, 0b01110001

            .end
			




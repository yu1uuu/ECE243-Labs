/******************************************************************************
 * Assembly program to toggle HEX display in response to key presses
 *****************************************************************************/

    .section .bss
    .align 2
    toggle_states: .space 4  # Reserve 4 bytes for the toggle states of HEX0-HEX3

    .section .text
    .global _start

/******************************************************************************
 * Main program
 *****************************************************************************/
_start:
    /* 1. Initialize the stack pointer */
    movia   sp, 0x20000

    /* 2. Set up keys to generate interrupts */
    .equ KEYS, 0xFF200050
    movia   r2, KEYS
    movi    r4, 0x1
    stwio   r4, 0xC(r2)       # Clear edge capture bits for all keys
    stwio   r4, 0x8(r2)       # Enable interrupts for KEY0

    /* 3. Enable interrupts in NIOS II */
    movi    r5, 0x3
    wrctl   ctl3, r5          # Enable interrupts for IRQ1 (pushbuttons)
    movi    r4, 1
    wrctl   ctl0, r4          # Enable PIE (Processor Interrupt Enable)

IDLE:
    br IDLE                   # Infinite loop to keep the processor idle

/******************************************************************************
 * Write an interrupt service routine
 *****************************************************************************/
    .section .exceptions, "ax"
IRQ_HANDLER:
    /* save registers on the stack */
    subi    sp, sp, 16
    stw     et, 0(sp)
    stw     ra, 4(sp)
    stw     r20, 8(sp)
    stw     r21, 12(sp)

    rdctl   et, ctl4
    beq     et, r0, SKIP_EA_DEC
    subi    ea, ea, 4

SKIP_EA_DEC:
    andi    r20, et, 0x2
    beq     r20, r0, END_ISR
    call    KEY_ISR

END_ISR:
    ldw     et, 0(sp)
    ldw     ra, 4(sp)
    ldw     r20, 8(sp)
    ldw     r21, 12(sp)
    addi    sp, sp, 16
    eret

/******************************************************************************
 * KEY Interrupt Service Routine
 *****************************************************************************/
    .section .text
    .global KEY_ISR
KEY_ISR:
    movia   r2, KEYS
    ldwio   r3, 0xC(r2)

    movi    r18, 1
    movi    r19, 0

key_check_loop:
    and     r20, r3, r18
    beq     r20, r0, skip_key

    movia   r21, toggle_states
    add     r21, r21, r19
    ldb     r22, 0(r21)
    xor     r22, r22, 1
    stb     r22, 0(r21)

    mov     r5, r19
    beq     r22, r0, display_blank
    mov     r4, r19
    br      update_display

display_blank:
    movi    r4, 0x10

update_display:
    call    HEX_DISP

    movi    r20, 1
    sll     r20, r20, r19
    stwio   r20, 0xC(r2)

skip_key:
    slli    r18, r18, 1
    addi    r19, r19, 1
    cmpgei  r20, r19, 4
    blt     r20, r19, key_check_loop

    ret

/******************************************************************************
 * HEX Display Subroutine and BIT_CODES
 *****************************************************************************/
    .equ HEX_BASE1, 0xff200020
    .equ HEX_BASE2, 0xff200030

HEX_DISP:
    movia    r8, BIT_CODES
    andi     r6, r4, 0x10
    beq      r6, r0, not_blank
    mov      r2, r0
    br       DO_DISP

not_blank:
    andi     r4, r4, 0x0f
    add      r4, r4, r8
    ldb      r2, 0(r4)

DO_DISP:
    movia    r8, HEX_BASE1
    movi     r6, 4
    blt      r5, r6, FIRST_SET
    sub      r5, r5, r6
    addi     r8, r8,

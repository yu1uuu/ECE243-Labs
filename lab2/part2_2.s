.text  # The numbers that turn into executable instructions
.global _start
_start:

/* r13 should contain the grade of the person with the student number, -1 if not found */
/* r10 has the student number being searched */


	movia r10, 718293		# r10 is where you put the student number being searched for
	
/* Your code goes here  */
	
	# Initialize r13 to -1
    movi r13, -1

  	# Load the address of the Snumbers array into r8
    movia r8, Snumbers

    # Load the address of the Grades array into r9 
    movia r9, Grades
	
	# keep current student number being checked in r11
	ldw r11, (r8)

search_loop:

    # Check if r11 is zero (end of the array)
    beq r11, r0, end_loop

    # Compare r11 (current student number) with r10 (searched student number) 
    beq r11, r10, found_student

    # Increment the array pointers and continue searching 
    addi r8, r8, 4
    addi r9, r9, 1
	
	# Load the current student number from the array into r11
    ldw r11, (r8)
	
    br search_loop

found_student:
    /* Load the corresponding grade */
    ldb r13, 0(r9)
    br end_loop

end_loop:

	movia r8, result
   
    stb r13, (r8)


/* result should hold the grade of the student number put into r10, or
-1 if the student number isn't found */

iloop: br iloop


.data  	# the numbers that are the data 


/* result should hold the grade of the student number put into r10, or
-1 if the student number isn't found */ 

result: .byte 0
		.align 2 # place Snumbers at an address divisable by 4
/* Snumbers is the "array," terminated by a zero of the student numbers  */
Snumbers: .word 10392584, 423195, 644370, 496059, 296800
        .word 265133, 68943, 718293, 315950, 785519
        .word 982966, 345018, 220809, 369328, 935042
        .word 467872, 887795, 681936, 0	
	
		.align 2
/* Grades is the corresponding "array" with the grades, in the same order*/
Grades: .byte 99, 68, 90, 85, 91, 67, 80
        .byte 66, 95, 91, 91, 99, 76, 68  
        .byte 69, 93, 90, 72
	
	

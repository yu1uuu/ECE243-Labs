.global _start
_start:
		.equ LEDs, 0xFF200000
		movi r8, 1
		movi r9, 30
		movi r12, 0
  		
		
myloop: 
		add r12, r8
		addi r8, r8, 1
		ble r8, r9, myloop

  		movia r25, LEDs
    		stwio r12, (r25)
fin: br fin
	
	

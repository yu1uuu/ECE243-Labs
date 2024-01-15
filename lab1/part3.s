.global _start
_start:
		
		movi r8, 1
		movi r9, 30
		movi r12, 0
		
myloop: 

		addi r8, r8, 1
		add r12, r12, r8
		ble r8, r9, myloop
		
fin: br fin
	
	

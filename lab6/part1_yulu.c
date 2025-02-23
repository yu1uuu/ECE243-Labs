int main(void){
	volatile int*LEDR_ptr = 0xff200000;
	volatile int*KEY_ptr = 0xff200050;
	int LED_state = 0;

	// clear everything just in case
	*LEDR_ptr = 0;
	 *(KEY_ptr + 3) = 0;


	while(1){
		if(!LED_state){
			if(*(KEY_ptr + 3) & 0x1){
				*(KEY_ptr + 3) = 0xffffffff;
				*(LEDR_ptr) = 0xffffffff;
				LED_state = 1;
			}
		}else{
			if( *(KEY_ptr + 3) & 0x2){
				*(KEY_ptr + 3) = 0xffffffff;
				*(LEDR_ptr) = 0;
				LED_state = 0;
			}
		}
	}
}

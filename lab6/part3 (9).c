int main(){
    volatile int * audio_ptr = (int*) 0xFF203040;
    volatile int * SW_ptr = (int*) 0xFF200040;
    
    int freq, SW, num_burst;
    while (1){

        //code to figure out the freq based off val of switches
        SW = *SW_ptr & 0b1111111111; //lower ten 1s
        freq = 100 + (1900 * SW / 1024);
        num_burst = 8000 / (2 * freq);
        //code to output wave
        int fifospace = (*(audio_ptr + 1) & 0x00FF0000) >> 16;
        if (fifospace >= (2 * num_burst) ) {    
            
            for (int j = 0; j < num_burst; j++){
                *(audio_ptr + 2) = 0x00FFFFFF;
                *(audio_ptr + 3) = 0x00FFFFFF;
            }
            for (int j = 0; j < num_burst; j++){
            	*(audio_ptr + 2) = 0;
                *(audio_ptr + 3) = 0;
        	}
	    }
	}
}

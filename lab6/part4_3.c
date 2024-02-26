#define BUFFER_SIZE 3200
#define DAMPING_FACTOR 0.4

int main(void) {
    volatile int *base_audio = (int*)0xFF203040;
    int audio_buffer[BUFFER_SIZE];
    int buffer_index = 0;

    *base_audio = 0b1100; // reset the registers
    *base_audio = 0b0000;

    //need to populate buffer first
    for(int x = 0; x < BUFFER_SIZE; x++){
        int left = *(base_audio + 2);

        // store audio in the buffer
        audio_buffer[x] = (left * DAMPING_FACTOR);
    }

    while (1) {
        int fifospace = *(base_audio + 1);

        for (int x = 0; x < BUFFER_SIZE; x++) {
            if ((fifospace & 0x000000FF) > 0) { //make sure its not empty
                //sample FIFO
                int left = *(base_audio + 2) + audio_buffer[buffer_index];

                //send the audio to speaker
                *(base_audio + 2) = left;
                *(base_audio + 3) = left;

                //store audio samples in the buffer
                audio_buffer[buffer_index] +=  (left * DAMPING_FACTOR);
            
                //increment buffer index (mod to prevent out of bounds)
                buffer_index = (buffer_index + 1) % BUFFER_SIZE;
            }
        }
    }
    return 0;
}

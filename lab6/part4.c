#define AUDIO_BASE 0xFF203040
#define SAMPLE_RATE 8000 // Sample rate in Hz
#define DELAY_IN_SECONDS 0.4 // Echo delay in seconds
#define DAMPING_FACTOR 3 // Damping factor for the echo
#define BUFFER_SIZE (int)(SAMPLE_RATE * DELAY_IN_SECONDS) // Size of the buffer

struct audio_t {
    volatile unsigned int control; // The control/status register
    volatile unsigned char rarc; // the 8 bit RARC register
    volatile unsigned char ralc; // the 8 bit RALC register
    volatile unsigned char wsrc; // the 8 bit WSRC register
    volatile unsigned char wslc; // the 8 bit WSLC register
    volatile unsigned int ldata;
    volatile unsigned int rdata;
};

// Initialize the audio port structure
struct audio_t *const audiop = (struct audio_t *) AUDIO_BASE;

// Circular buffer and index for implementing the echo effect
int echoBuffer[BUFFER_SIZE];
int echoIndex = 0; // Current position in the echo buffer

int main(void) {
    // Initialize the echo buffer
    for (int i = 0; i < BUFFER_SIZE; i++) {
        echoBuffer[i] = 0;
    }

    int left, right;

    while (1) {
        if (audiop->rarc > 0) { // Check if there is data to read
            // Load the input samples
            left = audiop->ldata;
            right = audiop->rdata;


            // Mix the echo with the current input
            left += echoBuffer[echoIndex] * DAMPING_FACTOR;
            right += echoBuffer[echoIndex] * DAMPING_FACTOR;

            // Store the mixed sample in the buffer (to be used as echo for future samples)
            echoBuffer[echoIndex] = (left + right) / 2; // Simple mono mix for the echo

            // Output the mixed samples
            audiop->ldata = left;
            audiop->rdata = right;

            // Move to the next position in the circular buffer
            echoIndex = (echoIndex + 1) % BUFFER_SIZE;
        }
    }
}

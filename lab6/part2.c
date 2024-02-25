/* Here is a new version of the code given on Wednesday, using structs */
#define AUDIO_BASE 0xFF203040
int main(void) {
	// Audio port structure
	struct audio_t {
	volatile unsigned int control; // The control/status register
	volatile unsigned char rarc; // the 8 bit RARC register
	volatile unsigned char ralc; // the 8 bit RALC register
	volatile unsigned char wsrc; // the 8 bit WSRC register
	volatile unsigned char wslc; // the 8 bit WSLC register
	volatile unsigned int ldata;
	volatile unsigned int rdata;
	};

	/* we don't need to 'reserve memory' for this, it is already there
	so we just need a pointer to this structure */
	struct audio_t *const audiop = ((struct audio_t *) AUDIO_BASE);

	// to hold values of samples
	int left, right;

	// infinite loop checking the RARC to see if there is at least a single
	// entry in the input fifos. If there is, just copy it over to the output fifo.
	// The timing of the input fifo controls the timing of the output

	while (1) {
		if ( audiop->rarc > 0){ // check RARC to see if there is data to read
			// load both input microphone channels - just get one sample from each
			left = audiop->ldata; // load the left input fifo
			right = audiop->rdata; // load the right input fifo
			audiop->ldata = left; // store to the left output fifo
			audiop->rdata = right; // store to the right output fifo
		}
	}
}

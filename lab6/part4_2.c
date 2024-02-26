
/*
delay of 0.4s

sampling period of 0.000125s

delay lasts for 3200 samples

*/

struct audio_t {
    volatile unsigned int control;
    volatile unsigned char rarc;
    volatile unsigned char ralc;
    volatile unsigned char wsrc;
    volatile unsigned char wslc;
    volatile unsigned int left;
    volatile unsigned int right;
};


int main() {
    struct audio_t *audioPtr = 0xff203040;

    int head = 0;
    // sort of a ring buffer; starting from head, going left (and wrapping around) gives samples from newest to oldest
    // this also means the entry to the right of head (with wrapping around) is the oldest entry
    int outputs[3199] = {0}; 
    while (1) {
        if (audioPtr->rarc > 0 && audioPtr->ralc > 0) {
            outputs[head] = audioPtr->right; // this is read then thrown away
            outputs[head] = audioPtr->left + 0.4 * outputs[(head+1)%3200];

            audioPtr->left = outputs[head];
            audioPtr->right = outputs[head];
            head = (head+1)%3200;
        }
    }
}

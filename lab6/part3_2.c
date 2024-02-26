
/*
10 switches, 1024 settings (0-1023 unsigned)

all off = 100Hz
all on = 2000Hz

target frequency = 100Hz + (swValue/1023) * 1900Hz

sampling rate = 8000Hz
sampling period = 125 mus

to achieve period T:
 - T/(125 mus) samples per period
 - half should be high, half should be low

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
    volatile int *swPtr = 0xff200040;
    struct audio_t *audioPtr = 0xff203040;

    double targetFreq;
    int halfPeriodSampleNum = 0;
    int currSampleCount = 0;
    int audioVal = 0;

    while (1) {
        targetFreq = 100 + ((double) ((*swPtr) & 0x3ff) / 1023) * 1900;
        halfPeriodSampleNum = (int) ((8000/targetFreq) / 2);

        if (currSampleCount >= halfPeriodSampleNum) {
            currSampleCount = 0;
            if (audioVal) {
                audioVal = 0;
            } else {
                audioVal = 0xffffff;
            }
        }

        if (audioPtr->wsrc > 0 && audioPtr->wslc > 0) {
            audioPtr->left = audioVal;
            audioPtr->right = audioVal; 
        }

        currSampleCount++;
    }
}


#include <stdlib.h>

volatile int pixel_buffer_start; // global variable

void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, int color);
void swap(int *a, int *b);
int abs(int a);
void vsyncWait();
void drawBox(int i, char erase);

short int Buffer1[240][512]; // 240 rows, 512 (320 + padding) columns
short int Buffer2[240][512];


// 2nd index: [0] is most recent value, [1] is one frame ago, [2] is two frames ago
int boxX[8][3], boxY[8][3]; // x & y of the upper left corner of the 2x2 box
int dx[8], dy[8];
short int boxColor[8];
short int colors[10] = {0xffff, 0xf800, 0x7e0, 0x001f, 0xF81F, 0xFFE0, 0x07FF, 0x4380, 0x0384, 0x8384};


int main(void)
{


    for (int i = 0; i < 8; ++i) {
        boxX[i][0] = rand() % 319; // 319 and not 320, bc the box is 2x2, and none of it can go offscreen
        boxY[i][0] = rand() % 239;
        dx[i] = ((rand() % 2) * 2) - 1; // -1 or 1
        dy[i] = ((rand() % 2) * 2) - 1;
        boxColor[i] = colors[rand() % 10];
    }

    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
    // initialize location and direction of rectangles(not shown)

    /* set front pixel buffer to Buffer 1 */
    *(pixel_ctrl_ptr + 1) = (int) &Buffer1; // first store the address in the  back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    vsyncWait();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer

    /* set back pixel buffer to Buffer 2 */
    *(pixel_ctrl_ptr + 1) = (int) &Buffer2;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen(); // pixel_buffer_start points to the pixel buffer

    while (1)
    {

        for (int i = 0; i < 8; ++i) {
            drawBox(i, 1);
            draw_line(boxX[i][2], boxY[i][2], boxX[(i+1)%8][2], boxY[(i+1)%8][2], 0);
        }

        for (int i = 0; i < 8; ++i) {
            drawBox(i, 0);
            draw_line(boxX[i][0], boxY[i][0], boxX[(i+1)%8][0], boxY[(i+1)%8][0], boxColor[i]);
        }

        for (int i = 0; i < 8; ++i) {
            boxX[i][2] = boxX[i][1];
            boxY[i][2] = boxY[i][1];

            boxX[i][1] = boxX[i][0];
            boxY[i][1] = boxY[i][0];

            int x = boxX[i][0];
            int y = boxY[i][0];
            if (x == 0) {
                dx[i] = 1;
            } else if (x == 318) {
                dx[i] = -1;
            } 
            if (y == 0) {
                dy[i] = 1;
            } else if (y == 238) {
                dy[i] = -1;
            }
            boxX[i][0] += dx[i];
            boxY[i][0] += dy[i];
        }

        vsyncWait(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }
}

void drawBox(int i, char erase) {
    if (erase == 1) {
        plot_pixel(boxX[i][2], boxY[i][2], 0);
        plot_pixel(boxX[i][2]+1, boxY[i][2], 0);
        plot_pixel(boxX[i][2], boxY[i][2]+1, 0);
        plot_pixel(boxX[i][2]+1, boxY[i][2]+1, 0);
    } else {
        plot_pixel(boxX[i][0], boxY[i][0], boxColor[i]);
        plot_pixel(boxX[i][0]+1, boxY[i][0], boxColor[i]);
        plot_pixel(boxX[i][0], boxY[i][0]+1, boxColor[i]);
        plot_pixel(boxX[i][0]+1, boxY[i][0]+1, boxColor[i]);
    }
}

void vsyncWait() {
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    *pixel_ctrl_ptr = 1;
    int status = *(pixel_ctrl_ptr + 3) & 1;
    while (status != 0) {
        status = *(pixel_ctrl_ptr + 3) & 1;
    }
}

int abs(int a) {
    if (a < 0) {
        return -a;
    }
    return a;
}

void clear_screen() {
    for (int x = 0; x < 320; ++x) {
        for (int y = 0; y < 240; ++y) {
            plot_pixel(x, y, 0);
        }
    }
}

void draw_line(int x0, int y0, int x1, int y1, int color) {
    char steep = 0;
    if (abs(y1-y0) > abs(x1-x0)) {
        steep = 1;
    }

    if (steep == 1) {
        swap(&x0, &y0);
        swap(&x1, &y1);
    }
    if (x0 > x1) {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }

    int dx = x1 - x0;
    int dy = abs(y1 - y0);
    int error = -(dx/2);
    int y = y0;

    int ystep = 1;
    if (y0 > y1) {
        ystep = -1;
    }

    for (int x = x0; x <= x1; ++x) {
        if (steep == 1) {
            plot_pixel(y, x, color);
        } else {
            plot_pixel(x, y, color);
        }
        error = error + dy;
        if (error > 0) {
            y = y + ystep;
            error = error - dx;
        }
    }
}

void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}


void plot_pixel(int x, int y, short int line_color)
{
    volatile short int *one_pixel_address;
    one_pixel_address = pixel_buffer_start + (y << 10) + (x << 1);
    *one_pixel_address = line_color;
}



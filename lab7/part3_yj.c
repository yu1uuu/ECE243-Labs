#include <stdlib.h>

// Global variable to store the start address of the current pixel buffer.
volatile int pixel_buffer_start; 

// Function prototypes for graphics operations.
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, int color);
void swap(int *a, int *b);
int abs(int a);
void vsyncWait();
void drawBox(int i, char erase);

// Two frame buffers for double buffering, allowing for smooth animations.
short int Buffer1[240][512]; // First buffer, 240 rows by 512 columns (with padding).
short int Buffer2[240][512]; // Second buffer, same dimensions.

// Position history (current, -1 frame, -2 frames) for up to 8 boxes.
int boxX[8][3], boxY[8][3];
// Velocity vectors for each box in x and y directions.
int dx[8], dy[8];
// Color for each box.
short int boxColor[8];
// Predefined color palette.
short int colors[10] = {0xffff, 0xf800, 0x7e0, 0x001f, 0xF81F, 0xFFE0, 0x07FF, 0x4380, 0x0384, 0x8384};

int main(void) {
    // Initialize box positions, velocities, and colors randomly.
    for (int i = 0; i < 8; ++i) {
        // Positions are within screen bounds, considering box dimensions to avoid clipping.
        boxX[i][0] = rand() % 319; 
        boxY[i][0] = rand() % 239;
        // Velocities are either -1 or 1 for x and y directions.
        dx[i] = ((rand() % 2) * 2) - 1;
        dy[i] = ((rand() % 2) * 2) - 1;
        // Random color assignment from predefined palette.
        boxColor[i] = colors[rand() % 10];
    }

    // Setup pixel buffer controller address and configure double buffering.
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // Set front buffer to Buffer1.
    *(pixel_ctrl_ptr + 1) = (int) &Buffer1;
    // Wait for vsync to swap front and back buffers.
    vsyncWait();
    // After the swap, pixel_buffer_start points to Buffer1 for drawing.
    pixel_buffer_start = *pixel_ctrl_ptr;
    // Clear the screen.
    clear_screen();

    // Set back buffer to Buffer2 for the next drawing phase.
    *(pixel_ctrl_ptr + 1) = (int) &Buffer2;
    // Now draw on Buffer2.
    pixel_buffer_start = *(pixel_ctrl_ptr + 1);
    // Clear the back buffer to start with a blank canvas.
    clear_screen();

    // Main animation loop.
    while (1) {
        // Erase old boxes and lines by drawing them in background color.
        for (int i = 0; i < 8; ++i) {
            drawBox(i, 1); // Erase the box.
            draw_line(boxX[i][2], boxY[i][2], boxX[(i+1)%8][2], boxY[(i+1)%8][2], 0); // Erase connecting lines.
        }

        // Draw new boxes and lines in their current positions.
        for (int i = 0; i < 8; ++i) {
            drawBox(i, 0); // Draw the box.
            draw_line(boxX[i][0], boxY[i][0], boxX[(i+1)%8][0], boxY[(i+1)%8][0], boxColor[i]); // Draw connecting lines.
        }

        // Update positions based on velocities and screen boundaries.
        for (int i = 0; i < 8; ++i) {
            // Update position history.
            boxX[i][2] = boxX[i][1];
            boxY[i][2] = boxY[i][1];
            boxX[i][1] = boxX[i][0];
            boxY[i][1] = boxY[i][0];

            // Adjust position and direction if a box hits screen boundaries.
            int x = boxX[i][0];
            int y = boxY[i][0];
            if (x == 0 || x == 318) dx[i] = -dx[i]; // Reverse x direction.
            if (y == 0 || y == 238) dy[i] = -dy[i]; // Reverse y direction.

            // Apply velocity to update position.
            boxX[i][0] += dx[i];
            boxY[i][0] += dy[i];
        }

        // Wait for vsync and swap buffers to display the drawn frame.
        vsyncWait();
        // Update pixel_buffer_start to point to the new back buffer for the next frame.
        pixel_buffer_start = *(pixel_ctrl_ptr + 1);
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



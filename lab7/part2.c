#include <stdbool.h>

int pixel_buffer_start;  // Global variable location of frame buffer

void plot_pixel(int x, int y, short int line_colour) {
    volatile short int *one_pixel_address;

    one_pixel_address = pixel_buffer_start + (y << 10) + (x << 1);

    *one_pixel_address = line_colour;
}

void clear_screen() {
    int x, y;

    for (x = 0; x < 320; x++)
        for (y = 0; y < 240; y++) plot_pixel(x, y, 0);
}

void swap(int *x, int *y) {
  int temp = *x;
  *x = *y;
  *y = temp;
}

void draw_line(int x0, int y0, int x1, int y1, short int line_colour) {
    bool is_steep = abs(y1 - y0) > abs(x1 - x0);
    if (is_steep) {
        swap(&x0, &y0);
        swap(&x1, &y1);
    } else if (x0 > x1) {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }

    int deltax = x1 - x0;
    int deltay = abs(y1 - y0);

    int error = -(deltax / 2);
    int y = y0;
    int y_step;

    if (y0 < y1) {
        y_step = 1;
    } else {
        y_step = -1;
    }

    for (int x = x0; x <= x1; x++) {
        if (is_steep) {
            plot_pixel(y, x, line_colour);
        } else {
            plot_pixel(x, y, line_colour);
        }
        error = error + deltay;

        if (error > 0) {
            y = y + y_step;
            error = error - deltax;
        }
    }
}

void erase_line(int x0, int y0, int x1, int y1, short int line_colour) {
    draw_line(x0, y0, x1, y1, 0x0000);
}

int main(void) {
    volatile int *pixel_ctrl_ptr = (int *)0xFF203020;
    volatile int *status_register = (int *)0xFF20302C;
	
    // Read location of the pixel buffer from the pixel buffer controller 
    pixel_buffer_start = *pixel_ctrl_ptr;

    int x0 = 0;
    int y0 = 150;
    int x1 = 319;
    int y1 = 150;
    short int line_colour = 0x07E0; // Green line
    bool move_up = true;

    clear_screen();
	
    draw_line(x0, y0, x1, y1, line_colour);
	
    while (1) {
        *pixel_ctrl_ptr = 1;
		
		while ((*status_register) & 0x1) {
			// Wait for 1/60th of a second (wait for status register S bit to go to 0)
		}
        
        erase_line(x0, y0, x1, y1, line_colour);

        if (move_up) {
            y0--;
            y1--;
            if (y0 == 0) {
                move_up = false;
            }
        } else {
            y0++;
            y1++;
            if (y0 == 239) {
                move_up = true;
            }
        }

        draw_line(x0, y0, x1, y1, line_colour);
    }
}

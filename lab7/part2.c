//vga in de1soc redraws screen every 1/60th second. 
//use frame buffer to synchronize with the vertical synchronization cycle to ensure image is changed only once every 1/60th second. 
//synchronizing is done by writing 1 into Buffer register then waiting until bit S of status register =0 

//frame buffer swap can be used to sync vga controller via S bit in status register

//write a c program that moves horizontal line up and down the screen and bounces the line off the top and bottom. 
//1. clear screen 
//2. draw line at starting row on the screen 
//3. endless loop to erase the line by drawing the line using black and redraw it one row above or below 
//4. when line reaches edges it should move opposite way

#include <stdio.h>
#include <stdbool.h>

int pixel_buffer_start;  // global variable location of frame buffer

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

void swap(int *a, int *b) {
  int temp = *a;
  *a = *b;
  *b = temp;
}

void draw_line(int x0, int y0, int x1, int y1, short int color){

    int y_step = 0; 
    bool steep= abs(y1-y0) > abs(x1-x0); 
    if (steep){ 
        swap(&x0, &y0);
        swap(&x1, &y1);
    }

    else if (x0>x1){
        swap(&x0, &x1);
        swap(&y0, &y1);
    }

    int deltax = x1 - x0;
    int deltay = abs(y1 - y0);
    int error = -(deltax / 2); 

    int y = y0; 
  

    if (y0 < y1){ 
        y_step =1 ; 
    }
    else{
        y_step = -1; 
    }

    for (int x= x0; x<= x1; x++){
        if (steep){
            plot_pixel(y,x,color); 
        }
        else{
            plot_pixel(x,y,color); 
        }

        error = error + deltay; 
        if (error >0){
            y += y_step; 
            error -= deltax; 
        }
    }


}
void erase_line(int x0, int y0, int x1, int y1, short int line_colour) {
    draw_line(x0, y0, x1, y1, 0);
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

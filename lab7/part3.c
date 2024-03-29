#include <stdlib.h>

volatile int pixel_buffer_start; // global variable
short int Buffer1[240][512]; // 240 rows, 512 (320 + padding) columns
short int Buffer2[240][512];


//given
void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

//draws a line from x1, y1 to x2, y2. Requires plotpixel to run

void draw_line(int x1, int y1, int x2, int y2, int colour) {
	int is_steep = 0;
	int deltay = y2 - y1;
	int deltax = x2 - x1;
	int error = (-1)*(deltax / 2);

	//checking if deltay is positive
	if (deltay < 0) {
		deltay = deltay * (-1);
	}

	//finds it the slope is greater than 1
	if (((deltax >= 0) && (deltay > deltax)) || ((deltax < 0) && (deltay > (deltax * (-1))))) {
		is_steep = 1;
	}
	
	//if slope greater than one trades variables to switch from y/x to x/y
	if (is_steep) {
		int temp = x1;
		x1 = y1;
		y1 = temp;

		temp = x2;
		x2 = y2;
		y2 = temp;
	}
	
	//ensures x2 is greater than x1
	if (x1 > x2) {
		int temp = x1;
		x1 = x2;
		x2 = temp;

		temp = y1;
		y1 = y2;
		y2 = temp;
	}
	deltay = y2 - y1;
	deltax = x2 - x1;
	error = (-1)*(deltax / 2);
	int y = y1;
	int y_step;

	if (deltay < 0) {
		deltay = deltay * (-1);
	}

	//determines which way to increment y
	if (y1 < y2) {
		y_step = 1;
	}
	else {
		y_step = -1;
	}

	int x = 0;

	//plots all the pixels in the line
	for (x = x1; x <= x2; x++) {
		if (is_steep) {
			plot_pixel(y, x, colour);
		}
		else {
			plot_pixel(x, y, colour);
		}

		error = error + deltay;

		if (error >= 0) {
			y = y + y_step;
			error = error - deltax;
		}
	}	
}

void draw_rectangle(int x1, int y1, int size, int colour) {
	int x;
	
	for (x = x1; x < (size + x1); x++){
		draw_line(x, y1, x, (size + y1), colour);
	}
}

//writes all pixels to black
void clear_screen() {
	int x = 0;
	
	for (x = 0; x < 320; x++) {
		int y = 0;
		
		for (y = 0; y < 240; y++) {
			plot_pixel(x, y, 0);
		}
	}
}

//waits for the S value in the registry to change to 0 indication the frame is drawn
void wait_for_vsync(){
	volatile int *pixel_ctrl_ptr = (int*)0xFF203020;
	register int status;
	
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3);
	while((status & 0x01) != 0){
		status = *(pixel_ctrl_ptr +3);
	}
}

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
    // initialize location and direction of rectangles(not shown)
	/* set front pixel buffer to Buffer 1 */
    *(pixel_ctrl_ptr + 1) = (int) &Buffer1; // first store the address in the  back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer

    /* set back pixel buffer to Buffer 2 */
    *(pixel_ctrl_ptr + 1) = (int) &Buffer2;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen(); // pixel_buffer_start points to the pixel buffer

	int rectx[8];
	int recty[8];
	int right[8];
	int down[8];
    short int colour_box[8]; // Colour of each box

	int i = 0;
	int size = 3;
	
	
     // Initialize boxes
    for (int i = 0; i < 8; i++) {
        rectx[i] = rand() % (320 - 2); // Random initial x-coordinate within the visible area
        recty[i] = rand() % (240 - 2); // Random initial y-coordinate within the visible area
        right[i] = (rand() % 2);  // Random direction for x-axis (-1 or 1)
        down[i] = (rand() % 2); // Random direction for y-axis (-1 or 1)
        short int colors[10] = { 0xffff, 0xf800, 0x07e0, 0x001f, 0xf81f, 0x07ff, 0x4810, 0x915c, 0x0435, 0xffe0 }; // Array of random colors
        colour_box[i] = colors[rand() % 10]; // Get a random color from the array
    }

  
    while (1)
    {
		clear_screen();
		 /* Erase any boxes and lines that were drawn in the last iteration */
		for(i = 0; i < 8; i++){
			
			draw_rectangle(rectx[i], recty[i], size, 0);
			
			if(i != 7){
				draw_line(rectx[i], recty[i], rectx[i + 1], recty[i + 1], 0);
			}
			else{
				draw_line(rectx[i], recty[i], rectx[0], recty[0], 0);
			}
			
			if(rectx[i] == (319 - size)){
				right[i] = 0;
			}
			else if(rectx[i] == 0){
				right[i] = 1;
			}
			

			

		}
		
		for (i = 0; i < 8; i++){
						// code for updating the locations of boxes
			//checking for collisions
			if(recty[i] == (239 - size)){
				down[i] = 0;
			}
			else if(recty[i] == 0){
				down[i] = 1;
			}
			
			//incrementing x and y values
			if(right[i]){
				rectx[i] ++;
			}
			else{
				rectx[i] --;
			}
			
			if(down[i]){
				recty[i] ++;
			}
			else{
				recty[i] --;
			}
		}
		
	for(i = 0; i < 8; i++){
    draw_rectangle(rectx[i], recty[i], size, 0x001F); // Draw rectangles in blue

    // Draw lines with different colors
    short int line_color = 0xF800 + (i * 1000); // Start with red color and increment by 1000 for each line
    if(i != 7){
        draw_line(rectx[i], recty[i], rectx[i + 1], recty[i + 1], line_color);
    } else {
        draw_line(rectx[i], recty[i], rectx[0], recty[0], line_color);
    }
}

}
       
        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }


// code for subroutines (not shown)

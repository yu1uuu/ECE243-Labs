int pixel_buffer_start; // global variable

void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, int color);
void swap(int *a, int *b);
int abs(int a);
void vsyncWait();

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();

    int dy = 1;
    int lineY = 0;
    int lineX1 = 50;
    int lineX2 = 200;

    draw_line(lineX1, lineY, lineX2, lineY, 0x001F);

    while (1) {
        vsyncWait();
        draw_line(lineX1, lineY, lineX2, lineY, 0); // erase line
        if (lineY == 0) {
            dy = 1;
        } else if (lineY == 239) {
            dy = -1;
        }
        lineY += dy;
        draw_line(lineX1, lineY, lineX2, lineY, 0x001F);
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


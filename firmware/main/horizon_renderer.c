#include "horizon_renderer.h"

#include <stdlib.h>

#define RGB565_BLUE   0x259F
#define RGB565_BROWN  0x79E4
#define RGB565_WHITE  0xFFFF
#define RGB565_YELLOW 0xFFE0
#define RGB565_BLACK  0x0000

static void put_pixel(uint16_t *fb, int w, int h, int x, int y, uint16_t c)
{
    if ((unsigned)x < (unsigned)w && (unsigned)y < (unsigned)h) {
        fb[y * w + x] = c;
    }
}

static void hline(uint16_t *fb, int w, int h, int x0, int x1, int y, uint16_t c)
{
    if (y < 0 || y >= h) return;
    if (x0 > x1) { int t = x0; x0 = x1; x1 = t; }
    if (x0 < 0) x0 = 0;
    if (x1 >= w) x1 = w - 1;
    for (int x = x0; x <= x1; ++x) put_pixel(fb, w, h, x, y, c);
}

static void vline(uint16_t *fb, int w, int h, int x, int y0, int y1, uint16_t c)
{
    if (x < 0 || x >= w) return;
    if (y0 > y1) { int t = y0; y0 = y1; y1 = t; }
    if (y0 < 0) y0 = 0;
    if (y1 >= h) y1 = h - 1;
    for (int y = y0; y <= y1; ++y) put_pixel(fb, w, h, x, y, c);
}

void horizon_render_static(uint16_t *fb, int width, int height)
{
    const int cy = height / 2;

    for (int y = 0; y < height; ++y) {
        const uint16_t c = (y < cy) ? RGB565_BLUE : RGB565_BROWN;
        for (int x = 0; x < width; ++x) {
            fb[y * width + x] = c;
        }
    }

    /* Horizon line. */
    for (int dy = -2; dy <= 2; ++dy) {
        hline(fb, width, height, 45, width - 46, cy + dy, RGB565_WHITE);
    }

    /* Simple pitch ladder: 5-degree visual test spacing, not yet AHRS-scaled. */
    for (int step = 1; step <= 4; ++step) {
        int offset = step * 34;
        int half = (step % 2) ? 42 : 62;
        hline(fb, width, height, width/2 - half, width/2 + half, cy - offset, RGB565_WHITE);
        hline(fb, width, height, width/2 - half, width/2 + half, cy + offset, RGB565_WHITE);
    }

    /* Fixed aircraft symbol. */
    for (int dy = -2; dy <= 2; ++dy) {
        hline(fb, width, height, width/2 - 82, width/2 - 18, cy + 26 + dy, RGB565_YELLOW);
        hline(fb, width, height, width/2 + 18, width/2 + 82, cy + 26 + dy, RGB565_YELLOW);
        hline(fb, width, height, width/2 - 18, width/2 + 18, cy + 36 + dy, RGB565_YELLOW);
    }
    vline(fb, width, height, width/2, cy + 18, cy + 38, RGB565_YELLOW);

    /* Centre datum. */
    for (int d = -5; d <= 5; ++d) {
        put_pixel(fb, width, height, width/2 + d, cy, RGB565_BLACK);
        put_pixel(fb, width, height, width/2, cy + d, RGB565_BLACK);
    }
}

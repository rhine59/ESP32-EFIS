#pragma once

#include <stdint.h>

#define AH_DISPLAY_WIDTH  480
#define AH_DISPLAY_HEIGHT 480

void horizon_render_static(uint16_t *fb, int width, int height);

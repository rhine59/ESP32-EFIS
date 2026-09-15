#pragma once

#include <stdint.h>

#define AH_DISPLAY_WIDTH  480
#define AH_DISPLAY_HEIGHT 480

/* Render the moving attitude background and pitch ladder. The aircraft symbol
   remains fixed while the horizon translates with pitch and rotates with roll. */
void horizon_render(uint16_t *fb, int width, int height,
                    float pitch_deg, float roll_deg);

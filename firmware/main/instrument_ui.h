#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"

typedef enum {
    PANEL_HORIZON = 0,
    PANEL_ALTIMETER,
    PANEL_COMPASS,
    PANEL_COUNT
} instrument_panel_t;

typedef struct {
    instrument_panel_t panel;
    bool settings_active;
    int qnh_hpa;
    int heading_bug_deg;
    int brightness_percent;
} instrument_ui_t;

/* Loads defaults then restores last panel/settings from NVS when available. */
void instrument_ui_init(instrument_ui_t *ui);
/* Poll every ~10 ms. Short push cycles panels; long push enters/exits settings. */
esp_err_t instrument_ui_poll(instrument_ui_t *ui, bool *redraw);
/* Persist current panel, QNH, heading bug and brightness. */
esp_err_t instrument_ui_save(const instrument_ui_t *ui);

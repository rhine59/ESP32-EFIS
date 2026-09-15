#include "instrument_ui.h"

#include "mcp23008.h"
#include "pins.h"

#define LONG_PRESS_POLLS 80 /* ~800 ms at a 10 ms poll interval */

void instrument_ui_init(instrument_ui_t *ui)
{
    *ui = (instrument_ui_t){
        .panel = PANEL_HORIZON,
        .settings_active = false,
        .qnh_hpa = 1013,
        .heading_bug_deg = 0,
        .brightness_percent = 100,
    };
}

esp_err_t instrument_ui_poll(instrument_ui_t *ui, bool *redraw)
{
    static bool initialized;
    static uint8_t last_ab;
    static bool last_button = true;
    static unsigned held_polls;
    static bool long_fired;
    uint8_t gpio;
    esp_err_t err = mcp23008_read_gpio(&gpio);
    if (err != ESP_OK) return err;

    *redraw = false;
    const bool a = (gpio & (1u << IOX_ENCODER_A)) != 0;
    const bool b = (gpio & (1u << IOX_ENCODER_B)) != 0;
    const bool button = (gpio & (1u << IOX_ENCODER_PUSH)) != 0;
    const uint8_t ab = (a ? 2u : 0u) | (b ? 1u : 0u);

    if (!initialized) {
        initialized = true;
        last_ab = ab;
        last_button = button;
        return ESP_OK;
    }

    /* Decode only stable detent transitions returning to 11. This deliberately
       favours predictable cockpit operation over maximum encoder sensitivity. */
    if (ui->settings_active && ab == 3 && last_ab != 3) {
        int delta = (last_ab == 1) ? +1 : (last_ab == 2) ? -1 : 0;
        if (delta) {
            if (ui->panel == PANEL_ALTIMETER) {
                ui->qnh_hpa += delta;
                if (ui->qnh_hpa < 950) ui->qnh_hpa = 950;
                if (ui->qnh_hpa > 1050) ui->qnh_hpa = 1050;
            } else if (ui->panel == PANEL_COMPASS) {
                ui->heading_bug_deg = (ui->heading_bug_deg + delta + 360) % 360;
            } else {
                ui->brightness_percent += delta * 5;
                if (ui->brightness_percent < 10) ui->brightness_percent = 10;
                if (ui->brightness_percent > 100) ui->brightness_percent = 100;
            }
            *redraw = true;
        }
    }
    last_ab = ab;

    if (!button) {
        if (held_polls < LONG_PRESS_POLLS + 1) held_polls++;
        if (held_polls >= LONG_PRESS_POLLS && !long_fired) {
            ui->settings_active = !ui->settings_active;
            long_fired = true;
            *redraw = true;
        }
    } else if (!last_button) {
        if (!long_fired) {
            if (ui->settings_active) ui->settings_active = false;
            else ui->panel = (instrument_panel_t)((ui->panel + 1) % PANEL_COUNT);
            *redraw = true;
        }
        held_polls = 0;
        long_fired = false;
    }
    last_button = button;
    return ESP_OK;
}

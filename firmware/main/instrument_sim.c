#include "instrument_sim.h"

static int wrap_heading(int h) { h %= 360; return h < 0 ? h + 360 : h; }

const char *instrument_sim_scenario_name(instrument_sim_scenario_t s) {
    static const char *const n[SIM_SCENARIO_COUNT] = {
        "LEVEL","PITCH +10","PITCH -10","PITCH +20","PITCH -20",
        "BANK LEFT 30","BANK RIGHT 30","BANK LEFT 60","BANK RIGHT 60",
        "PITCH +10 BANK R30","ATTITUDE FAIL","RECOVERY LEVEL",
        "ALT 0","ALT 500","ALT 1000","ALT 2500","ALT 5000","ALT 9500",
        "ALT 9900","ALT 10000","ALT 10100","ALT 10500","ALT 12500",
        "ALT SWEEP","ALT FAIL","RECOVERY ALT","HDG NORTH","HDG NE",
        "HDG EAST","HDG SE","HDG SOUTH","HDG SW","HDG WEST","HDG NW",
        "HDG 350-010","HDG ROTATE","HEADING FAIL","GNSS EXCELLENT",
        "GNSS GOOD","GNSS FAIR","GNSS WEAK","GNSS POOR","GNSS STALE",
        "GNSS NO FIX","ALL FAIL"
    };
    return (unsigned)s < SIM_SCENARIO_COUNT ? n[s] : "UNKNOWN";
}

void instrument_sim_init(instrument_sim_t *s, bool e) {
    s->t = 0; s->scenario_t = 0; s->enabled = e; s->scenario = SIM_SCENARIO_LEVEL;
}
void instrument_sim_set_scenario(instrument_sim_t *s, instrument_sim_scenario_t sc) {
    if ((unsigned)sc >= SIM_SCENARIO_COUNT) sc = SIM_SCENARIO_LEVEL;
    s->scenario = sc; s->scenario_t = 0;
}
instrument_sim_scenario_t instrument_sim_next_scenario(instrument_sim_t *s) {
    instrument_sim_set_scenario(s, (instrument_sim_scenario_t)((s->scenario + 1) % SIM_SCENARIO_COUNT));
    return s->scenario;
}

void instrument_sim_step(instrument_sim_t *s, float dt, instrument_data_t *d) {
    if (!s->enabled) return;
    s->t += dt; s->scenario_t += dt;
    d->pitch_deg = 0; d->roll_deg = 0; d->attitude_valid = true;
    d->altitude_ft = 2500; d->altitude_valid = true;
    d->heading_deg = 0; d->heading_valid = true;
    /* Deterministic North Yorkshire development position. Synthetic only. */
    d->gps_latitude_deg = 54.0015413;
    d->gps_longitude_deg = -2.1407870;
    d->gps_horizontal_accuracy_m = 0.8f;
    d->gps_satellites_used = 12;
    d->gps_fix_type = GPS_FIX_3D;
    d->gps_valid = true;
    d->gps_stale = false;
    d->simulated = true;

    switch (s->scenario) {
    case SIM_SCENARIO_LEVEL: case SIM_SCENARIO_RECOVERY_LEVEL: break;
    case SIM_SCENARIO_PITCH_UP: d->pitch_deg = 10; break;
    case SIM_SCENARIO_PITCH_DOWN: d->pitch_deg = -10; break;
    case SIM_SCENARIO_PITCH_UP_20: d->pitch_deg = 20; break;
    case SIM_SCENARIO_PITCH_DOWN_20: d->pitch_deg = -20; break;
    case SIM_SCENARIO_BANK_LEFT: d->roll_deg = -30; break;
    case SIM_SCENARIO_BANK_RIGHT: d->roll_deg = 30; break;
    case SIM_SCENARIO_BANK_LEFT_60: d->roll_deg = -60; break;
    case SIM_SCENARIO_BANK_RIGHT_60: d->roll_deg = 60; break;
    case SIM_SCENARIO_COMBINED_UP_RIGHT: d->pitch_deg = 10; d->roll_deg = 30; break;
    case SIM_SCENARIO_ATTITUDE_FAIL: d->attitude_valid = false; break;
    case SIM_SCENARIO_ALT_0: d->altitude_ft = 0; break;
    case SIM_SCENARIO_ALT_500: d->altitude_ft = 500; break;
    case SIM_SCENARIO_ALT_1000: d->altitude_ft = 1000; break;
    case SIM_SCENARIO_ALT_2500: case SIM_SCENARIO_ALTITUDE_RECOVERY: d->altitude_ft = 2500; break;
    case SIM_SCENARIO_ALT_5000: d->altitude_ft = 5000; break;
    case SIM_SCENARIO_ALT_9500: d->altitude_ft = 9500; break;
    case SIM_SCENARIO_ALT_9900: d->altitude_ft = 9900; break;
    case SIM_SCENARIO_ALT_10000: d->altitude_ft = 10000; break;
    case SIM_SCENARIO_ALT_10100: d->altitude_ft = 10100; break;
    case SIM_SCENARIO_ALT_10500: d->altitude_ft = 10500; break;
    case SIM_SCENARIO_ALT_12500: d->altitude_ft = 12500; break;
    case SIM_SCENARIO_ALTITUDE_SWEEP: { int p = ((int)(s->scenario_t * 1000.0f)) % 10000; d->altitude_ft = p <= 5000 ? p : 10000 - p; break; }
    case SIM_SCENARIO_ALTITUDE_FAIL: d->altitude_valid = false; break;
    case SIM_SCENARIO_HEADING_NORTH: d->heading_deg = 0; break;
    case SIM_SCENARIO_HEADING_NE: d->heading_deg = 45; break;
    case SIM_SCENARIO_HEADING_EAST: d->heading_deg = 90; break;
    case SIM_SCENARIO_HEADING_SE: d->heading_deg = 135; break;
    case SIM_SCENARIO_HEADING_SOUTH: d->heading_deg = 180; break;
    case SIM_SCENARIO_HEADING_SW: d->heading_deg = 225; break;
    case SIM_SCENARIO_HEADING_WEST: d->heading_deg = 270; break;
    case SIM_SCENARIO_HEADING_NW: d->heading_deg = 315; break;
    case SIM_SCENARIO_HEADING_WRAP: d->heading_deg = wrap_heading(350 + (int)(s->scenario_t * 5.0f)); break;
    case SIM_SCENARIO_HEADING_ROTATE: d->heading_deg = wrap_heading((int)(s->scenario_t * 60.0f)); break;
    case SIM_SCENARIO_HEADING_FAIL: d->heading_valid = false; break;
    case SIM_SCENARIO_GNSS_EXCELLENT: d->gps_horizontal_accuracy_m = 0.8f; break;
    case SIM_SCENARIO_GNSS_GOOD: d->gps_horizontal_accuracy_m = 2.0f; break;
    case SIM_SCENARIO_GNSS_FAIR: d->gps_horizontal_accuracy_m = 6.0f; break;
    case SIM_SCENARIO_GNSS_WEAK: d->gps_horizontal_accuracy_m = 18.0f; break;
    case SIM_SCENARIO_GNSS_POOR: d->gps_horizontal_accuracy_m = 45.0f; break;
    case SIM_SCENARIO_GNSS_STALE: d->gps_stale = true; break;
    case SIM_SCENARIO_GNSS_NO_FIX: d->gps_valid = false; d->gps_fix_type = GPS_FIX_NONE; d->gps_satellites_used = 0; break;
    case SIM_SCENARIO_ALL_FAIL:
        d->attitude_valid = d->altitude_valid = d->heading_valid = false;
        d->gps_valid = false; d->gps_stale = true; d->gps_fix_type = GPS_FIX_NONE;
        break;
    default: break;
    }
}

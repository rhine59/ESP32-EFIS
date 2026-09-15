#pragma once
#include <stdbool.h>
#include "instrument_screens.h"

typedef enum {
    SIM_SCENARIO_LEVEL = 0,
    SIM_SCENARIO_PITCH_UP,
    SIM_SCENARIO_PITCH_DOWN,
    SIM_SCENARIO_PITCH_UP_20,
    SIM_SCENARIO_PITCH_DOWN_20,
    SIM_SCENARIO_BANK_LEFT,
    SIM_SCENARIO_BANK_RIGHT,
    SIM_SCENARIO_BANK_LEFT_60,
    SIM_SCENARIO_BANK_RIGHT_60,
    SIM_SCENARIO_COMBINED_UP_RIGHT,
    SIM_SCENARIO_ATTITUDE_FAIL,
    SIM_SCENARIO_RECOVERY_LEVEL,
    SIM_SCENARIO_ALT_0,
    SIM_SCENARIO_ALT_500,
    SIM_SCENARIO_ALT_1000,
    SIM_SCENARIO_ALT_2500,
    SIM_SCENARIO_ALT_5000,
    SIM_SCENARIO_ALT_9500,
    SIM_SCENARIO_ALT_9900,
    SIM_SCENARIO_ALT_10000,
    SIM_SCENARIO_ALT_10100,
    SIM_SCENARIO_ALT_10500,
    SIM_SCENARIO_ALT_12500,
    SIM_SCENARIO_ALTITUDE_SWEEP,
    SIM_SCENARIO_ALTITUDE_FAIL,
    SIM_SCENARIO_ALTITUDE_RECOVERY,
    SIM_SCENARIO_HEADING_NORTH,
    SIM_SCENARIO_HEADING_NE,
    SIM_SCENARIO_HEADING_EAST,
    SIM_SCENARIO_HEADING_SE,
    SIM_SCENARIO_HEADING_SOUTH,
    SIM_SCENARIO_HEADING_SW,
    SIM_SCENARIO_HEADING_WEST,
    SIM_SCENARIO_HEADING_NW,
    SIM_SCENARIO_HEADING_WRAP,
    SIM_SCENARIO_HEADING_ROTATE,
    SIM_SCENARIO_HEADING_FAIL,
    SIM_SCENARIO_ALL_FAIL,
    SIM_SCENARIO_COUNT
} instrument_sim_scenario_t;

typedef struct { float t; float scenario_t; bool enabled; instrument_sim_scenario_t scenario; } instrument_sim_t;
void instrument_sim_init(instrument_sim_t *sim, bool enabled);
void instrument_sim_step(instrument_sim_t *sim, float dt_s, instrument_data_t *data);
void instrument_sim_set_scenario(instrument_sim_t *sim, instrument_sim_scenario_t scenario);
instrument_sim_scenario_t instrument_sim_next_scenario(instrument_sim_t *sim);
const char *instrument_sim_scenario_name(instrument_sim_scenario_t scenario);

#pragma once
#include <stdbool.h>
#include "instrument_screens.h"

typedef struct { float t; bool enabled; } instrument_sim_t;
void instrument_sim_init(instrument_sim_t *sim, bool enabled);
/* Bench-only synthetic data. Never enable in flight builds. */
void instrument_sim_step(instrument_sim_t *sim, float dt_s, instrument_data_t *data);

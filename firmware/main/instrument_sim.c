#include "instrument_sim.h"
#include <math.h>

void instrument_sim_init(instrument_sim_t *s, bool enabled)
{
    s->t = 0;
    s->enabled = enabled;
}

void instrument_sim_step(instrument_sim_t *s, float dt, instrument_data_t *d)
{
    if (!s->enabled) {
        return;
    }

    s->t += dt;
    d->pitch_deg = 8.0f * sinf(s->t * 0.45f);
    d->roll_deg = 28.0f * sinf(s->t * 0.31f);
    d->attitude_valid = true;
    d->altitude_ft = 2450 + (int)(900.0f * sinf(s->t * 0.11f));
    d->altitude_valid = true;
    d->heading_deg = ((int)(s->t * 12.0f)) % 360;
    d->heading_valid = true;
}

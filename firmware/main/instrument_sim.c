#include "instrument_sim.h"

static int wrap_heading(int heading)
{
    heading %= 360;
    return heading < 0 ? heading + 360 : heading;
}

const char *instrument_sim_scenario_name(instrument_sim_scenario_t scenario)
{
    static const char *const names[SIM_SCENARIO_COUNT] = {
        "LEVEL",
        "PITCH +10",
        "PITCH -10",
        "BANK LEFT 30",
        "BANK RIGHT 30",
        "ALTITUDE 1000-5000",
        "HEADING 350-010",
        "ATTITUDE FAIL",
        "ALTITUDE FAIL",
        "HEADING FAIL",
        "ALL FAIL",
    };
    return ((unsigned)scenario < SIM_SCENARIO_COUNT) ? names[scenario] : "UNKNOWN";
}

void instrument_sim_init(instrument_sim_t *s, bool enabled)
{
    s->t = 0.0f;
    s->scenario_t = 0.0f;
    s->enabled = enabled;
    s->scenario = SIM_SCENARIO_LEVEL;
}

void instrument_sim_set_scenario(instrument_sim_t *s, instrument_sim_scenario_t scenario)
{
    if ((unsigned)scenario >= SIM_SCENARIO_COUNT) {
        scenario = SIM_SCENARIO_LEVEL;
    }
    s->scenario = scenario;
    s->scenario_t = 0.0f;
}

instrument_sim_scenario_t instrument_sim_next_scenario(instrument_sim_t *s)
{
    instrument_sim_set_scenario(s, (instrument_sim_scenario_t)((s->scenario + 1) % SIM_SCENARIO_COUNT));
    return s->scenario;
}

void instrument_sim_step(instrument_sim_t *s, float dt, instrument_data_t *d)
{
    if (!s->enabled) {
        return;
    }

    s->t += dt;
    s->scenario_t += dt;

    /* Every scenario starts from an explicit, known, valid reference state. */
    d->pitch_deg = 0.0f;
    d->roll_deg = 0.0f;
    d->attitude_valid = true;
    d->altitude_ft = 2500;
    d->altitude_valid = true;
    d->heading_deg = 0;
    d->heading_valid = true;
    d->simulated = true;

    switch (s->scenario) {
    case SIM_SCENARIO_LEVEL:
        break;
    case SIM_SCENARIO_PITCH_UP:
        d->pitch_deg = 10.0f;
        break;
    case SIM_SCENARIO_PITCH_DOWN:
        d->pitch_deg = -10.0f;
        break;
    case SIM_SCENARIO_BANK_LEFT:
        d->roll_deg = -30.0f;
        break;
    case SIM_SCENARIO_BANK_RIGHT:
        d->roll_deg = 30.0f;
        break;
    case SIM_SCENARIO_ALTITUDE_SWEEP: {
        const int phase = ((int)(s->scenario_t * 250.0f)) % 8000;
        d->altitude_ft = phase <= 4000 ? 1000 + phase : 9000 - phase;
        break;
    }
    case SIM_SCENARIO_HEADING_WRAP:
        d->heading_deg = wrap_heading(350 + (int)(s->scenario_t * 4.0f));
        break;
    case SIM_SCENARIO_ATTITUDE_FAIL:
        d->attitude_valid = false;
        break;
    case SIM_SCENARIO_ALTITUDE_FAIL:
        d->altitude_valid = false;
        break;
    case SIM_SCENARIO_HEADING_FAIL:
        d->heading_valid = false;
        break;
    case SIM_SCENARIO_ALL_FAIL:
        d->attitude_valid = false;
        d->altitude_valid = false;
        d->heading_valid = false;
        break;
    default:
        break;
    }
}

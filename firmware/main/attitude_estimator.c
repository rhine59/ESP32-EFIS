#include "attitude_estimator.h"

#include <math.h>
#include <stddef.h>
#include <string.h>

#define RAD_TO_DEG 57.2957795131f
#define COMPLEMENTARY_GYRO_WEIGHT 0.98f
#define MIN_ACCEL_NORM_G 0.70f
#define MAX_ACCEL_NORM_G 1.30f
#define MAX_SAMPLE_INTERVAL_MS 100u
#define ATTITUDE_STALE_MS 250u

static bool finite_sample(const bmi088_sample_t *s)
{
    return isfinite(s->accel_x_g) && isfinite(s->accel_y_g) &&
           isfinite(s->accel_z_g) && isfinite(s->gyro_x_dps) &&
           isfinite(s->gyro_y_dps) && isfinite(s->gyro_z_dps);
}

static void accel_angles(const bmi088_sample_t *s, float *pitch, float *roll)
{
    /* Input must be aircraft body axes: +X forward, +Y right, +Z down.
       Installation-axis mapping is deliberately kept outside this estimator. */
    *roll = atan2f(s->accel_y_g, s->accel_z_g) * RAD_TO_DEG;
    *pitch = atan2f(-s->accel_x_g,
                    sqrtf(s->accel_y_g * s->accel_y_g +
                          s->accel_z_g * s->accel_z_g)) * RAD_TO_DEG;
}

void attitude_estimator_init(attitude_estimator_t *state)
{
    if (state != NULL) memset(state, 0, sizeof(*state));
}

bool attitude_estimator_update(attitude_estimator_t *state,
                               const bmi088_sample_t *sample)
{
    if (state == NULL || sample == NULL || !finite_sample(sample)) {
        if (state != NULL) state->valid = false;
        return false;
    }

    const float norm = sqrtf(sample->accel_x_g * sample->accel_x_g +
                             sample->accel_y_g * sample->accel_y_g +
                             sample->accel_z_g * sample->accel_z_g);
    const bool gravity_usable = norm >= MIN_ACCEL_NORM_G && norm <= MAX_ACCEL_NORM_G;

    float accel_pitch = 0.0f;
    float accel_roll = 0.0f;
    if (gravity_usable) accel_angles(sample, &accel_pitch, &accel_roll);

    if (!state->initialized) {
        if (!gravity_usable) {
            state->valid = false;
            return false;
        }
        state->pitch_deg = accel_pitch;
        state->roll_deg = accel_roll;
        state->last_sample_ms = sample->timestamp_ms;
        state->initialized = true;
        state->valid = true;
        return true;
    }

    const uint32_t elapsed_ms = sample->timestamp_ms - state->last_sample_ms;
    if (elapsed_ms == 0u || elapsed_ms > MAX_SAMPLE_INTERVAL_MS) {
        state->last_sample_ms = sample->timestamp_ms;
        state->valid = false;
        return false;
    }

    const float dt = (float)elapsed_ms * 0.001f;
    float pitch = state->pitch_deg + sample->gyro_y_dps * dt;
    float roll = state->roll_deg + sample->gyro_x_dps * dt;

    if (gravity_usable) {
        const float a = COMPLEMENTARY_GYRO_WEIGHT;
        pitch = a * pitch + (1.0f - a) * accel_pitch;
        roll = a * roll + (1.0f - a) * accel_roll;
    }

    if (!isfinite(pitch) || !isfinite(roll) || fabsf(pitch) > 89.0f ||
        fabsf(roll) > 180.0f) {
        state->valid = false;
        return false;
    }

    state->pitch_deg = pitch;
    state->roll_deg = roll;
    state->last_sample_ms = sample->timestamp_ms;
    state->valid = true;
    return true;
}

void attitude_estimator_check_stale(attitude_estimator_t *state,
                                    uint32_t now_ms)
{
    if (state == NULL || !state->initialized) return;
    if ((uint32_t)(now_ms - state->last_sample_ms) > ATTITUDE_STALE_MS)
        state->valid = false;
}

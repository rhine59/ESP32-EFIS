#pragma once

#include <stdbool.h>

/*
 * Convert static pressure and selected QNH to indicated altitude.
 *
 * pressure_hpa: static pressure in hectopascals from the pressure sensor.
 * qnh_hpa:      pilot-selected sea-level pressure setting in hectopascals.
 * altitude_ft:  resulting indicated altitude in feet.
 *
 * Uses the ISA tropospheric barometric relation. Returns false for inputs
 * outside deliberately broad sanity limits so bad sensor/UI data cannot
 * silently become a plausible altitude.
 */
bool baro_altitude_from_pressure(float pressure_hpa, float qnh_hpa, int *altitude_ft);

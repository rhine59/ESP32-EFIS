#pragma once
#include <stddef.h>
/* Snapshot is safe, read-only and explicitly distinguishes unimplemented hardware tests. */
void recovery_diagnostics_json(char *out, size_t capacity);
void recovery_diagnostics_print(void);

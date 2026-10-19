#!/usr/bin/env python3
"""Offline boot-state fault matrix. Not an ESP-IDF or physical recovery test."""
import json
from dataclasses import dataclass


@dataclass(frozen=True)
class State:
    active: str = 'ota_0'
    candidate: str = 'ota_1'
    pending: bool = False
    candidate_verified: bool = False
    recovery_intact: bool = True


def transition(state: State, event: str) -> State:
    """Model only: power cuts never change boot selection or recovery contents."""
    if event == 'stage_complete':
        return State(state.active, state.candidate, False, True, state.recovery_intact)
    if event == 'power_cut_during_stage':
        return State(state.active, state.candidate, False, False, state.recovery_intact)
    if event == 'activate' and state.candidate_verified:
        return State(state.candidate, state.active, True, False, state.recovery_intact)
    if event in ('power_cut_before_activation', 'power_cut_after_activation'):
        return state
    if event in ('boot_health_failed', 'power_cut_during_pending_boot') and state.pending:
        return State(state.candidate, state.active, False, False, state.recovery_intact)
    if event == 'confirm_boot' and state.pending:
        raise ValueError('physical confirmation gates not modelled; refuse confirmation')
    if event == 'activate':
        raise ValueError('unverified candidate cannot be activated')
    raise ValueError('unsupported or inapplicable transition')


def audit():
    baseline = State()
    scenarios = {
        'interrupted_stage': ('power_cut_during_stage',),
        'completed_stage_power_cut': ('stage_complete', 'power_cut_before_activation'),
        'unverified_activation_refused': ('power_cut_during_stage', 'activate'),
        'pending_boot_interrupted': ('stage_complete', 'activate', 'power_cut_during_pending_boot'),
        'boot_health_failure': ('stage_complete', 'activate', 'boot_health_failed'),
        'confirmation_refused': ('stage_complete', 'activate', 'confirm_boot'),
    }
    results = {}
    for name, events in scenarios.items():
        state = baseline
        refused = False
        for event in events:
            try:
                state = transition(state, event)
            except ValueError:
                refused = True
                break
        results[name] = {'recovery_intact_in_model': state.recovery_intact,
                         'active_slot_in_model': state.active,
                         'refused': refused}
    return {'scope': 'offline-state-machine-only', 'scenarios': results,
            'hardware_rollback_verified': False,
            'power_interruption_physically_tested': False,
            'recovery_partition_physically_verified': False,
            'safe_to_flash_partition_b': False, 'decision': 'NO-GO'}


if __name__ == '__main__':
    print(json.dumps(audit(), indent=2))

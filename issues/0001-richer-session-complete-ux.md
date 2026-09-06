# 0001 — Richer "session complete" UX

**Status:** open (deferred surplus feature, not blocking any milestone)
**Filed:** 2026-09-06, during M3 (Feedback & settings)

## Summary

M3 implements the simplest possible session-complete behavior: once the
configured session length (in minutes, converted to a target cycle count for
the active pattern) is reached, `BreathingSession` auto-pauses and
`BreathwayView` swaps the circle animation for a static "Session complete /
Select to restart" text screen. Pressing Select resets and starts a fresh
run.

This is intentionally minimal. Possible richer follow-ups, roughly in order
of likely value:

- A short summary screen showing cycles completed / total elapsed time
  before returning to the "Select to restart" state.
- Auto-return to the watch face after a timeout (e.g. a few seconds) instead
  of waiting indefinitely on the complete screen, matching typical Garmin
  activity-summary UX.
- A distinct "session complete" haptic pattern (currently it reuses the
  same double-buzz as an inhale/exhale phase transition, since completion
  always coincides with wrapping back to phase 0 of a fresh cycle boundary
  — technically it's silent, since `advance()` auto-pauses *before* the
  session would enter a new phase and vibrate; worth double-checking this
  behavior feels right in practice on a real device).
- Optional: a light "confetti"/checkmark animation instead of plain text.

## Why deferred

Doesn't block core M3 functionality (haptics, session length, pattern
selection) and is more of a polish item — better suited for M4 (Polish) or
a dedicated follow-up once the core loop has been used for a while and the
plain version's rough edges are clearer.

## Notes for whoever picks this up

- `BreathwayView.onUpdate()` is where the current "Session complete" text is
  drawn (early-return branch guarded by `session.isComplete()`).
- `BreathwayView.togglePause()` is where restart-from-complete is handled.
- `BreathingSession.isComplete()` / `.cyclesCompleted()` / `.reset()` already
  provide the state needed for a richer summary screen.

# 0002 — Down button as a "reset session" shortcut once running

**Status:** open (feature request)
**Filed:** 2026-09-06

## Summary

Add a quick way to reset the current breathing session back to the start
(phase 0, elapsed 0, cycles completed 0) using the **down** button
(`onNextPage()` in `BehaviorDelegate` terms — Garmin's standard mapping for
the physical/virtual down button), once a session has actually started.

Currently the only session controls are:
- **Select** (`onSelect`) — toggle pause/resume, or restart-from-complete
  once the session has finished (see `BreathwayView.togglePause()`).
- **Menu** (`onMenu`, long-press Select) — opens the settings screen.
- **Back** (`onBack`) — exits the app (default `BehaviorDelegate` handling).

There's currently no way to abandon the current run and start over from
phase 0 without either waiting for it to complete or backing out of the app
entirely and relaunching.

## Proposed behavior

- Bind `BreathwayDelegate.onNextPage()` (down button) to call a new
  `BreathwayView.resetSession()` method, which calls
  `BreathingSession.reset()` and leaves the running/paused state as-is (i.e.
  resetting a running session keeps it running from phase 0; resetting a
  paused session stays paused at phase 0 — matching how `reset()` already
  behaves per its doc comment in `BreathingSession.mc`).
- Should probably be a no-op (or require the session to be actively
  started/paused, not brand new at phase 0 with zero elapsed) to avoid
  wasted haptic/redraw churn if pressed immediately at launch — minor
  polish, not a hard requirement.
- Consider whether down should also work from the "Session complete" screen
  as an alternative to Select-to-restart, or whether that would be
  confusingly redundant with the existing restart-on-Select behavior there.

## Why deferred

Not part of the M3 (Feedback & settings) scope that was just completed;
tracked here so it isn't lost. Reasonable candidate for M4 (Polish) or
whenever button-mapping/UX polish is next picked up.

## Related

- `issues/0004-standard-timer-ui.md` (filed 2026-09-21) adds a visual reset
  icon (circular arrow) once a session is running/paused. Both this issue's
  down-button shortcut and 0004's icon should route through the same
  `BreathwayView.resetSession()` / `BreathingSession.reset()` call rather
  than diverging into two separate reset code paths — the icon can be
  thought of as the visual affordance for the same action this issue wires
  to the down button.
- `issues/0005-idle-start-screen.md` (filed 2026-09-21) makes "phase 0, 0
  elapsed, not running" a real, commonly-reached idle state (not just a
  transient one at launch as it is today). That makes the "no-op when
  already at phase 0 with 0 elapsed" guard mentioned below more than minor
  polish once 0005 lands — pressing down on the idle start screen shouldn't
  cause redraw/haptic churn.

## Notes for whoever picks this up

- `BreathwayDelegate.mc` is where `onSelect()` / `onMenu()` / `onBack()` are
  currently overridden; add `onNextPage()` (or check the exact Garmin
  `BehaviorDelegate` method name for "down" on the target devices — some
  devices map it to `onNextPage()`, others may expose a distinct
  down-button behavior depending on device button layout) alongside them.
- `BreathingSession.reset()` already exists and does exactly what's needed
  state-wise (`source/BreathingSession.mc`); this is mostly a delegate/view
  wiring task, not new session-state logic.
- Should be covered by a unit test at the `BreathingSession` level only if
  new state-machine behavior is introduced beyond the existing `reset()`
  (e.g. if "no-op when already at phase 0 with 0 elapsed" is implemented,
  that's a small pure-logic addition worth testing directly).

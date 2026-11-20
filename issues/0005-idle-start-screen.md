# 0005 — Show a start screen instead of auto-starting the session on launch

**Status:** resolved (v0.4.0) — `BreathwayView.onShow()` no longer
auto-starts; the session opens idle ("Select to start") and Select starts
it. Idle = `!isRunning() && BreathingSession.isAtStart()`. Icon-based start
affordance still pending in 0004.
**Filed:** 2026-09-21

## Summary

Currently the app appears to begin the breathing session immediately when
launched. Instead, the app should open to an idle **start screen** and wait
for explicit user input (Select, or the new start icon from issue 0004)
before the `BreathingSession` timer/phase progression begins.

## Proposed behavior

- On `BreathwayApp`/`BreathwayView` initial load, the session should be
  created/reset but **not** running — i.e. `BreathingSession` starts in a
  paused/idle state at phase 0, elapsed 0, rather than auto-starting.
- `BreathwayView.onUpdate()` should render an idle "ready to start" screen
  in this state — ideally the same visual state as "not started" described
  in issue 0004 (start triangle + menu dots visible, no progress ring
  animation running).
- Pressing Select (`BreathwayDelegate.onSelect()` /
  `BreathwayView.togglePause()`) from this idle state starts the session
  for the first time, same as it currently resumes from a manual pause.
- Verify this doesn't conflict with existing pause/resume semantics in
  `BreathingSession`/`BreathwayView.togglePause()` — starting from idle and
  resuming from pause may already be the same code path depending on how
  `BreathingSession` currently initializes; if so this may be a smaller
  change than it sounds (e.g. just changing the initial `running`/`paused`
  flag rather than adding new states).

## Why filed

Auto-starting on launch is surprising and doesn't match standard Garmin
timer/activity app behavior (see issue 0004's reference screenshot, which
shows a stock Timer app that also waits at 00:00-ish with a start icon
before running). Users should be able to open the app, adjust settings via
the menu, and only start the breathing exercise when ready.

## Notes for whoever picks this up

- Check `BreathwayApp.mc` (entry point) and `BreathwayView.initialize()`/
  `onShow()` for where the session currently gets kicked off, and
  `BreathingSession.mc` for its constructor/initial state defaults.
- Should be straightforward to cover with a unit test in
  `test/BreathwayTests.mc` asserting a freshly constructed
  `BreathingSession` is not running/has zero elapsed time.

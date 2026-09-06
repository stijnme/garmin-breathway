# 0003 — Whole-session countdown display (mm:ss, counting down from session length to 0:00)

**Status:** open (feature request)
**Filed:** 2026-09-06

## Summary

In addition to (or instead of) the current per-phase countdown (e.g. "3"
seconds remaining in the current Inhale/Hold/Exhale phase), display a
**whole-session** countdown timer in `mm:ss` format, counting down from the
configured session length (default 5 minutes, see `BreathwaySettings`) to
`0:00` as the session progresses toward completion.

## Proposed behavior

- Format: `mm:ss`, e.g. `05:00` at the very start of a fresh 5-minute
  session, ticking down to `00:00` right as the session completes.
- Needs a way to compute "total seconds remaining in the whole session",
  not just "seconds remaining in the current phase". This requires knowing:
  - the per-cycle pattern duration (`BreathingSession.patternDurationSeconds()`
    already exists),
  - how many cycles remain (`targetCycles() - cyclesCompleted()`, minus the
    current partially-elapsed cycle),
  - and the elapsed time within the current phase/cycle.
  
  Likely a new `BreathingSession` accessor, e.g.
  `totalRemainingSeconds() as Number?` (returning `null` for an unlimited/
  free-run session where `targetCycles()` is `null`, since there's no total
  to count down from in that case).
- `BreathwayView.onUpdate()` would format that into `mm:ss` (simple
  `minutes.format("%02d") + ":" + seconds.format("%02d")`-style formatting)
  and draw it somewhere that doesn't clash with the existing phase name /
  per-phase countdown / "Paused" label layout — needs a small layout pass to
  decide placement (e.g. top corner, or replacing the per-phase countdown
  during holds where it matters less, etc.) — worth a deliberate layout
  decision rather than just cramming it in.
- Decide whether this **replaces** the per-phase countdown or is shown
  **alongside** it. Showing both (session mm:ss + per-phase seconds) is
  probably most useful but needs careful layout given watch screen size.

## Why deferred

Not part of the M3 (Feedback & settings) scope that was just completed;
tracked here so it isn't lost. This is a display/UX feature that pairs
naturally with M4 (Polish) or whenever layout work is next picked up —
`issues/0001-richer-session-complete-ux.md` also touches related
session-progress display ideas (e.g. a summary screen), so these two issues
may be worth tackling together.

## Notes for whoever picks this up

- `BreathingSession.remainingSeconds()` (existing) only covers the current
  phase — do not repurpose it; add a distinct method for the whole-session
  total to keep responsibilities clear and unit-testable independently.
- `BreathingSession.patternDurationSeconds()` (existing, static/pure helper)
  and `BreathwaySettings.targetCyclesFor()` (existing) already provide the
  building blocks for computing total session duration in seconds
  (`targetCycles * patternDurationSeconds`), so the new accessor is mostly
  "total duration minus elapsed duration so far", accounting for completed
  cycles + progress within the current cycle.
- Should get direct unit test coverage in `test/BreathwayTests.mc` given the
  existing precedent (pure state-machine logic, no Toybox UI dependency) —
  e.g. asserting the value at session start equals the full configured
  duration, and that it reaches `0` exactly when `isComplete()` becomes
  true.

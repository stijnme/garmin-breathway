# 0004 — Adopt standard Garmin timer app UI (start/menu/reset icons)

**Status:** open (feature request)
**Filed:** 2026-09-21

## Summary

Rework `BreathwayView`'s visual layout to match the look and feel of
Garmin's built-in **Timer** app, so Breathway feels native to the platform
instead of using bespoke text prompts ("Select to start", "Menu for
settings", etc.).

See `issues/0004-standard-timer-ui.jpg` for a reference photo of the stock
Timer app on a Fenix-family device (moved/renamed here from
`example-ui-garmin-timer-app.jpg` to keep it grouped with this issue).

## Reference UI elements (from the screenshot)

- Current time of day in a small font at the top.
- A **start icon** (solid right-pointing triangle, ▶) in the upper-right
  area, near the top of the progress ring — shown when the timer is not
  running.
- A **3-dot menu icon** (⋮) — Garmin's standard affordance for "long-press
  for more options" / settings, in place of Breathway's current plain-text
  "Menu" hint.
- Once started, the start icon is replaced by a **reset icon** (circular
  arrow, ↺) lower on the screen, giving a clear iconography-based way to
  reset instead of (or in addition to) a text hint.
- Large, bold elapsed/remaining time as the dominant central element,
  bracketed by thin horizontal divider lines, with the session length shown
  smaller underneath.
- An outer ring showing progress (partially filled arc) around the whole
  watch face.

## Proposed behavior

- Replace current text-based affordances in `BreathwayView.onUpdate()`
  (e.g. "Select to start", "Menu for settings" style hints, if present)
  with icon-based drawables matching the above, drawn at consistent
  positions across device shapes (round vs. semi-round — check target
  device list in `manifest.xml`).
- Add the three icons (start triangle, 3-dot menu, reset arrow) as
  drawables in `resources/drawables/drawables.xml`, referenced via
  `@Drawables.*`, per the existing convention in `AGENTS.md`.
- Icon visibility should follow session state:
  - Not started (phase 0, 0 elapsed): show start icon + menu icon.
  - Running/paused: show reset icon (+ pause/resume indication somehow,
    e.g. dim/solid triangle vs. two bars — check what stock Timer app does
    when paused, since the reference photo only shows the running state).
  - Complete: existing "session complete" screen (see issue 0001) takes
    over; icons may not apply there.
- This is purely a presentational change — no changes expected to
  `BreathingSession` state machine or `BreathwayDelegate` button wiring
  (menu/select/back keep their current bindings; this issue is about how
  their availability is *communicated visually*, not remapping them).

## Why filed

Improves visual consistency with the rest of the Garmin OS and reduces
reliance on text (which doesn't scale well across screen sizes/locales)
for basic timer affordances.

## Notes for whoever picks this up

- `BreathwayView.onUpdate()` is where current drawing logic lives per
  `AGENTS.md` conventions (draw logic belongs in the view).
- Check icon sizing/positioning across all target devices in
  `manifest.xml` (fenix7, fenix7s, fr265, fr965, fenix8solar51mm) since
  screen resolutions differ.
- Consider whether existing text hints should simply be removed once icons
  are in place, or kept as a fallback/accessibility aid.

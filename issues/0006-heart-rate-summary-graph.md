# 0006 — Record heart rate during a session and show a summary graph

**Status:** open (feature request)
**Filed:** 2026-09-21

## Summary

Record the user's heart rate at the start of a breathing session and at a
regular interval throughout, then display a simple graph of heart rate over
time as part of the session summary/complete screen.

## Proposed behavior

- On session start (first transition from idle to running — see issue
  0005), sample the current heart rate via
  `Toybox.Sensor`/`Toybox.SensorHistory` (whichever API is appropriate for
  a non-activity, non-recording watch app context — this needs research,
  see below) and store it as the first data point.
- While the session is running, sample heart rate at a fixed interval
  (e.g. every 5–10 seconds — exact interval TBD, should probably be a
  small constant rather than tied to breathing-phase timing) and append
  each reading to an in-memory array/collection for the duration of the
  session.
- On session complete, pass the recorded heart-rate series to the
  "session complete" screen (building on the richer summary screen already
  proposed in issue 0001) and render it as a simple line/bar graph (min/max
  scaled to fit the available drawable area), alongside existing summary
  stats (cycles completed, elapsed time).
- Data should be transient (in-memory only for the current session) unless
  a future issue asks for persistence — no requirement here to store
  history across app runs.

## Open questions / research needed

- Which Connect IQ API gives heart rate readings for a plain
  `WatchUi.View`-based app (not an activity/session recording)? Likely
  `Toybox.Sensor.getInfo().heartRate` (polled) or
  `Toybox.SensorHistory.getHeartRateHistory()` (post-hoc lookback) —
  confirm availability/permissions needed on the target device list in
  `manifest.xml` (fenix7, fenix7s, fr265, fr965, fenix8solar51mm) and
  whether a permission needs to be added there.
- Battery/perf impact of polling heart rate at an interval on a watch app
  that isn't a recorded activity — check Garmin docs/forums for guidance
  on non-activity heart rate access, since some APIs are only available
  during a recording session.
- Array size / memory bounds for longer sessions — a fixed-length
  session (see existing "session length" setting) bounds the number of
  samples, but confirm a reasonable interval keeps the array small enough
  for watch memory constraints (e.g. a 20-minute session at a 10s interval
  is ~120 samples, which should be fine, but worth sanity-checking against
  actual device memory limits).

## Why filed

Turns the app from a pure timer into something that gives the user
feedback on the physiological effect of the breathing exercise, which is
the main value proposition of a breathing/relaxation app.

## Notes for whoever picks this up

- This is the biggest of the three issues filed alongside it (0004, 0005)
  — likely needs its own milestone in `PLAN.md` rather than being folded
  into an existing one, given the API research required.
- Should probably live in a new plain class (e.g.
  `source/HeartRateRecorder.mc`) per the `AGENTS.md` convention of
  extracting business logic out of the view, so it can be unit tested
  independent of drawing code (feed it fake heart-rate samples, assert the
  min/max/series are tracked correctly).

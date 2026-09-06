# PLAN.md

Living development plan for **Breathway**, a Garmin Connect IQ breathing-exercise
watch app. Update this file as scope, decisions, or priorities change.

## Vision

A simple, distraction-free watch app that guides the user through a breathing
exercise using an expanding/contracting circle, phase labels, a countdown, and
optional haptic cues — usable in under 10 seconds from launch, no account or
phone pairing required.

## Milestones

### M0 — Project skeleton (done)
- [x] Manifest, jungle file, source/resource layout
- [x] Minimal `BreathwayApp` / `BreathwayView` / `BreathwayDelegate`
- [x] Placeholder launcher icon
- [x] Placeholder unit test scaffold
- [x] Editor config (VS Code Monkey C extension settings/launch config)
- [x] AGENTS.md / PLAN.md / README.md

### M1 — Toolchain bring-up (done)
- [x] Install Garmin Connect IQ SDK + accept license via `sdkmanager`
- [x] Generate a developer signing key (`developer_key`, gitignored)
- [x] Confirm `monkeyc` compiles `monkey.jungle` for `fenix7s`
- [x] Confirm simulator run via `monkeydo` / VS Code "Run" command
- [x] Confirm `--unit-test` build + `monkeydo -t` runs the placeholder test

### M2 — Core breathing loop (done)
- [x] Extract breathing-pattern state machine out of `BreathwayView` into a
      plain, unit-testable class (e.g. `BreathingSession`)
- [x] Support at least one configurable pattern with
      real unit tests for phase transitions and countdown behavior:
      - box breathing 4-1-6-1 = 4 in, 1 hold, 6 out, 1 hold
- [x] Smooth circle animation (avoid visible stepping at 1Hz timer tick;
      consider higher-frequency timer or eased interpolation)
- [x] Start/pause/resume via `onSelect`; confirm `onBack` exits cleanly

### M3 — Feedback & settings (done)
- [x] Haptic pulse on phase change (`Toybox.Attention` if device supports it):
      short/light buzz entering a hold, longer double-buzz entering an
      inhale/exhale; guarded by a haptics on/off setting
- [x] Session length / number-of-cycles setting (persisted via
      `Application.Storage`): stored in **minutes**, converted to a target
      cycle count per-pattern so switching patterns preserves the
      requested duration; default 5 minutes
- [x] On-device settings screen (`WatchUi.Menu2`, opened via the standard
      `onMenu()` long-press-Select behavior — no phone pairing / Connect IQ
      mobile app involved, consistent with the non-goals below) for haptics
      on/off, session length, and pattern selection (box 4-1-6-1 / 4-7-8)

See `issues/0001-richer-session-complete-ux.md` for a deferred polish item
(richer session-complete screen) surfaced while building this milestone.

### M4 — Polish (next)
- [ ] Round vs semi-round layout tuning (`resources-round` override if needed)
- [ ] Proper launcher icon (replace placeholder PNG)
- [ ] Localized strings beyond `eng` if needed
- [ ] Battery/backlight considerations for longer sessions

### M5 — Release readiness
- [ ] Expand device coverage in `manifest.xml` (round AMOLED, vivoactive, etc.)
- [ ] Manual test pass across target devices/simulators
- [ ] Store listing assets (screenshots, description) — outside this repo's
      scope but tracked here as a reminder
- [ ] Tag a release build

## Open decisions (revisit before M2)

- ~~Which breathing patterns to ship by default~~ — resolved in M3: box
  4-1-6-1 and classic 4-7-8, selectable via the on-device settings menu.
  Custom user-defined timings remain a possible future addition.
- Whether session progress/history should be tracked at all, or app stays
  fully stateless/ephemeral.
- Minimum SDK / API level tradeoff vs. device coverage (`minSdkVersion` is
  currently `4.2.0` in `manifest.xml`).

## Non-goals (for now)

- Phone companion app / Connect IQ mobile settings sync
- Cloud sync or account system
- Activity/sensor integration (heart rate, respiration sensor) — could be a
  future stretch goal once the core loop is solid.

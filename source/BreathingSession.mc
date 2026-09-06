import Toybox.Lang;

// Plain, unit-testable state machine for a breathing pattern (e.g. box
// breathing 4-1-6-1). Deliberately has no Toybox.WatchUi / Graphics / Timer
// dependencies so it can be exercised directly from test/BreathwayTests.mc.
//
// Time is tracked in milliseconds internally so the view can drive it from a
// higher-frequency timer (e.g. every 100ms) for smooth circle animation,
// while phase durations are still specified in whole seconds.
class BreathingSession {

    private var _phases as Array<Dictionary>;
    private var _phaseIndex as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _running as Boolean = false;

    // phases: Array of { :name as String, :seconds as Number }, in order.
    // Must contain at least one phase with :seconds > 0.
    function initialize(phases as Array<Dictionary>) {
        _phases = phases;
    }

    function start() as Void {
        _running = true;
    }

    function pause() as Void {
        _running = false;
    }

    function togglePause() as Void {
        _running = !_running;
    }

    function isRunning() as Boolean {
        return _running;
    }

    // Reset back to the first phase, elapsed time zero. Does not change
    // running/paused state.
    function reset() as Void {
        _phaseIndex = 0;
        _elapsedMs = 0;
    }

    // Advance the session clock by deltaMs milliseconds. No-op while paused.
    // Handles deltaMs larger than a single phase duration by rolling over
    // through as many phases as needed (each phase must have seconds > 0).
    function advance(deltaMs as Number) as Void {
        if (!_running || deltaMs <= 0) {
            return;
        }
        _elapsedMs += deltaMs;
        var durationMs = currentPhaseDurationMs();
        while (durationMs > 0 && _elapsedMs >= durationMs) {
            _elapsedMs -= durationMs;
            _phaseIndex = (_phaseIndex + 1) % _phases.size();
            durationMs = currentPhaseDurationMs();
        }
    }

    function phaseIndex() as Number {
        return _phaseIndex;
    }

    function currentPhaseName() as String {
        return _phases[_phaseIndex].get(:name) as String;
    }

    function currentPhaseSeconds() as Number {
        return _phases[_phaseIndex].get(:seconds) as Number;
    }

    private function currentPhaseDurationMs() as Number {
        return currentPhaseSeconds() * 1000;
    }

    // Fraction of the current phase elapsed, from 0.0 (just started) to
    // just-under 1.0 (about to transition).
    function progress() as Float {
        var durationMs = currentPhaseDurationMs();
        if (durationMs <= 0) {
            return 0.0;
        }
        return _elapsedMs.toFloat() / durationMs;
    }

    // Whole seconds remaining in the current phase, for display (e.g. "3").
    // Counts down from the phase's :seconds value to 1 (never 0, since the
    // phase transitions as soon as elapsed reaches the duration).
    function remainingSeconds() as Number {
        var durationMs = currentPhaseDurationMs();
        var remainingMs = durationMs - _elapsedMs;
        if (remainingMs <= 0) {
            return currentPhaseSeconds();
        }
        // Ceil division so e.g. 3900ms remaining still shows "4" briefly
        // before ticking down, and 1ms remaining shows "1" not "0".
        return (remainingMs + 999) / 1000;
    }
}

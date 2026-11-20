import Toybox.Lang;

// Plain, unit-testable state machine for a breathing pattern (e.g. box
// breathing 4-1-6-1, or 4-7-8). Deliberately has no Toybox.WatchUi /
// Graphics / Timer / Attention dependencies so it can be exercised directly
// from test/BreathwayTests.mc.
//
// Time is tracked in milliseconds internally so the view can drive it from a
// higher-frequency timer (e.g. every 100ms) for smooth circle animation,
// while phase durations are still specified in whole seconds.
class BreathingSession {

    // Phase "direction" drives both the circle animation (grow/shrink/hold)
    // and which haptic pulse plays on entering the phase (see
    // BreathwayView.onTick()). Using an explicit direction instead of
    // matching on :name or phase index lets arbitrary patterns (including
    // ones with no second hold, like 4-7-8) render/vibrate correctly.
    enum {
        DIRECTION_IN,
        DIRECTION_HOLD,
        DIRECTION_OUT
    }

    private var _phases as Array<Dictionary>;
    private var _phaseIndex as Number = 0;
    private var _elapsedMs as Number = 0;
    private var _running as Boolean = false;
    private var _cyclesCompleted as Number = 0;
    private var _targetCycles as Number?;

    // phases: Array of { :name as String, :seconds as Number,
    // :direction as Number (DIRECTION_IN/HOLD/OUT) }, in order. Must contain
    // at least one phase with :seconds > 0.
    // targetCycles: optional number of full pattern loops before the session
    // is considered complete (null = unlimited/free-run session).
    function initialize(phases as Array<Dictionary>, targetCycles as Number?) {
        _phases = phases;
        _targetCycles = targetCycles;
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

    // Reset back to the first phase, elapsed time zero, cycles-completed
    // zero. Does not change running/paused state.
    function reset() as Void {
        _phaseIndex = 0;
        _elapsedMs = 0;
        _cyclesCompleted = 0;
    }

    // True when the session sits at its very beginning: first phase, zero
    // elapsed time, no cycles completed. Combined with !isRunning() this is
    // the idle "ready to start" state.
    function isAtStart() as Boolean {
        return _phaseIndex == 0 && _elapsedMs == 0 && _cyclesCompleted == 0;
    }

    function setTargetCycles(targetCycles as Number?) as Void {
        _targetCycles = targetCycles;
    }

    function targetCycles() as Number? {
        return _targetCycles;
    }

    function cyclesCompleted() as Number {
        return _cyclesCompleted;
    }

    // True once cyclesCompleted() has reached targetCycles() (always false
    // for an unlimited/free-run session, i.e. targetCycles() == null).
    function isComplete() as Boolean {
        return _targetCycles != null && _cyclesCompleted >= (_targetCycles as Number);
    }

    // Advance the session clock by deltaMs milliseconds. No-op while paused
    // or once the session is complete. Handles deltaMs larger than a single
    // phase duration by rolling over through as many phases as needed (each
    // phase must have seconds > 0). Returns true if at least one phase
    // transition occurred during this call, so callers (e.g. the view) can
    // trigger a haptic pulse without duplicating phase-comparison logic.
    // Auto-pauses as soon as the target cycle count is reached.
    function advance(deltaMs as Number) as Boolean {
        if (!_running || deltaMs <= 0 || isComplete()) {
            return false;
        }
        var didTransition = false;
        _elapsedMs += deltaMs;
        var durationMs = currentPhaseDurationMs();
        while (durationMs > 0 && _elapsedMs >= durationMs) {
            _elapsedMs -= durationMs;
            _phaseIndex = (_phaseIndex + 1) % _phases.size();
            didTransition = true;
            if (_phaseIndex == 0) {
                _cyclesCompleted += 1;
                if (isComplete()) {
                    _running = false;
                    break;
                }
            }
            durationMs = currentPhaseDurationMs();
        }
        return didTransition;
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

    function currentPhaseDirection() as Number {
        return _phases[_phaseIndex].get(:direction) as Number;
    }

    // Direction of the phase immediately preceding the current one (wraps
    // around to the last phase if currently on the first). Used by the view
    // to know which extreme to hold the circle radius at during a HOLD
    // phase, regardless of how many holds the pattern has or where they
    // fall.
    function previousPhaseDirection() as Number {
        var count = _phases.size();
        var previousIndex = (_phaseIndex - 1 + count) % count;
        return _phases[previousIndex].get(:direction) as Number;
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

    // Total duration of one full pattern loop, in seconds. Used to convert
    // a "session length in minutes" setting into a target cycle count.
    static function patternDurationSeconds(phases as Array<Dictionary>) as Number {
        var total = 0;
        for (var i = 0; i < phases.size(); i++) {
            total += phases[i].get(:seconds) as Number;
        }
        return total;
    }
}

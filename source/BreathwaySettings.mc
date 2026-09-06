import Toybox.Application.Storage;
import Toybox.Lang;

// Centralizes all persisted, on-device settings (no phone pairing / Connect
// IQ mobile sync involved — see AGENTS.md non-goals). Read/write helpers
// apply sensible defaults when a value hasn't been set yet.
//
// This is a module rather than a class for the same reason as
// BreathingPatterns: it holds no instance state, and Monkey C's
// `static function`s on a class cannot reference that class's own `const`s.
module BreathwaySettings {

    const KEY_HAPTICS as String = "hapticsEnabled";
    const KEY_MINUTES as String = "sessionMinutes";
    const KEY_PATTERN as String = "patternId";

    const DEFAULT_MINUTES as Number = 5;
    const DEFAULT_PATTERN_ID as Number = BreathingPatterns.PATTERN_BOX;

    // Fixed set of selectable session lengths; selecting the menu item
    // cycles through these in order.
    const MINUTE_OPTIONS as Array<Number> = [3, 5, 10, 15];

    function hapticsEnabled() as Boolean {
        var value = Storage.getValue(KEY_HAPTICS);
        return (value == null) ? true : value as Boolean;
    }

    function setHapticsEnabled(enabled as Boolean) as Void {
        Storage.setValue(KEY_HAPTICS, enabled);
    }

    function sessionMinutes() as Number {
        var value = Storage.getValue(KEY_MINUTES);
        return (value == null) ? DEFAULT_MINUTES : value as Number;
    }

    function setSessionMinutes(minutes as Number) as Void {
        Storage.setValue(KEY_MINUTES, minutes);
    }

    // Advance to the next value in MINUTE_OPTIONS (wrapping), persist it,
    // and return the new value.
    function cycleSessionMinutes() as Number {
        var options = MINUTE_OPTIONS;
        var current = sessionMinutes();
        var index = 0;
        for (var i = 0; i < options.size(); i++) {
            if (options[i] == current) {
                index = i;
                break;
            }
        }
        index = (index + 1) % options.size();
        var next = options[index];
        setSessionMinutes(next);
        return next;
    }

    function patternId() as Number {
        var value = Storage.getValue(KEY_PATTERN);
        return (value == null) ? DEFAULT_PATTERN_ID : value as Number;
    }

    function setPatternId(id as Number) as Void {
        Storage.setValue(KEY_PATTERN, id);
    }

    // Toggle between the two built-in patterns and return the new id.
    function toggleForNextPattern() as Number {
        var next = (patternId() == BreathingPatterns.PATTERN_BOX)
            ? BreathingPatterns.PATTERN_478
            : BreathingPatterns.PATTERN_BOX;
        setPatternId(next);
        return next;
    }

    // Converts a "session length in minutes" setting into a target cycle
    // count for the given pattern, so switching patterns preserves roughly
    // the same session duration instead of a fixed cycle count. Always
    // returns at least 1.
    function targetCyclesFor(pattern as Array<Dictionary>, minutes as Number) as Number {
        var patternSeconds = BreathingSession.patternDurationSeconds(pattern);
        if (patternSeconds <= 0) {
            return 1;
        }
        var cycles = (minutes * 60) / patternSeconds;
        return (cycles < 1) ? 1 : cycles;
    }
}

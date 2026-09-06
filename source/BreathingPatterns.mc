import Toybox.Lang;

// Built-in breathing patterns, expressed as phase arrays compatible with
// BreathingSession's constructor. Each phase carries an explicit
// BreathingSession.DIRECTION_* so the view can animate/vibrate correctly
// regardless of how many hold phases a pattern has (box has two, 4-7-8 has
// only one).
//
// This is a module rather than a class: it holds no instance state, and
// Monkey C's `static function`s on a class cannot reference that class's own
// `const`s (a compiler limitation) — module-level functions/consts don't
// have that restriction.
module BreathingPatterns {

    enum {
        PATTERN_BOX,
        PATTERN_478
    }

    // Box breathing: 4s in, 1s hold, 6s out, 1s hold.
    const BOX as Array<Dictionary> = [
        { :name => "Inhale", :seconds => 4, :direction => BreathingSession.DIRECTION_IN },
        { :name => "Hold",   :seconds => 1, :direction => BreathingSession.DIRECTION_HOLD },
        { :name => "Exhale", :seconds => 6, :direction => BreathingSession.DIRECTION_OUT },
        { :name => "Hold",   :seconds => 1, :direction => BreathingSession.DIRECTION_HOLD },
    ];

    // Classic 4-7-8: 4s in, 7s hold, 8s out. No second hold.
    const FOUR_SEVEN_EIGHT as Array<Dictionary> = [
        { :name => "Inhale", :seconds => 4, :direction => BreathingSession.DIRECTION_IN },
        { :name => "Hold",   :seconds => 7, :direction => BreathingSession.DIRECTION_HOLD },
        { :name => "Exhale", :seconds => 8, :direction => BreathingSession.DIRECTION_OUT },
    ];

    const NAMES as Array<String> = ["Box (4-1-6-1)", "4-7-8"];

    function byId(id as Number) as Array<Dictionary> {
        if (id == PATTERN_478) {
            return FOUR_SEVEN_EIGHT;
        }
        return BOX;
    }

    function nameForId(id as Number) as String {
        if (id == PATTERN_478) {
            return NAMES[PATTERN_478];
        }
        return NAMES[PATTERN_BOX];
    }
}

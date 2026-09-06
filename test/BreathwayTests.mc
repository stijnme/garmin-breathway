import Toybox.Test;
import Toybox.Lang;

// Run with: monkeydo <built-test.prg> <device> -t, or via the "Run test"
// command in the VS Code Monkey C extension.

(:test)
function testPlaceholder(logger as Test.Logger) as Boolean {
    logger.debug("placeholder test executed");
    return true;
}

function boxPattern() as Array<Dictionary> {
    return [
        { :name => "Inhale", :seconds => 4 },
        { :name => "Hold",   :seconds => 1 },
        { :name => "Exhale", :seconds => 6 },
        { :name => "Hold",   :seconds => 1 },
    ];
}

(:test)
function testInitialStateIsFirstPhasePaused(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    return !session.isRunning()
        && session.phaseIndex() == 0
        && session.currentPhaseName().equals("Inhale")
        && session.currentPhaseSeconds() == 4
        && session.remainingSeconds() == 4
        && session.progress() == 0.0;
}

(:test)
function testAdvanceDoesNothingWhilePaused(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.advance(2000);
    return session.phaseIndex() == 0 && session.progress() == 0.0;
}

(:test)
function testAdvanceWithinPhaseUpdatesProgress(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.start();
    session.advance(2000); // 2s into a 4s Inhale
    return session.phaseIndex() == 0
        && session.currentPhaseName().equals("Inhale")
        && session.progress() == 0.5
        && session.remainingSeconds() == 2;
}

(:test)
function testAdvancePastPhaseBoundaryTransitions(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.start();
    session.advance(4000); // exactly the full Inhale duration
    return session.phaseIndex() == 1
        && session.currentPhaseName().equals("Hold")
        && session.progress() == 0.0
        && session.remainingSeconds() == 1;
}

(:test)
function testAdvanceAcrossMultiplePhasesInOneCall(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.start();
    // Inhale(4) + Hold(1) + 2s into Exhale(6) = 7000ms
    session.advance(7000);
    return session.phaseIndex() == 2
        && session.currentPhaseName().equals("Exhale")
        && session.remainingSeconds() == 4;
}

(:test)
function testAdvanceWrapsAroundToFirstPhase(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.start();
    // Full pattern is 4+1+6+1 = 12s; advance exactly one full cycle plus 1s.
    session.advance(13000);
    return session.phaseIndex() == 0
        && session.currentPhaseName().equals("Inhale")
        && session.remainingSeconds() == 3; // 1s elapsed into a 4s phase
}

(:test)
function testTogglePausePreservesPosition(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.start();
    session.advance(2000);
    session.togglePause();
    if (session.isRunning()) {
        return false;
    }
    session.advance(5000); // should be ignored while paused
    session.togglePause();
    if (!session.isRunning()) {
        return false;
    }
    return session.phaseIndex() == 0 && session.progress() == 0.5;
}

(:test)
function testResetReturnsToStart(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern());
    session.start();
    session.advance(7000);
    session.reset();
    return session.phaseIndex() == 0 && session.progress() == 0.0;
}

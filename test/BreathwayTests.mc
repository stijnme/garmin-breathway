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
    return BreathingPatterns.BOX;
}

function fourSevenEightPattern() as Array<Dictionary> {
    return BreathingPatterns.FOUR_SEVEN_EIGHT;
}

// --- Basic phase progression (box 4-1-6-1) ---------------------------------

(:test)
function testInitialStateIsFirstPhasePaused(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
    return !session.isRunning()
        && session.phaseIndex() == 0
        && session.currentPhaseName().equals("Inhale")
        && session.currentPhaseDirection() == BreathingSession.DIRECTION_IN
        && session.currentPhaseSeconds() == 4
        && session.remainingSeconds() == 4
        && session.progress() == 0.0;
}

(:test)
function testAdvanceDoesNothingWhilePaused(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
    var transitioned = session.advance(2000);
    return !transitioned && session.phaseIndex() == 0 && session.progress() == 0.0;
}

(:test)
function testAdvanceWithinPhaseUpdatesProgress(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
    session.start();
    var transitioned = session.advance(2000); // 2s into a 4s Inhale
    return !transitioned
        && session.phaseIndex() == 0
        && session.currentPhaseName().equals("Inhale")
        && session.progress() == 0.5
        && session.remainingSeconds() == 2;
}

(:test)
function testAdvancePastPhaseBoundaryTransitions(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
    session.start();
    var transitioned = session.advance(4000); // exactly the full Inhale duration
    return transitioned
        && session.phaseIndex() == 1
        && session.currentPhaseName().equals("Hold")
        && session.currentPhaseDirection() == BreathingSession.DIRECTION_HOLD
        && session.previousPhaseDirection() == BreathingSession.DIRECTION_IN
        && session.progress() == 0.0
        && session.remainingSeconds() == 1;
}

(:test)
function testAdvanceAcrossMultiplePhasesInOneCall(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
    session.start();
    // Inhale(4) + Hold(1) + 2s into Exhale(6) = 7000ms
    var transitioned = session.advance(7000);
    return transitioned
        && session.phaseIndex() == 2
        && session.currentPhaseName().equals("Exhale")
        && session.currentPhaseDirection() == BreathingSession.DIRECTION_OUT
        && session.remainingSeconds() == 4;
}

(:test)
function testAdvanceWrapsAroundToFirstPhase(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
    session.start();
    // Full pattern is 4+1+6+1 = 12s; advance exactly one full cycle plus 1s.
    var transitioned = session.advance(13000);
    return transitioned
        && session.phaseIndex() == 0
        && session.currentPhaseName().equals("Inhale")
        && session.remainingSeconds() == 3 // 1s elapsed into a 4s phase
        && session.cyclesCompleted() == 1;
}

(:test)
function testTogglePausePreservesPosition(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null);
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
    var session = new BreathingSession(boxPattern(), null);
    session.start();
    session.advance(7000);
    session.reset();
    return session.phaseIndex() == 0 && session.progress() == 0.0 && session.cyclesCompleted() == 0;
}

// --- 4-7-8 pattern: only one hold, exercises previousPhaseDirection() -----

(:test)
function testFourSevenEightHoldFollowsInhale(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(fourSevenEightPattern(), null);
    session.start();
    session.advance(4000); // Inhale(4) complete -> Hold(7)
    return session.currentPhaseDirection() == BreathingSession.DIRECTION_HOLD
        && session.previousPhaseDirection() == BreathingSession.DIRECTION_IN;
}

(:test)
function testFourSevenEightWrapsWithThreePhases(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(fourSevenEightPattern(), null);
    session.start();
    // 4 (in) + 7 (hold) + 8 (out) = 19s per cycle; advance one full cycle.
    var transitioned = session.advance(19000);
    return transitioned && session.phaseIndex() == 0 && session.cyclesCompleted() == 1;
}

// --- Target cycles / session completion ------------------------------------

(:test)
function testUnlimitedSessionNeverCompletes(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), null); // targetCycles defaults to null
    session.start();
    session.advance(120000); // 10 full cycles
    return !session.isComplete() && session.cyclesCompleted() == 10;
}

(:test)
function testSessionCompletesAtTargetCyclesAndAutoPauses(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), 2);
    session.start();
    var transitioned = session.advance(24000); // exactly 2 full cycles (12s each)
    return transitioned
        && session.isComplete()
        && !session.isRunning()
        && session.cyclesCompleted() == 2;
}

(:test)
function testAdvanceIsNoOpOnceComplete(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), 1);
    session.start();
    session.advance(12000); // completes exactly 1 cycle
    if (!session.isComplete()) {
        return false;
    }
    session.start(); // simulate stray resume attempt without reset
    var transitioned = session.advance(5000);
    return !transitioned && session.cyclesCompleted() == 1;
}

(:test)
function testResetFromCompleteAllowsRestart(logger as Test.Logger) as Boolean {
    var session = new BreathingSession(boxPattern(), 1);
    session.start();
    session.advance(12000);
    if (!session.isComplete()) {
        return false;
    }
    session.reset();
    session.start();
    return !session.isComplete() && session.isRunning() && session.cyclesCompleted() == 0;
}

// --- Pure helper functions (BreathingSession.patternDurationSeconds,
// BreathwaySettings.targetCyclesFor, BreathingPatterns) --------------------

(:test)
function testPatternDurationSeconds(logger as Test.Logger) as Boolean {
    return BreathingSession.patternDurationSeconds(boxPattern()) == 12
        && BreathingSession.patternDurationSeconds(fourSevenEightPattern()) == 19;
}

(:test)
function testTargetCyclesForConvertsMinutesToCycles(logger as Test.Logger) as Boolean {
    // Box = 12s/cycle; 5 minutes = 300s -> 25 cycles.
    return BreathwaySettings.targetCyclesFor(boxPattern(), 5) == 25
        // 4-7-8 = 19s/cycle; 5 minutes = 300s -> 15 cycles (integer division).
        && BreathwaySettings.targetCyclesFor(fourSevenEightPattern(), 5) == 15;
}

(:test)
function testTargetCyclesForIsAtLeastOne(logger as Test.Logger) as Boolean {
    // A pattern longer than the requested minutes should still yield >= 1.
    return BreathwaySettings.targetCyclesFor(fourSevenEightPattern(), 0) == 1;
}

(:test)
function testBreathingPatternsById(logger as Test.Logger) as Boolean {
    return BreathingPatterns.byId(BreathingPatterns.PATTERN_BOX) == BreathingPatterns.BOX
        && BreathingPatterns.byId(BreathingPatterns.PATTERN_478) == BreathingPatterns.FOUR_SEVEN_EIGHT
        && BreathingPatterns.nameForId(BreathingPatterns.PATTERN_BOX).equals("Box (4-1-6-1)")
        && BreathingPatterns.nameForId(BreathingPatterns.PATTERN_478).equals("4-7-8");
}

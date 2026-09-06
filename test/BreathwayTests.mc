import Toybox.Test;
import Toybox.Lang;

// Run with: monkeydo <built-test.prg> <device> or via the "Run test" command
// in the VS Code Monkey C extension. Uses the Connect IQ Test framework.
(:test)
function testPlaceholder(logger as Test.Logger) as Boolean {
    // Replace with real assertions once BreathwayView exposes testable state
    // (e.g. extract phase-progression logic into a plain class/module).
    logger.debug("placeholder test executed");
    return true;
}

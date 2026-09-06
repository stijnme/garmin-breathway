import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

// Renders the breathing guide: a pulsing circle that expands on inhale and
// contracts on exhale, plus a phase label and countdown. Breathing-phase
// timing/state lives in BreathingSession (see BreathingSession.mc) so it can
// be unit tested independently of drawing code. Pattern/session-length/
// haptics preferences live in BreathwaySettings (Application.Storage,
// on-device only — no phone pairing).
class BreathwayView extends WatchUi.View {

    // Timer tick interval in milliseconds. Higher frequency than 1Hz so the
    // circle radius animates smoothly instead of visibly stepping once per
    // second; the countdown label still only changes on whole-second
    // boundaries (see BreathingSession.remainingSeconds()).
    private const TICK_MS as Number = 100;

    private var _session as BreathingSession?;
    private var _timer as Timer.Timer?;
    private var _hapticsEnabled as Boolean = true;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Intentionally not loading a layout resource yet; drawing is done
        // procedurally in onUpdate(). Swap in WatchUi.loadResource(Rez.Layouts.*)
        // once a richer layout is designed.
    }

    function onShow() as Void {
        // Rebuild from current settings every time the view becomes visible
        // (covers first launch and returning from the settings menu, so
        // pattern/length changes take effect immediately on a fresh run).
        var pattern = BreathingPatterns.byId(BreathwaySettings.patternId());
        var minutes = BreathwaySettings.sessionMinutes();
        var targetCycles = BreathwaySettings.targetCyclesFor(pattern, minutes);
        _hapticsEnabled = BreathwaySettings.hapticsEnabled();

        _session = new BreathingSession(pattern, targetCycles);
        (_session as BreathingSession).start();
        startTimer();
    }

    function onHide() as Void {
        stopTimer();
    }

    private function startTimer() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        (_timer as Timer.Timer).start(method(:onTick), TICK_MS, true);
    }

    private function stopTimer() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
        }
    }

    function onTick() as Void {
        var session = _session as BreathingSession;
        var transitioned = session.advance(TICK_MS);
        if (transitioned) {
            vibrateForCurrentPhase(session);
        }
        if (session.isRunning() || transitioned) {
            WatchUi.requestUpdate();
        }
    }

    // Toggles between running and paused, except once the session is
    // complete: then it starts a fresh run instead (avoids a dead-end
    // "complete" screen with no way back in other than reopening the app).
    function togglePause() as Void {
        var session = _session as BreathingSession;
        if (session.isComplete()) {
            session.reset();
            session.start();
        } else {
            session.togglePause();
        }
        WatchUi.requestUpdate();
    }

    // Short/light pulse entering a hold, longer/double pulse entering an
    // inhale or exhale. Guarded by both device support and the haptics
    // on/off setting.
    private function vibrateForCurrentPhase(session as BreathingSession) as Void {
        if (!_hapticsEnabled) {
            return;
        }
        if (!(Attention has :vibrate)) {
            return;
        }
        var direction = session.currentPhaseDirection();
        if (direction == BreathingSession.DIRECTION_HOLD) {
            Attention.vibrate([new Attention.VibeProfile(40, 100)]);
        } else {
            Attention.vibrate([
                new Attention.VibeProfile(70, 120),
                new Attention.VibeProfile(0, 80),
                new Attention.VibeProfile(70, 120),
            ]);
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var session = _session as BreathingSession;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        if (session.isComplete()) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height * 0.42, Graphics.FONT_MEDIUM, "Session\ncomplete", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, height * 0.62, Graphics.FONT_XTINY, "Select to restart", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var direction = session.currentPhaseDirection();
        var progress = session.progress();

        var minRadius = width * 0.15;
        var maxRadius = width * 0.4;
        var radius;
        if (direction == BreathingSession.DIRECTION_IN) {
            radius = minRadius + (maxRadius - minRadius) * progress;
        } else if (direction == BreathingSession.DIRECTION_OUT) {
            radius = maxRadius - (maxRadius - minRadius) * progress;
        } else {
            // Hold: stay at whichever extreme the previous (non-hold) phase
            // reached, so this works regardless of how many holds a given
            // pattern has or where they fall (e.g. 4-7-8 only has one).
            var previousDirection = session.previousPhaseDirection();
            radius = (previousDirection == BreathingSession.DIRECTION_IN) ? maxRadius : minRadius;
        }

        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, radius);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.15, Graphics.FONT_MEDIUM, session.currentPhaseName(), Graphics.TEXT_JUSTIFY_CENTER);

        var remaining = session.remainingSeconds();
        dc.drawText(centerX, height * 0.78, Graphics.FONT_SMALL, remaining.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        if (!session.isRunning()) {
            dc.drawText(centerX, height * 0.9, Graphics.FONT_XTINY, "Paused", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

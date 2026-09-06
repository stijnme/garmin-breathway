import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

// Renders the breathing guide: a pulsing circle that expands on inhale and
// contracts on exhale, plus a phase label and countdown. Breathing-phase
// timing/state lives in BreathingSession (see BreathingSession.mc) so it can
// be unit tested independently of drawing code.
class BreathwayView extends WatchUi.View {

    // Default pattern: box breathing 4-1-6-1 (4s in, 1s hold, 6s out, 1s hold).
    private const DEFAULT_PATTERN as Array<Dictionary> = [
        { :name => "Inhale", :seconds => 4 },
        { :name => "Hold",   :seconds => 1 },
        { :name => "Exhale", :seconds => 6 },
        { :name => "Hold",   :seconds => 1 },
    ];

    // Timer tick interval in milliseconds. Higher frequency than 1Hz so the
    // circle radius animates smoothly instead of visibly stepping once per
    // second; the countdown label still only changes on whole-second
    // boundaries (see BreathingSession.remainingSeconds()).
    private const TICK_MS as Number = 100;

    private var _session as BreathingSession;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _session = new BreathingSession(DEFAULT_PATTERN);
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Intentionally not loading a layout resource yet; drawing is done
        // procedurally in onUpdate(). Swap in WatchUi.loadResource(Rez.Layouts.*)
        // once a richer layout is designed.
    }

    function onShow() as Void {
        _session.start();
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
        _session.advance(TICK_MS);
        WatchUi.requestUpdate();
    }

    // Toggles between running and paused. While paused the timer keeps
    // firing (so requestUpdate() still redraws e.g. after a settings change)
    // but the session clock does not advance.
    function togglePause() as Void {
        _session.togglePause();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        var phaseName = _session.currentPhaseName();
        var progress = _session.progress();

        var minRadius = width * 0.15;
        var maxRadius = width * 0.4;
        var radius;
        if (phaseName.equals("Inhale")) {
            radius = minRadius + (maxRadius - minRadius) * progress;
        } else if (phaseName.equals("Exhale")) {
            radius = maxRadius - (maxRadius - minRadius) * progress;
        } else {
            // Hold phases: stay at whichever extreme the pattern reached
            // (first hold after inhale = expanded, second hold after
            // exhale = contracted).
            radius = (_session.phaseIndex() == 1) ? maxRadius : minRadius;
        }

        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, radius);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.15, Graphics.FONT_MEDIUM, phaseName, Graphics.TEXT_JUSTIFY_CENTER);

        var remaining = _session.remainingSeconds();
        dc.drawText(centerX, height * 0.78, Graphics.FONT_SMALL, remaining.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        if (!_session.isRunning()) {
            dc.drawText(centerX, height * 0.9, Graphics.FONT_XTINY, "Paused", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

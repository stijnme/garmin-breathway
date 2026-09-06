import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

// Renders the breathing guide. Kept intentionally simple as a starting point:
// a pulsing circle that expands on inhale and contracts on exhale.
class BreathwayView extends WatchUi.View {

    // Breathing phase durations in seconds (box breathing: 4-4-4-4 by default).
    private const PHASES as Array<Dictionary> = [
        { :name => "Inhale", :seconds => 4 },
        { :name => "Hold",   :seconds => 4 },
        { :name => "Exhale", :seconds => 4 },
        { :name => "Hold",   :seconds => 4 },
    ];

    private var _phaseIndex as Number = 0;
    private var _secondsInPhase as Number = 0;
    private var _timer as Timer.Timer?;
    private var _running as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Intentionally not loading a layout resource yet; drawing is done
        // procedurally in onUpdate(). Swap in WatchUi.loadResource(Rez.Layouts.*)
        // once a richer layout is designed.
    }

    function onShow() as Void {
        startTimer();
    }

    function onHide() as Void {
        stopTimer();
    }

    private function startTimer() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        _running = true;
        _timer.start(method(:onTick), 1000, true);
    }

    private function stopTimer() as Void {
        if (_timer != null) {
            _timer.stop();
        }
        _running = false;
    }

    function onTick() as Void {
        _secondsInPhase += 1;
        var currentPhase = PHASES[_phaseIndex];
        if (_secondsInPhase >= currentPhase.get(:seconds)) {
            _secondsInPhase = 0;
            _phaseIndex = (_phaseIndex + 1) % PHASES.size();
        }
        WatchUi.requestUpdate();
    }

    function togglePause() as Void {
        if (_running) {
            stopTimer();
        } else {
            startTimer();
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        var phase = PHASES[_phaseIndex];
        var phaseSeconds = phase.get(:seconds) as Number;
        var progress = phaseSeconds > 0 ? (_secondsInPhase.toFloat() / phaseSeconds) : 0.0;

        var minRadius = width * 0.15;
        var maxRadius = width * 0.4;
        var radius;
        if (phase.get(:name).equals("Inhale")) {
            radius = minRadius + (maxRadius - minRadius) * progress;
        } else if (phase.get(:name).equals("Exhale")) {
            radius = maxRadius - (maxRadius - minRadius) * progress;
        } else {
            radius = (_phaseIndex == 1) ? maxRadius : minRadius;
        }

        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, centerY, radius);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.15, Graphics.FONT_MEDIUM, phase.get(:name), Graphics.TEXT_JUSTIFY_CENTER);

        var remaining = phaseSeconds - _secondsInPhase;
        dc.drawText(centerX, height * 0.78, Graphics.FONT_SMALL, remaining.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }
}

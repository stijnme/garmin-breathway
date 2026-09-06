import Toybox.Lang;
import Toybox.WatchUi;

// Handles button/tap input for the main breathing view.
class BreathwayDelegate extends WatchUi.BehaviorDelegate {

    private var _view as BreathwayView;

    function initialize(view as BreathwayView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.togglePause();
        return true;
    }

    // Standard "Menu" behavior — long-press Select on devices without a
    // dedicated menu button. Opens the on-device settings screen (no phone
    // pairing / Connect IQ mobile app involved).
    function onMenu() as Boolean {
        WatchUi.pushView(new BreathwaySettingsMenu(), new BreathwaySettingsMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() as Boolean {
        // Let the system pop the view / exit the app.
        return false;
    }
}

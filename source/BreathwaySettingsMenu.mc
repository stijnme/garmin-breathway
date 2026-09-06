import Toybox.Lang;
import Toybox.WatchUi;

// On-device settings menu (opened via BreathwayDelegate.onMenu(), the
// standard long-press-Select "Menu" behavior on Garmin devices without a
// dedicated menu button). No phone pairing / Connect IQ mobile app is
// involved — everything is read/written straight to Application.Storage via
// BreathwaySettings.
class BreathwaySettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "Settings" });

        addItem(new WatchUi.ToggleMenuItem(
            "Haptics",
            { :enabled => "On", :disabled => "Off" },
            :haptics,
            BreathwaySettings.hapticsEnabled(),
            null
        ));

        addItem(new WatchUi.MenuItem(
            "Session length",
            BreathwaySettings.sessionMinutes().toString() + " min",
            :minutes,
            null
        ));

        addItem(new WatchUi.MenuItem(
            "Pattern",
            BreathingPatterns.nameForId(BreathwaySettings.patternId()),
            :pattern,
            null
        ));
    }
}

class BreathwaySettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        if (menuItem instanceof WatchUi.ToggleMenuItem && id == :haptics) {
            BreathwaySettings.setHapticsEnabled(menuItem.isEnabled());
        } else if (id == :minutes) {
            var minutes = BreathwaySettings.cycleSessionMinutes();
            menuItem.setSubLabel(minutes.toString() + " min");
        } else if (id == :pattern) {
            var patternId = BreathwaySettings.toggleForNextPattern();
            menuItem.setSubLabel(BreathingPatterns.nameForId(patternId));
        }
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

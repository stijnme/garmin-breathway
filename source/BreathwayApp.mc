import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point declared in manifest.xml (entry="BreathwayApp").
class BreathwayApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new BreathwayView();
        var delegate = new BreathwayDelegate(view);
        return [view, delegate];
    }

}

function getApp() as BreathwayApp {
    return Application.getApp() as BreathwayApp;
}

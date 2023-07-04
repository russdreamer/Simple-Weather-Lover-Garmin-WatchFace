import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class IgafaceApp extends Application.AppBase {
    var watchFace = null;

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
    function getInitialView() as Array<Views or InputDelegates>? {
        watchFace = new IgafaceView();
        return [ watchFace ] as Array<Views or InputDelegates>;
    }

    function getServiceDelegate() as Array<Toybox.System.ServiceDelegate> {
        return [ new ExternalWeatherService() ] as Array<Toybox.System.ServiceDelegate>;
    }


    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function onBackgroundData(data) {
        if (watchFace != null) {
            watchFace.onBackgroundData(data);
        }
    }

}

function getApp() as IgafaceApp {
    return Application.getApp() as IgafaceApp;
}
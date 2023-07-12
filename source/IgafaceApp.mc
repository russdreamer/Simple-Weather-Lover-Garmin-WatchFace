import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class IgafaceApp extends Application.AppBase {
    var watchFace = null;
    var inBackground = false;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        if (!inBackground) {
            Toybox.Background.deleteTemporalEvent();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        watchFace = new IgafaceView();
        return [ watchFace ] as Array<Views or InputDelegates>;
    }

    function getServiceDelegate() as Array<Toybox.System.ServiceDelegate> {
        inBackground = true;
        return [ new ExternalWeatherService() ] as Array<Toybox.System.ServiceDelegate>;
    }


    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function onBackgroundData(data) {
        System.println("data received: " + data);
    }

    function  onStorageChanged() {
        System.println("onStorageChanged called");
        if (watchFace != null) {
            var weatherData = Toybox.Application.Storage.getValue("weatherData");
            if (weatherData != null) {
                watchFace.onBackgroundData(weatherData);
            }
        }
    }
}

function getApp() as IgafaceApp {
    return Application.getApp() as IgafaceApp;
}
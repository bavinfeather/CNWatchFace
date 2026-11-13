using Toybox.Application;
using Toybox.WatchUi;

(:background, :QWeatherDisabled)
class CNWatchFaceApp extends Application.AppBase {
    private var _mainView = null;
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        _mainView = new CNWatchFaceView();
        return [_mainView];
    }
    function getSettingsView() {
        return null;
    }
    function onSettingsChanged() {
        if (_mainView != null) { _mainView.onSettingsChanged(); }
        else { WatchUi.requestUpdate(); }
    }
}

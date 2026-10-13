using Toybox.Application;
using Toybox.WatchUi;

class CNWatchFaceApp extends Application.AppBase {
    private var _mainView = null;
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _mainView = new CNWatchFaceView();
        return [_mainView];
    }

    function getSettingsView() {
        var menu = new CNWatchFaceSettingsMenu();
        return [menu, new CNWatchFaceSettingsDelegate(menu)];
    }

    function onSettingsChanged() {
        if (_mainView != null) { _mainView.onSettingsChanged(); }
        else { WatchUi.requestUpdate(); }
    }
}

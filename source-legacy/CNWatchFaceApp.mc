using Toybox.Application;
using Toybox.WatchUi;

class CNWatchFaceApp extends Application.AppBase {
    private var _mainView = null;
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        _mainView = new CNWatchFaceLegacyView();
        return [_mainView];
    }

    function onSettingsChanged() {
        if (_mainView != null) { _mainView.onSettingsChanged(); }
        else { WatchUi.requestUpdate(); }
    }
}

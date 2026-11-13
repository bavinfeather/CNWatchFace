using Toybox.Application;
using Toybox.WatchUi;

(:background, :QWeatherEnabled)
class CNWatchFaceApp extends Application.AppBase {
    private var _mainView = null;
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        QWeatherLocation.reload();
        QWeatherWeather.reload();
        QWeatherLocation.schedule(true);
        _mainView = new CNWatchFaceView();
        return [_mainView];
    }

    function getSettingsView() {
        if (_mainView != null) { _mainView.onSettingsChanged(); }
        var menu = new CNWatchFaceSettingsMenu();
        return [menu, new CNWatchFaceSettingsDelegate(menu)];
    }

    function onSettingsChanged() {
        QWeatherLocation.reload();
        QWeatherWeather.reload();
        Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.DAILY_RETRY_KEY);
        QWeatherLocation.schedule(true);
        if (_mainView != null) { _mainView.onSettingsChanged(); }
        else { WatchUi.requestUpdate(); }
    }

    function getServiceDelegate() { return [new QWeatherLocationService()]; }

    function onBackgroundData(data) {
        QWeatherLocation.reload();
        QWeatherWeather.reload();
        if (_mainView != null) { _mainView.onSettingsChanged(); }
        WatchUi.requestUpdate();
    }
}

// Exclude the complete QWeather implementation on products below 128 KiB.
(:QWeatherEnabled)
module CNWeatherProvider {
    var source = -1;
    function available() { return true; }
    function selectedSource() { return QWeatherWeather.isSelected() ? 1 : 0; }
    function conditions(now) { return QWeatherAdapter.conditions(now); }
    function locationName(fallback) {
        if (QWeatherLocation.configured) { return QWeatherLocation.name != null ? QWeatherLocation.name : "--"; }
        return fallback;
    }
}

(:QWeatherDisabled)
module CNWeatherProvider {
    var source = -1;
    function available() { return false; }
    function selectedSource() { return 0; }
    function conditions(now) { return null; }
    function locationName(fallback) { return fallback; }
}

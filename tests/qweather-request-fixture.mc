module AuditQWeather {
    var coordinates = [39.92, 116.41];
    var useCachedCoordinates = false;
    var requests = 0;
    var scheduled = 0;
    var deleted = 0;
    var responseCode = 200;
    var data = {"code" => "200", "location" => [{"name" => "东城", "adm2" => "北京"}]};
    var url = null;
    var params = null;
    var options = null;
    var result = null;
    var changeCredentials = false;
    var currentResponseCode = 200;
    var dailyResponseCode = 200;
    var currentData = {"temperature" => {"value" => 0, "unit" => "°C"},
        "feelsLike" => {"value" => -2.5, "unit" => "°C"},
        "condition" => {"code" => "400", "text" => "小雪"}, "humidity" => 0.72, "uvIndex" => 0,
        "wind" => {"speed" => {"value" => 3.0, "unit" => "m/s"}, "direction" => {"degree" => 123}}};
    var dailyData = null;
    var urls = [];

    function utcText(seconds) {
        var d = Toybox.Time.Gregorian.utcInfo(new Time.Moment(seconds), Time.FORMAT_SHORT);
        return d.year.format("%04d") + "-" + d.month.format("%02d") + "-" + d.day.format("%02d") +
            "T" + d.hour.format("%02d") + ":" + d.min.format("%02d") + ":" + d.sec.format("%02d") + "Z";
    }

    function prepareDaily() {
        var now = Time.now().value();
        dailyData = {"days" => [{"forecastStartTime" => utcText(now - 3600),
            "forecastEndTime" => utcText(now + 86400),
            "temperatureMax" => {"value" => 5.5, "unit" => "°C"},
            "temperatureMin" => {"value" => -3.0, "unit" => "°C"}, "uvIndexMax" => 2,
            "astro" => {"sunrise" => utcText(now - 1800), "sunset" => utcText(now + 7200)},
            "daytime" => {"forecastStartTime" => utcText(now - 3600), "forecastEndTime" => utcText(now + 43200),
                "precipitation" => {"amount" => {"value" => 12.5, "unit" => "mm"}, "probability" => 0.35}},
            "nighttime" => {"forecastStartTime" => utcText(now + 43200), "forecastEndTime" => utcText(now + 86400),
                "precipitation" => {"probability" => 0.8}}},
            {"astro" => {"sunrise" => utcText(now + 86400)}}]};
    }

    function exit(value) { result = value; }
    function request(requestUrl, requestParams, requestOptions, callback) {
        requests += 1;
        urls.add(requestUrl);
        url = requestUrl;
        params = requestParams;
        options = requestOptions;
        if (changeCredentials) { Application.Properties.setValue("QWeatherKey", "changed-key"); }
        if (requestUrl.find("/weather/v1/current/") != null) { callback.invoke(currentResponseCode, currentData); }
        else if (requestUrl.find("/weather/v1/daily/") != null) { callback.invoke(dailyResponseCode, dailyData); }
        else { callback.invoke(responseCode, data); }
    }
}

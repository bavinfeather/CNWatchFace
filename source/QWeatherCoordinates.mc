using Toybox.Lang;
using Toybox.Math;

// WGS-to-GCJ formula adapted from googollee/eviltransform (BSD-2-Clause).
// See licenses/BSD-2-Clause-eviltransform.txt and THIRD_PARTY_NOTICES.md.
(:background, :QWeatherEnabled)
module QWeatherCoordinates {
    function requestCoordinates(raw as Lang.Array or Null, mainland as Lang.Boolean) as Lang.Array or Null {
        if (!QWeatherLocation.validCoordinates(raw)) { return null; }
        var lat = raw[0].toDouble();
        var lon = raw[1].toDouble();
        // The caller selects mainland explicitly; the bounds are only a guard.
        if (!mainland || lon < 72.004d || lon > 137.8347d || lat < 0.8293d || lat > 55.8271d) { return [lat, lon]; }
        var x = lon - 105.0d;
        var y = lat - 35.0d;
        var pi = 3.141592653589793d;
        var xy = x * y;
        var absX = Math.sqrt(x < 0 ? -x : x).toDouble();
        var xp = x * pi;
        var yp = y * pi;
        var common = 20.0d * Math.sin(6.0d * xp).toDouble() + 20.0d * Math.sin(2.0d * xp).toDouble();
        var dLat = common + 20.0d * Math.sin(yp).toDouble() + 40.0d * Math.sin(yp / 3.0d).toDouble() +
            160.0d * Math.sin(yp / 12.0d).toDouble() + 320.0d * Math.sin(yp / 30.0d).toDouble();
        var dLon = common + 20.0d * Math.sin(xp).toDouble() + 40.0d * Math.sin(xp / 3.0d).toDouble() +
            150.0d * Math.sin(xp / 12.0d).toDouble() + 300.0d * Math.sin(xp / 30.0d).toDouble();
        dLat = dLat * 2.0d / 3.0d - 100.0d + 2.0d * x + 3.0d * y + 0.2d * y * y + 0.1d * xy + 0.2d * absX;
        dLon = dLon * 2.0d / 3.0d + 300.0d + x + 2.0d * y + 0.1d * x * x + 0.1d * xy + 0.1d * absX;
        var rad = lat / 180.0d * pi;
        var magic = Math.sin(rad).toDouble();
        var ee = 0.00669342162296594323d;
        magic = 1.0d - ee * magic * magic;
        var root = Math.sqrt(magic).toDouble();
        dLat = dLat * 180.0d / ((6378137.0d * (1.0d - ee)) / (magic * root) * pi);
        dLon = dLon * 180.0d / (6378137.0d / root * Math.cos(rad).toDouble() * pi);
        return [lat + dLat, lon + dLon];
    }
}

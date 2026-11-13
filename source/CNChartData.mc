using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

(:ChartAmoled)
module CNChartData {
    var labels = {};
    var fitted = [null, null, null, null];
    var sizes = [0, 0, 0, 0];
    function clear() as Void {
        labels = {};
        for (var i = 0; i < fitted.size(); i += 1) { fitted[i] = null; sizes[i] = 0; }
    }
    function label(field as Lang.Number) as Lang.String {
        if (labels.hasKey(field)) { return labels[field]; }
        var fields = CNFieldOptions.options();
        for (var i = 0; i < fields.size(); i += 1) {
            if (fields[i][1] == field) {
                var text = WatchUi.loadResource(fields[i][0]) as Lang.String;
                if (labels.size() >= 4) { labels = {}; }
                labels[field] = text;
                return text;
            }
        }
        return "";
    }

    function font(dc as Graphics.Dc, text as Lang.String, width as Lang.Number, normal, row as Lang.Number) {
        var measured = dc.getTextWidthInPixels(text, normal);
        if (measured <= width) {
            fitted[row] = null;
            sizes[row] = 0;
            return normal;
        }
        if (!(Graphics has :getVectorFont)) { return normal; }
        var size = (dc.getFontHeight(normal) * width / measured * 0.85).toNumber();
        if (size < 8) { size = 8; }
        if (sizes[row] != size || fitted[row] == null) {
            fitted[row] = null;
            try { fitted[row] = Graphics.getVectorFont({:face => "NotoSansSCMedium", :size => size}); }
            catch (e) { return normal; }
            sizes[row] = size;
        }
        return fitted[row] == null ? normal : fitted[row];
    }

    function withUnit(field as Lang.Number, value as Lang.String) as Lang.String {
        var chinese = (WatchUi.loadResource(Rez.Strings.CalendarLanguage) as Lang.String).equals("zh");
        return localizedValue(field, value, chinese);
    }

    function clipText(dc as Graphics.Dc, value as Lang.String, face, width as Lang.Number) as Lang.String {
        if (dc.getTextWidthInPixels(value, face) <= width) { return value; }
        var end = value.length();
        while (end > 0) {
            end -= 1;
            var shortened = value.substring(0, end) + "…";
            if (dc.getTextWidthInPixels(shortened, face) <= width) { return shortened; }
        }
        return "";
    }

    function localizedValue(field as Lang.Number, value as Lang.String, chinese as Lang.Boolean) as Lang.String {
        if (value.equals("--")) { return value; }
        if (field == 1) { return value + (chinese ? " 步" : " steps"); }
        if (field == 2 || field == 25) { return value + (chinese ? " 层" : " fl"); }
        if (field == 3 || field == 23 || field == 24) { return value + (chinese ? " 千卡" : " kcal"); }
        if (field == 4 || field == 33 || field == 52 || (field >= 54 && field <= 59)) { return value + (chinese ? " 公里" : " km"); }
        if (field == 7 || field == 18 || field == 45) { return value + (chinese ? " 次/分" : " bpm"); }
        if (field == 9) { return value + (chinese ? " 秒" : " s"); }
        if (field == 14 || field == 26) { return value + (chinese ? " 分钟" : " min"); }
        if (field == 20) { return value + (chinese ? " 百帕" : " hPa"); }
        if (field == 31) { return value + (chinese ? " 毫升/公斤/分" : " mL/kg/min"); }
        if (field == 49) { return value + (chinese ? " 次/分" : " /min"); }
        if (field == 79) { return value + (chinese ? " 分" : " pts"); }
        if (chinese && (field == 13 || field == 19 || field == 29)) {
            var suffix = field == 13 ? "h" : (field == 19 ? "m" : "d");
            if (value.length() > 1 && value.substring(value.length() - 1, value.length()).equals(suffix)) {
                return value.substring(0, value.length() - 1) + (field == 13 ? " 小时" : (field == 19 ? " 米" : " 天"));
            }
        }
        if (field == 40 && value.length() > 0 && "0123456789".find(value.substring(0, 1)) != null) {
            var divider = value.find("h");
            if (divider != null) {
                return chinese ? value.substring(0, divider) + "小时" + value.substring(divider + 1, value.length()) + "分钟" : value + "m";
            }
        }
        return value;
    }

    function draw(dc as Graphics.Dc, field as Lang.Number, value as Lang.String, cy as Lang.Number, color as Lang.Number, normal, row as Lang.Number) as Void {
        var labelRight = (dc.getWidth() * 0.58).toNumber();
        var valueLeft = (dc.getWidth() * 0.62).toNumber();
        var valueWidth = (dc.getWidth() * 0.30).toNumber();
        value = withUnit(field, value);
        var name = label(field);
        var nameFont = font(dc, name, (dc.getWidth() * 0.25).toNumber(), normal, row * 2);
        name = clipText(dc, name, nameFont, (dc.getWidth() * 0.25).toNumber());
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelRight, cy, nameFont, name, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        var valueFont = font(dc, value, valueWidth, normal, row * 2 + 1);
        value = clipText(dc, value, valueFont, valueWidth);
        dc.drawText(valueLeft, cy, valueFont, value, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}


(:ChartMip)
module CNChartData {
    function clear() as Void {}
    function draw(dc, field, value, cy, color, normal, row) as Void {}
}

using Toybox.Graphics;
using Toybox.Lang;

// Portable AMOLED renderer. Call only in low power; pass formatted clock/date
// and cached field strings. No application properties, resources or sensors.
class SharedAod {
    private var _width = 0;
    private var _timeFont = Graphics.FONT_NUMBER_MEDIUM;
    // Cached proportions from the active face, shared by every AOD frame.
    private const RIDGES = [
        [[0.0, 0.46], [0.12, 0.38], [0.22, 0.44], [0.36, 0.32],
         [0.48, 0.42], [0.60, 0.28], [0.74, 0.40], [0.86, 0.30], [1.0, 0.40]],
        [[0.0, 0.50], [0.14, 0.43], [0.28, 0.50], [0.42, 0.40],
         [0.56, 0.49], [0.70, 0.38], [0.84, 0.48], [1.0, 0.44]]
    ];

    private function dimColor(color as Lang.Number, gain as Lang.Float) as Lang.Number {
        return (((color >> 16) & 255) * gain).toNumber() * 0x010000 +
               (((color >> 8) & 255) * gain).toNumber() * 0x000100 +
               ((color & 255) * gain).toNumber();
    }

    private function drawMountains(dc as Graphics.Dc, shiftX as Lang.Number,
                                   shiftY as Lang.Number, gain as Lang.Float) as Void {
        var h = dc.getHeight();
        // The active face's far/mid ridge proportions, reduced to two lines.
        var lineWidth = (_width / 210).toNumber();
        if (lineWidth < 1) { lineWidth = 1; }
        dc.setPenWidth(lineWidth);
        dc.setColor(dimColor(0x251C18, gain), Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [(_width * 0.562).toNumber() + shiftX, (h * 0.728).toNumber() + shiftY],
            [(_width * 0.600).toNumber() + shiftX, (h * 0.844).toNumber() + shiftY],
            [(_width * 0.649).toNumber() + shiftX, (h * 0.800).toNumber() + shiftY]
        ]);
        for (var r = 0; r < RIDGES.size(); r += 1) {
            dc.setColor(dimColor(r == 0 ? 0x70584C : 0x44362E, gain), Graphics.COLOR_TRANSPARENT);
            var points = RIDGES[r];
            for (var p = 1; p < points.size(); p += 1) {
                dc.drawLine((_width * (0.19 + points[p - 1][0] * 0.62)).toNumber() + shiftX,
                            (h * (0.56 + points[p - 1][1] * 0.60)).toNumber() + shiftY,
                            (_width * (0.19 + points[p][0] * 0.62)).toNumber() + shiftX,
                            (h * (0.56 + points[p][1] * 0.60)).toNumber() + shiftY);
            }
        }
        dc.setColor(dimColor(0x44362E, gain), Graphics.COLOR_TRANSPARENT);
        dc.drawLine((_width * 0.562).toNumber() + shiftX, (h * 0.728).toNumber() + shiftY,
                    (_width * 0.600).toNumber() + shiftX, (h * 0.844).toNumber() + shiftY);
        dc.setPenWidth(1);
    }

    private function prepare(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        if (_width == width) { return; }
        _width = width;
        _timeFont = Graphics.FONT_NUMBER_MEDIUM;
        if (Graphics has :getVectorFont) {
            // Regular strokes leave more black space than the active face's
            // bold digits. Size is independent of active-face font settings.
            try {
                var font = Graphics.getVectorFont({
                    :face => ["RobotoCondensedRegular", "RobotoRegular", "KosugiRegular"],
                    :size => (width * 0.24).toNumber()
                });
                if (font != null) { _timeFont = font; }
            } catch (e) {}
        }
        if (dc.getTextWidthInPixels("88:88", _timeFont) > width * 0.78 ||
            dc.getFontHeight(_timeFont) > dc.getHeight() * 0.30) {
            _timeFont = Graphics.FONT_NUMBER_MILD;
        }
    }

    // Clip exceptional long labels by shortening whole strings before drawing.
    private function fitText(dc as Graphics.Dc, value as Lang.String, limit as Lang.Number) as Lang.String {
        if (dc.getTextWidthInPixels(value, Graphics.FONT_XTINY) <= limit) { return value; }
        var n = value.length();
        while (n > 0) {
            n -= 1;
            var shortened = value.substring(0, n) + "…";
            if (dc.getTextWidthInPixels(shortened, Graphics.FONT_XTINY) <= limit) { return shortened; }
        }
        return "";
    }

    function draw(dc as Graphics.Dc, minute as Lang.Number, timeText as Lang.String,
                  dateText as Lang.String, fields as Lang.Array) as Void {
        prepare(dc);
        var height = dc.getHeight();
        var shiftX = (minute % 5) - 2;
        var shiftY = ((minute / 5).toNumber() % 5) - 2;
        var center = (_width / 2).toNumber() + shiftX;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        // Conservative brightness estimate: filled text boxes, expanded line
        // areas, and the facet bounding box. Use each color's largest channel
        // as an upper bound, not an exact Garmin luminance or burn-in analysis.
        var smallHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var weightedArea = dc.getTextWidthInPixels("88:88", _timeFont) *
            dc.getFontHeight(_timeFont) * 170.0;
        // Reserve fixed row areas so changing values cannot pulse the clock brightness.
        weightedArea += _width * 0.70 * smallHeight * 119.0;
        weightedArea += _width * 0.66 * smallHeight * 102.0;
        var lineWidth = (_width / 210).toNumber();
        if (lineWidth < 1) { lineWidth = 1; }
        weightedArea += (3 * _width + height) * (lineWidth + 2) * 112.0;
        weightedArea += (_width * 0.09 + 2) * (height * 0.12 + 2) * 37.0;
        var budget = _width * height * 0.785398 * 255.0 * 0.08;
        var gain = (weightedArea > budget ? budget / weightedArea : 1.0).toFloat();
        var timeGray = (170 * gain).toNumber();
        var dateGray = (119 * gain).toNumber();
        var fieldGray = (102 * gain).toNumber();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        drawMountains(dc, shiftX, shiftY, gain);
        dc.setColor(timeGray * 0x010101, Graphics.COLOR_TRANSPARENT);
        dc.drawText(center, (height * 0.35).toNumber() + shiftY,
                    _timeFont, timeText, justify);
        dc.setColor(dateGray * 0x010101, Graphics.COLOR_TRANSPARENT);
        dc.drawText(center, (height * 0.51).toNumber() + shiftY,
                    Graphics.FONT_XTINY, fitText(dc, dateText, (_width * 0.70).toNumber()), justify);

        // Compact non-empty fields; hidden fields leave no empty columns.
        var count = 0;
        for (var i = 0; i < fields.size(); i += 1) {
            if (fields[i] != "") { count += 1; }
        }
        if (count == 0) { return; }
        var slot = (_width * 0.66 / count).toNumber();
        var left = center - (((count - 1) * slot) / 2).toNumber();
        var index = 0;
        dc.setColor(fieldGray * 0x010101, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < fields.size(); i += 1) {
            if (fields[i] == "") { continue; }
            dc.drawText(left + index * slot, (height * 0.61).toNumber() + shiftY,
                        Graphics.FONT_XTINY, fitText(dc, fields[i], slot - 6), justify);
            index += 1;
        }
    }
}

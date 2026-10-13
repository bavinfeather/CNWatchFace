using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

module CNTopLabelFonts {
    function face(value) {
        if (value == 1) { return "RobotoRegular"; }
        if (value == 2) { return "RobotoCondensedRegular"; }
        if (value == 3) { return "RobotoItalic"; }
        if (value == 4) { return "RobotoMedium"; }
        return null;
    }

    function supported(value) {
        var available = WatchUi.loadResource(Rez.Strings.TopLabelFontAvailable) as Lang.String;
        return value >= 1 && value <= 4 && available.find(value.toString()) != null;
    }

    function options() as Lang.Array {
        var result = [[Rez.Strings.TopLabelFontDefault, 0]];
        var labels = [Rez.Strings.TopLabelFontStandard, Rez.Strings.TopLabelFontCondensed,
                      Rez.Strings.TopLabelFontItalic, Rez.Strings.TopLabelFontMedium];
        if (Graphics has :getVectorFont) {
            for (var value = 1; value <= 4; value += 1) {
                if (!supported(value)) { continue; }
                try {
                    var font = Graphics.getVectorFont({:face => face(value), :size => 20});
                    if (font != null) { result.add([labels[value - 1], value]); }
                } catch (e) { }
            }
        }
        return result;
    }
}

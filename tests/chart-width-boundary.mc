using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;
module AuditWidth {
    var bitmapOnly = false;
}
class CNWatchFaceView extends WatchUi.WatchFace {
    function initialize() { WatchFace.initialize(); }
    function onSettingsChanged() {}
    function onUpdate(dc as Graphics.Dc) as Void {
        var samples = [
            [53, "这是一个用于检查长地点名称是否会超出右侧列宽的测试城市名称"],
            [50, "A very long weather description that cannot fit inside the chart column"],
            [1, "12860"], [4, "8.6"]
        ];
        for (var mode = 0; mode < 2; mode += 1) {
            AuditWidth.bitmapOnly = mode == 1;
            for (var i = 0; i < samples.size(); i += 1) {
                CNChartData.draw(dc, samples[i][0], samples[i][1], dc.getHeight() / 2,
                    Graphics.COLOR_WHITE, Graphics.FONT_SMALL, i % 2);
            }
        }
        System.println("AUDIT_COMPLETE chart-width cases=8");
    }
}

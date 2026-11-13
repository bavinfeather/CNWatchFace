module ChartLocalizationAudit {
    function run() {
        var cases = [
            [1, "12860", "12860 步", "12860 steps"],
            [4, "8.6", "8.6 公里", "8.6 km"],
            [54, "12.3", "12.3 公里", "12.3 km"],
            [7, "80", "80 次/分", "80 bpm"],
            [3, "500", "500 千卡", "500 kcal"],
            [14, "30", "30 分钟", "30 min"],
            [20, "1013", "1013 百帕", "1013 hPa"],
            [13, "2.5h", "2.5 小时", "2.5h"],
            [19, "120m", "120 米", "120m"],
            [29, "4.2d", "4.2 天", "4.2d"],
            [40, "3h20", "3小时20分钟", "3h20m"],
            [40, "Night", "Night", "Night"],
            [5, "50%", "50%", "50%"],
            [12, "17°C", "17°C", "17°C"],
            [4, "--", "--", "--"]
        ];
        for (var i = 0; i < cases.size(); i += 1) {
            for (var language = 0; language < 2; language += 1) {
                var actual = CNChartData.localizedValue(cases[i][0], cases[i][1], language == 0);
                if (!actual.equals(cases[i][language + 2])) {
                    Toybox.System.println("CHART_LOCALE_FAIL " + i + ":" + language);
                    throw new Toybox.Lang.InvalidValueException("chart units");
                }
            }
        }
        Toybox.System.println("CHART_LOCALE_COMPLETE assertions=30");
    }
}

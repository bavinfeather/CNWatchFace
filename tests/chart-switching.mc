    private function auditChartMapping(dc as Graphics.Dc) {
        var icons = [
            [1, Rez.Drawables.MdiShoePrint], [2, Rez.Drawables.MdiStairs],
            [3, Rez.Drawables.MdiFire], [4, Rez.Drawables.MdiMapMarkerDistance],
            [5, Rez.Drawables.MdiBattery], [7, Rez.Drawables.MdiHeart],
            [8, Rez.Drawables.BodyBatteryIcon], [12, Rez.Drawables.MdiThermometer],
            [16, Rez.Drawables.MdiSunrise], [17, Rez.Drawables.MdiSunset],
            [19, Rez.Drawables.MdiTerrain], [20, Rez.Drawables.MdiGauge],
            [21, Rez.Drawables.MdiMolecule], [22, Rez.Drawables.MdiCalendar],
            [38, Rez.Drawables.MdiWeatherRainy], [48, Rez.Drawables.MdiAlarm],
            [49, Rez.Drawables.MdiWaves], [50, Rez.Drawables.MdiWeatherPartlyCloudy],
            [53, Rez.Drawables.MdiMapMarker], [54, Rez.Drawables.MdiMapMarkerDistance],
            [57, Rez.Drawables.MdiBike], [73, Rez.Drawables.MdiSunny]
        ];
        for (var i = 0; i < icons.size(); i += 1) {
            auditAssert(fieldIconResource(icons[i][0]) == icons[i][1], "field icon mapping " + icons[i][0]);
        }
        AuditChart.fields = CNFieldOptions.options();
        for (var i = 0; i < AuditChart.fields.size(); i += 1) {
            var entry = AuditChart.fields[i];
            AuditChart.rendered.add(false);
            auditAssert(CNChartData.label(entry[1]).equals(WatchUi.loadResource(entry[0])), "field label mapping " + entry[1]);
            auditAssert(entry[1] == 0 || fieldIconResource(entry[1]) != null, "available field has an icon " + entry[1]);
        }
        System.println("CHART_MAPPING_COMPLETE fields=" + AuditChart.fields.size() + " icons=" + icons.size());
    }

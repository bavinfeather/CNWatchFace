// One valid recent activity makes the iterator enter week/date calculations.
class AuditHistoryActivity {
    public var startTime;
    public var distance = 5000.0;
    public var type = Activity.SPORT_RUNNING;
    function initialize() { startTime = Time.now(); }
}
class AuditHistoryIterator {
    private var sent = false;
    function next() {
        if (sent) { return null; }
        sent = true;
        return new AuditHistoryActivity();
    }
}

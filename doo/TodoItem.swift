import Foundation

struct TodoItem: Identifiable, Equatable {
    let id = UUID()
    var over = false
    var content = ""
    var elapsedTime: TimeInterval = 0
    private(set) var startedAt: Date?

    var isRunning: Bool { startedAt != nil }

    init(_ content: String = "", _ over: Bool = false, elapsedTime: TimeInterval = 0) {
        self.content = content
        self.over = over
        self.elapsedTime = elapsedTime
    }

    func totalElapsedTime(at date: Date = Date()) -> TimeInterval {
        guard let startedAt else { return elapsedTime }
        let midnight = Calendar.autoupdatingCurrent.dateInterval(of: .day, for: startedAt)?.end ?? date
        return elapsedTime + max(0, min(date, midnight).timeIntervalSince(startedAt))
    }

    func formattedElapsedTime(at date: Date = Date()) -> String {
        Self.formatDuration(totalElapsedTime(at: date))
    }

    static func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(max(0, duration))
        if seconds <= 60 { return "\(seconds)秒" }
        if seconds < 3600 { return "\(seconds / 60)分\(seconds % 60)秒" }
        return "\(seconds / 3600)时\(seconds % 3600 / 60)分"
    }

    mutating func pauseExecutionIfDayChanged(at date: Date = Date()) {
        guard let startedAt,
              !Calendar.autoupdatingCurrent.isDate(startedAt, inSameDayAs: date) else { return }
        pauseExecution(at: date)
    }

    mutating func toggleExecution(at date: Date = Date()) {
        guard !over, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if isRunning {
            pauseExecution(at: date)
        } else {
            startedAt = date
        }
    }

    mutating func pauseExecution(at date: Date = Date()) {
        elapsedTime = totalElapsedTime(at: date)
        startedAt = nil
    }

    mutating func toggleCompletion(at date: Date = Date()) {
        pauseExecution(at: date)
        over.toggle()
    }
}

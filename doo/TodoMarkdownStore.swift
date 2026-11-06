import Foundation

struct TodoDaySnapshot {
    let items: [TodoItem]
    let sectionExists: Bool
}

final class TodoMarkdownStore {
    static func storageDirectoryURL(fileManager: FileManager = .default) -> URL {
        let appSupportDirectory =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let bundleName = Bundle.main.bundleIdentifier ?? "doo"
        return appSupportDirectory.appendingPathComponent(bundleName, isDirectory: true)
    }

    static func storageFileURL(fileManager: FileManager = .default) -> URL {
        storageDirectoryURL(fileManager: fileManager)
            .appendingPathComponent("todos.md", isDirectory: false)
    }

    private let fileManager: FileManager
    private let todayProvider: () -> Date
    private let fileURL: URL
    private let formatter: DateFormatter
    private let sectionHeaderExpression = try! NSRegularExpression(
        pattern: #"(?m)^## (\d{4}-\d{2}-\d{2})\s*$"#
    )
    private let itemExpression = try! NSRegularExpression(
        pattern: #"(?m)^- \[( |x)\] (.+?)\s*$"#
    )

    private let durationExpression = try! NSRegularExpression(
        pattern: #" \[耗时: (?:([0-9]+)时([0-9]+)分|([0-9]+)分([0-9]+)秒|([0-9]+(?:\.[0-9]+)?) ?秒)\](?: <!-- elapsed: [0-9]+(?:\.[0-9]+)? -->)?$"#
    )

    init(
        fileManager: FileManager = .default,
        calendar: Calendar = .autoupdatingCurrent,
        todayProvider: @escaping () -> Date = Date.init,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.todayProvider = todayProvider

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        self.formatter = formatter

        self.fileURL = fileURL ?? Self.storageFileURL(fileManager: fileManager)
    }

    func loadToday() -> TodoDaySnapshot {
        let document = readDocument()
        let dateKey = currentDateKey()

        guard let sectionRange = sectionRange(for: dateKey, in: document) else {
            return TodoDaySnapshot(items: [], sectionExists: false)
        }

        let sectionText = nsString(for: document).substring(with: sectionRange)
        return TodoDaySnapshot(
            items: parseItems(from: sectionText),
            sectionExists: true
        )
    }

    func todayKey() -> String {
        currentDateKey()
    }

    func loadPreviousDayIncompleteItems() -> [TodoItem] {
        guard let previousDay = formatter.calendar.date(byAdding: .day, value: -1, to: todayProvider()) else {
            return []
        }

        let dateKey = formatter.string(from: previousDay)
        let document = readDocument()

        guard let sectionRange = sectionRange(for: dateKey, in: document) else {
            return []
        }

        let sectionText = nsString(for: document).substring(with: sectionRange)
        return parseItems(from: sectionText).filter { !$0.over }
    }

    @discardableResult
    func syncToday(with items: [TodoItem], sectionExists: Bool, dateKey: String? = nil) -> Bool {
        let persistedItems = items
            .map { item in
                var item = item
                item.content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return item
            }
            .filter { !$0.content.isEmpty }

        guard sectionExists || !persistedItems.isEmpty else {
            return false
        }

        let document = readDocument()
        let dateKey = dateKey ?? currentDateKey()
        let renderedSection = renderSection(for: dateKey, items: persistedItems)

        let updatedDocument: String
        if let existingRange = sectionRange(for: dateKey, in: document) {
            updatedDocument = nsString(for: document).replacingCharacters(
                in: existingRange,
                with: renderedSection + "\n\n"
            )
        } else {
            let trimmedDocument = document.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedDocument =
                trimmedDocument.isEmpty ? renderedSection : "\(trimmedDocument)\n\n\(renderedSection)"
        }

        let normalizedDocument = updatedDocument.trimmingCharacters(in: .newlines) + "\n"
        if normalizedDocument != document {
            writeDocument(normalizedDocument)
        }
        return true
    }

    private func currentDateKey() -> String {
        formatter.string(from: todayProvider())
    }

    private func readDocument() -> String {
        guard let data = try? Data(contentsOf: fileURL),
              let document = String(data: data, encoding: .utf8)
        else {
            return ""
        }

        return document
    }

    private func writeDocument(_ document: String) {
        let directoryURL = fileURL.deletingLastPathComponent()
        try? fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? document.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func parseItems(from sectionText: String) -> [TodoItem] {
        let nsSection = nsString(for: sectionText)
        let matches = itemExpression.matches(
            in: sectionText,
            range: NSRange(location: 0, length: nsSection.length)
        )

        return matches.compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }
            let completionMark = nsSection.substring(with: match.range(at: 1))
            var content = nsSection.substring(with: match.range(at: 2))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            var elapsedTime: TimeInterval = 0
            let nsContent = content as NSString
            if let match = durationExpression.firstMatch(
                in: content,
                range: NSRange(location: 0, length: nsContent.length)
            ) {
                let multipliers: [TimeInterval] = [3600, 60, 60, 1, 1]
                for (index, multiplier) in multipliers.enumerated() {
                    let range = match.range(at: index + 1)
                    guard range.location != NSNotFound else { continue }
                    elapsedTime += (TimeInterval(nsContent.substring(with: range)) ?? 0) * multiplier
                }
                if elapsedTime.isFinite {
                    content = nsContent.substring(to: match.range.location)
                } else {
                    elapsedTime = 0
                }
            }
            guard !content.isEmpty else { return nil }
            return TodoItem(content, completionMark == "x", elapsedTime: elapsedTime)
        }
    }

    private func renderSection(for dateKey: String, items: [TodoItem]) -> String {
        let itemLines = items.map { item in
            let elapsedTime = item.totalElapsedTime(at: todayProvider())
            let suffix = elapsedTime > 0 || item.isRunning
                ? " [耗时: \(TodoItem.formatDuration(elapsedTime))]"
                : ""
            return "- [\(item.over ? "x" : " ")] \(item.content)\(suffix)"
        }

        guard !itemLines.isEmpty else {
            return "## \(dateKey)"
        }

        return "## \(dateKey)\n" + itemLines.joined(separator: "\n")
    }

    private func sectionRange(for dateKey: String, in document: String) -> NSRange? {
        let nsDocument = nsString(for: document)
        let matches = sectionHeaderExpression.matches(
            in: document,
            range: NSRange(location: 0, length: nsDocument.length)
        )

        var locatedRange: NSRange?
        for (index, match) in matches.enumerated() {
            guard match.numberOfRanges > 1 else { continue }
            let matchDate = nsDocument.substring(with: match.range(at: 1))
            guard matchDate == dateKey else { continue }

            let nextLocation = index + 1 < matches.count
                ? matches[index + 1].range.location
                : nsDocument.length
            locatedRange = NSRange(
                location: match.range.location,
                length: nextLocation - match.range.location
            )
        }

        return locatedRange
    }

    private func nsString(for string: String) -> NSString {
        string as NSString
    }
}

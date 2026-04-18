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

    init(
        fileManager: FileManager = .default,
        calendar: Calendar = .autoupdatingCurrent,
        todayProvider: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.todayProvider = todayProvider

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        self.formatter = formatter

        self.fileURL = Self.storageFileURL(fileManager: fileManager)
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

    @discardableResult
    func syncToday(with items: [TodoItem], sectionExists: Bool) -> Bool {
        let persistedItems = items
            .map { TodoItem($0.content.trimmingCharacters(in: .whitespacesAndNewlines), $0.over) }
            .filter { !$0.content.isEmpty }

        guard sectionExists || !persistedItems.isEmpty else {
            return false
        }

        let document = readDocument()
        let dateKey = currentDateKey()
        let renderedSection = renderSection(for: dateKey, items: persistedItems)

        let updatedDocument: String
        if let existingRange = sectionRange(for: dateKey, in: document) {
            updatedDocument = nsString(for: document).replacingCharacters(
                in: existingRange,
                with: renderedSection
            )
        } else {
            let trimmedDocument = document.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedDocument =
                trimmedDocument.isEmpty ? renderedSection : "\(trimmedDocument)\n\n\(renderedSection)"
        }

        writeDocument(updatedDocument + "\n")
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
            let content = nsSection.substring(with: match.range(at: 2))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !content.isEmpty else { return nil }
            return TodoItem(content, completionMark == "x")
        }
    }

    private func renderSection(for dateKey: String, items: [TodoItem]) -> String {
        let itemLines = items.map { item in
            "- [\(item.over ? "x" : " ")] \(item.content)"
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

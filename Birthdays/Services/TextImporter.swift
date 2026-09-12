import Foundation

/// Parses pasted text like "Anna Meier, 14 September 1990" into birthdays.
enum TextImporter {
    struct ParsedLine: Identifiable {
        let id = UUID()
        let raw: String
        let birthday: Birthday?
    }

    static func parse(_ text: String) -> [ParsedLine] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { ParsedLine(raw: $0, birthday: parseLine($0)) }
    }

    private struct DateMatch {
        var range: Range<String.Index>
        var month: Int
        var day: Int
        var year: Int?
    }

    static func parseLine(_ line: String) -> Birthday? {
        let finders: [(String) -> DateMatch?] = [isoDate, dottedDate, slashedDate, monthNameThenDay, dayThenMonthName]
        for find in finders {
            guard let match = find(line) else { continue }
            guard (1...12).contains(match.month), (1...31).contains(match.day) else { continue }
            let name = cleanName(line, removing: match.range)
            guard !name.isEmpty else { continue }
            return Birthday(name: name, month: match.month, day: match.day, year: match.year, source: .text)
        }
        return nil
    }

    // MARK: - Patterns

    private static func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    private static func firstMatch(_ pattern: String, in line: String) -> (Range<String.Index>, [String?])? {
        let re = regex(pattern)
        guard let m = re.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let whole = Range(m.range, in: line) else { return nil }
        var groups: [String?] = []
        for i in 1..<m.numberOfRanges {
            groups.append(Range(m.range(at: i), in: line).map { String(line[$0]) })
        }
        return (whole, groups)
    }

    /// 1990-09-14
    private static func isoDate(_ line: String) -> DateMatch? {
        guard let (range, g) = firstMatch(#"\b(\d{4})-(\d{1,2})-(\d{1,2})\b"#, in: line),
              let y = g[0].flatMap(Int.init), let m = g[1].flatMap(Int.init), let d = g[2].flatMap(Int.init) else { return nil }
        return DateMatch(range: range, month: m, day: d, year: normalizeYear(y))
    }

    /// 14.9.1990, 14.09., 14.9
    private static func dottedDate(_ line: String) -> DateMatch? {
        guard let (range, g) = firstMatch(#"\b(\d{1,2})\.(\d{1,2})\.?\s?(\d{2,4})?\b"#, in: line),
              let d = g[0].flatMap(Int.init), let m = g[1].flatMap(Int.init) else { return nil }
        return DateMatch(range: range, month: m, day: d, year: g[2].flatMap(Int.init).flatMap(normalizeYear))
    }

    /// 9/14/1990 or 14/9/1990, decided by the values and the user's locale.
    private static func slashedDate(_ line: String) -> DateMatch? {
        guard let (range, g) = firstMatch(#"\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b"#, in: line),
              let a = g[0].flatMap(Int.init), let b = g[1].flatMap(Int.init) else { return nil }
        let year = g[2].flatMap(Int.init).flatMap(normalizeYear)
        if a > 12 { return DateMatch(range: range, month: b, day: a, year: year) }
        if b > 12 { return DateMatch(range: range, month: a, day: b, year: year) }
        return monthFirstLocale
            ? DateMatch(range: range, month: a, day: b, year: year)
            : DateMatch(range: range, month: b, day: a, year: year)
    }

    /// September 14, 1990 / Sep 14 / Sept. 14th
    private static func monthNameThenDay(_ line: String) -> DateMatch? {
        guard let (range, g) = firstMatch(#"\b([A-Za-zÄÖÜäöüéû]{3,})\.?\s+(\d{1,2})(?:st|nd|rd|th|\.)?,?(?:\s+(\d{4}))?\b"#, in: line),
              let m = g[0].flatMap(monthNumber), let d = g[1].flatMap(Int.init) else { return nil }
        return DateMatch(range: range, month: m, day: d, year: g[2].flatMap(Int.init).flatMap(normalizeYear))
    }

    /// 14 September 1990 / 14. Sept. / 14th of Sep
    private static func dayThenMonthName(_ line: String) -> DateMatch? {
        guard let (range, g) = firstMatch(#"\b(\d{1,2})(?:st|nd|rd|th|\.)?\s*(?:of\s+)?([A-Za-zÄÖÜäöüéû]{3,})\.?,?(?:\s+(\d{4}))?\b"#, in: line),
              let d = g[0].flatMap(Int.init), let m = g[1].flatMap(monthNumber) else { return nil }
        return DateMatch(range: range, month: m, day: d, year: g[2].flatMap(Int.init).flatMap(normalizeYear))
    }

    // MARK: - Helpers

    private static var monthFirstLocale: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "MMdd", options: 0, locale: .current) ?? "MMdd"
        return format.lowercased().hasPrefix("m")
    }

    private static let monthNames: [String: Int] = {
        var map: [String: Int] = [:]
        for id in ["en_US", "de_DE", "fr_FR", "it_IT", "es_ES"] {
            let f = DateFormatter()
            f.locale = Locale(identifier: id)
            for (i, name) in f.monthSymbols.enumerated() { map[name.lowercased()] = i + 1 }
            for (i, name) in f.shortMonthSymbols.enumerated() {
                map[name.lowercased().replacingOccurrences(of: ".", with: "")] = i + 1
            }
        }
        map["sept"] = 9
        return map
    }()

    private static func monthNumber(_ word: String) -> Int? {
        let key = word.lowercased().replacingOccurrences(of: ".", with: "")
        if let n = monthNames[key] { return n }
        // Allow a unique prefix of at least 3 letters, e.g. "Septem".
        let candidates = Set(monthNames.filter { $0.key.hasPrefix(key) && key.count >= 3 }.map(\.value))
        return candidates.count == 1 ? candidates.first : nil
    }

    private static func normalizeYear(_ y: Int) -> Int? {
        let current = Calendar.current.component(.year, from: .now)
        if y < 100 {
            let full = y + 2000
            return full > current ? y + 1900 : full
        }
        return (1900...current).contains(y) ? y : nil
    }

    private static func cleanName(_ line: String, removing range: Range<String.Index>) -> String {
        var text = line
        text.removeSubrange(range)
        text = text.replacingOccurrences(of: #"(?i)\b(born|geb\.?|geboren|birthday|bday|geburtstag)\b"#, with: "", options: .regularExpression)
        let junk = CharacterSet(charactersIn: ",;:.-–—|()*\t").union(.whitespacesAndNewlines)
        text = text.trimmingCharacters(in: junk)
        return text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

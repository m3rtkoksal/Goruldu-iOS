import Foundation

/// Reads a WhatsApp text export (iOS or Android layout, Turkish or English) into messages.
///
/// The rules live in `karne/KARNE-KURALLARI.md` of the API repository; `reference/report.py`
/// there is normative and this file follows it line by line.
enum ChatParser {
    private typealias Scalars = TextRules.Scalars

    private struct Header {
        var first: Int
        var second: Int
        var year: Int
        var hour: Int
        var minute: Int
        var second60: Int
        var meridiem: Meridiem
        var rest: Scalars
    }

    private enum Meridiem { case none, am, pm }

    private enum RawLine {
        case header(Header)
        case continuation(Scalars)
    }

    private struct Draft {
        var sender: String
        var time: ChatTime
        var text: Scalars
        var marked: Bool
    }

    static func parse(_ text: String) throws -> [ChatMessage] {
        var raw: [RawLine] = []
        var headerCount = 0
        forEachLine(of: text) { line in
            var start = 0
            while start < line.count, TextRules.bidiMarks.contains(line[start]) { start += 1 }
            if let header = matchHeader(line, from: start) {
                raw.append(.header(header))
                headerCount += 1
            } else {
                raw.append(.continuation(TextRules.stripBidi(line)))
            }
        }
        guard headerCount > 0 else { throw ReportError.unrecognized }

        let headers: [Header] = raw.compactMap { line in
            if case .header(let header) = line { return header }
            return nil
        }
        let dayFirst = decideDayFirst(headers)

        var drafts: [Draft] = []
        var hasCurrent = false
        for line in raw {
            switch line {
            case .continuation(let extra):
                if hasCurrent {
                    drafts[drafts.count - 1].text.append("\n")
                    drafts[drafts.count - 1].text.append(contentsOf: extra)
                }
            case .header(let header):
                hasCurrent = false
                guard let time = time(of: header, dayFirst: dayFirst),
                      let split = firstColonSpace(in: header.rest)
                else { continue }
                let senderScalars = TextRules.trim(TextRules.stripBidi(Array(header.rest[..<split])))
                guard !senderScalars.isEmpty, senderScalars.count <= ReportRules.maxSenderLength else { continue }
                let body = Array(header.rest[(split + 2)...])
                let marked = body.first(where: { $0 != " " }) == TextRules.leftToRightMark
                drafts.append(Draft(
                    sender: TextRules.string(senderScalars),
                    time: time,
                    text: TextRules.stripBidi(body),
                    marked: marked
                ))
                hasCurrent = true
            }
        }

        var result: [ChatMessage] = []
        result.reserveCapacity(drafts.count)
        for draft in drafts {
            var body = TextRules.trim(draft.text)
            var low = TextRules.lower(body, turkish: false)
            for suffix in TextRules.editedSuffixes where TextRules.hasSuffix(low, suffix) {
                body = TextRules.trim(Array(body.prefix(max(0, body.count - suffix.count))))
                low = TextRules.lower(body, turkish: false)
            }
            var probe = low
            while probe.last == "." { probe.removeLast() }

            let kind: ChatMessage.Kind
            if TextRules.mediaExact.contains(probe)
                || TextRules.mediaPrefixes.contains(where: { probe.starts(with: $0) })
                || TextRules.mediaSuffixes.contains(where: { TextRules.hasSuffix(probe, $0) }) {
                kind = .media
            } else if TextRules.deletedExact.contains(probe) {
                kind = .deleted
            } else if draft.marked || TextRules.containsAny(low, TextRules.systemContains) {
                continue
            } else {
                kind = .text
            }
            result.append(ChatMessage(sender: draft.sender, time: draft.time, kind: kind, text: TextRules.string(body)))
        }
        guard !result.isEmpty else { throw ReportError.unrecognized }
        return result
    }

    // MARK: - Lines

    /// Splits on `\r\n`, `\r` and `\n`, and turns narrow and regular no-break spaces into spaces.
    private static func forEachLine(of text: String, _ body: (Scalars) -> Void) {
        var line: Scalars = []
        var previousWasCarriageReturn = false
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\r":
                body(line)
                line.removeAll(keepingCapacity: true)
                previousWasCarriageReturn = true
                continue
            case "\n":
                if !previousWasCarriageReturn {
                    body(line)
                    line.removeAll(keepingCapacity: true)
                }
            case "\u{202F}", "\u{00A0}":
                line.append(" ")
            default:
                line.append(scalar)
            }
            previousWasCarriageReturn = false
        }
        body(line)
    }

    // MARK: - Header

    /// Matches `[date time] rest` (iOS) or `date time - rest` (Android).
    private static func matchHeader(_ line: Scalars, from start: Int) -> Header? {
        if start < line.count, line[start] == "[" {
            return matchHeader(line, from: start + 1, tail: ["]", " "])
        }
        return matchHeader(line, from: start, tail: [" ", "-", " "])
    }

    private static func matchHeader(_ line: Scalars, from start: Int, tail: Scalars) -> Header? {
        var position = start

        func peek(_ offset: Int = 0) -> Unicode.Scalar? {
            position + offset < line.count ? line[position + offset] : nil
        }
        func digits(min: Int, max: Int) -> Int? {
            var value = 0
            var count = 0
            while count < max, let scalar = peek(), scalar.value >= 48, scalar.value <= 57 {
                value = value * 10 + Int(scalar.value - 48)
                count += 1
                position += 1
            }
            return count >= min ? value : nil
        }
        func take(where matches: (Unicode.Scalar) -> Bool) -> Bool {
            guard let scalar = peek(), matches(scalar) else { return false }
            position += 1
            return true
        }
        func isDateSeparator(_ scalar: Unicode.Scalar) -> Bool { scalar == "." || scalar == "/" || scalar == "-" }
        func isTimeSeparator(_ scalar: Unicode.Scalar) -> Bool { scalar == ":" || scalar == "." }
        func isDigit(_ scalar: Unicode.Scalar?) -> Bool {
            guard let scalar else { return false }
            return scalar.value >= 48 && scalar.value <= 57
        }

        guard let first = digits(min: 1, max: 2), take(where: isDateSeparator),
              let second = digits(min: 1, max: 2), take(where: isDateSeparator),
              let rawYear = digits(min: 2, max: 4)
        else { return nil }
        _ = take { $0 == "," }
        guard take(where: { $0 == " " }),
              let hour = digits(min: 1, max: 2), take(where: isTimeSeparator),
              let minute = digits(min: 2, max: 2)
        else { return nil }

        var seconds = 0
        if let separator = peek(), isTimeSeparator(separator), isDigit(peek(1)), isDigit(peek(2)) {
            position += 1
            seconds = digits(min: 2, max: 2) ?? 0
        }

        var meridiem = Meridiem.none
        let beforeMeridiem = position
        if peek() == " " { position += 1 }
        if let letter = peek(), letter == "A" || letter == "a" || letter == "P" || letter == "p" {
            var cursor = 1
            if peek(cursor) == "." { cursor += 1 }
            if let m = peek(cursor), m == "M" || m == "m" {
                cursor += 1
                if peek(cursor) == "." { cursor += 1 }
                position += cursor
                meridiem = (letter == "P" || letter == "p") ? .pm : .am
            }
        } else if peek() == "Ö", let next = peek(1), next == "Ö" || next == "S" {
            position += 2
            meridiem = next == "S" ? .pm : .am
        }
        if meridiem == .none { position = beforeMeridiem }

        for expected in tail {
            guard take(where: { $0 == expected }) else { return nil }
        }
        return Header(
            first: first, second: second, year: rawYear, hour: hour, minute: minute,
            second60: seconds, meridiem: meridiem, rest: Array(line[position...])
        )
    }

    private static func firstColonSpace(in scalars: Scalars) -> Int? {
        guard scalars.count >= 2 else { return nil }
        for index in 0..<(scalars.count - 1) where scalars[index] == ":" && scalars[index + 1] == " " {
            return index
        }
        return nil
    }

    // MARK: - Dates

    private static func decideDayFirst(_ headers: [Header]) -> Bool {
        if headers.contains(where: { $0.first > 12 }) { return true }
        if headers.contains(where: { $0.second > 12 }) { return false }

        func inversions(dayFirst: Bool) -> Int {
            var count = 0
            var previous: ChatTime?
            for header in headers {
                guard let current = time(of: header, dayFirst: dayFirst) else { continue }
                if let previous, current < previous { count += 1 }
                previous = current
            }
            return count
        }
        return inversions(dayFirst: true) <= inversions(dayFirst: false)
    }

    private static func time(of header: Header, dayFirst: Bool) -> ChatTime? {
        let day = dayFirst ? header.first : header.second
        let month = dayFirst ? header.second : header.first
        let year = header.year < 100 ? header.year + 2000 : header.year
        var hour = header.hour
        switch header.meridiem {
        case .none: break
        case .pm: if hour != 12 { hour += 12 }
        case .am: if hour == 12 { hour = 0 }
        }
        return ChatTime(year: year, month: month, day: day, hour: hour, minute: header.minute, second: header.second60)
    }
}

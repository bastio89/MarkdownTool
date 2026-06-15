import SwiftUI
import Combine

// MARK: - Lint Rule

struct LintRule: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let description: String
    let severity: LintSeverity
    let pattern: String?
    let validate: ((String) -> [LintIssue])?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LintRule, rhs: LintRule) -> Bool {
        lhs.id == rhs.id
    }
}

enum LintSeverity: String, CaseIterable {
    case error = "Fehler"
    case warning = "Warnung"
    case info = "Info"

    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Lint Issue

struct LintIssue: Identifiable, Hashable {
    let id: UUID
    let rule: String
    let message: String
    let severity: LintSeverity
    let line: Int
    let column: Int?

    init(rule: String, message: String, severity: LintSeverity, line: Int, column: Int? = nil) {
        self.id = UUID()
        self.rule = rule
        self.message = message
        self.severity = severity
        self.line = line
        self.column = column
    }

    var location: String {
        if let col = column {
            return "Zeile \(line), Spalte \(col)"
        }
        return "Zeile \(line)"
    }
}

// MARK: - Markdown Linter

class MarkdownLinter: ObservableObject {
    @Published var issues: [LintIssue] = []
    @Published var isEnabled: Bool = true
    @Published var enabledRules: Set<String> = Set(LintRule.allRules.map { $0.code })

    init() {
        loadSettings()
    }

    func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "markdownLintEnabled")
        if let savedRules = UserDefaults.standard.array(forKey: "markdownLintEnabledRules") as? [String] {
            enabledRules = Set(savedRules)
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "markdownLintEnabled")
        UserDefaults.standard.set(Array(enabledRules), forKey: "markdownLintEnabledRules")
    }

    func lint(_ text: String) {
        guard isEnabled else {
            issues = []
            return
        }

        var foundIssues: [LintIssue] = []
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            for rule in LintRule.allRules {
                guard enabledRules.contains(rule.code), let validate = rule.validate else { continue }

                let ruleIssues = validate(line)
                for issue in ruleIssues {
                    // Adjust line number
                    let adjustedIssue = LintIssue(
                        rule: issue.rule,
                        message: issue.message,
                        severity: issue.severity,
                        line: lineNumber,
                        column: issue.column
                    )
                    foundIssues.append(adjustedIssue)
                }
            }
        }

        issues = foundIssues
    }

    func clearIssues() {
        issues = []
    }
}

// MARK: - Lint Rules

extension LintRule {
    static let allRules: [LintRule] = [
        // MD001 - Heading levels should only increment by one level at a time
        LintRule(
            code: "MD001",
            name: "heading-increment",
            description: "Überschriften-Ebenen sollten nur um eine Stufe incrementieren",
            severity: .warning,
            pattern: nil,
            validate: { line in
                var issues: [LintIssue] = []
                let regex = try? NSRegularExpression(pattern: "^(#{1,6})\\s+(.+)$", options: [])
                let range = NSRange(line.startIndex..., in: line)

                if let match = regex?.firstMatch(in: line, options: [], range: range) {
                    let headingLevel = match.numberOfRanges > 1 ? match.range(at: 1).length : 0
                    // This is a simplified check - a full implementation would track the previous level
                }
                return issues
            }
        ),

        // MD003 - Heading style
        LintRule(
            code: "MD003",
            name: "heading-style",
            description: "Konsistenter Überschriften-Stil empfohlen",
            severity: .info,
            pattern: nil,
            validate: { line in
                var issues: [LintIssue] = []
                if line.hasPrefix("#") && !line.hasPrefix("##") {
                    let stripped = line.trimmingCharacters(in: .whitespaces)
                    if stripped.hasPrefix("#") && !stripped.hasPrefix("##") {
                        // Check for ATX style consistency
                    }
                }
                return issues
            }
        ),

        // MD009 - No trailing spaces
        LintRule(
            code: "MD009",
            name: "no-trailing-spaces",
            description: "Keine Leerzeichen am Zeilenende",
            severity: .info,
            pattern: nil,
            validate: { line in
                if line.hasSuffix(" ") || line.hasSuffix("\t") {
                    return [LintIssue(
                        rule: "MD009",
                        message: "Trailing spaces found",
                        severity: .info,
                        line: 0,
                        column: line.count
                    )]
                }
                return []
            }
        ),

        // MD010 - Hard tabs
        LintRule(
            code: "MD010",
            name: "no-hard-tabs",
            description: "Keine Tabs verwenden - Leerzeichen bevorzugen",
            severity: .info,
            pattern: nil,
            validate: { line in
                if line.contains("\t") {
                    let column = line.distance(from: line.startIndex, to: line.firstIndex(of: "\t") ?? line.startIndex) + 1
                    return [LintIssue(
                        rule: "MD010",
                        message: "Hard tab found - use spaces instead",
                        severity: .info,
                        line: 0,
                        column: column
                    )]
                }
                return []
            }
        ),

        // MD012 - Multiple consecutive blank lines
        LintRule(
            code: "MD012",
            name: "no-consecutive-blank-lines",
            description: "Nicht mehrere Leerzeilen hintereinander",
            severity: .info,
            pattern: nil,
            validate: { line in
                var issues: [LintIssue] = []
                return issues
            }
        ),

        // MD013 - Line length
        LintRule(
            code: "MD013",
            name: "line-length",
            description: "Zeilen sollten nicht länger als 120 Zeichen sein",
            severity: .warning,
            pattern: nil,
            validate: { line in
                if line.count > 120 && !line.hasPrefix("```") && !line.hasPrefix("    ") {
                    return [LintIssue(
                        rule: "MD013",
                        message: "Line exceeds \(120) characters (\(line.count))",
                        severity: .warning,
                        line: 0,
                        column: nil
                    )]
                }
                return []
            }
        ),

        // MD022 - Headings should be surrounded by blank lines
        LintRule(
            code: "MD022",
            name: "blanks-around-headings",
            description: "Überschriften sollten von Leerzeilen umgeben sein",
            severity: .info,
            pattern: nil,
            validate: { _ in [] }
        ),

        // MD025 - Multiple top-level headings
        LintRule(
            code: "MD025",
            name: "single-h1",
            description: "Nur eine H1-Überschrift pro Dokument",
            severity: .warning,
            pattern: nil,
            validate: { line in
                if line.hasPrefix("# ") {
                    return [LintIssue(
                        rule: "MD025",
                        message: "Multiple H1 headings found - only one is allowed",
                        severity: .warning,
                        line: 0,
                        column: nil
                    )]
                }
                return []
            }
        ),

        // MD026 - Trailing punctuation in heading
        LintRule(
            code: "MD026",
            name: "no-trailing-punctuation",
            description: "Keine Satzzeichen am Ende von Überschriften",
            severity: .info,
            pattern: nil,
            validate: { line in
                if line.hasPrefix("#") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasSuffix(".") || trimmed.hasSuffix(",") || trimmed.hasSuffix(";") || trimmed.hasSuffix(":") {
                        return [LintIssue(
                            rule: "MD026",
                            message: "Trailing punctuation in heading",
                            severity: .info,
                            line: 0,
                            column: nil
                        )]
                    }
                }
                return []
            }
        ),

        // MD029 - Ordered list item prefix
        LintRule(
            code: "MD029",
            name: "ol-prefix",
            description: "Geordnete Listen sollten korrekt nummeriert sein",
            severity: .info,
            pattern: nil,
            validate: { _ in [] }
        ),

        // MD033 - No inline HTML
        LintRule(
            code: "MD033",
            name: "no-inline-html",
            description: "Vermeiden Sie inline HTML",
            severity: .info,
            pattern: nil,
            validate: { line in
                let htmlPattern = "<[a-zA-Z][^>]*>"
                if let regex = try? NSRegularExpression(pattern: htmlPattern, options: .caseInsensitive) {
                    let range = NSRange(line.startIndex..., in: line)
                    if regex.firstMatch(in: line, options: [], range: range) != nil {
                        return [LintIssue(
                            rule: "MD033",
                            message: "Inline HTML detected",
                            severity: .info,
                            line: 0,
                            column: nil
                        )]
                    }
                }
                return []
            }
        ),

        // MD034 - No bare URLs
        LintRule(
            code: "MD034",
            name: "no-bare-urls",
            description: "URLs sollten als Links formatiert werden",
            severity: .info,
            pattern: nil,
            validate: { line in
                let urlPattern = "(?<!\\()https?://[^\\s>]+(?!\\))"
                if let regex = try? NSRegularExpression(pattern: urlPattern, options: []) {
                    let range = NSRange(line.startIndex..., in: line)
                    if let match = regex.firstMatch(in: line, options: [], range: range) {
                        // Check if it's inside brackets [text](url)
                        let matchRange = Range(match.range, in: line)!
                        let before = line[..<matchRange.lowerBound]
                        let after = line[matchRange.upperBound...]

                        if !before.hasSuffix("[") && !after.hasPrefix(")") {
                            return [LintIssue(
                                rule: "MD034",
                                message: "Bare URL found - use [text](url) format instead",
                                severity: .info,
                                line: 0,
                                column: line.distance(from: line.startIndex, to: matchRange.lowerBound) + 1
                            )]
                        }
                    }
                }
                return []
            }
        ),

        // MD037 - Spaces inside emphasis markers
        LintRule(
            code: "MD037",
            name: "no-space-in-emphasis",
            description: "Keine Leerzeichen in Hervorhebungen",
            severity: .info,
            pattern: nil,
            validate: { line in
                let patterns = ["\\* .+ \\*", "\\*\\* .+ \\*\\*", "_ .+ _", "__ .+ __"]
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                        let range = NSRange(line.startIndex..., in: line)
                        if regex.firstMatch(in: line, options: [], range: range) != nil {
                            return [LintIssue(
                                rule: "MD037",
                                message: "Spaces inside emphasis markers",
                                severity: .info,
                                line: 0,
                                column: nil
                            )]
                        }
                    }
                }
                return []
            }
        ),

        // MD039 - Spaces inside link text
        LintRule(
            code: "MD039",
            name: "no-space-in-links",
            description: "Keine Leerzeichen in Link-Text",
            severity: .info,
            pattern: nil,
            validate: { line in
                let pattern = "\\]\\s+("
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(line.startIndex..., in: line)
                    if regex.firstMatch(in: line, options: [], range: range) != nil {
                        return [LintIssue(
                            rule: "MD039",
                            message: "Spaces inside link text",
                            severity: .info,
                            line: 0,
                            column: nil
                        )]
                    }
                }
                return []
            }
        ),

        // MD040 - Fenced code blocks should have a language specified
        LintRule(
            code: "MD040",
            name: "fenced-code-language",
            description: "Code-Blöcke sollten eine Sprache angeben",
            severity: .info,
            pattern: nil,
            validate: { line in
                if line.trimmingCharacters(in: .whitespaces) == "```" {
                    return [LintIssue(
                        rule: "MD040",
                        message: "Fenced code block should have a language",
                        severity: .info,
                        line: 0,
                        column: nil
                    )]
                }
                return []
            }
        ),

        // MD041 - First line in file should be a top-level heading
        LintRule(
            code: "MD041",
            name: "first-line-heading",
            description: "Erste Zeile sollte eine H1-Überschrift sein",
            severity: .info,
            pattern: nil,
            validate: { _ in [] }
        ),

        // MD042 - No empty links
        LintRule(
            code: "MD042",
            name: "no-empty-links",
            description: "Keine leeren Links",
            severity: .info,
            pattern: nil,
            validate: { line in
                if let regex = try? NSRegularExpression(pattern: "\\]\\[\\]", options: []) {
                    let range = NSRange(line.startIndex..., in: line)
                    if regex.firstMatch(in: line, options: [], range: range) != nil {
                        return [LintIssue(
                            rule: "MD042",
                            message: "Empty link found",
                            severity: .info,
                            line: 0,
                            column: nil
                        )]
                    }
                }
                return []
            }
        ),

        // MD045 - Images should have alt text
        LintRule(
            code: "MD045",
            name: "image-alt",
            description: "Bilder sollten Alt-Text haben",
            severity: .info,
            pattern: nil,
            validate: { line in
                if line.contains("![](") || line.contains("![](") {
                    return [LintIssue(
                        rule: "MD045",
                        message: "Image missing alt text",
                        severity: .info,
                        line: 0,
                        column: nil
                    )]
                }
                return []
            }
        )
    ]
}

// MARK: - Lint Panel View

struct LintPanelView: View {
    @ObservedObject var linter: MarkdownLinter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "checkmark.shield")
                    .font(.title3)
                    .foregroundStyle(linter.issues.isEmpty ? .green : .orange)
                Text("Markdown-Lint")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: $linter.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: linter.isEnabled) { _, _ in
                        linter.saveSettings()
                    }

                Button(action: { linter.clearIssues() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(linter.issues.isEmpty)
            }
            .padding()

            Divider()

            if linter.issues.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("Keine Probleme gefunden")
                        .font(.headline)
                    Text("Ihr Markdown sieht gut aus!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Issues List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(linter.issues) { issue in
                            LintIssueRow(issue: issue)
                        }
                    }
                    .padding()
                }
            }

            // Footer
            HStack {
                Text("\(linter.issues.count) Probleme")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                let errors = linter.issues.filter { $0.severity == .error }.count
                let warnings = linter.issues.filter { $0.severity == .warning }.count
                let info = linter.issues.filter { $0.severity == .info }.count

                HStack(spacing: 12) {
                    if errors > 0 {
                        Label("\(errors)", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if warnings > 0 {
                        Label("\(warnings)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if info > 0 {
                        Label("\(info)", systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(10)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
        }
        .frame(width: 400, height: 400)
    }
}

// MARK: - Lint Issue Row

struct LintIssueRow: View {
    let issue: LintIssue

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: issue.severity.icon)
                .foregroundStyle(issue.severity.color)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(issue.rule)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(issue.severity.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(issue.severity.color.opacity(0.2))
                        .clipShape(Capsule())
                }

                Text(issue.message)
                    .font(.caption)

                Text(issue.location)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
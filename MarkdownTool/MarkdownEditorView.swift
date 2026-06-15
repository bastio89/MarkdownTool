import SwiftUI
import AppKit
import Combine
import Carbon.HIToolbox // Für Key Codes

// MARK: - Autocomplete Suggestions

struct AutocompleteSuggestion: Identifiable {
    let id = UUID()
    let trigger: String
    let display: String
    let insert: String
    let description: String
}

class AutocompleteManager: ObservableObject {
    @Published var suggestions: [AutocompleteSuggestion] = []
    @Published var selectedIndex: Int = 0
    @Published var isActive: Bool = false

    private let allSuggestions: [AutocompleteSuggestion] = [
        // Headers
        AutocompleteSuggestion(trigger: "#", display: "# H1", insert: "# ", description: "Überschrift 1"),
        AutocompleteSuggestion(trigger: "##", display: "## H2", insert: "## ", description: "Überschrift 2"),
        AutocompleteSuggestion(trigger: "###", display: "### H3", insert: "### ", description: "Überschrift 3"),
        // Formatting
        AutocompleteSuggestion(trigger: "**", display: "****", insert: "**", description: "Fett"),
        AutocompleteSuggestion(trigger: "*", display: "**", insert: "**", description: "Fett/Kursiv"),
        AutocompleteSuggestion(trigger: "`", display: "``", insert: "`", description: "Inline Code"),
        AutocompleteSuggestion(trigger: "```", display: "```", insert: "```\n\n```", description: "Code Block"),
        // Links
        AutocompleteSuggestion(trigger: "[", display: "[text](url)", insert: "[](https://)", description: "Link"),
        AutocompleteSuggestion(trigger: "![", display: "![alt](url)", insert: "![alt](https://)", description: "Bild"),
        // Lists
        AutocompleteSuggestion(trigger: "-", display: "- ", insert: "- ", description: "Aufzählung"),
        AutocompleteSuggestion(trigger: "*", display: "* ", insert: "* ", description: "Aufzählung"),
        AutocompleteSuggestion(trigger: "1.", display: "1. ", insert: "1. ", description: "Nummerierte Liste"),
        // Block elements
        AutocompleteSuggestion(trigger: ">", display: "> ", insert: "> ", description: "Blockzitat"),
        AutocompleteSuggestion(trigger: "---", display: "---", insert: "\n---\n", description: "Trennlinie"),
        // Table
        AutocompleteSuggestion(trigger: "|", display: "| | |", insert: "| Header | Header |\n|--------|--------|\n| Cell | Cell |", description: "Tabelle"),
    ]

    func updateSuggestions(for text: String, cursorPosition: Int) {
        guard cursorPosition > 0 else {
            suggestions = []
            isActive = false
            return
        }

        // Find trigger character
        let nsText = text as NSString
        let beforeCursor = nsText.substring(to: cursorPosition)

        // Check for trigger characters
        var foundTrigger: String?
        var foundSuggestion: AutocompleteSuggestion?

        for suggestion in allSuggestions {
            if beforeCursor.hasSuffix(suggestion.trigger) {
                foundTrigger = suggestion.trigger
                foundSuggestion = suggestion
                break
            }
        }

        if let trigger = foundTrigger {
            // Remove trigger from text
            let cleanText = String(beforeCursor.dropLast(trigger.count))

            // Find matching suggestions that follow the trigger text
            let afterTrigger = nsText.substring(with: NSRange(location: cursorPosition - trigger.count, length: trigger.count))
            if afterTrigger == trigger {
                // Trigger only, show suggestions
                suggestions = allSuggestions.filter { $0.trigger == trigger }
                isActive = !suggestions.isEmpty
                selectedIndex = 0
            }
        } else {
            // Look for word-based suggestions
            let words = beforeCursor.components(separatedBy: .whitespacesAndNewlines)
            if let lastWord = words.last, lastWord.count >= 2 {
                let filtered = allSuggestions.filter {
                    $0.trigger.hasPrefix(lastWord) || $0.display.lowercased().contains(lastWord.lowercased())
                }
                suggestions = filtered
                isActive = !suggestions.isEmpty
                selectedIndex = 0
            } else {
                suggestions = []
                isActive = false
            }
        }
    }

    func selectNext() {
        if selectedIndex < suggestions.count - 1 {
            selectedIndex += 1
        }
    }

    func selectPrevious() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func selectCurrent() -> String? {
        guard selectedIndex < suggestions.count else { return nil }
        return suggestions[selectedIndex].insert
    }
}

// MARK: - Format Actions

enum FormatAction {
    case bold, italic, strikethrough
    case codeInline, codeBlock
    case h1, h2, h3
    case bulletList, numberedList
    case blockquote, link, horizontalRule
    case insertTable
}

// MARK: - Syntax Highlighting Colors

struct MarkdownColors {
    static let heading1 = NSColor(red: 0.29, green: 0.57, blue: 0.87, alpha: 1.0)  // #4A92DF
    static let heading2 = NSColor(red: 0.35, green: 0.62, blue: 0.87, alpha: 1.0)  // #599EDF
    static let heading3 = NSColor(red: 0.41, green: 0.68, blue: 0.88, alpha: 1.0)  // #68AEE0
    static let bold = NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0)        // #E6E6F3
    static let italic = NSColor(red: 0.85, green: 0.85, blue: 0.95, alpha: 1.0)    // #D9D9F2
    static let code = NSColor(red: 0.99, green: 0.76, blue: 0.43, alpha: 1.0)        // #FCC26F
    static let codeBlock = NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0) // #D9D9D9
    static let link = NSColor(red: 0.29, green: 0.69, blue: 0.93, alpha: 1.0)       // #4AB0ED
    static let blockquote = NSColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)    // #808099
    static let listMarker = NSColor(red: 0.39, green: 0.70, blue: 0.89, alpha: 1.0) // #63B3E3
    static let hr = NSColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)           // #4D4D66
    static let strikethrough = NSColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0) // #9999B3
    static let table = NSColor(red: 0.3, green: 0.78, blue: 0.55, alpha: 1.0)      // #4DC78C
}

// MARK: - NSTextView Wrapper

struct MarkdownNSTextView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var syntaxHighlighting: Bool
    var spellChecking: Bool = true
    var autocompleteEnabled: Bool = true
    var onReady: (NSTextView) -> Void
    var onAutocomplete: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: MarkdownNSTextView
        var autocompleteManager = AutocompleteManager()
        var isProcessingAutocomplete = false
        var languageHints: [String: String] = [
            "swift": "Swift", "js": "JavaScript", "javascript": "JavaScript",
            "ts": "TypeScript", "typescript": "TypeScript", "py": "Python",
            "python": "Python", "rb": "Ruby", "ruby": "Ruby", "go": "Go",
            "rust": "Rust", "java": "Java", "c": "C", "cpp": "C++",
            "c++": "C++", "html": "HTML", "css": "CSS", "sql": "SQL",
            "bash": "Bash", "sh": "Shell", "shell": "Shell", "json": "JSON",
            "xml": "XML", "yaml": "YAML", "yml": "YAML", "md": "Markdown"
        ]

        init(_ parent: MarkdownNSTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string

            // Apply syntax highlighting
            if parent.syntaxHighlighting {
                parent.applyHighlighting(tv, fontSize: parent.fontSize)
            }

            // Handle intelligent list continuation
            handleListContinuation(tv)

            // Update autocomplete
            if parent.autocompleteEnabled && !isProcessingAutocomplete {
                autocompleteManager.updateSuggestions(for: tv.string, cursorPosition: tv.selectedRange().location)
            }
        }

        func textDidEndEditing(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            // Detect language in code blocks
            detectLanguage(tv)
        }

        private func handleListContinuation(_ tv: NSTextView) {
            let nsStr = tv.string as NSString
            let sel = tv.selectedRange()
            let lineRange = nsStr.lineRange(for: sel)
            let lineText = nsStr.substring(with: lineRange)

            // Check if line ends with list continuation
            if let match = lineText.range(of: #"^(\s*)([-*+]|\d+\.)\s+(.+)$"#, options: .regularExpression) {
                let content = lineText[match].trimmingCharacters(in: .whitespaces)
                // Check if user pressed Enter at end of list item
                if sel.location == lineRange.upperBound && !lineText.hasSuffix("\n") {
                    // This is a new list item continuation
                    let indent = lineText.prefix(while: { $0.isWhitespace })
                    var prefix = "- "
                    var nextNumber = 1

                    if let bulletMatch = content.range(of: #"^[-*+]"#, options: .regularExpression) {
                        prefix = String(content[bulletMatch])
                        prefix = prefix + " "
                    } else if let numMatch = content.range(of: #"^\d+"#, options: .regularExpression) {
                        if let num = Int(content[numMatch]) {
                            nextNumber = num + 1
                        }
                        prefix = "\(nextNumber). "
                    }

                    // Check if content is complete (ends with proper punctuation)
                    let trimmedContent = content.replacingOccurrences(of: #"^(\s*)([-*+]|\d+\.)\s+"#, with: "", options: .regularExpression)
                    if trimmedContent.hasSuffix(".") || trimmedContent.hasSuffix("!") || trimmedContent.hasSuffix("?") {
                        // Content is complete, continue list on new line
                        let continuation = "\n" + indent + prefix
                        tv.insertText(continuation, replacementRange: sel)
                        tv.setSelectedRange(NSRange(location: sel.location + continuation.count, length: 0))
                    }
                }
            }
        }

        private func detectLanguage(_ tv: NSTextView) {
            let text = tv.string
            let codeBlockPattern = #"```(\w+)"#

            guard let regex = try? NSRegularExpression(pattern: codeBlockPattern) else { return }
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)

            for match in matches where match.numberOfRanges > 1 {
                let langRange = match.range(at: 1)
                let lang = (text as NSString).substring(with: langRange).lowercased()
                let normalizedLang = languageHints[lang] ?? lang.capitalized

                // Apply language hint styling
                tv.textStorage?.beginEditing()
                tv.textStorage?.addAttribute(.foregroundColor, value: MarkdownColors.code, range: langRange)
                tv.textStorage?.endEditing()
            }
        }
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let tv = scrollView.documentView as? NSTextView else { return scrollView }
        tv.delegate = context.coordinator
        tv.isEditable = true
        tv.isSelectable = true
        tv.isRichText = false
        tv.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        tv.textContainerInset = NSSize(width: 12, height: 12)
        tv.allowsUndo = true
        tv.string = text
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = .width
        tv.textContainer?.widthTracksTextView = true
        tv.backgroundColor = NSColor.textBackgroundColor
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = spellChecking
        tv.isContinuousSpellCheckingEnabled = spellChecking
        tv.isGrammarCheckingEnabled = spellChecking
        tv.isAutomaticLinkDetectionEnabled = true
        tv.isAutomaticDataDetectionEnabled = true

        // Setup key handling for autocomplete
        setupKeyHandling(tv)

        let onReadyCallback = self.onReady
        DispatchQueue.main.async {
            onReadyCallback(tv)
        }
        return scrollView
    }

    private func setupKeyHandling(_ tv: NSTextView) {
        // This will be called after tv is set up
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let tv = scrollView.documentView as? NSTextView else { return }

        // Update font size if changed
        if tv.font?.pointSize != fontSize {
            tv.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }

        if tv.string != text {
            let sel = tv.selectedRange()
            tv.string = text
            let safeLoc = min(sel.location, tv.string.utf16.count)
            tv.setSelectedRange(NSRange(location: safeLoc, length: 0))
            if syntaxHighlighting {
                applyHighlighting(tv, fontSize: fontSize)
            }
        }
    }

    private func applyHighlighting(_ tv: NSTextView, fontSize: CGFloat) {
        let text = tv.string
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        tv.textStorage?.beginEditing()

        // Clear all attributes
        tv.textStorage?.removeAttribute(.foregroundColor, range: fullRange)
        tv.textStorage?.removeAttribute(.font, range: fullRange)
        tv.textStorage?.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
        tv.textStorage?.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular), range: fullRange)

        // 1. Code blocks (```...```)
        let codeBlockPattern = #"```[\s\S]*?```"#
        applyPattern(codeBlockPattern, to: tv, nsString: nsString, color: MarkdownColors.codeBlock, bold: true, fontSize: fontSize)

        // 2. Inline code (`...`)
        let inlineCodePattern = #"`[^`\n]+`"#
        applyPattern(inlineCodePattern, to: tv, nsString: nsString, color: MarkdownColors.code, bold: false, fontSize: fontSize)

        // 3. Headings (must be after code to avoid matching ```
        let h1Pattern = #"^# .+$"#
        applyPattern(h1Pattern, to: tv, nsString: nsString, color: MarkdownColors.heading1, bold: true, options: [.anchorsMatchLines], fontSize: fontSize)

        let h2Pattern = #"^## .+$"#
        applyPattern(h2Pattern, to: tv, nsString: nsString, color: MarkdownColors.heading2, bold: true, options: [.anchorsMatchLines], fontSize: fontSize)

        let h3Pattern = #"^### .+$"#
        applyPattern(h3Pattern, to: tv, nsString: nsString, color: MarkdownColors.heading3, bold: true, options: [.anchorsMatchLines], fontSize: fontSize)

        // 4. Bold (**...**)
        let boldPattern = #"\*\*[^*]+\*\*"#
        applyPattern(boldPattern, to: tv, nsString: nsString, color: MarkdownColors.bold, bold: true, fontSize: fontSize)

        // 5. Italic (*...*)
        let italicPattern = #"(?<!\*)\*[^*]+\*(?!\*)"#
        applyPattern(italicPattern, to: tv, nsString: nsString, color: MarkdownColors.italic, bold: false, fontSize: fontSize)

        // 6. Strikethrough (~~...~~)
        let strikePattern = #"~~[^~]+~~"#
        applyPattern(strikePattern, to: tv, nsString: nsString, color: MarkdownColors.strikethrough, bold: false, fontSize: fontSize)

        // 7. Links ([text](url))
        let linkPattern = #"\[[^\]]+\]\([^)]+\)"#
        applyPattern(linkPattern, to: tv, nsString: nsString, color: MarkdownColors.link, bold: false, fontSize: fontSize)

        // 8. Blockquotes (> ...)
        let bqPattern = #"^> .+$"#
        applyPattern(bqPattern, to: tv, nsString: nsString, color: MarkdownColors.blockquote, bold: false, options: [.anchorsMatchLines], fontSize: fontSize)

        // 9. List markers (- , * , 1.)
        let listPattern = #"^(\s*[-*]|\s*\d+\.) "#
        applyPattern(listPattern, to: tv, nsString: nsString, color: MarkdownColors.listMarker, bold: false, options: [.anchorsMatchLines], fontSize: fontSize)

        // 10. Horizontal rules (---, ***, ___)
        let hrPattern = #"^(-{3,}|\*{3,}|_{3,})$"#
        applyPattern(hrPattern, to: tv, nsString: nsString, color: MarkdownColors.hr, bold: false, options: [.anchorsMatchLines], fontSize: fontSize)

        // 11. Table pipes (|)
        let tablePattern = #"\|"#
        applyPattern(tablePattern, to: tv, nsString: nsString, color: MarkdownColors.table, bold: false, fontSize: fontSize)

        tv.textStorage?.endEditing()
    }

    private func applyPattern(_ pattern: String, to tv: NSTextView, nsString: NSString, color: NSColor, bold: Bool, options: NSRegularExpression.Options = [], fontSize: CGFloat) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let fullRange = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: tv.string, options: [], range: fullRange)

        for match in matches {
            let font = bold ?
                NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold) :
                NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            tv.textStorage?.addAttribute(.foregroundColor, value: color, range: match.range)
            tv.textStorage?.addAttribute(.font, value: font, range: match.range)
        }
    }
}

// MARK: - Toolbar Buttons

private struct FmtLabelButton: View {
    let label: String
    let help: String
    let action: () -> Void
    @State private var hovered = false

    init(_ label: String, help: String, action: @escaping () -> Void) {
        self.label = label
        self.help = help
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .frame(width: 28, height: 26)
                .background(hovered ? Color.secondary.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        })
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovered = $0 }
    }
}

private struct FmtIconButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    @State private var hovered = false

    init(_ icon: String, help: String, action: @escaping () -> Void) {
        self.icon = icon
        self.help = help
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 28, height: 26)
                .background(hovered ? Color.secondary.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        })
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovered = $0 }
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    let onFormat: (FormatAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                FmtLabelButton("H1", help: "Überschrift 1") { onFormat(.h1) }
                FmtLabelButton("H2", help: "Überschrift 2") { onFormat(.h2) }
                FmtLabelButton("H3", help: "Überschrift 3") { onFormat(.h3) }

                Divider().frame(height: 20)

                FmtIconButton("bold", help: "Fett") { onFormat(.bold) }
                FmtIconButton("italic", help: "Kursiv") { onFormat(.italic) }
                FmtIconButton("strikethrough", help: "Durchgestrichen") { onFormat(.strikethrough) }

                Divider().frame(height: 20)

                FmtIconButton("chevron.left.forwardslash.chevron.right", help: "Inline-Code") { onFormat(.codeInline) }
                FmtIconButton("curlybraces", help: "Code-Block") { onFormat(.codeBlock) }

                Divider().frame(height: 20)

                FmtIconButton("list.bullet", help: "Aufzählungsliste") { onFormat(.bulletList) }
                FmtIconButton("list.number", help: "Nummerierte Liste") { onFormat(.numberedList) }
                FmtIconButton("text.quote", help: "Blockzitat") { onFormat(.blockquote) }

                Divider().frame(height: 20)

                FmtIconButton("link", help: "Link einfügen") { onFormat(.link) }
                FmtIconButton("tablecells", help: "Tabelle einfügen") { onFormat(.insertTable) }
                FmtIconButton("minus", help: "Trennlinie") { onFormat(.horizontalRule) }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Autocomplete Popup View

struct AutocompletePopupView: View {
    @ObservedObject var manager: AutocompleteManager
    var onSelect: (String) -> Void
    @State private var hoveredIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(manager.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button(action: {
                    onSelect(suggestion.insert)
                }) {
                    HStack {
                        Text(suggestion.display)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(index == manager.selectedIndex ? .primary : .secondary)

                        Spacer()

                        Text(suggestion.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(index == manager.selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering { hoveredIndex = index }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .frame(width: 280)
    }
}

// MARK: - Main Editor View

struct MarkdownEditorView: View {
    @Binding var text: String
    var fontSize: CGFloat = 14
    var searchText: String = ""
    var syntaxHighlighting: Bool = true
    @State private var textView: NSTextView?
    @StateObject private var autocompleteManager = AutocompleteManager()

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                FormattingToolbar(onFormat: applyFormat)
                Divider()
                MarkdownNSTextView(text: $text, fontSize: fontSize, syntaxHighlighting: syntaxHighlighting, autocompleteEnabled: true) { tv in
                    textView = tv
                    highlightSearch(tv)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Autocomplete Popup
            if autocompleteManager.isActive && !autocompleteManager.suggestions.isEmpty {
                AutocompletePopupView(manager: autocompleteManager) { insert in
                    insertAutocomplete(insert)
                }
                .padding(.leading, 50)
                .padding(.top, 80)
            }
        }
        .onChange(of: searchText) { _, newValue in
            if let tv = textView {
                highlightSearch(tv)
            }
        }
    }

    private func insertAutocomplete(_ insert: String) {
        guard let tv = textView else { return }
        let sel = tv.selectedRange()
        tv.insertText(insert, replacementRange: sel)
        autocompleteManager.isActive = false
        autocompleteManager.suggestions = []
        tv.window?.makeFirstResponder(tv)
    }

    private func highlightSearch(_ tv: NSTextView) {
        guard !searchText.isEmpty else {
            // Clear highlights
            tv.textStorage?.beginEditing()
            tv.textStorage?.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: tv.string.utf16.count))
            tv.textStorage?.endEditing()
            return
        }

        tv.textStorage?.beginEditing()
        tv.textStorage?.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: tv.string.utf16.count))

        let nsString = tv.string as NSString
        var searchRange = NSRange(location: 0, length: nsString.length)
        while searchRange.location + searchRange.length <= nsString.length {
            let range = nsString.range(of: searchText, options: .caseInsensitive, range: searchRange)
            if range.location == NSNotFound { break }
            tv.textStorage?.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.4), range: range)
            searchRange = NSRange(location: range.upperBound, length: nsString.length - range.upperBound)
        }

        tv.textStorage?.endEditing()
    }

    // MARK: - Formatting Logic

    private func applyFormat(_ action: FormatAction) {
        guard let tv = textView else { return }
        let nsStr = tv.string as NSString
        let sel = tv.selectedRange()
        let selected = nsStr.substring(with: sel)

        switch action {
        case .bold:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "**", close: "**", placeholder: "Fetter Text")
        case .italic:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "*", close: "*", placeholder: "Kursiver Text")
        case .strikethrough:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "~~", close: "~~", placeholder: "Text")
        case .codeInline:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "`", close: "`", placeholder: "code")
        case .codeBlock:
            let block = selected.isEmpty ? "```\n\n```" : "```\n\(selected)\n```"
            tv.insertText(block, replacementRange: sel)
            if selected.isEmpty {
                tv.setSelectedRange(NSRange(location: sel.location + 4, length: 0))
            }
        case .h1:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "# ")
        case .h2:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "## ")
        case .h3:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "### ")
        case .bulletList:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "- ")
        case .numberedList:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "1. ")
        case .blockquote:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "> ")
        case .link:
            if selected.isEmpty {
                tv.insertText("[Linktext](https://)", replacementRange: sel)
                tv.setSelectedRange(NSRange(location: sel.location + 1, length: 8))
            } else {
                tv.insertText("[\(selected)](https://)", replacementRange: sel)
                tv.setSelectedRange(NSRange(location: sel.location + selected.count + 3, length: 8))
            }
        case .horizontalRule:
            let needsNewline = sel.location > 0 &&
                nsStr.character(at: sel.location - 1) != "\n".utf16.first!
            tv.insertText(needsNewline ? "\n---\n" : "---\n", replacementRange: sel)
        case .insertTable:
            let table = """
            | Header 1 | Header 2 | Header 3 |
            |----------|----------|----------|
            | Cell 1   | Cell 2   | Cell 3   |
            | Cell 4   | Cell 5   | Cell 6   |
            """
            tv.insertText(table, replacementRange: sel)
        }

        tv.window?.makeFirstResponder(tv)
    }

    private func wrapInline(tv: NSTextView, sel: NSRange, selected: String,
                             open: String, close: String, placeholder: String) {
        if selected.isEmpty {
            tv.insertText("\(open)\(placeholder)\(close)", replacementRange: sel)
            tv.setSelectedRange(NSRange(location: sel.location + open.count, length: placeholder.count))
        } else {
            tv.insertText("\(open)\(selected)\(close)", replacementRange: sel)
        }
    }

    private func applyLinePrefix(tv: NSTextView, nsStr: NSString, sel: NSRange, prefix: String) {
        let lineRange = nsStr.lineRange(for: sel)
        var lineText = nsStr.substring(with: lineRange)
        let hasTrailingNewline = lineText.hasSuffix("\n")
        if hasTrailingNewline { lineText = String(lineText.dropLast()) }

        let prefixed = lineText.components(separatedBy: "\n").map { line -> String in
            guard !line.isEmpty else { return line }
            return line.hasPrefix(prefix) ? String(line.dropFirst(prefix.count)) : prefix + line
        }.joined(separator: "\n")

        tv.insertText(hasTrailingNewline ? prefixed + "\n" : prefixed, replacementRange: lineRange)
    }
}

#Preview {
    MarkdownEditorView(text: .constant("# Test\n\nEin **fetter** Test."))
}


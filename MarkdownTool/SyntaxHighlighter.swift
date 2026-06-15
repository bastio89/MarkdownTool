import SwiftUI
import AppKit

// MARK: - Syntax Highlighter

class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()

    // Programming languages supported
    static let supportedLanguages = [
        "swift", "python", "javascript", "typescript", "java", "kotlin",
        "go", "rust", "c", "cpp", "csharp", "ruby", "php", "html", "css",
        "json", "yaml", "xml", "sql", "bash", "shell", "powershell",
        "markdown", "dockerfile", "terraform", "graphql", "lua", "perl",
        "r", "scala", "haskell", "elixir", "clojure", "dart", "objc"
    ]

    // Color scheme for code highlighting
    struct CodeColors {
        static let keyword = NSColor(red: 0.97, green: 0.47, blue: 0.73, alpha: 1.0)     // Pink
        static let string = NSColor(red: 0.90, green: 0.86, blue: 0.57, alpha: 1.0)      // Yellow
        static let comment = NSColor(red: 0.46, green: 0.44, blue: 0.40, alpha: 1.0)    // Gray
        static let number = NSColor(red: 0.81, green: 0.60, blue: 1.0, alpha: 1.0)       // Purple
        static let function = NSColor(red: 0.40, green: 0.80, blue: 0.67, alpha: 1.0)    // Green
        static let type = NSColor(red: 0.39, green: 0.74, blue: 0.93, alpha: 1.0)        // Blue
        static let variable = NSColor(red: 0.86, green: 0.93, blue: 0.91, alpha: 1.0)    // Light Gray
        static let operator_ = NSColor(red: 0.97, green: 0.47, blue: 0.73, alpha: 1.0)   // Pink
        static let attribute = NSColor(red: 0.98, green: 0.82, blue: 0.44, alpha: 1.0)   // Orange
        static let default_ = NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)    // White-ish
    }

    // Keyword patterns per language
    private let patterns: [String: [String: [String]]] = [
        "swift": [
            "keywords": ["func", "var", "let", "class", "struct", "enum", "protocol", "extension", "import", "return", "if", "else", "guard", "switch", "case", "default", "for", "while", "do", "break", "continue", "throw", "throws", "try", "catch", "nil", "true", "false", "self", "Self", "super", "init", "deinit", "get", "set", "willSet", "didSet", "override", "private", "public", "internal", "fileprivate", "open", "static", "final", "lazy", "weak", "unowned", "mutating", "nonmutating", "convenience", "required", "optional", "some", "any", "async", "await", "actor"],
            "types": ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set", "Optional", "Result", "Void", "Any", "AnyObject", "View", "Text", "Button", "VStack", "HStack", "ZStack", "List", "ForEach", "NavigationStack", "NavigationLink", "State", "Binding", "ObservedObject", "StateObject", "Published", "Environment", "EnvironmentObject", "Scene", "Application"],
            "functions": ["print", "debugPrint", "dump", "fatalError", "precondition", "assert", "abs", "min", "max", "map", "filter", "reduce", "forEach", "compactMap", "flatMap", "sorted", "reversed", "contains", "first", "last", "append", "insert", "remove", "update", "fetch", "request", "load", "save"]
        ],
        "python": [
            "keywords": ["def", "class", "if", "elif", "else", "for", "while", "try", "except", "finally", "with", "as", "import", "from", "return", "yield", "lambda", "and", "or", "not", "in", "is", "True", "False", "None", "pass", "break", "continue", "raise", "assert", "global", "nonlocal", "async", "await", "del", "self", "cls"],
            "types": ["int", "float", "str", "bool", "list", "dict", "set", "tuple", "bytes", "object", "type", "range", "slice", "property", "staticmethod", "classmethod", "Exception", "TypeError", "ValueError", "KeyError", "IndexError"],
            "functions": ["print", "len", "str", "int", "float", "bool", "list", "dict", "set", "range", "sorted", "reversed", "enumerate", "zip", "map", "filter", "any", "all", "sum", "min", "max", "abs", "open", "input", "repr", "format", "type", "isinstance", "hasattr", "getattr", "setattr", "vars", "dir", "super", "super"]
        ],
        "javascript": [
            "keywords": ["function", "var", "let", "const", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "new", "this", "class", "extends", "super", "import", "export", "from", "as", "async", "await", "yield", "typeof", "instanceof", "in", "of", "true", "false", "null", "undefined", "void", "delete", "static", "get", "set", "constructor"],
            "types": ["Array", "Object", "String", "Number", "Boolean", "Date", "RegExp", "Map", "Set", "WeakMap", "WeakSet", "Promise", "Symbol", "Error", "TypeError", "SyntaxError", "JSON", "Math", "console", "window", "document", "Node"],
            "functions": ["console", "log", "warn", "error", "alert", "prompt", "confirm", "setTimeout", "setInterval", "clearTimeout", "clearInterval", "fetch", "then", "catch", "finally", "Promise", "resolve", "reject", "map", "filter", "reduce", "forEach", "some", "every", "find", "findIndex", "indexOf", "includes", "push", "pop", "shift", "unshift", "splice", "slice", "concat", "join", "split", "trim", "replace", "match", "search"]
        ],
        "typescript": [
            "keywords": ["function", "var", "let", "const", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "new", "this", "class", "extends", "super", "import", "export", "from", "as", "async", "await", "yield", "typeof", "instanceof", "in", "of", "true", "false", "null", "undefined", "void", "delete", "static", "get", "set", "constructor", "interface", "type", "enum", "namespace", "module", "declare", "abstract", "implements", "readonly", "private", "public", "protected", "keyof", "infer", "never", "unknown", "any"],
            "types": ["string", "number", "boolean", "any", "void", "never", "unknown", "object", "Array", "ReadonlyArray", "Partial", "Required", "Pick", "Omit", "Record", "Map", "Set", "Promise", "Error"],
            "functions": []
        ],
        "html": [
            "keywords": [],
            "types": [],
            "functions": ["div", "span", "p", "a", "img", "ul", "ol", "li", "table", "tr", "td", "th", "form", "input", "button", "label", "select", "option", "textarea", "h1", "h2", "h3", "h4", "h5", "h6", "header", "footer", "nav", "main", "section", "article", "aside", "script", "style", "link", "meta", "title", "body", "head", "html"]
        ],
        "css": [
            "keywords": [],
            "types": [],
            "functions": ["color", "background", "background-color", "font-size", "font-family", "font-weight", "padding", "margin", "border", "width", "height", "display", "flex", "grid", "position", "top", "left", "right", "bottom", "z-index", "opacity", "transform", "transition", "animation", "box-shadow", "border-radius", "text-align", "line-height", "overflow", "cursor", "visibility", "content", "justify-content", "align-items"]
        ],
        "sql": [
            "keywords": ["SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE", "CREATE", "TABLE", "DROP", "ALTER", "INDEX", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON", "AND", "OR", "NOT", "NULL", "IS", "IN", "LIKE", "BETWEEN", "ORDER", "BY", "ASC", "DESC", "GROUP", "HAVING", "LIMIT", "OFFSET", "UNION", "ALL", "DISTINCT", "AS", "CASE", "WHEN", "THEN", "ELSE", "END", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "CONSTRAINT", "DEFAULT", "AUTO_INCREMENT"],
            "types": [],
            "functions": ["COUNT", "SUM", "AVG", "MIN", "MAX", "COALESCE", "IFNULL", "NULLIF", "CAST", "CONVERT", "CONCAT", "LENGTH", "UPPER", "LOWER", "TRIM", "SUBSTRING", "REPLACE", "NOW", "DATE", "TIME", "YEAR", "MONTH", "DAY", "HOUR", "MINUTE", "SECOND", "GROUP_CONCAT", "DISTINCT", "IF", "EXISTS"]
        ],
        "bash": [
            "keywords": ["if", "then", "else", "elif", "fi", "for", "do", "done", "while", "case", "esac", "in", "function", "return", "exit", "break", "continue", "local", "export", "source", "alias", "echo", "read", "cd", "pwd", "ls", "mkdir", "rm", "cp", "mv", "cat", "grep", "sed", "awk", "find", "chmod", "chown", "sudo", "apt", "yum", "brew", "npm", "pip", "git"],
            "types": [],
            "functions": ["echo", "printf", "read", "test", "expr", "true", "false", "yes", "seq", "sleep", "date", "timeout"]
        ],
        "json": [
            "keywords": ["true", "false", "null"],
            "types": [],
            "functions": []
        ],
        "yaml": [
            "keywords": ["true", "false", "null", "yes", "no", "on", "off"],
            "types": [],
            "functions": []
        ],
        "go": [
            "keywords": ["func", "var", "const", "type", "struct", "interface", "map", "chan", "package", "import", "return", "if", "else", "for", "range", "switch", "case", "default", "break", "continue", "fallthrough", "go", "defer", "panic", "recover", "select", "nil", "true", "false", "iota"],
            "types": ["string", "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "float32", "float64", "complex64", "complex128", "byte", "rune", "bool", "error", "any", "comparable"],
            "functions": ["print", "println", "printf", "sprintf", "make", "new", "append", "len", "cap", "copy", "delete", "close", "panic", "recover", "go", "defer"]
        ],
        "rust": [
            "keywords": ["fn", "let", "mut", "const", "static", "struct", "enum", "impl", "trait", "type", "where", "for", "match", "if", "else", "loop", "while", "break", "continue", "return", "pub", "mod", "use", "crate", "self", "Self", "super", "as", "in", "ref", "move", "async", "await", "dyn", "unsafe", "extern", "true", "false", "Some", "None", "Ok", "Err"],
            "types": ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "bool", "char", "str", "String", "Vec", "Box", "Option", "Result", "HashMap", "HashSet"],
            "functions": ["println", "print", "format", "vec", "Some", "None", "Ok", "Err", "unwrap", "expect", "map", "and_then", "match", "if let", "while let"]
        ],
        "java": [
            "keywords": ["class", "interface", "extends", "implements", "package", "import", "public", "private", "protected", "static", "final", "abstract", "synchronized", "volatile", "transient", "native", "strictfp", "if", "else", "for", "do", "while", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "throws", "new", "this", "super", "null", "true", "false", "instanceof", "void", "var", "enum", "assert", "record"],
            "types": ["String", "Integer", "Long", "Double", "Float", "Boolean", "Character", "Object", "Class", "System", "Thread", "Runnable", "Exception", "Error", "List", "ArrayList", "Map", "HashMap", "Set", "HashSet", "Queue", "Deque"],
            "functions": ["print", "printf", "println", "main", "println", "toString", "equals", "hashCode", "getClass", "notify", "notifyAll", "wait", "sleep", "start", "run", "join"]
        ]
    ]

    // MARK: - Highlighting

    func highlight(code: String, language: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: code)
        let range = NSRange(location: 0, length: code.utf16.count)

        // Set default attributes
        attributed.addAttribute(.foregroundColor, value: CodeColors.default_, range: range)
        attributed.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: range)

        let lang = language.lowercased()
        guard let langPatterns = patterns[lang] else {
            // Try to detect common patterns
            return applyBasicHighlighting(attributed, code: code)
        }

        // Highlight comments
        highlightComments(attributed, code: code, language: lang)

        // Highlight strings
        highlightStrings(attributed, code: code)

        // Highlight keywords
        for keyword in langPatterns["keywords"] ?? [] {
            highlightPattern(attributed, code: code, pattern: "\\b\(keyword)\\b", color: CodeColors.keyword)
        }

        // Highlight types
        for type in langPatterns["types"] ?? [] {
            highlightPattern(attributed, code: code, pattern: "\\b\(type)\\b", color: CodeColors.type)
        }

        // Highlight numbers
        highlightPattern(attributed, code: code, pattern: "\\b\\d+\\.?\\d*\\b", color: CodeColors.number)

        return attributed
    }

    private func applyBasicHighlighting(_ attributed: NSMutableAttributedString, code: String) -> NSAttributedString {
        highlightComments(attributed, code: code, language: "default")
        highlightStrings(attributed, code: code)
        highlightPattern(attributed, code: code, pattern: "\\b\\d+\\.?\\d*\\b", color: CodeColors.number)
        return attributed
    }

    private func highlightComments(_ attributed: NSMutableAttributedString, code: String, language: String) {
        // Single line comments
        let singleLinePatterns = [
            "//.*$",           // C-style, Swift, Java, JavaScript, Go, Rust
            "#.*$",            // Python, Ruby, Shell
            "--.*$"            // SQL, Haskell
        ]

        for pattern in singleLinePatterns {
            highlightPattern(attributed, code: code, pattern: pattern, color: CodeColors.comment, options: .anchorsMatchLines)
        }

        // Multi-line comments
        highlightPattern(attributed, code: code, pattern: "/\\*[\\s\\S]*?\\*/", color: CodeColors.comment)
    }

    private func highlightStrings(_ attributed: NSMutableAttributedString, code: String) {
        // Double-quoted strings
        highlightPattern(attributed, code: code, pattern: "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"", color: CodeColors.string)

        // Single-quoted strings
        highlightPattern(attributed, code: code, pattern: "'[^'\\\\]*(\\\\.[^'\\\\]*)*'", color: CodeColors.string)

        // Template literals (JavaScript)
        highlightPattern(attributed, code: code, pattern: "`[^`]*`", color: CodeColors.string)
    }

    private func highlightPattern(_ attributed: NSMutableAttributedString, code: String, pattern: String, color: NSColor, options: NSRegularExpression.Options = []) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }

        let range = NSRange(location: 0, length: code.utf16.count)
        let matches = regex.matches(in: code, options: [], range: range)

        for match in matches {
            attributed.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
}

// MARK: - Code Block Renderer

struct CodeBlockRenderer {
    static func render(code: String, language: String) -> NSAttributedString {
        let highlighter = SyntaxHighlighter.shared
        return highlighter.highlight(code: code, language: language)
    }

    static func detectLanguage(from fencedCode: String) -> String? {
        // Pattern: ```language
        let pattern = "^```([a-zA-Z0-9_-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines),
              let match = regex.firstMatch(in: fencedCode, options: [], range: NSRange(location: 0, length: fencedCode.utf16.count)),
              match.numberOfRanges > 1 else {
            return nil
        }

        let languageRange = match.range(at: 1)
        let language = (fencedCode as NSString).substring(with: languageRange)
        return language.lowercased()
    }

    static func extractCode(from fencedCode: String) -> String {
        let lines = fencedCode.components(separatedBy: .newlines)
        var codeLines = lines.dropFirst() // Remove ```language

        // Remove last line if it's just ```
        if let last = codeLines.last, last.trimmingCharacters(in: .whitespaces) == "```" {
            codeLines = codeLines.dropLast()
        }

        return codeLines.joined(separator: "\n")
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            codeView
        }
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text(language.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: copyCode) {
                HStack(spacing: 4) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    Text(isCopied ? "Kopiert" : "Kopieren")
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.8))
    }

    @ViewBuilder
    private var codeView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(attributedCode)
                .font(.system(size: 13, design: .monospaced))
                .padding(12)
        }
        .background(Color(nsColor: NSColor.textBackgroundColor))
    }

    private var attributedCode: AttributedString {
        let nsAttributed = CodeBlockRenderer.render(code: code, language: language)
        return AttributedString(nsAttributed)
    }

    private func copyCode() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)

        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
        #endif
    }
}

// MARK: - Language Selector

struct LanguageSelector: View {
    @Binding var selectedLanguage: String
    let onLanguageSelected: (String) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var filteredLanguages: [String] {
        if searchText.isEmpty {
            return SyntaxHighlighter.supportedLanguages
        }
        return SyntaxHighlighter.supportedLanguages.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            languageList
        }
        .frame(width: 200, height: 250)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 1)
        )
        .onAppear {
            isSearchFocused = true
        }
    }

    @ViewBuilder
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Sprache suchen...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private var languageList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(filteredLanguages, id: \.self) { language in
                    languageRow(language)
                }
            }
        }
    }

    @ViewBuilder
    private func languageRow(_ language: String) -> some View {
        Button(action: {
            selectedLanguage = language
            onLanguageSelected(language)
        }) {
            HStack {
                Text(language)
                    .font(.system(size: 13))
                Spacer()
                if language == selectedLanguage {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(language == selectedLanguage ? Color.accentColor.opacity(0.2) : Color.clear)
    }
}
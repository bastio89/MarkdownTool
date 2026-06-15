import SwiftUI

struct ToolbarView: View {
    @ObservedObject var fileManager: MarkdownFileManager
    @ObservedObject var editorModel: EditorModel
    @Binding var showTemplatePicker: Bool
    @Binding var showFolderPicker: Bool
    @Binding var showSaveDialog: Bool
    @Binding var editorFontSize: CGFloat
    @Binding var previewFontSize: CGFloat
    @Binding var showSearchBar: Bool
    @Binding var searchText: String
    @Binding var syntaxHighlighting: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Dateiname + Status
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(editorModel.currentFileName)
                    .font(.headline)
                    .lineLimit(1)

                if editorModel.hasUnsavedChanges {
                    Text("●")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            Spacer()

            // Font Size Anzeige
            HStack(spacing: 4) {
                Text("A")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("\(Int(editorFontSize))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("A")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)

            // Syntax Highlighting Toggle
            Toggle(isOn: $syntaxHighlighting) {
                Image(systemName: "paintpalette")
                    .foregroundStyle(syntaxHighlighting ? .blue : .secondary)
            }
            .toggleStyle(.button)
            .buttonStyle(.borderless)
            .help("Syntax-Highlighting (⌘⇧H)")
            .padding(.horizontal, 4)

            // Aktionen
            HStack(spacing: 12) {
                if let folder = fileManager.selectedFolder {
                    Button(action: {
                        fileManager.loadFiles(in: folder)
                    }, label: {
                        Label("Aktualisieren", systemImage: "arrow.clockwise")
                    })
                    .help("Dateiliste aktualisieren (⌘R)")
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isActive: Bool
    @Binding var isRegex: Bool
    @Binding var isCaseSensitive: Bool
    @Binding var replaceText: String
    @Binding var showReplace: Bool
    let onClose: () -> Void
    let onFindNext: () -> Void
    let onFindPrevious: () -> Void
    let onReplace: () -> Void
    let onReplaceAll: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showError: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Suchen...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        if validateRegex() {
                            onFindNext()
                        }
                    }
                    .onChange(of: searchText) { _, _ in
                        showError = false
                    }

                if !searchText.isEmpty {
                    Text("\(countMatches()) Treffer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Regex Toggle
                Toggle(isOn: $isRegex) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(isRegex ? .blue : .secondary)
                }
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .help("Regex-Suche")

                // Case Sensitive Toggle
                Toggle(isOn: $isCaseSensitive) {
                    Image(systemName: "textformat.size")
                        .foregroundStyle(isCaseSensitive ? .blue : .secondary)
                }
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .help("Groß-/Kleinschreibung")

                // Replace Toggle
                Button(action: { showReplace.toggle() }) {
                    Image(systemName: showReplace ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle")
                        .foregroundStyle(showReplace ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Ersetzen einblenden")

                // Navigation
                Button(action: onFindPrevious) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .help("Vorheriger Treffer (⇧↵)")

                Button(action: onFindNext) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.plain)
                .help("Nächster Treffer (↵)")

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Replace Row
            if showReplace {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)

                    TextField("Ersetzen durch...", text: $replaceText)
                        .textFieldStyle(.plain)

                    Spacer()

                    Button(action: onReplace) {
                        Text("Ersetzen")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(searchText.isEmpty)

                    Button(action: onReplaceAll) {
                        Text("Alle ersetzen")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(searchText.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            // Regex Error
            if showError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Ungültiger Regex-Ausdruck")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            isFocused = true
        }
    }

    private func validateRegex() -> Bool {
        if isRegex && !searchText.isEmpty {
            do {
                _ = try NSRegularExpression(pattern: searchText)
                return true
            } catch {
                showError = true
                return false
            }
        }
        return true
    }

    private func countMatches() -> Int {
        return 0 // Wird vom Editor gehandhabt
    }
}

// MARK: - Search Result Highlighter

// MARK: - Status Bar

struct StatusBarView: View {
    let wordCount: Int
    let characterCount: Int
    let hasUnsavedChanges: Bool

    // Extended stats from EditorModel
    var characterCountNoSpaces: Int = 0
    var lineCount: Int = 0
    var paragraphCount: Int = 0
    var readingTimeMinutes: Double = 0
    @State private var showStatsPopover = false

    var body: some View {
        HStack {
            // Links: Dateistatus
            HStack(spacing: 4) {
                if hasUnsavedChanges {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                    Text("Nicht gespeichert")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Gespeichert")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Rechts: Statistiken
            HStack(spacing: 12) {
                // Quick stats
                Text("\(wordCount) Wörter")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(characterCount) Zeichen")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Stats button
                Button(action: { showStatsPopover.toggle() }) {
                    Image(systemName: "chart.bar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showStatsPopover) {
                    StatisticsPopoverView(
                        wordCount: wordCount,
                        characterCount: characterCount,
                        characterCountNoSpaces: characterCountNoSpaces,
                        lineCount: lineCount,
                        paragraphCount: paragraphCount,
                        readingTimeMinutes: readingTimeMinutes
                    )
                    .padding()
                    .fixedSize()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Statistics Popover

struct StatisticsPopoverView: View {
    let wordCount: Int
    let characterCount: Int
    let characterCountNoSpaces: Int
    let lineCount: Int
    let paragraphCount: Int
    let readingTimeMinutes: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dokument-Statistiken")
                .font(.headline)

            Divider()

            StatRow(label: "Wörter", value: "\(wordCount)")
            StatRow(label: "Zeichen", value: "\(characterCount)")
            StatRow(label: "Zeichen (ohne Leerzeichen)", value: "\(characterCountNoSpaces)")
            StatRow(label: "Zeilen", value: "\(lineCount)")
            StatRow(label: "Absätze", value: "\(paragraphCount)")

            Divider()

            HStack {
                Text("Lesezeit")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f min", readingTimeMinutes))
                    .fontWeight(.medium)
            }
            .font(.caption)
        }
        .frame(width: 240)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .font(.system(.body, design: .monospaced))
        }
        .font(.caption)
    }
}

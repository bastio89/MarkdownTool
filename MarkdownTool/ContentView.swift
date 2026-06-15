import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct MarkdownExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .html, UTType(filenameExtension: "md")!] }
    static var writableContentTypes: [UTType] { [.plainText, .html, .rtf] }
    var text: String
    var contentType: UTType

    init(text: String, contentType: UTType = .plainText) {
        self.text = text
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        text = configuration.file.regularFileContents
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        contentType = .plainText
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if contentType == .rtf {
            let rtfData = markdownToRTF(text)
            return FileWrapper(regularFileWithContents: rtfData)
        }
        return FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct ContentView: View {
    @StateObject private var fileManager = MarkdownFileManager()
    @StateObject private var tabManager = TabManager()
    @StateObject private var editorModel = EditorModel()
    @StateObject private var exportSettings = ExportSettings()
    @StateObject private var vimState = VimState()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var backupManager = BackupManager()
    @StateObject private var iCloudManager = iCloudSyncManager()
    @State private var selectedTemplate: String?
    @State private var showTemplatePicker = false
    @State private var showFolderPicker = false
    @State private var showSaveDialog = false
    @State private var showHTMLExportDialog = false
    @State private var showRTFExportDialog = false
    @State private var showExportSettings = false
    @State private var showThemePicker = false
    @State private var showBackupSettings = false
    @State private var editorFontSize: CGFloat = 14
    @State private var previewFontSize: CGFloat = 14
    @State private var showSearchBar = false
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var searchIsRegex = false
    @State private var searchCaseSensitive = false
    @State private var replaceText = ""
    @State private var showReplace = false
    @State private var syntaxHighlighting = true
    @State private var currentSearchIndex = 0
    @State private var searchMatches: [NSRange] = []
    @State private var vimModeEnabled = false

    var body: some View {
        NavigationSplitView {
            // Sidebar: File Browser
            FileBrowserView(fileManager: fileManager)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
        } detail: {
            // Main Editor Area
            VStack(spacing: 0) {
                // Tab Bar
                TabBarView(
                    tabManager: tabManager,
                    onNewTab: {
                        tabManager.createNewTab()
                    },
                    onCloseTab: { id in
                        tabManager.closeTab(id)
                    }
                )

                // Toolbar
                ToolbarView(
                    fileManager: fileManager,
                    editorModel: editorModel,
                    showTemplatePicker: $showTemplatePicker,
                    showFolderPicker: $showFolderPicker,
                    showSaveDialog: $showSaveDialog,
                    editorFontSize: $editorFontSize,
                    previewFontSize: $previewFontSize,
                    showSearchBar: $showSearchBar,
                    searchText: $searchText,
                    syntaxHighlighting: $syntaxHighlighting
                )

                // Vim Mode Indicator
                if vimModeEnabled {
                    HStack {
                        VimModeIndicator(state: vimState)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.windowBackgroundColor))
                }

                // Search Bar (conditional)
                if showSearchBar {
                    SearchBarView(
                        searchText: $searchText,
                        isActive: $isSearchActive,
                        isRegex: $searchIsRegex,
                        isCaseSensitive: $searchCaseSensitive,
                        replaceText: $replaceText,
                        showReplace: $showReplace,
                        onClose: { showSearchBar = false },
                        onFindNext: findNextMatch,
                        onFindPrevious: findPreviousMatch,
                        onReplace: replaceCurrentMatch,
                        onReplaceAll: replaceAllMatches
                    )
                    Divider()
                }

                // Split View: Editor | Preview
                Divider()
                HSplitView {
                    // Left: Markdown Editor
                    MarkdownEditorView(
                        text: Binding(
                            get: { tabManager.activeTab?.text ?? "" },
                            set: { tabManager.updateActiveTab(text: $0) }
                        ),
                        fontSize: editorFontSize,
                        searchText: searchText,
                        syntaxHighlighting: syntaxHighlighting
                    )
                    .frame(minWidth: 300)

                    // Right: Live Preview
                    MarkdownPreviewView(
                        markdownText: tabManager.activeTab?.text ?? "",
                        fontSize: previewFontSize
                    )
                    .frame(minWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Status Bar
                StatusBarView(
                    wordCount: editorModel.wordCount,
                    characterCount: editorModel.characterCount,
                    hasUnsavedChanges: tabManager.activeTab?.hasUnsavedChanges ?? false,
                    characterCountNoSpaces: editorModel.characterCountNoSpaces,
                    lineCount: editorModel.lineCount,
                    paragraphCount: editorModel.paragraphCount,
                    readingTimeMinutes: editorModel.readingTimeMinutes
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { tabManager.createNewTab() }) {
                    Image(systemName: "doc")
                    Text("Neu")
                }
                .help("Neues Dokument (⌘N)")
                .keyboardShortcut("n", modifiers: .command)

                Button(action: { showTemplatePicker.toggle() }) {
                    Image(systemName: "doc.badge.plus")
                    Text("Vorlage")
                }
                .help("Markdown-Vorlage laden (⌘⇧N)")
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button(action: { showFolderPicker.toggle() }) {
                    Image(systemName: "folder")
                    Text("Ordner öffnen")
                }
                .help("Ordner öffnen (⌘O)")
                .keyboardShortcut("o", modifiers: .command)

                Button(action: {
                    editorModel.saveState()
                    showSaveDialog.toggle()
                }) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Speichern")
                }
                .help("Als .md speichern (⌘S)")
                .keyboardShortcut("s", modifiers: .command)

                Button(action: { showHTMLExportDialog.toggle() }) {
                    Image(systemName: "globe")
                    Text("HTML")
                }
                .help("Als HTML exportieren (für PDF: Im Browser drucken)")
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button(action: { showRTFExportDialog.toggle() }) {
                    Image(systemName: "doc.richtext")
                    Text("Word/RTF")
                }
                .help("Als RTF/Word exportieren")
                .keyboardShortcut("e", modifiers: [.command, .option])

                Button(action: { showExportSettings = true }) {
                    Image(systemName: "gearshape")
                }
                .help("Export-Einstellungen")

                Divider()

                // Font Size Controls
                HStack(spacing: 4) {
                    Button(action: {
                        editorFontSize = max(10, editorFontSize - 1)
                        previewFontSize = max(10, previewFontSize - 1)
                    }) {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .help("Schriftgröße verkleinern (⌘-)")

                    Button(action: {
                        editorFontSize += 1
                        previewFontSize += 1
                    }) {
                        Image(systemName: "textformat.size.larger")
                    }
                    .help("Schriftgröße vergrößern (⌘+)")

                    Divider()

                    Button(action: { showSearchBar.toggle() }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .help("Suchen (⌘F)")
                    .keyboardShortcut("f", modifiers: .command)

                    // Syntax Highlighting Toggle (Compact)
                    Button(action: { syntaxHighlighting.toggle() }) {
                        Image(systemName: syntaxHighlighting ? "paintpalette.fill" : "paintpalette")
                            .foregroundStyle(syntaxHighlighting ? .blue : .secondary)
                    }
                    .help("Syntax-Highlighting (⌘⇧H)")
                    .keyboardShortcut("h", modifiers: [.command, .shift])

                    // Vim Mode Toggle (Compact)
                    Button(action: { vimModeEnabled.toggle() }) {
                        Image(systemName: "keyboard")
                            .foregroundStyle(vimModeEnabled ? .green : .secondary)
                    }
                    .help("Vim-Modus")
                    .buttonStyle(.borderless)

                    Divider()

                    Button(action: { showThemePicker = true }) {
                        Image(systemName: "paintpalette.fill")
                    }
                    .help("Theme wählen")
                    .buttonStyle(.borderless)

                    Button(action: { showBackupSettings = true }) {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                    .help("Backup & Sync Einstellungen")
                    .buttonStyle(.borderless)
                }
            }
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(selectedTemplate: $selectedTemplate)
        }
        .sheet(isPresented: $showExportSettings) {
            ExportSettingsView(settings: exportSettings)
        }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerView(themeManager: themeManager)
        }
        .sheet(isPresented: $showBackupSettings) {
            BackupSettingsView(backupManager: backupManager, iCloudManager: iCloudManager)
        }
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url):
                fileManager.setSelectedFolder(url)
            case .failure:
                break
            }
        }
        .fileExporter(
            isPresented: $showSaveDialog,
            document: MarkdownExportDocument(text: editorModel.text),
            contentType: .plainText,
            defaultFilename: "\(editorModel.currentFileName).md"
        ) { result in
            switch result {
            case .success(let url):
                editorModel.saveState()
                fileManager.addRecentFile(url)
                if let folder = fileManager.selectedFolder {
                    fileManager.loadFiles(in: folder)
                } else {
                    fileManager.setSelectedFolder(url.deletingLastPathComponent())
                }
            case .failure:
                break
            }
        }
        .onChange(of: selectedTemplate) {
            if let template = selectedTemplate {
                editorModel.loadTemplate(template)
                selectedTemplate = nil
            }
        }
        .onChange(of: fileManager.selectedFile) {
            if let url = fileManager.selectedFile,
               let content = fileManager.readFileContent(url) {
                tabManager.openFile(url, content: content)
                editorModel.loadFileContent(content, fileName: url.deletingPathExtension().lastPathComponent)
            }
        }
        .fileExporter(
            isPresented: $showHTMLExportDialog,
            document: MarkdownExportDocument(text: {
                if let html = try? generateStyledHTML(editorModel.text, fontSize: previewFontSize) {
                    return html
                }
                return editorModel.text
            }()),
            contentType: .html,
            defaultFilename: "\(editorModel.currentFileName).html"
        ) { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
        }
        .fileExporter(
            isPresented: $showRTFExportDialog,
            document: MarkdownExportDocument(text: editorModel.text, contentType: .rtf),
            contentType: .rtf,
            defaultFilename: "\(editorModel.currentFileName).rtf"
        ) { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Search Functions

extension ContentView {
    private func findNextMatch() {
        let text = tabManager.activeTab?.text ?? ""
        performSearch(in: text)
        if !searchMatches.isEmpty {
            currentSearchIndex = (currentSearchIndex + 1) % searchMatches.count
            scrollToMatch(at: currentSearchIndex)
        }
    }

    private func findPreviousMatch() {
        let text = tabManager.activeTab?.text ?? ""
        performSearch(in: text)
        if !searchMatches.isEmpty {
            currentSearchIndex = (currentSearchIndex - 1 + searchMatches.count) % searchMatches.count
            scrollToMatch(at: currentSearchIndex)
        }
    }

    private func performSearch(in text: String) {
        guard !searchText.isEmpty else {
            searchMatches = []
            return
        }

        do {
            var options: NSRegularExpression.Options = []
            if !searchCaseSensitive {
                options.insert(.caseInsensitive)
            }

            let regex = try NSRegularExpression(pattern: searchText, options: options)
            let range = NSRange(location: 0, length: text.utf16.count)
            searchMatches = regex.matches(in: text, options: [], range: range).map { $0.range }
        } catch {
            searchMatches = []
        }
    }

    private func scrollToMatch(at index: Int) {
        // Will be handled by the editor view
    }

    private func replaceCurrentMatch() {
        guard currentSearchIndex < searchMatches.count,
              let tab = tabManager.activeTab else { return }

        var text = tab.text
        let nsText = text as NSString
        let range = searchMatches[currentSearchIndex]
        let matched = nsText.substring(with: range)

        text = nsText.replacingCharacters(in: range, with: replaceText) as String
        tabManager.updateActiveTab(text: text)

        // Re-search after replace
        performSearch(in: text)
    }

    private func replaceAllMatches() {
        guard let tab = tabManager.activeTab else { return }

        var text = tab.text
        let nsText = text as NSString

        do {
            var options: NSRegularExpression.Options = []
            if !searchCaseSensitive {
                options.insert(.caseInsensitive)
            }

            let regex = try NSRegularExpression(pattern: searchText, options: options)
            let range = NSRange(location: 0, length: nsText.length)
            text = regex.stringByReplacingMatches(in: nsText as String, options: [], range: range, withTemplate: replaceText)
            tabManager.updateActiveTab(text: text)
            performSearch(in: text)
        } catch {
            // Invalid regex
        }
    }
}

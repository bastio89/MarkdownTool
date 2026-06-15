import SwiftUI
import Combine
import Foundation

class EditorModel: ObservableObject {
    @Published var text: String = ""
    @Published var currentFileName: String = "Unbenannt"
    @Published var hasUnsavedChanges: Bool = false
    @Published var lastAutoSave: Date?

    // Statistics
    @Published var wordCount: Int = 0
    @Published var characterCount: Int = 0
    @Published var characterCountNoSpaces: Int = 0
    @Published var lineCount: Int = 0
    @Published var paragraphCount: Int = 0
    @Published var readingTimeMinutes: Double = 0

    // Auto-save settings
    @Published var autoSaveEnabled: Bool = true
    @Published var autoSaveInterval: TimeInterval = 30 // seconds

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTimer: Timer?

    init() {
        // Load settings
        autoSaveEnabled = defaults.object(forKey: "autoSaveEnabled") as? Bool ?? true
        autoSaveInterval = defaults.object(forKey: "autoSaveInterval") as? TimeInterval ?? 30

        // Try to recover from crash
        if let recoveredText = loadRecoveredText() {
            text = recoveredText
        } else if let saved = defaults.string(forKey: "lastMarkdownText") {
            text = saved
        } else {
            text = defaultWelcomeText()
        }

        // Debounced Auto-Save (2 Sekunden nach letzter Änderung)
        $text
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveState()
            }
            .store(in: &cancellables)

        // Update Word/Character Count bei Textänderungen
        $text
            .sink { [weak self] newText in
                self?.updateCounts(newText)
            }
            .store(in: &cancellables)

        // Start auto-save timer
        if autoSaveEnabled {
            startAutoSaveTimer()
        }
    }

    private func updateCounts(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Character counts
        characterCount = trimmed.count
        characterCountNoSpaces = trimmed.filter { !$0.isWhitespace }.count

        // Word count (split by whitespace)
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        wordCount = words.count

        // Line count
        lineCount = max(1, text.components(separatedBy: .newlines).count)

        // Paragraph count (non-empty lines separated by blank lines)
        let paragraphs = trimmed.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        paragraphCount = max(1, paragraphs.count)

        // Reading time (average 200 words per minute)
        readingTimeMinutes = max(1, Double(wordCount) / 200.0)
    }

    // MARK: - Auto-Save

    private func startAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.performAutoSave()
        }
    }

    private func performAutoSave() {
        guard hasUnsavedChanges else { return }
        saveState()
        lastAutoSave = Date()
    }

    func setAutoSaveInterval(_ interval: TimeInterval) {
        autoSaveInterval = max(10, min(300, interval)) // 10s - 5min
        defaults.set(autoSaveInterval, forKey: "autoSaveInterval")
        if autoSaveEnabled {
            startAutoSaveTimer()
        }
    }

    func toggleAutoSave(_ enabled: Bool) {
        autoSaveEnabled = enabled
        defaults.set(enabled, forKey: "autoSaveEnabled")
        if enabled {
            startAutoSaveTimer()
        } else {
            autoSaveTimer?.invalidate()
            autoSaveTimer = nil
        }
    }

    // MARK: - Recovery

    private func saveRecoveredText(_ text: String) {
        let fileURL = recoveryFileURL()
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func loadRecoveredText() -> String? {
        let fileURL = recoveryFileURL()
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // Check if recovery file is newer than last saved
        if let recoveryDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
           let savedDate = defaults.object(forKey: "lastSaveDate") as? Date,
           recoveryDate < savedDate {
            // Last save is newer, clear recovery
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    private func recoveryFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("MarkdownTool/Recovery", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("recovery.md")
    }

    func clearRecovery() {
        try? FileManager.default.removeItem(at: recoveryFileURL())
    }

    // MARK: - Undo History Persistence

    private var undoStack: [String] = []
    private var redoStack: [String] = []
    private let maxUndoHistory = 100

    func pushUndoState(_ text: String) {
        undoStack.append(text)
        if undoStack.count > maxUndoHistory {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    func undo() -> String? {
        guard let state = undoStack.popLast() else { return nil }
        redoStack.append(text)
        return state
    }

    func redo() -> String? {
        guard let state = redoStack.popLast() else { return nil }
        undoStack.append(text)
        return state
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Save State

    func saveState() {
        defaults.set(text, forKey: "lastMarkdownText")
        defaults.set(Date(), forKey: "lastSaveDate")
        saveRecoveredText(text)
        hasUnsavedChanges = false
    }

    func loadTemplate(_ templateName: String) {
        let template = Templates.get(templateName)
        pushUndoState(text)
        text = template
        currentFileName = templateName
        hasUnsavedChanges = true
        saveState()
    }

    func loadFileContent(_ content: String, fileName: String) {
        pushUndoState(text)
        text = content
        currentFileName = fileName
        hasUnsavedChanges = false
        updateCounts(content)
        clearRecovery()
    }

    func newDocument() {
        pushUndoState(text)
        text = ""
        currentFileName = "Unbenannt"
        hasUnsavedChanges = false
        updateCounts("")
        saveState()
    }

    // Markiert Änderungen nach Edits
    func markChanged() {
        hasUnsavedChanges = true
    }

    private func defaultWelcomeText() -> String {
        return """
        # Willkommen bei Markdown Tool ✍️

        Dein **nativer macOS-Markdown-Editor** für schnelle Notizen, README-Dateien und Dokumentation.

        ## Schnellstart

        - 📁 **Ordner öffnen** – Lade deine Markdown-Dateien
        - 📝 **Vorlage laden** – Wähle eine Vorlage für README, Changelog, Notizen etc.
        - 💾 **Speichern** – Exportiere als `.md`-Datei
        - 📄 **PDF-Export** – Erstelle direkt ein PDF

        ## Markdown-Beispiel

        ```swift
        struct Hello: View {
            var body: some View {
                Text("Hallo Welt!")
            }
        }
        ```

        > Dies ist ein Zitat – perfekt für wichtige Hinweise!

        ---

        | Feature | Status |
        |---------|--------|
        | Editor | ✅ |
        | Vorschau | ✅ |
        | Templates | ✅ |

        ---
        *Schreibe jetzt deine erste Markdown-Datei!*
        """
    }
}
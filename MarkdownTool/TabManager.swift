import SwiftUI
import Combine

/// Represents a single document tab
struct DocumentTab: Identifiable, Equatable {
    let id: UUID
    var text: String
    var fileName: String
    var hasUnsavedChanges: Bool
    var folderURL: URL?

    init(text: String = "", fileName: String = "Unbenannt", hasUnsavedChanges: Bool = false, folderURL: URL? = nil) {
        self.id = UUID()
        self.text = text
        self.fileName = fileName
        self.hasUnsavedChanges = hasUnsavedChanges
        self.folderURL = folderURL
    }

    static func == (lhs: DocumentTab, rhs: DocumentTab) -> Bool {
        lhs.id == rhs.id
    }
}

/// Manages multiple document tabs
class TabManager: ObservableObject {
    @Published var tabs: [DocumentTab] = []
    @Published var activeTabId: UUID?

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load saved tabs from UserDefaults
        if let data = defaults.data(forKey: "savedTabs"),
           let savedTabs = try? JSONDecoder().decode([SavedTabData].self, from: data) {
            tabs = savedTabs.map { $0.toDocumentTab() }
            if let first = tabs.first {
                activeTabId = first.id
            }
        } else {
            // Create initial empty tab
            createNewTab()
        }
    }

    /// Returns the currently active tab
    var activeTab: DocumentTab? {
        tabs.first { $0.id == activeTabId }
    }

    /// Creates a new empty tab and activates it
    @discardableResult
    func createNewTab() -> DocumentTab {
        let newTab = DocumentTab()
        tabs.append(newTab)
        activeTabId = newTab.id
        saveTabs()
        return newTab
    }

    /// Creates a new tab with given content
    @discardableResult
    func createTab(text: String, fileName: String, folderURL: URL? = nil) -> DocumentTab {
        let newTab = DocumentTab(text: text, fileName: fileName, folderURL: folderURL)
        tabs.append(newTab)
        activeTabId = newTab.id
        saveTabs()
        return newTab
    }

    /// Closes a tab by ID
    func closeTab(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)

        // If we closed the active tab, switch to another
        if activeTabId == id {
            if let nextTab = tabs.first {
                activeTabId = nextTab.id
            } else {
                // If no tabs left, create a new one
                createNewTab()
            }
        }
        saveTabs()
    }

    /// Updates the content of the active tab
    func updateActiveTab(text: String) {
        guard let index = tabs.firstIndex(where: { $0.id == activeTabId }) else { return }
        tabs[index].text = text
        tabs[index].hasUnsavedChanges = true
        saveTabs()
    }

    /// Marks active tab as saved
    func markActiveTabSaved(fileName: String) {
        guard let index = tabs.firstIndex(where: { $0.id == activeTabId }) else { return }
        tabs[index].hasUnsavedChanges = false
        tabs[index].fileName = fileName
        saveTabs()
    }

    /// Loads content into the active tab
    func loadIntoActiveTab(text: String, fileName: String, folderURL: URL? = nil) {
        guard let index = tabs.firstIndex(where: { $0.id == activeTabId }) else { return }
        tabs[index].text = text
        tabs[index].fileName = fileName
        tabs[index].folderURL = folderURL
        tabs[index].hasUnsavedChanges = false
        saveTabs()
    }

    /// Switches to a specific tab
    func switchToTab(_ id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabId = id
        }
    }

    /// Loads content from a file into a new tab or existing tab
    func openFile(_ url: URL, content: String) {
        let fileName = url.deletingPathExtension().lastPathComponent
        let folderURL = url.deletingLastPathComponent()

        // Check if file is already open
        if let existingIndex = tabs.firstIndex(where: { $0.fileName == fileName && $0.folderURL == folderURL }) {
            activeTabId = tabs[existingIndex].id
            return
        }

        createTab(text: content, fileName: fileName, folderURL: folderURL)
    }

    private func saveTabs() {
        let savedData = tabs.map { SavedTabData(from: $0) }
        if let data = try? JSONEncoder().encode(savedData) {
            defaults.set(data, forKey: "savedTabs")
        }
    }
}

// MARK: - Codable Helper

private struct SavedTabData: Codable {
    let id: UUID
    let text: String
    let fileName: String
    let hasUnsavedChanges: Bool
    let folderURL: URL?

    init(from tab: DocumentTab) {
        self.id = tab.id
        self.text = tab.text
        self.fileName = tab.fileName
        self.hasUnsavedChanges = tab.hasUnsavedChanges
        self.folderURL = tab.folderURL
    }

    func toDocumentTab() -> DocumentTab {
        DocumentTab(text: text, fileName: fileName, hasUnsavedChanges: hasUnsavedChanges, folderURL: folderURL)
    }
}
import SwiftUI
import Combine

class MarkdownFileManager: ObservableObject {
    @Published var selectedFolder: URL?
    @Published var files: [URL] = []
    @Published var recentFiles: [URL] = []
    @Published var selectedFile: URL?
    
    private let defaults = UserDefaults.standard
    private var folderWatcher: DispatchSourceFileSystemObject?
    // Behält den Security-Scope aktiv, solange der Ordner geöffnet ist
    private var securityScopedFolder: URL?
    
    init() {
        loadRecentFiles()
        restoreFolderBookmark()
    }
    
    func setSelectedFolder(_ url: URL) {
        // Alten Scope freigeben
        securityScopedFolder?.stopAccessingSecurityScopedResource()
        // Neuen Scope öffnen
        let accessed = url.startAccessingSecurityScopedResource()
        securityScopedFolder = accessed ? url : nil
        selectedFolder = url
        loadFiles(in: url)
        startWatching(url)
        saveFolderBookmark(url)
    }
    
    func loadFiles(in folder: URL) {
        files.removeAll()
        
        guard let enumerator = Foundation.FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "md" {
                files.append(fileURL)
            }
        }
        
        // Sortiere: Dateien nach Name
        files.sort { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    func openFile(_ url: URL) {
        // Nil-Reset erzwingt onChange auch bei gleicher URL
        selectedFile = nil
        DispatchQueue.main.async {
            self.selectedFile = url
        }
    }
    
    func readFileContent(_ url: URL) -> String? {
        // Zuerst Security-Scope der Datei selbst versuchen
        let fileAccessed = url.startAccessingSecurityScopedResource()
        defer { if fileAccessed { url.stopAccessingSecurityScopedResource() } }

        // Falls Datei im gewählten Ordner liegt und Ordner-Scope aktiv ist, reicht das aus
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Fehler beim Lesen: \(error)")
            return nil
        }
    }
    
    func addRecentFile(_ url: URL) {
        // Vermeide Duplikate
        if let index = recentFiles.firstIndex(of: url) {
            recentFiles.remove(at: index)
        }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > 10 {
            recentFiles.removeLast()
        }
        saveRecentFiles()
    }
    
    func deleteFile(_ url: URL) {
        do {
            try Foundation.FileManager.default.removeItem(at: url)
            files.removeAll { $0 == url }
        } catch {
            print("Fehler beim Löschen: \(error)")
        }
    }
    
    func createNewFile(in folder: URL, named name: String) -> URL? {
        let fileURL = folder.appendingPathComponent(name.trimmingCharacters(in: .whitespaces) + ".md")
        
        do {
            if Foundation.FileManager.default.fileExists(atPath: fileURL.path) {
                print("Datei existiert bereits")
                return nil
            }
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            files.append(fileURL)
            files.sort { $0.lastPathComponent < $1.lastPathComponent }
            return fileURL
        } catch {
            print("Fehler beim Erstellen: \(error)")
            return nil
        }
    }
    
    // MARK: - Folder Watching
    
    private func startWatching(_ url: URL) {
        folderWatcher?.cancel()
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .link],
            queue: DispatchQueue.main
        )
        source.setEventHandler { [weak self] in
            self?.loadFiles(in: url)
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        folderWatcher = source
    }
    
    // MARK: - Persistence

    private func saveFolderBookmark(_ url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        defaults.set(data, forKey: "selectedFolderBookmark")
    }

    private func restoreFolderBookmark() {
        guard let data = defaults.data(forKey: "selectedFolderBookmark") else { return }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return }
        if isStale {
            // Bookmark erneuern beim nächsten Zugriff via fileImporter
            defaults.removeObject(forKey: "selectedFolderBookmark")
            return
        }
        // Scope aktivieren und Ordner laden (ohne erneutes Speichern)
        let accessed = url.startAccessingSecurityScopedResource()
        securityScopedFolder = accessed ? url : nil
        selectedFolder = url
        loadFiles(in: url)
        startWatching(url)
    }

    private func saveRecentFiles() {
        defaults.set(recentFiles.map(\.path), forKey: "recentFiles")
    }

    private func loadRecentFiles() {
        if let paths = defaults.array(forKey: "recentFiles") as? [String] {
            recentFiles = paths.compactMap { URL(fileURLWithPath: $0) }
        }
    }
}

import SwiftUI
import Foundation

struct FileBrowserView: View {
    @ObservedObject var fileManager: MarkdownFileManager
    @State private var showNewFileDialog = false
    @State private var newFileName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Dateien")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showNewFileDialog = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Neue Datei erstellen")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Ordner-Inhalt
            if let folder = fileManager.selectedFolder {
                FolderSection(folder: folder, files: fileManager.files) { file in
                    fileManager.openFile(file)
                } onDelete: { file in
                    fileManager.deleteFile(file)
                }
            } else {
                EmptyStateView()
            }
            
            // Unten: Zuletzt geöffnet
            if !fileManager.recentFiles.isEmpty {
                Divider()
                RecentFilesSection(recentFiles: fileManager.recentFiles) { file in
                    fileManager.openFile(file)
                }
            }
        }
        .sheet(isPresented: $showNewFileDialog) {
            NewFileDialog(
                fileName: $newFileName,
                folder: fileManager.selectedFolder,
                onCreate: { url in
                    fileManager.openFile(url)
                }
            )
        }
    }
}

// MARK: - Folder Section

struct FolderSection: View {
    let folder: URL
    let files: [URL]
    let onSelect: (URL) -> Void
    let onDelete: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(folder.lastPathComponent, systemImage: "folder")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 4)
            
            if files.isEmpty {
                ContentUnavailableView(
                    "Keine Markdown-Dateien",
                    systemImage: "doc.text",
                    description: Text("Wähle einen Ordner mit .md-Dateien")
                )
                .padding()
            } else {
                List(files, id: \.self) { file in
                    Button(action: { onSelect(file) }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text(file.lastPathComponent)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Löschen", role: .destructive) {
                            onDelete(file)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Recent Files Section

struct RecentFilesSection: View {
    let recentFiles: [URL]
    let onSelect: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Zuletzt geöffnet", systemImage: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 4)
            
            ForEach(recentFiles, id: \.self) { file in
                Button(action: { onSelect(file) }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        Text(file.lastPathComponent)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "Kein Ordner gewählt",
            systemImage: "folder",
            description: Text("Klicke auf \"Ordner\" um Markdown-Dateien zu laden")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - New File Dialog

struct NewFileDialog: View {
    @Binding var fileName: String
    let folder: URL?
    let onCreate: (URL) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Neue Markdown-Datei")
                .font(.headline)
            
            TextField("Dateiname", text: $fileName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { createFile() }
            
            HStack {
                Button("Abbrechen") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button("Erstellen") {
                    createFile()
                }
                .buttonStyle(.borderedProminent)
                .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            fileName = "neue-datei"
        }
    }
    
    private func createFile() {
        guard let folder = folder else { return }
        let name = fileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let fileURL = folder.appendingPathComponent(name + ".md")
        guard !Foundation.FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            onCreate(fileURL)
            dismiss()
        } catch {
            print("Fehler beim Erstellen: \(error)")
        }
    }
}

#Preview {
    FileBrowserView(fileManager: MarkdownFileManager())
}

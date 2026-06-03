import SwiftUI

struct ToolbarView: View {
    @ObservedObject var fileManager: MarkdownFileManager
    @ObservedObject var editorModel: EditorModel
    @Binding var showTemplatePicker: Bool
    @Binding var showFolderPicker: Bool
    @Binding var showSaveDialog: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Dateiname
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(editorModel.currentFileName)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Spacer()
            
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

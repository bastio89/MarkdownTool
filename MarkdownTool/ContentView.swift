import SwiftUI
import UniformTypeIdentifiers

struct MarkdownExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    static var writableContentTypes: [UTType] { [.plainText] }
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        text = configuration.file.regularFileContents
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct ContentView: View {
    @StateObject private var fileManager = MarkdownFileManager()
    @StateObject private var editorModel = EditorModel()
    @State private var selectedTemplate: String?
    @State private var showTemplatePicker = false
    @State private var showFolderPicker = false
    @State private var showSaveDialog = false

    var body: some View {
        NavigationSplitView {
            // Sidebar: File Browser
            FileBrowserView(fileManager: fileManager)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
        } detail: {
            // Main Editor Area
            VStack(spacing: 0) {
                // Toolbar
                ToolbarView(
                    fileManager: fileManager,
                    editorModel: editorModel,
                    showTemplatePicker: $showTemplatePicker,
                    showFolderPicker: $showFolderPicker,
                    showSaveDialog: $showSaveDialog
                )

                // Split View: Editor | Preview
                Divider()
                HSplitView {
                    // Left: Markdown Editor
                    MarkdownEditorView(text: $editorModel.text)
                        .frame(minWidth: 300)

                    // Right: Live Preview
                    MarkdownPreviewView(markdownText: editorModel.text)
                        .frame(minWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { editorModel.newDocument() }) {
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

                Button(action: { showSaveDialog.toggle() }) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Speichern")
                }
                .help("Als .md speichern (⌘S)")
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(selectedTemplate: $selectedTemplate)
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
                fileManager.addRecentFile(url)
                if let folder = fileManager.selectedFolder {
                    // Immer neu laden – kein Pfadvergleich (security-scoped URLs sind sonst nie gleich)
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
                editorModel.loadFileContent(content, fileName: url.deletingPathExtension().lastPathComponent)
            }
        }
    }
}

#Preview {
    ContentView()
}

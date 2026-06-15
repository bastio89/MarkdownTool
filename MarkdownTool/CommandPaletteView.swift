import SwiftUI

// MARK: - Command Palette Item

struct CommandPaletteItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: CommandCategory
    let icon: String
    let shortcut: String?

    enum CommandCategory: String, CaseIterable {
        case file = "Datei"
        case edit = "Bearbeiten"
        case view = "Ansicht"
        case tools = "Werkzeuge"
    }
}

// MARK: - Command Palette View

struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    let onSelect: (CommandPaletteItem) -> Void
    @State private var searchText = ""
    @State private var selectedIndex = 0

    private var commands: [CommandPaletteItem] {
        [
            // Datei
            CommandPaletteItem(id: "new", name: "Neues Dokument", category: .file, icon: "doc", shortcut: "⌘N"),
            CommandPaletteItem(id: "openFolder", name: "Ordner öffnen", category: .file, icon: "folder", shortcut: "⌘O"),
            CommandPaletteItem(id: "save", name: "Speichern", category: .file, icon: "square.and.arrow.down", shortcut: "⌘S"),
            CommandPaletteItem(id: "template", name: "Vorlage auswählen", category: .file, icon: "doc.badge.plus", shortcut: "⌘⇧N"),
            CommandPaletteItem(id: "export", name: "Exportieren...", category: .file, icon: "square.and.arrow.up", shortcut: "⌘⇧S"),

            // Bearbeiten
            CommandPaletteItem(id: "search", name: "Suchen", category: .edit, icon: "magnifyingglass", shortcut: "⌘F"),
            CommandPaletteItem(id: "searchReplace", name: "Suchen & Ersetzen", category: .edit, icon: "arrow.left.arrow.right", shortcut: "⌘H"),
            CommandPaletteItem(id: "undo", name: "Rückgängig", category: .edit, icon: "arrow.uturn.backward", shortcut: "⌘Z"),
            CommandPaletteItem(id: "redo", name: "Wiederholen", category: .edit, icon: "arrow.uturn.forward", shortcut: "⌘⇧Z"),

            // Ansicht
            CommandPaletteItem(id: "quickOpen", name: "Schnellöffnen", category: .view, icon: "doc.text.magnifyingglass", shortcut: "⌘P"),
            CommandPaletteItem(id: "toggleSidebar", name: "Seitenleiste ein/aus", category: .view, icon: "sidebar.left", shortcut: "⌘B"),
            CommandPaletteItem(id: "togglePreview", name: "Vorschau ein/aus", category: .view, icon: "eye", shortcut: "⌘⇧P"),
            CommandPaletteItem(id: "fontIncrease", name: "Schrift vergrößern", category: .view, icon: "textformat.size.larger", shortcut: "⌘+"),
            CommandPaletteItem(id: "fontDecrease", name: "Schrift verkleinern", category: .view, icon: "textformat.size.smaller", shortcut: "⌘-"),
            CommandPaletteItem(id: "fontReset", name: "Schriftgröße zurücksetzen", category: .view, icon: "textformat.size", shortcut: "⌘0"),
            CommandPaletteItem(id: "toggleHighlight", name: "Syntax-Highlighting", category: .view, icon: "paintpalette", shortcut: "⌘⇧H"),
            CommandPaletteItem(id: "toggleVim", name: "Vim-Modus", category: .view, icon: "keyboard", shortcut: nil),

            // Werkzeuge
            CommandPaletteItem(id: "theme", name: "Theme wählen", category: .tools, icon: "paintpalette.fill", shortcut: nil),
            CommandPaletteItem(id: "backup", name: "Backup & Sync", category: .tools, icon: "icloud.and.arrow.down", shortcut: nil),
            CommandPaletteItem(id: "snippets", name: "Snippets verwalten", category: .tools, icon: "text.snippet", shortcut: nil),
            CommandPaletteItem(id: "linter", name: "Markdown prüfen", category: .tools, icon: "checkmark.shield", shortcut: nil),
            CommandPaletteItem(id: "statistics", name: "Statistiken anzeigen", category: .tools, icon: "chart.bar", shortcut: nil),
            CommandPaletteItem(id: "help", name: "Hilfe anzeigen", category: .tools, icon: "questionmark.circle", shortcut: "⌘?"),
        ]
    }

    private var filteredCommands: [CommandPaletteItem] {
        if searchText.isEmpty {
            return commands
        }
        return commands.filter { command in
            command.name.localizedCaseInsensitiveContains(searchText) ||
            command.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedCommands: [(CommandPaletteItem.CommandCategory, [CommandPaletteItem])] {
        let grouped = Dictionary(grouping: filteredCommands) { $0.category }
        return CommandPaletteItem.CommandCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Befehl suchen...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .onSubmit {
                        if let first = filteredCommands.first {
                            onSelect(first)
                        }
                    }

                Button(action: { isPresented = false }) {
                    Text("ESC")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            // Command List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedCommands, id: \.0) { category, items in
                        Section {
                            ForEach(items) { command in
                                CommandRowView(command: command) {
                                    onSelect(command)
                                }
                            }
                        } header: {
                            HStack {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.5))
                        }
                    }
                }
            }
            .frame(maxHeight: 400)

            Divider()

            // Footer hint
            HStack {
                Text("↑↓ Navigieren")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("↵ Auswählen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("ESC Schließen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
        }
        .frame(width: 500, height: 500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
    }
}

struct CommandRowView: View {
    let command: CommandPaletteItem
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: command.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)

                Text(command.name)
                    .font(.body)

                Spacer()

                if let shortcut = command.shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Quick Open Item

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let url: URL
}

// MARK: - Quick Open View

struct QuickOpenView: View {
    @Binding var isPresented: Bool
    let files: [FileItem]
    let onSelect: (FileItem) -> Void
    @State private var searchText = ""
    @State private var selectedIndex = 0

    private var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return Array(files.prefix(20))
        }
        return files.filter { file in
            file.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Datei suchen...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))

                Button(action: { isPresented = false }) {
                    Text("ESC")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            // File List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredFiles) { file in
                        Button(action: { onSelect(file) }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)

                                VStack(alignment: .leading) {
                                    Text(file.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    Text(file.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 400)

            Divider()

            // Footer hint
            HStack {
                Text("\(filteredFiles.count) Dateien")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("↵ Öffnen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
        }
        .frame(width: 500, height: 500)
    }
}

#Preview("Command Palette") {
    CommandPaletteView(isPresented: .constant(true)) { command in
        print("Selected: \(command.name)")
    }
}

#Preview("Quick Open") {
    QuickOpenView(
        isPresented: .constant(true),
        files: [
            FileItem(name: "README.md", path: "/Users/test/README.md", url: URL(fileURLWithPath: "/Users/test/README.md")),
            FileItem(name: "CHANGELOG.md", path: "/Users/test/CHANGELOG.md", url: URL(fileURLWithPath: "/Users/test/CHANGELOG.md")),
        ],
        onSelect: { file in
            print("Selected: \(file.name)")
        }
    )
}
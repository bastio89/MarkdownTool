import SwiftUI
import Combine

// MARK: - Command

struct Command: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: CommandCategory
    let shortcut: String?
    let action: CommandAction

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Command, rhs: Command) -> Bool {
        lhs.id == rhs.id
    }
}

enum CommandCategory: String, CaseIterable {
    case file = "Datei"
    case edit = "Bearbeiten"
    case view = "Ansicht"
    case format = "Formatierung"
    case tools = "Werkzeuge"
    case help = "Hilfe"
}

enum CommandAction {
    case newDocument
    case openFolder
    case save
    case export
    case closeTab
    case undo
    case redo
    case cut
    case copy
    case paste
    case selectAll
    case find
    case replace
    case togglePreview
    case toggleSidebar
    case toggleSearch
    case increaseFontSize
    case decreaseFontSize
    case resetFontSize
    case toggleVimMode
    case toggleSyntaxHighlighting
    case openThemePicker
    case openBackupSettings
    case openExportSettings
    case openStatistics
    case openSnippets
    case openQuickOpen
    case insertTemplate(String)
    case custom(String)
}

// MARK: - Command Registry

class CommandRegistry: ObservableObject {
    @Published var commands: [Command] = []

    init() {
        registerDefaultCommands()
    }

    private func registerDefaultCommands() {
        commands = [
            // File Commands
            Command(name: "Neues Dokument", description: "Neue Markdown-Datei erstellen", icon: "doc.badge.plus", category: .file, shortcut: "⌘N", action: .newDocument),
            Command(name: "Ordner öffnen", description: "Ordner mit Markdown-Dateien öffnen", icon: "folder", category: .file, shortcut: "⌘O", action: .openFolder),
            Command(name: "Speichern", description: "Aktuelles Dokument speichern", icon: "square.and.arrow.down", category: .file, shortcut: "⌘S", action: .save),
            Command(name: "Exportieren", description: "In anderes Format exportieren", icon: "square.and.arrow.up", category: .file, shortcut: "⌘⇧S", action: .export),
            Command(name: "Tab schließen", description: "Aktuellen Tab schließen", icon: "xmark", category: .file, shortcut: "⌘W", action: .closeTab),

            // Edit Commands
            Command(name: "Rückgängig", description: "Letzte Änderung rückgängig machen", icon: "arrow.uturn.backward", category: .edit, shortcut: "⌘Z", action: .undo),
            Command(name: "Wiederholen", description: "Rückgängig gemachte Änderung wiederholen", icon: "arrow.uturn.forward", category: .edit, shortcut: "⌘⇧Z", action: .redo),
            Command(name: "Ausschneiden", description: "Auswahl ausschneiden", icon: "scissors", category: .edit, shortcut: "⌘X", action: .cut),
            Command(name: "Kopieren", description: "Auswahl kopieren", icon: "doc.on.doc", category: .edit, shortcut: "⌘C", action: .copy),
            Command(name: "Einfügen", description: "Aus Zwischenablage einfügen", icon: "doc.on.clipboard", category: .edit, shortcut: "⌘V", action: .paste),
            Command(name: "Alles auswählen", description: "Gesamten Text auswählen", icon: "selection.pin.in.out", category: .edit, shortcut: "⌘A", action: .selectAll),
            Command(name: "Suchen", description: "Text im Dokument suchen", icon: "magnifyingglass", category: .edit, shortcut: "⌘F", action: .find),
            Command(name: "Ersetzen", description: "Text suchen und ersetzen", icon: "arrow.left.arrow.right", category: .edit, shortcut: "⌘H", action: .replace),

            // View Commands
            Command(name: "Vorschau umschalten", description: "Markdown-Vorschau ein/ausblenden", icon: "eye", category: .view, shortcut: "⌘⇧P", action: .togglePreview),
            Command(name: "Seitenleiste umschalten", description: "Datei-Browser ein/ausblenden", icon: "sidebar.left", category: .view, shortcut: "⌘B", action: .toggleSidebar),
            Command(name: "Suchleiste umschalten", description: "Suchleiste ein/ausblenden", icon: "magnifyingglass", category: .view, shortcut: "⌘F", action: .toggleSearch),
            Command(name: "Schrift vergrößern", description: "Editor-Schrift vergrößern", icon: "plus.magnifyingglass", category: .view, shortcut: "⌘+", action: .increaseFontSize),
            Command(name: "Schrift verkleinern", description: "Editor-Schrift verkleinern", icon: "minus.magnifyingglass", category: .view, shortcut: "⌘-", action: .decreaseFontSize),
            Command(name: "Schriftgröße zurücksetzen", description: "Editor-Schriftgröße zurücksetzen", icon: "arrow.counterclockwise", category: .view, shortcut: "⌘0", action: .resetFontSize),

            // Format Commands
            Command(name: "Fett", description: "Auswahl fett formatieren", icon: "bold", category: .format, shortcut: nil, action: .custom("**text**")),
            Command(name: "Kursiv", description: "Auswahl kursiv formatieren", icon: "italic", category: .format, shortcut: nil, action: .custom("*text*")),
            Command(name: "Überschrift 1", description: "Als Überschrift 1 formatieren", icon: "textformat.size.larger", category: .format, shortcut: nil, action: .custom("# ")),
            Command(name: "Überschrift 2", description: "Als Überschrift 2 formatieren", icon: "textformat.size", category: .format, shortcut: nil, action: .custom("## ")),
            Command(name: "Code", description: "Als Code formatieren", icon: "chevron.left.forwardslash.chevron.right", category: .format, shortcut: nil, action: .custom("`code`")),

            // Tools Commands
            Command(name: "Vim-Modus", description: "Vim-Editor-Modus ein/aus", icon: "keyboard", category: .tools, shortcut: nil, action: .toggleVimMode),
            Command(name: "Syntax-Highlighting", description: "Syntax-Highlighting ein/aus", icon: "paintpalette", category: .tools, shortcut: nil, action: .toggleSyntaxHighlighting),
            Command(name: "Theme wählen", description: "Editor-Theme ändern", icon: "paintpalette.fill", category: .tools, shortcut: nil, action: .openThemePicker),
            Command(name: "Backup-Einstellungen", description: "Auto-Backup konfigurieren", icon: "icloud.and.arrow.down", category: .tools, shortcut: nil, action: .openBackupSettings),
            Command(name: "Export-Einstellungen", description: "Export-Optionen konfigurieren", icon: "square.and.arrow.up", category: .tools, shortcut: nil, action: .openExportSettings),
            Command(name: "Statistiken", description: "Dokument-Statistiken anzeigen", icon: "chart.bar", category: .tools, shortcut: nil, action: .openStatistics),
            Command(name: "Snippets", description: "Textbausteine verwalten", icon: "text.insert", category: .tools, shortcut: nil, action: .openSnippets),
            Command(name: "Schnellöffnen", description: "Datei im Ordner suchen", icon: "doc.text.magnifyingglass", category: .tools, shortcut: "⌘P", action: .openQuickOpen),
        ]
    }

    func filterCommands(_ query: String) -> [Command] {
        if query.isEmpty {
            return commands
        }
        return commands.filter { command in
            command.name.localizedCaseInsensitiveContains(query) ||
            command.description.localizedCaseInsensitiveContains(query) ||
            command.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    func addCustomCommand(_ command: Command) {
        commands.append(command)
    }
}

// MARK: - Command Palette View

struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @ObservedObject var commandRegistry: CommandRegistry

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var filteredCommands: [Command] {
        commandRegistry.filterCommands(searchText)
    }

    private var groupedCommands: [(CommandCategory, [Command])] {
        let filtered = filteredCommands
        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        return CommandCategory.allCases.compactMap { category in
            guard let commands = grouped[category], !commands.isEmpty else { return nil }
            return (category, commands)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "terminal")
                    .foregroundStyle(.secondary)

                TextField("Befehl eingeben...", text: $searchText)
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
            .padding(12)
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            // Results
            if filteredCommands.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "command.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Keine Befehle gefunden")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                                CommandRow(
                                    command: command,
                                    isSelected: index == selectedIndex
                                )
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    executeCommand(command)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }

            // Footer
            HStack {
                Text("\(filteredCommands.count) Befehle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                        Image(systemName: "arrow.down")
                        Text("Navigieren")
                    }
                    .font(.caption2)

                    HStack(spacing: 4) {
                        Image(systemName: "return")
                        Text("Ausführen")
                    }
                    .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
        }
        .frame(width: 500, height: 450)
        .onAppear {
            isSearchFocused = true
        }
    }

    private func executeCommand(_ command: Command) {
        isPresented = false
        // Command execution is handled by the parent view
        NotificationCenter.default.post(
            name: .executeCommand,
            object: nil,
            userInfo: ["command": command]
        )
    }
}

// MARK: - Command Row

struct CommandRow: View {
    let command: Command
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.title3)
                .frame(width: 24)
                .foregroundStyle(isSelected ? .white : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(command.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(command.description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }

            Spacer()

            Text(command.category.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.1))
                .clipShape(Capsule())

            if let shortcut = command.shortcut {
                Text(shortcut)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.15) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(isSelected ? .white : .primary)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let executeCommand = Notification.Name("executeCommand")
}
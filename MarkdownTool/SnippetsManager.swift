import SwiftUI
import Combine

// MARK: - Snippet Model

struct Snippet: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var trigger: String
    var content: String
    var description: String
    var category: String
    var createdAt: Date
    var usageCount: Int

    init(name: String, trigger: String, content: String, description: String = "", category: String = "Benutzerdefiniert") {
        self.id = UUID()
        self.name = name
        self.trigger = trigger
        self.content = content
        self.description = description
        self.category = category
        self.createdAt = Date()
        self.usageCount = 0
    }
}

// MARK: - Snippets Manager

class SnippetsManager: ObservableObject {
    @Published var snippets: [Snippet] = []

    private let snippetsKey = "markdownSnippets"

    init() {
        loadSnippets()
    }

    private func loadSnippets() {
        if let data = UserDefaults.standard.data(forKey: snippetsKey),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
        } else {
            // Default snippets
            snippets = Self.defaultSnippets
        }
    }

    func saveSnippets() {
        if let encoded = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(encoded, forKey: snippetsKey)
        }
    }

    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
        saveSnippets()
    }

    func updateSnippet(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
            saveSnippets()
        }
    }

    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        saveSnippets()
    }

    func incrementUsage(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index].usageCount += 1
            saveSnippets()
        }
    }

    func findSnippet(byTrigger trigger: String) -> Snippet? {
        snippets.first { $0.trigger == trigger }
    }

    // Default snippets
    static let defaultSnippets: [Snippet] = [
        Snippet(
            name: "README Header",
            trigger: "!readme",
            content: "# Project Name\n\n> Short description\n\n## Features\n\n- Feature 1\n- Feature 2\n\n## Installation\n\n```bash\nnpm install\n```\n",
            description: "README.md Header mit Features",
            category: "Templates"
        ),
        Snippet(
            name: "Code Block",
            trigger: "!code",
            content: "```\n\n```",
            description: "Markdown Code Block",
            category: "Code"
        ),
        Snippet(
            name: "Table",
            trigger: "!table",
            content: "| Header 1 | Header 2 | Header 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |\n| Cell 4   | Cell 5   | Cell 6   |",
            description: "Markdown Tabelle",
            category: "Tables"
        ),
        Snippet(
            name: "Task List",
            trigger: "!todo",
            content: "- [ ] Task 1\n- [ ] Task 2\n- [x] Completed Task",
            description: "Todo-Liste erstellen",
            category: "Lists"
        ),
        Snippet(
            name: "Image",
            trigger: "!img",
            content: "![Alt Text](image-url.png)",
            description: "Bild einfügen",
            category: "Media"
        ),
        Snippet(
            name: "Link",
            trigger: "!link",
            content: "[Link Text](url)",
            description: "Hyperlink einfügen",
            category: "Media"
        ),
        Snippet(
            name: "Heading 2",
            trigger: "!h2",
            content: "## ",
            description: "Überschrift 2",
            category: "Headings"
        ),
        Snippet(
            name: "Blockquote",
            trigger: "!quote",
            content: "> ",
            description: "Zitat-Block",
            category: "Text"
        ),
        Snippet(
            name: "Horizontal Rule",
            trigger: "!hr",
            content: "\n---\n",
            description: "Horizontale Linie",
            category: "Layout"
        ),
        Snippet(
            name: "Changelog Entry",
            trigger: "!log",
            content: "## [Unreleased]\n\n### Added\n- \n\n### Changed\n- \n\n### Fixed\n- ",
            description: "Changelog Entry",
            category: "Templates"
        )
    ]
}

// MARK: - Snippets View

struct SnippetsView: View {
    @ObservedObject var snippetsManager: SnippetsManager
    @State private var searchText = ""
    @State private var selectedSnippet: Snippet?
    @State private var showAddSnippet = false
    @State private var showEditSnippet = false
    @Environment(\.dismiss) private var dismiss

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return snippetsManager.snippets
        }
        return snippetsManager.snippets.filter { snippet in
            snippet.name.localizedCaseInsensitiveContains(searchText) ||
            snippet.trigger.localizedCaseInsensitiveContains(searchText) ||
            snippet.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedSnippets: [(String, [Snippet])] {
        let grouped = Dictionary(grouping: filteredSnippets, by: { $0.category })
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "text.insert")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Snippets")
                    .font(.headline)
                Spacer()

                Button(action: { showAddSnippet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search & Add
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Suchen...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Snippets List
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                    ForEach(groupedSnippets, id: \.0) { category, snippets in
                        Section {
                            ForEach(snippets) { snippet in
                                SnippetRow(
                                    snippet: snippet,
                                    onEdit: { selectedSnippet = snippet; showEditSnippet = true },
                                    onDelete: { snippetsManager.deleteSnippet(snippet) },
                                    onCopy: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(snippet.content, forType: .string)
                                    }
                                )
                            }
                        } header: {
                            HStack {
                                Text(category)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: NSColor.windowBackgroundColor))
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 550, height: 500)
        .sheet(isPresented: $showAddSnippet) {
            SnippetEditorView(snippet: nil) { newSnippet in
                snippetsManager.addSnippet(newSnippet)
            }
        }
        .sheet(isPresented: $showEditSnippet) {
            if let snippet = selectedSnippet {
                SnippetEditorView(snippet: snippet) { updatedSnippet in
                    snippetsManager.updateSnippet(updatedSnippet)
                }
            }
        }
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void

    @State private var showCopied = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(snippet.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(snippet.trigger)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(snippet.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(snippet.content.prefix(50) + (snippet.content.count > 50 ? "..." : ""))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    onCopy()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(showCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Snippet Editor View

struct SnippetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let snippet: Snippet?
    let onSave: (Snippet) -> Void

    @State private var name: String = ""
    @State private var trigger: String = ""
    @State private var content: String = ""
    @State private var description: String = ""
    @State private var category: String = "Benutzerdefiniert"

    private let categories = ["Benutzerdefiniert", "Templates", "Code", "Tables", "Lists", "Media", "Headings", "Text", "Layout"]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: snippet == nil ? "plus.circle" : "pencil.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(snippet == nil ? "Neues Snippet" : "Snippet bearbeiten")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Form
            VStack(spacing: 12) {
                HStack {
                    Text("Name:")
                        .frame(width: 80, alignment: .trailing)
                    TextField("Snippet-Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Trigger:")
                        .frame(width: 80, alignment: .trailing)
                    TextField("z.B. !table", text: $trigger)
                        .textFieldStyle(.roundedBorder)

                    Text("Typen Sie dies im Editor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Kategorie:")
                        .frame(width: 80, alignment: .trailing)
                    Picker("", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .labelsHidden()
                }

                HStack(alignment: .top) {
                    Text("Beschreibung:")
                        .frame(width: 80, alignment: .trailing)
                    TextField("Was macht dieses Snippet?", text: $description)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Inhalt:")
                        .frame(width: 80, alignment: .trailing)

                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: NSColor.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button("Abbrechen") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Speichern") {
                    saveSnippet()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || trigger.isEmpty || content.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500, height: 450)
        .onAppear {
            if let snippet = snippet {
                name = snippet.name
                trigger = snippet.trigger
                content = snippet.content
                description = snippet.description
                category = snippet.category
            }
        }
    }

    private func saveSnippet() {
        var snippetToSave: Snippet

        if let existing = snippet {
            snippetToSave = existing
            snippetToSave.name = name
            snippetToSave.trigger = trigger
            snippetToSave.content = content
            snippetToSave.description = description
            snippetToSave.category = category
        } else {
            snippetToSave = Snippet(name: name, trigger: trigger, content: content, description: description, category: category)
        }

        onSave(snippetToSave)
        dismiss()
    }
}
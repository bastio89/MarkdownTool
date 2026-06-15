import SwiftUI
import Carbon

// MARK: - Quick Open View

struct QuickOpenView: View {
    @Binding var isPresented: Bool
    let files: [FileItem]
    let onSelect: (FileItem) -> Void

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return files
        }
        return files.filter { file in
            file.name.localizedCaseInsensitiveContains(searchText) ||
            file.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Dateiname eingeben...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { isPresented = false }) {
                    Text("Esc")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            // Results
            if filteredFiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Keine Dateien gefunden")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredFiles.enumerated()), id: \.element.id) { index, file in
                                QuickOpenRow(
                                    file: file,
                                    isSelected: index == selectedIndex,
                                    searchText: searchText
                                )
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelect(file)
                                    isPresented = false
                                }
                                .onHover { hovering in
                                    if hovering {
                                        selectedIndex = index
                                    }
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
                Text("\(filteredFiles.count) von \(files.count) Dateien")
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
                        Text("Öffnen")
                    }
                    .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 400)
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: filteredFiles) { _, _ in
            if selectedIndex >= filteredFiles.count {
                selectedIndex = max(0, filteredFiles.count - 1)
            }
        }
    }
}

// MARK: - Quick Open Row

struct QuickOpenRow: View {
    let file: FileItem
    let isSelected: Bool
    let searchText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(isSelected ? .white : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                highlightedName
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(file.path)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Text("↵")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(isSelected ? .white : .primary)
    }

    @ViewBuilder
    private var highlightedName: some View {
        if searchText.isEmpty {
            Text(file.name)
        } else {
            let name = file.name
            let search = searchText.lowercased()
            let lowerName = name.lowercased()

            if let range = lowerName.range(of: search) {
                let start = name.distance(from: name.startIndex, to: range.lowerBound)
                let end = start + search.count

                let prefix = String(name.prefix(start))
                let match = String(name[name.index(name.startIndex, offsetBy: start)..<name.index(name.startIndex, offsetBy: end)])
                let suffix = String(name.suffix(name.count - end))

                Text(prefix) +
                Text(match)
                    .foregroundStyle(.yellow)
                    .fontWeight(.bold) +
                Text(suffix)
            } else {
                Text(name)
            }
        }
    }
}

// MARK: - File Item

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let url: URL

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}
import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager
    var onNewTab: () -> Void
    var onCloseTab: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tabManager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isActive: tab.id == tabManager.activeTabId,
                        onSelect: { tabManager.switchToTab(tab.id) },
                        onClose: { onCloseTab(tab.id) }
                    )
                }

                // New Tab Button
                Button(action: onNewTab) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Neuer Tab (⌘T)")
                .keyboardShortcut("t", modifiers: .command)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct TabItemView: View {
    let tab: DocumentTab
    let isActive: Bool
    var onSelect: () -> Void
    var onClose: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            // File icon
            Image(systemName: "doc.text")
                .font(.system(size: 10))
                .foregroundColor(isActive ? .accentColor : .secondary)

            // File name
            Text(tab.fileName)
                .font(.system(size: 12))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)

            // Unsaved indicator
            if tab.hasUnsavedChanges {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isActive ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.15) : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect() }
    }
}

#Preview {
    TabBarView(
        tabManager: {
            let tm = TabManager()
            tm.createTab(text: "# Test", fileName: "readme.md")
            tm.createTab(text: "# Notes", fileName: "notes.md")
            return tm
        }(),
        onNewTab: {},
        onCloseTab: { _ in }
    )
    .frame(width: 600, height: 40)
}
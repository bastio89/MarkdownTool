import SwiftUI
import Combine

// MARK: - Editor Theme

struct EditorTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let isDark: Bool
    let backgroundColor: Color
    let textColor: Color
    let cursorColor: Color
    let selectionColor: Color
    let lineNumberColor: Color
    let lineNumberBackground: Color
    let keywordColor: Color
    let stringColor: Color
    let commentColor: Color
    let headingColor: Color
    let linkColor: Color
    let codeColor: Color
    let blockquoteColor: Color
    let listColor: Color
    let horizontalRuleColor: Color
    let fontName: String
    let fontSize: CGFloat

    static let monokai = EditorTheme(
        id: "monokai",
        name: "Monokai",
        isDark: true,
        backgroundColor: Color(hex: "272822"),
        textColor: Color(hex: "F8F8F2"),
        cursorColor: Color(hex: "F8F8F0"),
        selectionColor: Color(hex: "49483E"),
        lineNumberColor: Color(hex: "90908A"),
        lineNumberBackground: Color(hex: "272822"),
        keywordColor: Color(hex: "F92672"),
        stringColor: Color(hex: "E6DB74"),
        commentColor: Color(hex: "75715E"),
        headingColor: Color(hex: "66D9EF"),
        linkColor: Color(hex: "A6E22E"),
        codeColor: Color(hex: "AE81FF"),
        blockquoteColor: Color(hex: "AE81FF"),
        listColor: Color(hex: "FD971F"),
        horizontalRuleColor: Color(hex: "49483E"),
        fontName: "JetBrains Mono",
        fontSize: 14
    )

    static let dracula = EditorTheme(
        id: "dracula",
        name: "Dracula",
        isDark: true,
        backgroundColor: Color(hex: "282A36"),
        textColor: Color(hex: "F8F8F2"),
        cursorColor: Color(hex: "F8F8F0"),
        selectionColor: Color(hex: "44475A"),
        lineNumberColor: Color(hex: "6272A4"),
        lineNumberBackground: Color(hex: "282A36"),
        keywordColor: Color(hex: "FF79C6"),
        stringColor: Color(hex: "F1FA8C"),
        commentColor: Color(hex: "6272A4"),
        headingColor: Color(hex: "50FA7B"),
        linkColor: Color(hex: "8BE9FD"),
        codeColor: Color(hex: "BD93F9"),
        blockquoteColor: Color(hex: "BD93F9"),
        listColor: Color(hex: "FFB86C"),
        horizontalRuleColor: Color(hex: "44475A"),
        fontName: "JetBrains Mono",
        fontSize: 14
    )

    static let github = EditorTheme(
        id: "github",
        name: "GitHub",
        isDark: false,
        backgroundColor: Color(hex: "FFFFFF"),
        textColor: Color(hex: "24292E"),
        cursorColor: Color(hex: "24292E"),
        selectionColor: Color(hex: "C8E1FF"),
        lineNumberColor: Color(hex: "6E7781"),
        lineNumberBackground: Color(hex: "FFFFFF"),
        keywordColor: Color(hex: "D73A49"),
        stringColor: Color(hex: "032F62"),
        commentColor: Color(hex: "6A737D"),
        headingColor: Color(hex: "005CC5"),
        linkColor: Color(hex: "0366D6"),
        codeColor: Color(hex: "E36209"),
        blockquoteColor: Color(hex: "6A737D"),
        listColor: Color(hex: "E36209"),
        horizontalRuleColor: Color(hex: "E1E4E8"),
        fontName: "SFMono-Regular",
        fontSize: 14
    )

    static let nord = EditorTheme(
        id: "nord",
        name: "Nord",
        isDark: true,
        backgroundColor: Color(hex: "2E3440"),
        textColor: Color(hex: "ECEFF4"),
        cursorColor: Color(hex: "ECEFF4"),
        selectionColor: Color(hex: "434C5E"),
        lineNumberColor: Color(hex: "4C566A"),
        lineNumberBackground: Color(hex: "2E3440"),
        keywordColor: Color(hex: "81A1C1"),
        stringColor: Color(hex: "A3BE8C"),
        commentColor: Color(hex: "616E88"),
        headingColor: Color(hex: "88C0D0"),
        linkColor: Color(hex: "8FBCBB"),
        codeColor: Color(hex: "B48EAD"),
        blockquoteColor: Color(hex: "B48EAD"),
        listColor: Color(hex: "EBCB8B"),
        horizontalRuleColor: Color(hex: "3B4252"),
        fontName: "SF Mono",
        fontSize: 14
    )

    static let solarized = EditorTheme(
        id: "solarized",
        name: "Solarized",
        isDark: true,
        backgroundColor: Color(hex: "002B36"),
        textColor: Color(hex: "839496"),
        cursorColor: Color(hex: "839496"),
        selectionColor: Color(hex: "073642"),
        lineNumberColor: Color(hex: "586E75"),
        lineNumberBackground: Color(hex: "002B36"),
        keywordColor: Color(hex: "859900"),
        stringColor: Color(hex: "2AA198"),
        commentColor: Color(hex: "586E75"),
        headingColor: Color(hex: "268BD2"),
        linkColor: Color(hex: "CB4B16"),
        codeColor: Color(hex: "B58900"),
        blockquoteColor: Color(hex: "B58900"),
        listColor: Color(hex: "CB4B16"),
        horizontalRuleColor: Color(hex: "073642"),
        fontName: "Menlo",
        fontSize: 14
    )

    static let oneDark = EditorTheme(
        id: "onedark",
        name: "One Dark",
        isDark: true,
        backgroundColor: Color(hex: "282C34"),
        textColor: Color(hex: "ABB2BF"),
        cursorColor: Color(hex: "528BFF"),
        selectionColor: Color(hex: "3E4451"),
        lineNumberColor: Color(hex: "4B5263"),
        lineNumberBackground: Color(hex: "282C34"),
        keywordColor: Color(hex: "C678DD"),
        stringColor: Color(hex: "98C379"),
        commentColor: Color(hex: "5C6370"),
        headingColor: Color(hex: "E06C75"),
        linkColor: Color(hex: "61AFEF"),
        codeColor: Color(hex: "D19A66"),
        blockquoteColor: Color(hex: "C678DD"),
        listColor: Color(hex: "E06C75"),
        horizontalRuleColor: Color(hex: "3E4451"),
        fontName: "JetBrains Mono",
        fontSize: 14
    )

    static let allThemes: [EditorTheme] = [monokai, dracula, github, nord, solarized, oneDark]
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: EditorTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.id, forKey: "editorTheme")
        }
    }

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "darkMode")
        }
    }

    init() {
        let savedThemeId = UserDefaults.standard.string(forKey: "editorTheme") ?? "monokai"
        self.currentTheme = EditorTheme.allThemes.first { $0.id == savedThemeId } ?? .monokai
        self.isDarkMode = UserDefaults.standard.object(forKey: "darkMode") as? Bool ?? true
    }

    func setTheme(_ theme: EditorTheme) {
        currentTheme = theme
        isDarkMode = theme.isDark
    }
}

// MARK: - Theme Picker View

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "paintpalette.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Theme wählen")
                    .font(.headline)
                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Quick Theme Toggle
                    HStack {
                        Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundStyle(themeManager.isDarkMode ? .indigo : .orange)
                            .font(.body)

                        Text("Interface Theme")
                            .font(.subheadline)

                        Spacer()

                        compactToggle(isOn: $themeManager.isDarkMode, icons: ("moon.fill", "sun.max.fill"))
                    }
                    .padding(12)
                    .background(Color(nsColor: NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Theme Grid Label
                    Text("Editor Theme")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    // Theme Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(EditorTheme.allThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme.id == theme.id,
                                onSelect: {
                                    themeManager.setTheme(theme)
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 520, height: 580)
    }

    private func compactToggle(isOn: Binding<Bool>, icons: (dark: String, light: String)) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Image(systemName: isOn.wrappedValue ? icons.dark : icons.light)
                .font(.system(size: 14))
                .foregroundStyle(isOn.wrappedValue ? .indigo : .orange)
                .frame(width: 28, height: 28)
                .background(isOn.wrappedValue ? Color.indigo.opacity(0.15) : Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: EditorTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Preview
                VStack(alignment: .leading, spacing: 4) {
                    // Line numbers
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            ForEach(1...3, id: \.self) { line in
                                Text("\(line)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(theme.lineNumberColor)
                            }
                        }
                        .frame(width: 20)

                        // Code preview
                        VStack(alignment: .leading, spacing: 2) {
                            Text("# Heading")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.headingColor)
                            Text("**bold** and *italic*")
                                .font(.system(size: 9))
                                .foregroundStyle(theme.textColor)
                            Text("`code` and [link](url)")
                                .font(.system(size: 9))
                                .foregroundStyle(theme.codeColor)
                            Text("> quote text")
                                .font(.system(size: 9))
                                .foregroundStyle(theme.blockquoteColor)
                        }
                    }
                }
                .padding(12)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(theme.backgroundColor)

                // Name bar
                HStack {
                    Text(theme.name)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    if theme.isDark {
                        Image(systemName: "moon.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "sun.max.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ThemePickerView(themeManager: ThemeManager())
        .frame(width: 500, height: 600)
}
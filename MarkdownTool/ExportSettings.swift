import SwiftUI
import Combine

/// Export format options
enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown = "Markdown (.md)"
    case html = "HTML (.html)"
    case rtf = "RTF/Word (.rtf)"
    case pdf = "PDF (.pdf)"
    case plainText = "Plain Text (.txt)"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .html: return "html"
        case .rtf: return "rtf"
        case .pdf: return "pdf"
        case .plainText: return "txt"
        }
    }

    var icon: String {
        switch self {
        case .markdown: return "doc.text"
        case .html: return "globe"
        case .rtf: return "doc.richtext"
        case .pdf: return "doc.fill"
        case .plainText: return "doc.plaintext"
        }
    }
}

/// Export settings manager
class ExportSettings: ObservableObject {
    @Published var defaultFormat: ExportFormat = .markdown
    @Published var includeMetadata: Bool = true
    @Published var includeToc: Bool = false
    @Published var htmlStyle: String = "github"
    @Published var pdfPageSize: String = "a4"
    @Published var pdfOrientation: String = "portrait"

    // Available HTML styles
    static let htmlStyles = ["github", "minimal", "elegant", "学术"]

    // Available PDF options
    static let pageSizes = ["a4", "letter", "legal"]
    static let orientations = ["portrait", "landscape"]

    private let defaults = UserDefaults.standard

    init() {
        // Load saved settings
        if let formatRaw = defaults.string(forKey: "exportDefaultFormat"),
           let format = ExportFormat(rawValue: formatRaw) {
            defaultFormat = format
        }
        includeMetadata = defaults.bool(forKey: "exportIncludeMetadata")
        includeToc = defaults.bool(forKey: "exportIncludeToc")
        htmlStyle = defaults.string(forKey: "exportHtmlStyle") ?? "github"
        pdfPageSize = defaults.string(forKey: "exportPdfPageSize") ?? "a4"
        pdfOrientation = defaults.string(forKey: "exportPdfOrientation") ?? "portrait"
    }

    func save() {
        defaults.set(defaultFormat.rawValue, forKey: "exportDefaultFormat")
        defaults.set(includeMetadata, forKey: "exportIncludeMetadata")
        defaults.set(includeToc, forKey: "exportIncludeToc")
        defaults.set(htmlStyle, forKey: "exportHtmlStyle")
        defaults.set(pdfPageSize, forKey: "exportPdfPageSize")
        defaults.set(pdfOrientation, forKey: "exportPdfOrientation")
    }
}

/// Export settings view
struct ExportSettingsView: View {
    @ObservedObject var settings: ExportSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Export-Einstellungen")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Fertig") {
                    settings.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 8)

            Divider()

            // Default Format
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard-Format")
                    .font(.headline)

                Picker("Format", selection: $settings.defaultFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Label(format.rawValue, systemImage: format.icon)
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // HTML Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("HTML-Export")
                    .font(.headline)

                HStack {
                    Text("Stil:")
                        .foregroundStyle(.secondary)
                    Picker("Stil", selection: $settings.htmlStyle) {
                        ForEach(ExportSettings.htmlStyles, id: \.self) { style in
                            Text(style.capitalized).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Metadaten einschließen", isOn: $settings.includeMetadata)
                Toggle("Inhaltsverzeichnis generieren", isOn: $settings.includeToc)
            }

            Divider()

            // PDF Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("PDF-Export")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Seitengröße")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Größe", selection: $settings.pdfPageSize) {
                            ForEach(ExportSettings.pageSizes, id: \.self) { size in
                                Text(size.uppercased()).tag(size)
                            }
                        }
                        .labelsHidden()
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Ausrichtung")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Orientierung", selection: $settings.pdfOrientation) {
                            Text("Hochformat").tag("portrait")
                            Text("Querformat").tag("landscape")
                        }
                        .labelsHidden()
                    }
                }
            }

            Spacer()

            // Reset button
            Button("Auf Standard zurückgesetzt") {
                settings.defaultFormat = .markdown
                settings.includeMetadata = true
                settings.includeToc = false
                settings.htmlStyle = "github"
                settings.pdfPageSize = "a4"
                settings.pdfOrientation = "portrait"
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 500, height: 580)
    }
}

/// Quick export menu
struct ExportMenuView: View {
    let text: String
    let fileName: String
    let exportSettings: ExportSettings
    @Binding var showExportSettings: Bool
    @Binding var showSaveDialog: Bool
    @Binding var showHTMLExportDialog: Bool
    @Binding var showRTFExportDialog: Bool

    var body: some View {
        Menu {
            // Quick exports
            Menu("Schnell-Export") {
                Button(action: { showSaveDialog = true }) {
                    Label("Markdown (.md)", systemImage: "doc.text")
                }

                Button(action: { showHTMLExportDialog = true }) {
                    Label("HTML (.html)", systemImage: "globe")
                }

                Button(action: { showRTFExportDialog = true }) {
                    Label("RTF/Word (.rtf)", systemImage: "doc.richtext")
                }
            }

            Divider()

            // Settings
            Button(action: { showExportSettings = true }) {
                Label("Export-Einstellungen...", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
}
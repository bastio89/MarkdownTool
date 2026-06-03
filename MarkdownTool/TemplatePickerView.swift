import SwiftUI

struct TemplatePickerView: View {
    @Binding var selectedTemplate: String?
    @Environment(\.dismiss) var dismiss

    let templates: [(name: String, icon: String, description: String)] = [
        ("README", "doc.text.magnifyingglass", "Standard README mit Projektbeschreibung"),
        ("Changelog", "list.bullet.clipboard", "Änderungsprotokoll mit Versionen"),
        ("Notizen", "note.text", "Schnelle Notizen mit Todo-Listen"),
        ("Meeting-Protokoll", "person.3.fill", "Protokollvorlage für Besprechungen"),
        ("API-Dokumentation", "terminal", "API-Referenz mit Endpunkten"),
        ("Projekt-Planung", "checklist", "Projektplan mit Meilensteinen")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vorlage wählen")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Wähle eine Vorlage zum Starten")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Schließen") { dismiss() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(templates, id: \.name) { template in
                        TemplateCard(
                            name: template.name,
                            icon: template.icon,
                            description: template.description
                        ) {
                            selectedTemplate = template.name
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 560, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TemplateCard: View {
    let name: String
    let icon: String
    let description: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered
                          ? Color.accentColor.opacity(0.08)
                          : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isHovered
                                    ? Color.accentColor.opacity(0.3)
                                    : Color(NSColor.separatorColor).opacity(0.6),
                                    lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

#Preview {
    TemplatePickerView(selectedTemplate: .constant(nil))
}

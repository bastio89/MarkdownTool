import SwiftUI
import AppKit

// MARK: - Format Actions

enum FormatAction {
    case bold, italic, strikethrough
    case codeInline, codeBlock
    case h1, h2, h3
    case bulletList, numberedList
    case blockquote, link, horizontalRule
}

// MARK: - NSTextView Wrapper

struct MarkdownNSTextView: NSViewRepresentable {
    @Binding var text: String
    var onReady: (NSTextView) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownNSTextView
        init(_ parent: MarkdownNSTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let tv = scrollView.documentView as? NSTextView else { return scrollView }
        tv.delegate = context.coordinator
        tv.isEditable = true
        tv.isSelectable = true
        tv.isRichText = false
        tv.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        tv.textContainerInset = NSSize(width: 12, height: 12)
        tv.allowsUndo = true
        tv.string = text
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = .width
        tv.textContainer?.widthTracksTextView = true
        tv.backgroundColor = .textBackgroundColor
        DispatchQueue.main.async { onReady(tv) }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let tv = scrollView.documentView as? NSTextView else { return }
        if tv.string != text {
            let sel = tv.selectedRange()
            tv.string = text
            let safeLoc = min(sel.location, tv.string.utf16.count)
            tv.setSelectedRange(NSRange(location: safeLoc, length: 0))
        }
    }
}

// MARK: - Toolbar Buttons

private struct FmtLabelButton: View {
    let label: String
    let help: String
    let action: () -> Void
    @State private var hovered = false

    init(_ label: String, help: String, action: @escaping () -> Void) {
        self.label = label
        self.help = help
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .frame(width: 28, height: 26)
                .background(hovered ? Color.secondary.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        })
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovered = $0 }
    }
}

private struct FmtIconButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    @State private var hovered = false

    init(_ icon: String, help: String, action: @escaping () -> Void) {
        self.icon = icon
        self.help = help
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 28, height: 26)
                .background(hovered ? Color.secondary.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        })
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovered = $0 }
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    let onFormat: (FormatAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                FmtLabelButton("H1", help: "Überschrift 1") { onFormat(.h1) }
                FmtLabelButton("H2", help: "Überschrift 2") { onFormat(.h2) }
                FmtLabelButton("H3", help: "Überschrift 3") { onFormat(.h3) }

                Divider().frame(height: 20)

                FmtIconButton("bold", help: "Fett") { onFormat(.bold) }
                FmtIconButton("italic", help: "Kursiv") { onFormat(.italic) }
                FmtIconButton("strikethrough", help: "Durchgestrichen") { onFormat(.strikethrough) }

                Divider().frame(height: 20)

                FmtIconButton("chevron.left.forwardslash.chevron.right", help: "Inline-Code") { onFormat(.codeInline) }
                FmtIconButton("curlybraces", help: "Code-Block") { onFormat(.codeBlock) }

                Divider().frame(height: 20)

                FmtIconButton("list.bullet", help: "Aufzählungsliste") { onFormat(.bulletList) }
                FmtIconButton("list.number", help: "Nummerierte Liste") { onFormat(.numberedList) }
                FmtIconButton("text.quote", help: "Blockzitat") { onFormat(.blockquote) }

                Divider().frame(height: 20)

                FmtIconButton("link", help: "Link einfügen") { onFormat(.link) }
                FmtIconButton("minus", help: "Trennlinie") { onFormat(.horizontalRule) }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Main Editor View

struct MarkdownEditorView: View {
    @Binding var text: String
    @State private var textView: NSTextView?

    var body: some View {
        VStack(spacing: 0) {
            FormattingToolbar(onFormat: applyFormat)
            Divider()
            MarkdownNSTextView(text: $text) { tv in
                textView = tv
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Formatting Logic

    private func applyFormat(_ action: FormatAction) {
        guard let tv = textView else { return }
        let nsStr = tv.string as NSString
        let sel = tv.selectedRange()
        let selected = nsStr.substring(with: sel)

        switch action {
        case .bold:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "**", close: "**", placeholder: "Fetter Text")
        case .italic:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "*", close: "*", placeholder: "Kursiver Text")
        case .strikethrough:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "~~", close: "~~", placeholder: "Text")
        case .codeInline:
            wrapInline(tv: tv, sel: sel, selected: selected, open: "`", close: "`", placeholder: "code")
        case .codeBlock:
            let block = selected.isEmpty ? "```\n\n```" : "```\n\(selected)\n```"
            tv.insertText(block, replacementRange: sel)
            if selected.isEmpty {
                tv.setSelectedRange(NSRange(location: sel.location + 4, length: 0))
            }
        case .h1:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "# ")
        case .h2:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "## ")
        case .h3:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "### ")
        case .bulletList:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "- ")
        case .numberedList:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "1. ")
        case .blockquote:
            applyLinePrefix(tv: tv, nsStr: nsStr, sel: sel, prefix: "> ")
        case .link:
            if selected.isEmpty {
                tv.insertText("[Linktext](https://)", replacementRange: sel)
                tv.setSelectedRange(NSRange(location: sel.location + 1, length: 8))
            } else {
                tv.insertText("[\(selected)](https://)", replacementRange: sel)
                tv.setSelectedRange(NSRange(location: sel.location + selected.count + 3, length: 8))
            }
        case .horizontalRule:
            let needsNewline = sel.location > 0 &&
                nsStr.character(at: sel.location - 1) != "\n".utf16.first!
            tv.insertText(needsNewline ? "\n---\n" : "---\n", replacementRange: sel)
        }

        tv.window?.makeFirstResponder(tv)
    }

    private func wrapInline(tv: NSTextView, sel: NSRange, selected: String,
                             open: String, close: String, placeholder: String) {
        if selected.isEmpty {
            tv.insertText("\(open)\(placeholder)\(close)", replacementRange: sel)
            tv.setSelectedRange(NSRange(location: sel.location + open.count, length: placeholder.count))
        } else {
            tv.insertText("\(open)\(selected)\(close)", replacementRange: sel)
        }
    }

    private func applyLinePrefix(tv: NSTextView, nsStr: NSString, sel: NSRange, prefix: String) {
        let lineRange = nsStr.lineRange(for: sel)
        var lineText = nsStr.substring(with: lineRange)
        let hasTrailingNewline = lineText.hasSuffix("\n")
        if hasTrailingNewline { lineText = String(lineText.dropLast()) }

        let prefixed = lineText.components(separatedBy: "\n").map { line -> String in
            guard !line.isEmpty else { return line }
            return line.hasPrefix(prefix) ? String(line.dropFirst(prefix.count)) : prefix + line
        }.joined(separator: "\n")

        tv.insertText(hasTrailingNewline ? prefixed + "\n" : prefixed, replacementRange: lineRange)
    }
}

#Preview {
    MarkdownEditorView(text: .constant("# Test\n\nEin **fetter** Test."))
}


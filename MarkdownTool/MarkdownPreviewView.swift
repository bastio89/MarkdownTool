import SwiftUI
import AppKit

// MARK: - Markdown → HTML

private func markdownToHTML(_ md: String) -> String {
    var html = ""
    let lines = md.components(separatedBy: "\n")
    var i = 0

    func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    func renderInline(_ s: String) -> String {
        var r = escapeHTML(s)
        // Bold + Italic
        r = r.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)
        r = r.replacingOccurrences(of: #"\*\*(.+?)\*\*"#,     with: "<strong>$1</strong>",        options: .regularExpression)
        r = r.replacingOccurrences(of: #"\*(.+?)\*"#,         with: "<em>$1</em>",                options: .regularExpression)
        r = r.replacingOccurrences(of: #"~~(.+?)~~"#,         with: "<del>$1</del>",              options: .regularExpression)
        r = r.replacingOccurrences(of: #"`(.+?)`"#,           with: "<code>$1</code>",            options: .regularExpression)
        r = r.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>",    options: .regularExpression)
        return r
    }

    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Thematic break
        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            html += "<p style='border-top: 1px solid #c7c7cc; margin: 1em 0; line-height: 0;'>&nbsp;</p>\n"
            i += 1; continue
        }

        // Headings
        if trimmed.hasPrefix("######") { html += "<h6>\(renderInline(String(trimmed.dropFirst(7))))</h6>\n"; i += 1; continue }
        if trimmed.hasPrefix("#####")  { html += "<h5>\(renderInline(String(trimmed.dropFirst(6))))</h5>\n"; i += 1; continue }
        if trimmed.hasPrefix("####")   { html += "<h4>\(renderInline(String(trimmed.dropFirst(5))))</h4>\n"; i += 1; continue }
        if trimmed.hasPrefix("###")    { html += "<h3>\(renderInline(String(trimmed.dropFirst(4))))</h3>\n"; i += 1; continue }
        if trimmed.hasPrefix("##")     { html += "<h2>\(renderInline(String(trimmed.dropFirst(3))))</h2>\n"; i += 1; continue }
        if trimmed.hasPrefix("#")      { html += "<h1>\(renderInline(String(trimmed.dropFirst(2))))</h1>\n"; i += 1; continue }

        // Blockquote
        if trimmed.hasPrefix("> ") {
            html += "<blockquote><p>\(renderInline(String(trimmed.dropFirst(2))))</p></blockquote>\n"
            i += 1; continue
        }

        // Code block
        if trimmed.hasPrefix("```") {
            let lang = String(trimmed.dropFirst(3))
            var code = ""
            i += 1
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                code += escapeHTML(lines[i]) + "\n"
                i += 1
            }
            let cls = lang.isEmpty ? "" : " class=\"language-\(lang)\""
            html += "<pre><code\(cls)>\(code)</code></pre>\n"
            i += 1; continue
        }

        // Unordered list
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.hasPrefix("- ") || l.hasPrefix("* ") else { break }
                let text = String(l.dropFirst(2))
                if text.hasPrefix("[ ] ") {
                    html += "<p style='margin:0.15em 0 0.15em 1.4em; text-indent:-1.4em;'>&#9744;&nbsp;&nbsp;\(renderInline(String(text.dropFirst(4))))</p>\n"
                } else if text.hasPrefix("[x] ") || text.hasPrefix("[X] ") {
                    html += "<p style='margin:0.15em 0 0.15em 1.4em; text-indent:-1.4em;'>&#9745;&nbsp;&nbsp;\(renderInline(String(text.dropFirst(4))))</p>\n"
                } else {
                    html += "<p style='margin:0.15em 0 0.15em 1.4em; text-indent:-1.4em;'>&#8226;&nbsp;&nbsp;\(renderInline(text))</p>\n"
                }
                i += 1
            }
            continue
        }

        // Ordered list
        if trimmed.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
            var counter = 1
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.range(of: #"^\d+\. "#, options: .regularExpression) != nil else { break }
                let text = l.replacingOccurrences(of: #"^\d+\. "#, with: "", options: .regularExpression)
                html += "<p style='margin:0.15em 0 0.15em 1.8em; text-indent:-1.8em;'>\(counter).&nbsp;&nbsp;\(renderInline(text))</p>\n"
                counter += 1
                i += 1
            }
            continue
        }

        // Empty line
        if trimmed.isEmpty { html += "<br>\n"; i += 1; continue }

        // Paragraph
        html += "<p>\(renderInline(trimmed))</p>\n"
        i += 1
    }
    return html
}

// MARK: - NSTextView HTML Renderer

struct MarkdownHTMLView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let tv = scrollView.documentView as? NSTextView else { return scrollView }
        tv.isEditable = false
        tv.isSelectable = true
        tv.textContainerInset = NSSize(width: 20, height: 20)
        tv.backgroundColor = .textBackgroundColor
        tv.drawsBackground = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        let styledHTML = """
        <html><head><meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                 font-size: 14px; line-height: 1.7; color: #1c1c1e; margin: 0; }
          h1 { font-size: 1.75em; font-weight: 700; margin: 0.8em 0 0.3em;
               padding-bottom: 0.2em; border-bottom: 1px solid #e5e5ea; }
          h2 { font-size: 1.35em; font-weight: 600; margin: 0.8em 0 0.3em;
               padding-bottom: 0.2em; border-bottom: 1px solid #e5e5ea; }
          h3 { font-size: 1.15em; font-weight: 600; margin: 0.8em 0 0.2em; }
          h4, h5, h6 { font-size: 1em; font-weight: 600; margin: 0.6em 0 0.2em; }
          p  { margin: 0.4em 0; }
          code { font-family: "SF Mono", Menlo, monospace; font-size: 0.88em;
                 background: #f2f2f7; padding: 2px 5px; border-radius: 4px; }
          pre  { background: #f2f2f7; padding: 12px 16px; border-radius: 8px;
                 margin: 0.8em 0; overflow-x: auto; }
          pre code { background: none; padding: 0; font-size: 0.85em; }
          blockquote { border-left: 4px solid #c7c7cc; margin: 0.5em 0;
                       padding: 4px 12px; color: #636366; }
          ul, ol { padding-left: 1.5em; margin: 0.4em 0; }
          li { margin: 0.2em 0; }
          hr { border: none; border-top: 1px solid #e5e5ea; margin: 1em 0; }
          a  { color: #007aff; }
          del { color: #8e8e93; }
          strong { font-weight: 600; }
        </style></head>
        <body>\(html)</body></html>
        """
        if let data = styledHTML.data(using: .utf8),
           let attrStr = NSAttributedString(
               html: data,
               options: [
                   .documentType: NSAttributedString.DocumentType.html,
                   .characterEncoding: String.Encoding.utf8.rawValue
               ],
               documentAttributes: nil
           ) {
            tv.textStorage?.setAttributedString(attrStr)
        }
    }
}

// MARK: - Preview View

struct MarkdownPreviewView: View {
    let markdownText: String

    var body: some View {
        MarkdownHTMLView(html: markdownToHTML(markdownText))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

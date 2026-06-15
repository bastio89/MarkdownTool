import AppKit

/// Hilfsfunktionen für Export

/// Konvertiert Markdown zu HTML mit vollständigem Styling
func markdownToStyledHTML(_ md: String, fontSize: CGFloat = 14) -> String {
    let previewHTML = generatePreviewHTML(md, fontSize: fontSize)
    return """
    <!DOCTYPE html>
    <html><head><meta charset="utf-8">
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif;
             font-size: \(Int(fontSize))px; line-height: 1.7; color: #1c1c1e; margin: 40px; max-width: 800px; }
      h1 { font-size: 1.75em; font-weight: 700; margin: 1em 0 0.3em;
           padding-bottom: 0.2em; border-bottom: 1px solid #e5e5ea; }
      h2 { font-size: 1.35em; font-weight: 600; margin: 1em 0 0.3em;
           padding-bottom: 0.2em; border-bottom: 1px solid #e5e5ea; }
      h3 { font-size: 1.15em; font-weight: 600; margin: 1em 0 0.2em; }
      h4, h5, h6 { font-size: 1em; font-weight: 600; margin: 0.8em 0 0.2em; }
      p  { margin: 0.5em 0; }
      code { font-family: "SF Mono", Menlo, monospace; font-size: 0.88em;
             background: #f2f2f7; padding: 2px 5px; border-radius: 4px; }
      pre  { background: #f2f2f7; padding: 12px 16px; border-radius: 8px;
             margin: 1em 0; overflow-x: auto; }
      pre code { background: none; padding: 0; font-size: 0.85em; }
      blockquote { border-left: 4px solid #c7c7cc; margin: 0.5em 0;
                   padding: 4px 12px; color: #636366; }
      ul, ol { padding-left: 1.5em; margin: 0.5em 0; }
      li { margin: 0.2em 0; }
      hr { border: none; border-top: 1px solid #e5e5ea; margin: 1.5em 0; }
      a  { color: #007aff; }
      del { color: #8e8e93; }
      strong { font-weight: 600; }
      table { border-collapse: collapse; width: 100%; margin: 1em 0; }
      th, td { border-bottom: 1px solid #e5e5ea; padding: 8px 12px; text-align: left; }
      th { border-bottom: 2px solid #e5e5ea; font-weight: 600; }
      tr:last-child td { border-bottom: none; }
    </style></head>
    <body>\(previewHTML)</body></html>
    """
}

/// Generiert Preview-HTML
private func generatePreviewHTML(_ md: String, fontSize: CGFloat) -> String {
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

        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            html += "<hr/>\n"
            i += 1; continue
        }

        if trimmed.hasPrefix("######") { html += "<h6>\(renderInline(String(trimmed.dropFirst(7))))</h6>\n"; i += 1; continue }
        if trimmed.hasPrefix("#####")  { html += "<h5>\(renderInline(String(trimmed.dropFirst(6))))</h5>\n"; i += 1; continue }
        if trimmed.hasPrefix("####")   { html += "<h4>\(renderInline(String(trimmed.dropFirst(5))))</h4>\n"; i += 1; continue }
        if trimmed.hasPrefix("###")    { html += "<h3>\(renderInline(String(trimmed.dropFirst(4))))</h3>\n"; i += 1; continue }
        if trimmed.hasPrefix("##")     { html += "<h2>\(renderInline(String(trimmed.dropFirst(3))))</h2>\n"; i += 1; continue }
        if trimmed.hasPrefix("#")      { html += "<h1>\(renderInline(String(trimmed.dropFirst(2))))</h1>\n"; i += 1; continue }

        if trimmed.hasPrefix("> ") {
            html += "<blockquote><p>\(renderInline(String(trimmed.dropFirst(2))))</p></blockquote>\n"
            i += 1; continue
        }

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

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            html += "<ul>\n"
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.hasPrefix("- ") || l.hasPrefix("* ") else { break }
                let text = String(l.dropFirst(2))
                if text.hasPrefix("[ ] ") {
                    html += "<li style='list-style-type:none;'>☐ \(renderInline(String(text.dropFirst(4))))</li>\n"
                } else if text.hasPrefix("[x] ") || text.hasPrefix("[X] ") {
                    html += "<li style='list-style-type:none;'>☑ \(renderInline(String(text.dropFirst(4))))</li>\n"
                } else {
                    html += "<li>\(renderInline(text))</li>\n"
                }
                i += 1
            }
            html += "</ul>\n"
            continue
        }

        if trimmed.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
            html += "<ol>\n"
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.range(of: #"^\d+\. "#, options: .regularExpression) != nil else { break }
                let text = l.replacingOccurrences(of: #"^\d+\. "#, with: "", options: .regularExpression)
                html += "<li>\(renderInline(text))</li>\n"
                i += 1
            }
            html += "</ol>\n"
            continue
        }

        if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
            var tableRows: [String] = []
            var isHeader = true
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.hasPrefix("|") && l.hasSuffix("|") else { break }
                if l.contains("---") || l.contains(":---") || l.contains("---:") || l.contains(":---:") {
                    isHeader = false
                    i += 1
                    continue
                }
                tableRows.append(l)
                i += 1
            }
            if tableRows.count >= 1 {
                html += "<table>\n"
                for (index, row) in tableRows.enumerated() {
                    let cells = row.split(separator: "|").map { String($0) }.filter { !$0.isEmpty }
                    let tag = (isHeader && index == 0) ? "th" : "td"
                    html += "  <tr>\n"
                    for cell in cells {
                        html += "    <\(tag)>\(renderInline(cell.trimmingCharacters(in: .whitespaces)))</\(tag)>\n"
                    }
                    html += "  </tr>\n"
                }
                html += "</table>\n"
                continue
            }
        }

        if trimmed.isEmpty { html += "<br>\n"; i += 1; continue }

        html += "<p>\(renderInline(trimmed))</p>\n"
        i += 1
    }
    return html
}

/// Alias für generateStyledHTML
func generateStyledHTML(_ md: String, fontSize: CGFloat = 14) throws -> String {
    return markdownToStyledHTML(md, fontSize: fontSize)
}

/// Konvertiert Markdown zu RTF für Word-Export
func markdownToRTF(_ md: String) -> Data {
    let html = markdownToStyledHTML(md, fontSize: 12)

    guard let htmlData = html.data(using: .utf8),
          let attrStr = try? NSAttributedString(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
          ) else {
        // Fallback: einfacher Text
        return Data(md.utf8)
    }

    let rtfData = try? attrStr.data(
        from: NSRange(location: 0, length: attrStr.length),
        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )

    return rtfData ?? Data(md.utf8)
}
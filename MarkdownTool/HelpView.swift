import SwiftUI
import WebKit

struct HelpView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("MarkdownTool Hilfe")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: NSColor.controlBackgroundColor))

            Divider()

            // Help Content
            HelpWebView()
        }
        .frame(width: 800, height: 600)
    }
}

struct HelpWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        // Load help HTML from bundle
        if let helpURL = Bundle.main.url(forResource: "Help", withExtension: "html", subdirectory: "Help") {
            webView.loadFileURL(helpURL, allowingReadAccessTo: helpURL.deletingLastPathComponent())
        } else if let helpURL = Bundle.main.url(forResource: "Help", withExtension: "html") {
            webView.loadFileURL(helpURL, allowingReadAccessTo: helpURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

#Preview {
    HelpView(isPresented: .constant(true))
}
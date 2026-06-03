import SwiftUI
import Combine

class EditorModel: ObservableObject {
    @Published var text: String = ""
    @Published var currentFileName: String = "Unbenannt"
    
    private let defaults = UserDefaults.standard
    
    init() {
        // Lade letzten Text aus UserDefaults
        if let saved = defaults.string(forKey: "lastMarkdownText") {
            text = saved
        } else {
            text = defaultWelcomeText()
        }
    }
    
    // Speichere Text automatisch
    func saveState() {
        defaults.set(text, forKey: "lastMarkdownText")
    }
    
    func loadTemplate(_ templateName: String) {
        let template = Templates.get(templateName)
        text = template
        currentFileName = templateName
        saveState()
    }
    
    func loadFileContent(_ content: String, fileName: String) {
        text = content
        currentFileName = fileName
        saveState()
    }
    
    func newDocument() {
        text = ""
        currentFileName = "Unbenannt"
        saveState()
    }
    
    private func defaultWelcomeText() -> String {
        return """
        # Willkommen bei Markdown Tool ✍️
        
        Dein **nativer macOS-Markdown-Editor** für schnelle Notizen, README-Dateien und Dokumentation.
        
        ## Schnellstart
        
        - 📁 **Ordner öffnen** – Lade deine Markdown-Dateien
        - 📝 **Vorlage laden** – Wähle eine Vorlage für README, Changelog, Notizen etc.
        - 💾 **Speichern** – Exportiere als `.md`-Datei
        - 📄 **PDF-Export** – Erstelle direkt ein PDF
        
        ## Markdown-Beispiel
        
        ```swift
        struct Hello: View {
            var body: some View {
                Text("Hallo Welt!")
            }
        }
        ```
        
        > Dies ist ein Zitat – perfekt für wichtige Hinweise!
        
        ---
        
        | Feature | Status |
        |---------|--------|
        | Editor | ✅ |
        | Vorschau | ✅ |
        | Templates | ✅ |
        
        ---
        *Schreibe jetzt deine erste Markdown-Datei!*
        """
    }
}

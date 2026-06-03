# MarkdownTool

Ein nativer macOS-Markdown-Editor — schlank, schnell und ohne Ablenkung.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Features

- **Live-Vorschau** — Markdown wird in Echtzeit als formatierter Text gerendert
- **Formatierungs-Toolbar** — H1–H3, Fett, Kursiv, Durchgestrichen, Code, Code-Block, Listen, Blockquote, Link, Trennlinie
- **Datei-Browser** — Ordner öffnen und alle `.md`-Dateien in der Sidebar anzeigen
- **Zuletzt geöffnet** — Schnellzugriff auf die letzten 10 Dateien
- **Vorlagen** — README, Changelog, Meeting-Notizen, Blog-Post und mehr
- **Speichern** — Export als `.md`-Datei mit macOS-Speicherdialog
- **Ordner-Bookmark** — gewählter Ordner wird über App-Neustarts hinweg gespeichert
- **Keyboard Shortcuts** — alle gängigen macOS-Shortcuts (⌘N, ⌘S, ⌘O …)

## Keyboard Shortcuts

| Shortcut | Aktion |
|----------|--------|
| ⌘N | Neues Dokument |
| ⌘⇧N | Vorlage auswählen |
| ⌘O | Ordner öffnen |
| ⌘S | Speichern / Exportieren |
| ⌘R | Dateiliste aktualisieren |

## Anforderungen

- macOS 13 Ventura oder neuer
- Xcode 15 oder neuer

## Installation

```bash
git clone https://github.com/bastio89/MarkdownTool.git
cd MarkdownTool
open MarkdownTool.xcodeproj
```

In Xcode:
1. Team in den Signing-Einstellungen auswählen
2. **⌘R** — bauen und starten

## Projektstruktur

```
MarkdownTool/
├── ContentView.swift          # Root-View mit NavigationSplitView
├── EditorModel.swift          # ObservableObject für Editor-Zustand
├── FileBrowserView.swift      # Sidebar: Ordner, Dateien, Zuletzt geöffnet
├── FileManager.swift          # Dateioperationen, Ordner-Watching, Bookmarks
├── MarkdownEditorView.swift   # NSTextView-Editor mit Formatierungs-Toolbar
├── MarkdownPreviewView.swift  # Live-Vorschau via NSAttributedString (HTML)
├── MarkdownToolApp.swift      # App Entry Point
├── TemplatePickerView.swift   # Vorlagen-Sheet
├── Templates.swift            # Vordefinierte Markdown-Vorlagen
└── ToolbarView.swift          # In-Content-Toolbar (Dateiname, Aktualisieren)
```

## Lizenz

MIT License — siehe [LICENSE](LICENSE)

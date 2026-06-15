# MarkdownTool

Ein nativer macOS-Markdown-Editor — schlank, schnell und ohne Ablenkung.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Features

- **Live-Vorschau** — Markdown wird in Echtzeit als formatierter Text gerendert (debounced für Performance)
- **Syntax-Highlighting** — Farbige Markdown-Hervorhebung im Editor (Überschriften, Code, Links, Listen, etc.)
- **Formatierungs-Toolbar** — H1–H3, Fett, Kursiv, Durchgestrichen, Code, Code-Block, Listen, Blockquote, Link, Tabelle, Trennlinie
- **Datei-Browser** — Ordner öffnen und alle `.md`-Dateien in der Sidebar anzeigen
- **Zuletzt geöffnet** — Schnellzugriff auf die letzten 10 Dateien
- **Vorlagen** — README, Changelog, Meeting-Notizen, Blog-Post und mehr
- **Speichern** — Export als `.md`-Datei mit macOS-Speicherdialog
- **Ordner-Bookmark** — gewählter Ordner wird über App-Neustarts hinweg gespeichert
- **Keyboard Shortcuts** — alle gängigen macOS-Shortcuts (⌘N, ⌘S, ⌘O …)
- **Auto-Save** — Text wird automatisch nach 2 Sekunden Inaktivität gespeichert
- **Schriftgröße anpassen** — Editor- und Preview-Schriftgröße individuell einstellbar (⌘+/⌘-)
- **Suchfunktion** — Text im Editor suchen mit Highlighting (⌘F)
- **Statusleiste** — Zeigt Wort-/Zeichenanzahl und Speicherstatus
- **Tabellen-Support** — Markdown-Tabellen werden in der Vorschau korrekt gerendert

## Keyboard Shortcuts

| Shortcut | Aktion |
|----------|--------|
| ⌘N | Neues Dokument |
| ⌘⇧N | Vorlage auswählen |
| ⌘O | Ordner öffnen |
| ⌘S | Speichern / Exportieren |
| ⌘R | Dateiliste aktualisieren |
| ⌘F | Suchen |
| ⌘+ | Schriftgröße vergrößern |
| ⌘- | Schriftgröße verkleinern |
| ⌘⇧H | Syntax-Highlighting umschalten |

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
├── EditorModel.swift          # ObservableObject für Editor-Zustand (Auto-Save, Word-Count)
├── FileBrowserView.swift      # Sidebar: Ordner, Dateien, Zuletzt geöffnet
├── FileManager.swift          # Dateioperationen, Ordner-Watching, Bookmarks
├── MarkdownEditorView.swift  # NSTextView-Editor mit Formatierungs-Toolbar, Suche, Syntax-Highlighting
├── MarkdownPreviewView.swift # Live-Vorschau via NSAttributedString (HTML, debounced, Tabellen)
├── MarkdownToolApp.swift      # App Entry Point
├── TemplatePickerView.swift   # Vorlagen-Sheet
├── Templates.swift            # Vordefinierte Markdown-Vorlagen
├── ToolbarView.swift          # In-Content-Toolbar + Statusleiste
└── SearchBarView.swift        # Suchleiste mit Highlighting
```

## Lizenz

MIT License — siehe [LICENSE](LICENSE)
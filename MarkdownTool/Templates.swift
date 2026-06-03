import SwiftUI

struct Templates {
    static func get(_ name: String) -> String {
        switch name {
        case "README":
            return readmeTemplate
        case "Changelog":
            return changelogTemplate
        case "Notizen":
            return notesTemplate
        case "Meeting-Protokoll":
            return meetingTemplate
        case "API-Dokumentation":
            return apiTemplate
        case "Projekt-Planung":
            return projectPlanTemplate
        default:
            return "# Neue Datei\n"
        }
    }
    
    // MARK: - README
    
    private static let readmeTemplate = """
    # Projektname
    
    Kurze Beschreibung deines Projekts in 1-2 Sätzen.
    
    ## Installation
    
    ```bash
    # Befehl zum Installieren
    npm install projektname
    ```
    
    ## Verwendung
    
    ```swift
    import Projektname
    
    let example = Example()
    example.run()
    ```
    
    ## Features
    
    - ✅ Feature 1
    - ✅ Feature 2
    - 🚧 Feature 3 (in Arbeit)
    
    ## Lizenz
    
    [MIT](LICENSE)
    """
    
    // MARK: - Changelog
    
    private static let changelogTemplate = """
    # Changelog
    
    Alle bedeutenden Änderungen an diesem Projekt werden hier dokumentiert.
    
    Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/).
    
    ## [Unreleased]
    
    ### Added
    - Neue Feature
    
    ### Changed
    - Änderung an bestehendem Feature
    
    ### Fixed
    - Bugfix
    
    ## [1.0.0] - 2026-06-02
    
    ### Added
    - Initial Release
    - Grundlegende Features
    
    [Unreleased]: https://github.com/user/repo/compare/v1.0.0...HEAD
    [1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
    """
    
    // MARK: - Notizen
    
    private static let notesTemplate = """
    # Notizen
    
    > Erstellt am: \(Date().formatted(date: .complete, time: .omitted))
    
    ## Ideen
    
    - [ ] Idee 1
    - [ ] Idee 2
    - [x] Bereits erledigt
    
    ## Wichtige Punkte
    
    1. Erster Punkt
    2. Zweiter Punkt
    3. Dritter Punkt
    
    ## Links
    
    - [Google](https://google.com)
    - [GitHub](https://github.com)
    
    ---
    *Letzte Änderung: \(Date().formatted(date: .complete, time: .complete))*
    """
    
    // MARK: - Meeting-Protokoll
    
    private static let meetingTemplate = """
    # Meeting-Protokoll
    
    | Detail | Info |
    |--------|------|
    | Datum | \(Date().formatted(date: .complete, time: .omitted)) |
    | Teilnehmer | Name 1, Name 2, Name 3 |
    | Ort | Raum / Video-Call |
    
    ## Agenda
    
    1. Thema 1
    2. Thema 2
    3. Thema 3
    
    ## Beschlüsse
    
    - [ ] Entscheidung 1 – Verantwortlich: Name, Frist: Datum
    - [ ] Entscheidung 2 – Verantwortlich: Name, Frist: Datum
    
    ## Diskussion
    
    ### Thema 1
    
    Hier die Notizen zum ersten Thema.
    
    ### Thema 2
    
    Hier die Notizen zum zweiten Thema.
    
    ## Nächste Schritte
    
    - [ ] Action Item 1
    - [ ] Action Item 2
    
    ---
    *Nächstes Meeting: [Datum einfügen]*
    """
    
    // MARK: - API-Dokumentation
    
    private static let apiTemplate = """
    # API-Dokumentation
    
    Basis-URL: `https://api.example.com/v1`
    
    ## Authentifizierung
    
    Alle Anfragen benötigen einen API-Key im Header:
    
    ```
    Authorization: Bearer YOUR_API_KEY
    ```
    
    ## Endpunkte
    
    ### GET /users
    
    Alle Benutzer abrufen.
    
    **Parameter:**
    
    | Name | Typ | Beschreibung |
    |------|-----|-------------|
    | page | Integer | Seitennummer (Standard: 1) |
    | limit | Integer | Ergebnisse pro Seite (Standard: 20) |
    
    **Antwort:**
    
    ```json
    {
      "data": [
        {
          "id": 1,
          "name": "Max Mustermann",
          "email": "max@example.com"
        }
      ],
      "total": 100
    }
    ```
    
    ### POST /users
    
    Neuen Benutzer erstellen.
    
    **Body:**
    
    ```json
    {
      "name": "Max Mustermann",
      "email": "max@example.com"
    }
    ```
    
    ## Fehlercodes
    
    | Code | Beschreibung |
    |------|-------------|
    | 400 | Ungültige Anfrage |
    | 401 | Nicht autorisiert |
    | 404 | Nicht gefunden |
    | 500 | Serverfehler |
    """
    
    // MARK: - Projekt-Planung
    
    private static let projectPlanTemplate = """
    # Projektplanung: Projektname
    
    > Status: 🟡 In Planung
    > Start: \(Date().formatted(date: .complete, time: .omitted))
    > Ziel: [Zieldatum einfügen]
    
    ## Ziel
    
    Was soll mit diesem Projekt erreicht werden?
    
    ## Meilensteine
    
    | # | Meilenstein | Status | Frist |
    |---|-----------|--------|-------|
    | 1 | Planung | ✅ Erledigt | WW/MMJJ |
    | 2 | Entwicklung | 🟡 In Arbeit | WW/MMJJ |
    | 3 | Testing | ⏳ Offen | WW/MMJJ |
    | 4 | Release | ⏳ Offen | WW/MMJJ |
    
    ## Aufgaben
    
    ### Phase 1: Planung
    
    - [x] Anforderungen sammeln
    - [x] Architektur entwerfen
    - [ ] Team-Briefing
    
    ### Phase 2: Entwicklung
    
    - [ ] Core-Features implementieren
    - [ ] UI/UX gestalten
    - [ ] Tests schreiben
    
    ## Ressourcen
    
    - [Design](link)
    - [Dokumentation](link)
    - [Repository](link)
    
    ## Risiken
    
    | Risiko | Wahrscheinlichkeit | Auswirkung | Gegenmaßnahme |
    |--------|-------------------|-----------|--------------|
    | Zeitmangel | Mittel | Hoch | Puffer einplanen |
    | Ressourcen | Niedrig | Mittel | Backup-Plan |
    """
}

import SwiftUI
import Combine

// MARK: - Document Statistics Model

struct DocumentStatistics {
    var characters: Int = 0
    var charactersNoSpaces: Int = 0
    var words: Int = 0
    var lines: Int = 0
    var paragraphs: Int = 0
    var sentences: Int = 0
    var readingTime: Int = 0 // minutes
    var speakingTime: Int = 0 // minutes

    // Readability scores
    var fleschReadingEase: Double = 0
    var fleschKincaidGrade: Double = 0

    static func analyze(_ text: String) -> DocumentStatistics {
        var stats = DocumentStatistics()

        let characters = text.count
        let charactersNoSpaces = text.filter { !$0.isWhitespace }.count
        let words = text.split { $0.isWhitespace || $0.isNewline }.count

        let lines = text.split { $0.isNewline }.count
        let paragraphs = text.split(whereSeparator: { $0.isNewline && $0.isNewline }).count
        let sentences = text.split(whereSeparator: { ".!?".contains($0) }).count

        // Reading time: avg 200-250 words/min
        let readingTime = max(1, Int(words / 200))
        let speakingTime = max(1, Int(words / 130)) // avg speaking rate

        // Flesch Reading Ease: 206.835 - 1.015(words/sentences) - 84.6(syllables/words)
        let avgWordsPerSentence = sentences > 0 ? Double(words) / Double(sentences) : 0
        let avgSyllablesPerWord = words > 0 ? Double(countSyllables(text)) / Double(words) : 0

        let fleschReadingEase = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord)
        let fleschKincaidGrade = (0.39 * avgWordsPerSentence) + (11.8 * avgSyllablesPerWord) - 15.59

        return DocumentStatistics(
            characters: characters,
            charactersNoSpaces: charactersNoSpaces,
            words: Int(words),
            lines: lines,
            paragraphs: max(1, paragraphs),
            sentences: max(1, Int(sentences)),
            readingTime: readingTime,
            speakingTime: speakingTime,
            fleschReadingEase: max(0, min(100, fleschReadingEase)),
            fleschKincaidGrade: max(0, fleschKincaidGrade)
        )
    }

    private static func countSyllables(_ text: String) -> Int {
        let wordRegex = try? NSRegularExpression(pattern: "[a-zA-Z]+", options: [])
        let range = NSRange(text.startIndex..., in: text)
        let matches = wordRegex?.matches(in: text, options: [], range: range) ?? []

        var totalSyllables = 0
        for match in matches {
            if let range = Range(match.range, in: text) {
                let word = String(text[range]).lowercased()
                totalSyllables += countSyllablesInWord(word)
            }
        }
        return totalSyllables
    }

    private static func countSyllablesInWord(_ word: String) -> Int {
        var count = 0
        var vowels: [Character] = ["a", "e", "i", "o", "u", "y"]
        var prevWasVowel = false

        for char in word {
            let isVowel = vowels.contains(char)

            if isVowel && !prevWasVowel {
                count += 1
            }

            // Handle silent 'e' at end
            if char == "e" && word.hasSuffix("e") && word.count > 2 {
                count -= 1
            }

            prevWasVowel = isVowel
        }

        return max(1, count)
    }
}

// MARK: - Readability Description

extension DocumentStatistics {
    var readabilityDescription: String {
        let score = fleschReadingEase
        switch score {
        case 90...100: return "Sehr einfach"
        case 80..<90: return "Einfach"
        case 60..<80: return "Mittelschwer"
        case 30..<60: return "Schwer"
        default: return "Sehr schwer"
        }
    }

    var readabilityColor: Color {
        let score = fleschReadingEase
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 30..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    let text: String
    @State private var stats: DocumentStatistics

    init(text: String) {
        self.text = text
        _stats = State(initialValue: DocumentStatistics.analyze(text))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Dokument-Statistiken")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Basic Stats Grid
                    basicStatsGrid

                    Divider()

                    // Time Estimates
                    timeEstimates

                    Divider()

                    // Readability Score
                    readabilitySection
                }
                .padding()
            }
        }
        .frame(width: 400, height: 450)
        .onChange(of: text) { _, newText in
            stats = DocumentStatistics.analyze(newText)
        }
    }

    // MARK: - Basic Stats Grid

    private var basicStatsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basis-Statistiken")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(value: "\(stats.words)", label: "Wörter", icon: "text.word.spacing")
                StatCard(value: "\(stats.characters)", label: "Zeichen", icon: "character.cursor.ibeam")
                StatCard(value: "\(stats.lines)", label: "Zeilen", icon: "text.alignleft")
                StatCard(value: "\(stats.sentences)", label: "Sätze", icon: "text.bubble")
                StatCard(value: "\(stats.paragraphs)", label: "Absätze", icon: "text.justify")
                StatCard(value: "\(stats.charactersNoSpaces)", label: "Ohne Leerz.", icon: "textformat")
            }
        }
        .padding(12)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Time Estimates

    private var timeEstimates: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lesezeit")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .foregroundStyle(.blue)
                        Text("\(stats.readingTime) min")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Lesen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mic")
                            .foregroundStyle(.green)
                        Text("\(stats.speakingTime) min")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Vorlesen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Readability Section

    private var readabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lesbarkeit")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flesch-Reading-Ease")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text(String(format: "%.1f", stats.fleschReadingEase))
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(stats.readabilityDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(stats.readabilityColor.opacity(0.2))
                            .foregroundStyle(stats.readabilityColor)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: stats.fleschReadingEase / 100)
                        .stroke(stats.readabilityColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.0f", stats.fleschReadingEase))
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 50, height: 50)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flesch-Kincaid Grade")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "Stufe %.1f", max(0, stats.fleschKincaidGrade)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Text("Schuljahr")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Compact Statistics Bar

struct StatisticsBar: View {
    let text: String

    var body: some View {
        let stats = DocumentStatistics.analyze(text)

        HStack(spacing: 16) {
            StatItem(value: "\(stats.words)", label: "Wörter")
            StatItem(value: "\(stats.characters)", label: "Zeichen")
            StatItem(value: "\(stats.lines)", label: "Zeilen")
            StatItem(value: "\(stats.readingTime) min", label: "Lesezeit")

            Spacer()

            Button(action: {}) {
                Image(systemName: "chart.bar")
                    .font(.caption)
            }
            .popover(isPresented: .constant(false)) {
                StatisticsView(text: text)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .fontWeight(.medium)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}
import SwiftUI
import AppKit
import Combine

// MARK: - Vim Mode

enum VimMode: String, CaseIterable {
    case normal = "NORMAL"
    case insert = "INSERT"
    case visual = "VISUAL"
    case visualLine = "VISUAL LINE"
}

// MARK: - Vim State

class VimState: ObservableObject {
    @Published var currentMode: VimMode = .normal
    @Published var commandBuffer: String = ""
    @Published var isRecording: Bool = false
    @Published var recordingRegister: String = "a"
    @Published var showModeIndicator: Bool = true

    // Counts for commands like 3w, 2dd
    @Published var pendingCount: String = ""

    func resetCommandBuffer() {
        commandBuffer = ""
        pendingCount = ""
    }

    func enterMode(_ mode: VimMode) {
        currentMode = mode
        resetCommandBuffer()
    }
}

// MARK: - Vim Commands

enum VimCommand {
    // Movement
    case moveLeft, moveRight, moveUp, moveDown
    case moveWordForward, moveWordBackward
    case moveToLineStart, moveToLineEnd
    case moveToFileStart, moveToFileEnd
    case moveToLine(Int)

    // Actions
    case deleteChar, deleteWord, deleteLine
    case yank, yankLine, paste
    case undo, redo
    case changeWord, changeLine

    // Mode changes
    case enterInsertMode, enterNormalMode, enterVisualMode, enterVisualLineMode

    // Misc
    case repeatLast, joinLines
    case indent, dedent

    case unknown
}

class VimCommandParser {
    static func parse(_ input: String) -> VimCommand {
        switch input.lowercased() {
        // Movement
        case "h": return .moveLeft
        case "l": return .moveRight
        case "j": return .moveDown
        case "k": return .moveUp
        case "w": return .moveWordForward
        case "b": return .moveWordBackward
        case "e": return .moveWordForward // word end
        case "0", "^": return .moveToLineStart
        case "$": return .moveToLineEnd
        case "gg": return .moveToFileStart
        case "G": return .moveToFileEnd
        case "i": return .enterInsertMode
        case "a": return .enterInsertMode // append after cursor
        case "A": return .enterInsertMode // append at line end
        case "I": return .enterInsertMode // insert at line start
        case "O": return .enterInsertMode // open line above
        case "o": return .enterInsertMode // open line below
        case "v": return .enterVisualMode
        case "V": return .enterVisualLineMode
        case "Esc", "<esc>": return .enterNormalMode
        case "dd": return .deleteLine
        case "dw": return .deleteWord
        case "x": return .deleteChar
        case "yy", "Y": return .yankLine
        case "y": return .yank
        case "p": return .paste
        case "P": return .paste // paste before
        case "u": return .undo
        case "Ctrl+r", "^R": return .redo
        case "cc": return .changeLine
        case "cw": return .changeWord
        case "J": return .joinLines
        case ">>": return .indent
        case "<<": return .dedent
        default: return .unknown
        }
    }

    static func parseCountCommand(_ input: String) -> (count: Int?, command: String) {
        var digits = ""
        var letters = ""

        for char in input {
            if char.isNumber {
                digits.append(char)
            } else {
                letters.append(char)
            }
        }

        let count = digits.isEmpty ? nil : Int(digits)
        return (count, letters)
    }
}

// MARK: - Vim Key Handler

class VimKeyHandler: ObservableObject {
    @Published var state = VimState()
    @Published var pendingKeys: String = ""

    var onCommand: ((VimCommand, Int?) -> Void)?
    var onModeChange: ((VimMode) -> Void)?

    private var keySequence: String = ""

    func handleKey(_ event: NSEvent, textView: NSTextView) -> Bool {
        guard let characters = event.characters else { return false }

        // Handle special keys
        if event.keyCode == 53 { // Escape
            state.enterMode(.normal)
            onModeChange?(.normal)
            return true
        }

        switch state.currentMode {
        case .normal, .visual, .visualLine:
            return handleNormalModeKey(event, characters: characters, textView: textView)
        case .insert:
            return handleInsertModeKey(event, characters: characters, textView: textView)
        }
    }

    private func handleNormalModeKey(_ event: NSEvent, characters: String, textView: NSTextView) -> Bool {
        keySequence += characters

        // Handle count prefix (e.g., 3w, 10j)
        if characters.first?.isNumber == true && keySequence.count <= 3 {
            state.pendingCount += characters
            return true
        }

        // Parse command
        let (count, command) = VimCommandParser.parseCountCommand(keySequence)

        if let cmd = parseCommand(command) {
            handleCommand(cmd, count: count ?? 1, textView: textView)
            keySequence = ""
            state.pendingCount = ""
            return true
        }

        // Reset if invalid sequence
        if keySequence.count > 3 {
            keySequence = ""
            state.pendingCount = ""
        }

        return true
    }

    private func handleInsertModeKey(_ event: NSEvent, characters: String, textView: NSTextView) -> Bool {
        // In insert mode, normal text input is handled by the text view
        // Only Escape key is handled here
        return false
    }

    private func parseCommand(_ command: String) -> VimCommand? {
        switch command.lowercased() {
        // Movement
        case "h": return .moveLeft
        case "l": return .moveRight
        case "j": return .moveDown
        case "k": return .moveUp
        case "w": return .moveWordForward
        case "b": return .moveWordBackward
        case "e": return .moveWordForward
        case "0", "^": return .moveToLineStart
        case "$": return .moveToLineEnd
        case "gg": return .moveToFileStart
        case "G": return .moveToFileEnd
        case "i": return .enterInsertMode
        case "a": return .enterInsertMode
        case "A": return .enterInsertMode
        case "I": return .enterInsertMode
        case "o": return .enterInsertMode
        case "O": return .enterInsertMode
        case "v": return .enterVisualMode
        case "V": return .enterVisualLineMode
        case "dd": return .deleteLine
        case "dw": return .deleteWord
        case "d": return .deleteChar // partial, handled specially
        case "x": return .deleteChar
        case "yy", "y": return .yankLine
        case "p": return .paste
        case "P": return .paste
        case "u": return .undo
        case "cc", "C": return .changeLine
        case "cw", "ce", "c": return .changeWord
        case "J": return .joinLines
        case ">>": return .indent
        case "<<": return .dedent
        default: return nil
        }
    }

    private func handleCommand(_ command: VimCommand, count: Int, textView: NSTextView) {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()

        switch command {
        case .moveLeft:
            let newLoc = max(0, sel.location - count)
            textView.setSelectedRange(NSRange(location: newLoc, length: 0))

        case .moveRight:
            let newLoc = min(nsText.length, sel.location + count)
            textView.setSelectedRange(NSRange(location: newLoc, length: 0))

        case .moveUp:
            moveLines(textView, count: -count)

        case .moveDown:
            moveLines(textView, count: count)

        case .moveWordForward:
            moveWord(textView, forward: true, count: count)

        case .moveWordBackward:
            moveWord(textView, forward: false, count: count)

        case .moveToLineStart:
            let lineRange = nsText.lineRange(for: NSRange(location: sel.location, length: 0))
            textView.setSelectedRange(NSRange(location: lineRange.location, length: 0))

        case .moveToLineEnd:
            let lineRange = nsText.lineRange(for: NSRange(location: sel.location, length: 0))
            textView.setSelectedRange(NSRange(location: lineRange.upperBound - 1, length: 0))

        case .moveToFileStart:
            textView.setSelectedRange(NSRange(location: 0, length: 0))

        case .moveToFileEnd:
            textView.setSelectedRange(NSRange(location: nsText.length, length: 0))

        case .deleteLine:
            deleteLines(textView, count: count)

        case .deleteChar:
            if sel.length > 0 {
                textView.insertText("", replacementRange: sel)
            } else if sel.location < nsText.length {
                let newRange = NSRange(location: sel.location, length: min(count, nsText.length - sel.location))
                textView.insertText("", replacementRange: newRange)
            }

        case .yankLine:
            let lineRange = getLineRange(textView, count: count)
            let text = nsText.substring(with: lineRange)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)

        case .paste:
            if let pasteText = NSPasteboard.general.string(forType: .string) {
                textView.insertText(pasteText, replacementRange: sel)
            }

        case .undo:
            textView.undoManager?.undo()

        case .enterInsertMode:
            state.enterMode(.insert)
            onModeChange?(.insert)
            // For 'a' (append), move cursor after current char
            if textView.string.hasSuffix("a") {
                let newLoc = min(nsText.length, sel.location + 1)
                textView.setSelectedRange(NSRange(location: newLoc, length: 0))
            }
            // For 'A', move to end of line
            // For 'I', move to start of line
            // For 'o', insert newline below
            // For 'O', insert newline above

        case .enterNormalMode:
            state.enterMode(.normal)
            onModeChange?(.normal)

        case .enterVisualMode:
            state.enterMode(.visual)
            onModeChange?(.visual)

        case .enterVisualLineMode:
            state.enterMode(.visualLine)
            onModeChange?(.visualLine)

        case .joinLines:
            joinLines(textView)

        case .indent:
            indentLines(textView, count: count)

        case .dedent:
            dedentLines(textView, count: count)

        default:
            break
        }

        onCommand?(command, count)
    }

    // MARK: - Helper Functions

    private func moveLines(_ textView: NSTextView, count: Int) {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()
        let currentLine = nsText.lineRange(for: sel)

        // Calculate new position
        var newLineStart = currentLine.location
        for _ in 0..<abs(count) {
            if count > 0 {
                newLineStart = nsText.lineRange(for: NSRange(location: newLineStart, length: 0)).upperBound
            } else {
                newLineStart = max(0, getPreviousLineStart(nsText, from: newLineStart))
            }
        }

        textView.setSelectedRange(NSRange(location: newLineStart, length: 0))
    }

    private func moveWord(_ textView: NSTextView, forward: Bool, count: Int) {
        let nsText = textView.string as NSString
        var loc = textView.selectedRange().location

        for _ in 0..<count {
            if forward {
                // Skip current word
                while loc < nsText.length && !CharacterSet.whitespaces.contains(Unicode.Scalar(nsText.character(at: loc))!) {
                    loc += 1
                }
                // Skip whitespace
                while loc < nsText.length && CharacterSet.whitespaces.contains(Unicode.Scalar(nsText.character(at: loc))!) {
                    loc += 1
                }
            } else {
                // Skip backwards
                if loc > 0 { loc -= 1 }
                while loc > 0 && CharacterSet.whitespaces.contains(Unicode.Scalar(nsText.character(at: loc - 1))!) {
                    loc -= 1
                }
                while loc > 0 && !CharacterSet.whitespaces.contains(Unicode.Scalar(nsText.character(at: loc - 1))!) {
                    loc -= 1
                }
            }
        }

        textView.setSelectedRange(NSRange(location: loc, length: 0))
    }

    private func deleteLines(_ textView: NSTextView, count: Int) {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()

        var startLine = nsText.lineRange(for: NSRange(location: sel.location, length: 0)).location

        var deleteRange = NSRange(location: startLine, length: 0)
        for _ in 0..<count {
            let lineRange = nsText.lineRange(for: NSRange(location: startLine, length: 0))
            deleteRange.length += lineRange.length
            startLine = lineRange.location
        }

        textView.insertText("", replacementRange: deleteRange)
        textView.setSelectedRange(NSRange(location: deleteRange.location, length: 0))
    }

    private func getLineRange(_ textView: NSTextView, count: Int) -> NSRange {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()
        var lineRange = nsText.lineRange(for: NSRange(location: sel.location, length: 0))

        for _ in 1..<count {
            let nextLineRange = nsText.lineRange(for: NSRange(location: lineRange.upperBound, length: 0))
            lineRange.length += nextLineRange.length
        }

        return lineRange
    }

    private func getPreviousLineStart(_ nsText: NSString, from loc: Int) -> Int {
        if loc >= nsText.length { return 0 }
        let before = nsText.substring(to: loc)
        if let lastNewline = before.range(of: "\n", options: .backwards) {
            let prevNewline = before[..<lastNewline.lowerBound]
            if let prev = prevNewline.range(of: "\n", options: .backwards) {
                return prevNewline.distance(from: prevNewline.startIndex, to: prev.upperBound)
            }
            return 0
        }
        return 0
    }

    private func joinLines(_ textView: NSTextView) {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()
        let lineRange = nsText.lineRange(for: sel)
        let endOfLine = lineRange.upperBound - 1

        if endOfLine < nsText.length {
            textView.insertText(" ", replacementRange: NSRange(location: endOfLine, length: 1))
        }
    }

    private func indentLines(_ textView: NSTextView, count: Int) {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()
        let lineRange = nsText.lineRange(for: sel)

        var insertLoc = lineRange.location
        for _ in 0..<count {
            textView.insertText("    ", replacementRange: NSRange(location: insertLoc, length: 0))
            insertLoc += 4
        }
    }

    private func dedentLines(_ textView: NSTextView, count: Int) {
        let nsText = textView.string as NSString
        let sel = textView.selectedRange()
        let lineRange = nsText.lineRange(for: sel)
        let lineText = nsText.substring(with: lineRange)

        var dedentCount = count
        var newText = lineText

        for _ in 0..<count {
            if newText.hasPrefix("    ") {
                newText = String(newText.dropFirst(4))
                dedentCount += 1
            } else if newText.hasPrefix("\t") {
                newText = String(newText.dropFirst())
                dedentCount += 1
            } else {
                break
            }
        }

        if dedentCount > 0 {
            textView.insertText(newText, replacementRange: lineRange)
        }
    }
}

// MARK: - Vim Mode Indicator

struct VimModeIndicator: View {
    @ObservedObject var state: VimState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(modeColor)
                .frame(width: 8, height: 8)

            Text(state.currentMode.rawValue)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(modeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(modeColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var modeColor: Color {
        switch state.currentMode {
        case .normal: return .green
        case .insert: return .blue
        case .visual: return .orange
        case .visualLine: return .purple
        }
    }
}
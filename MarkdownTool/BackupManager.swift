import Foundation
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Backup Manager

class BackupManager: ObservableObject {
    @Published var isBackingUp = false
    @Published var lastBackupDate: Date?
    @Published var backupLocation: URL?
    @Published var autoBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoBackupEnabled, forKey: "autoBackupEnabled")
        }
    }
    @Published var backupInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(backupInterval, forKey: "backupInterval")
        }
    }
    @Published var keepBackupVersions: Int {
        didSet {
            UserDefaults.standard.set(keepBackupVersions, forKey: "keepBackupVersions")
        }
    }

    private var autoBackupTimer: Timer?
    private let fileManager = FileManager.default

    init() {
        self.autoBackupEnabled = UserDefaults.standard.object(forKey: "autoBackupEnabled") as? Bool ?? false
        self.backupInterval = UserDefaults.standard.object(forKey: "backupInterval") as? TimeInterval ?? 300 // 5 min default
        self.keepBackupVersions = UserDefaults.standard.object(forKey: "keepBackupVersions") as? Int ?? 10

        if let savedPath = UserDefaults.standard.string(forKey: "backupLocation") {
            self.backupLocation = URL(fileURLWithPath: savedPath)
        }

        if let lastBackup = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date {
            self.lastBackupDate = lastBackup
        }

        if autoBackupEnabled {
            startAutoBackup()
        }
    }

    deinit {
        autoBackupTimer?.invalidate()
    }

    // MARK: - Manual Backup

    func createBackup(content: String, fileName: String) throws -> URL {
        isBackingUp = true
        defer { isBackingUp = false }

        let backupFolder = getBackupFolder()
        let timestamp = formatTimestamp(Date())
        let backupFileName = (fileName as NSString).deletingPathExtension + "_\(timestamp).md"
        let backupURL = backupFolder.appendingPathComponent(backupFileName)

        try content.write(to: backupURL, atomically: true, encoding: .utf8)

        lastBackupDate = Date()
        UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")

        // Cleanup old backups
        cleanupOldBackups()

        return backupURL
    }

    // MARK: - Auto Backup

    func startAutoBackup() {
        autoBackupTimer?.invalidate()

        guard autoBackupEnabled else { return }

        autoBackupTimer = Timer.scheduledTimer(withTimeInterval: backupInterval, repeats: true) { [weak self] _ in
            self?.performAutoBackup()
        }
    }

    func stopAutoBackup() {
        autoBackupTimer?.invalidate()
        autoBackupTimer = nil
    }

    private func performAutoBackup() {
        // This would be called by the app when content changes
        NotificationCenter.default.post(name: .performAutoBackup, object: nil)
    }

    // MARK: - Backup Folder

    private func getBackupFolder() -> URL {
        let folder: URL

        if let customLocation = backupLocation {
            folder = customLocation
        } else {
            // Default to ~/Documents/MarkdownTool Backups
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            folder = documentsURL.appendingPathComponent("MarkdownTool Backups")
        }

        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder
    }

    // MARK: - Restore

    func listBackups(for fileName: String) -> [URL] {
        let backupFolder = getBackupFolder()
        let baseName = (fileName as NSString).deletingPathExtension

        do {
            let contents = try fileManager.contentsOfDirectory(at: backupFolder, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)

            return contents
                .filter { $0.lastPathComponent.hasPrefix(baseName) && $0.pathExtension == "md" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }

    func restoreBackup(_ url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Cleanup

    private func cleanupOldBackups() {
        guard keepBackupVersions > 0 else { return }

        let backupFolder = getBackupFolder()

        do {
            let contents = try fileManager.contentsOfDirectory(at: backupFolder, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
                .filter { $0.pathExtension == "md" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                    return date1 > date2
                }

            if contents.count > keepBackupVersions {
                for url in contents.dropFirst(keepBackupVersions) {
                    try? fileManager.removeItem(at: url)
                }
            }
        } catch {
            print("Cleanup error: \(error)")
        }
    }

    // MARK: - Helpers

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    func setBackupLocation(_ url: URL?) {
        backupLocation = url
        if let path = url?.path {
            UserDefaults.standard.set(path, forKey: "backupLocation")
        } else {
            UserDefaults.standard.removeObject(forKey: "backupLocation")
        }
    }

    func deleteAllBackups() throws {
        let backupFolder = getBackupFolder()
        let contents = try fileManager.contentsOfDirectory(at: backupFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }
}

// MARK: - iCloud Sync

class iCloudSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var iCloudEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudEnabled, forKey: "iCloudEnabled")
            if iCloudEnabled {
                startSync()
            } else {
                stopSync()
            }
        }
    }
    @Published var syncStatus: SyncStatus = .idle

    private var syncTimer: Timer?
    private let fileManager = FileManager.default
    private var lastKnownContent: [String: String] = [:]

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case error(String)
    }

    init() {
        self.iCloudEnabled = UserDefaults.standard.object(forKey: "iCloudEnabled") as? Bool ?? false

        if let lastSync = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            self.lastSyncDate = lastSync
        }

        if iCloudEnabled {
            startSync()
        }
    }

    deinit {
        syncTimer?.invalidate()
    }

    var iCloudContainerURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: "iCloud.com.bastio89.MarkdownTool")
    }

    var iCloudDocumentsURL: URL? {
        guard let containerURL = iCloudContainerURL else { return nil }
        return containerURL.appendingPathComponent("Documents")
    }

    // MARK: - Sync Control

    func startSync() {
        syncTimer?.invalidate()

        guard iCloudEnabled, iCloudDocumentsURL != nil else { return }

        // Initial sync
        performSync()

        // Periodic sync every 60 seconds
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.performSync()
        }
    }

    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    func forceSync() {
        performSync()
    }

    // MARK: - Sync Operations

    private func performSync() {
        guard let iCloudURL = iCloudDocumentsURL else {
            syncStatus = .error("iCloud nicht verfügbar")
            return
        }

        isSyncing = true
        syncStatus = .syncing

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Ensure directory exists
            if !self.fileManager.fileExists(atPath: iCloudURL.path) {
                try? self.fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
            }

            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncDate = Date()
                self.syncStatus = .synced
                UserDefaults.standard.set(Date(), forKey: "lastSyncDate")
            }
        }
    }

    func saveToiCloud(fileName: String, content: String) throws {
        guard let iCloudURL = iCloudDocumentsURL else {
            throw SyncError.iCloudNotAvailable
        }

        let fileURL = iCloudURL.appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        lastKnownContent[fileName] = content
    }

    func loadFromiCloud(fileName: String) throws -> String? {
        guard let iCloudURL = iCloudDocumentsURL else {
            throw SyncError.iCloudNotAvailable
        }

        let fileURL = iCloudURL.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        lastKnownContent[fileName] = content

        return content
    }

    func listiCloudFiles() -> [URL] {
        guard let iCloudURL = iCloudDocumentsURL else { return [] }

        do {
            return try fileManager.contentsOfDirectory(at: iCloudURL, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
                .filter { $0.pathExtension == "md" }
        } catch {
            return []
        }
    }

    func deleteFromiCloud(fileName: String) throws {
        guard let iCloudURL = iCloudDocumentsURL else {
            throw SyncError.iCloudNotAvailable
        }

        let fileURL = iCloudURL.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }

        lastKnownContent.removeValue(forKey: fileName)
    }

    // MARK: - Conflict Resolution

    func checkForConflicts(fileName: String, localContent: String) -> Bool {
        guard let stored = lastKnownContent[fileName] else { return false }
        return stored != localContent
    }

    enum SyncError: LocalizedError {
        case iCloudNotAvailable
        case conflictDetected

        var errorDescription: String? {
            switch self {
            case .iCloudNotAvailable:
                return "iCloud ist nicht verfügbar. Bitte melde dich in den Systemeinstellungen an."
            case .conflictDetected:
                return "Ein Konflikt wurde erkannt. Bitte wähle eine Version aus."
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let performAutoBackup = Notification.Name("performAutoBackup")
    static let triggeriCloudSync = Notification.Name("triggeriCloudSync")
}

// MARK: - Backup Settings View

struct BackupSettingsView: View {
    @ObservedObject var backupManager: BackupManager
    @ObservedObject var iCloudManager: iCloudSyncManager
    @Environment(\.dismiss) private var dismiss
    @State private var showFolderPicker = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Backup & Synchronisierung")
                        .font(.headline)
                    Text("Automatische Backups und iCloud-Sync")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Auto Backup Section
                    backupSection

                    Divider()

                    // iCloud Sync Section
                    iCloudSection

                    Divider()

                    // Danger Zone
                    dangerZone
                }
            }
        }
        .padding(20)
        .frame(width: 520, height: 620)
        .navigationTitle("Backup & Sync")
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView { url in
                backupManager.setBackupLocation(url)
            }
        }
    }

    // MARK: - Backup Section

    @ViewBuilder
    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Auto-Backup", systemImage: "clock.arrow.circlepath")
                .font(.subheadline)
                .fontWeight(.semibold)

            // Toggle mit Icon-Button
            HStack {
                compactToggle(isOn: $backupManager.autoBackupEnabled, icon: "clock.arrow.circlepath")

                Text("Automatisches Backup")
                    .font(.subheadline)

                Spacer()
            }
            .onChange(of: backupManager.autoBackupEnabled) { _, newValue in
                if newValue {
                    backupManager.startAutoBackup()
                } else {
                    backupManager.stopAutoBackup()
                }
            }

            if backupManager.autoBackupEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intervall:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Picker("Intervall", selection: $backupManager.backupInterval) {
                        Text("1 Min").tag(TimeInterval(60))
                        Text("5 Min").tag(TimeInterval(300))
                        Text("15 Min").tag(TimeInterval(900))
                        Text("30 Min").tag(TimeInterval(1800))
                        Text("1 Std").tag(TimeInterval(3600))
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    HStack {
                        Text("Versionen behalten:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper("\(backupManager.keepBackupVersions)", value: $backupManager.keepBackupVersions, in: 1...50)
                            .labelsHidden()
                    }
                }
                .padding(.leading, 28)
            }

            // Backup Location
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(backupManager.backupLocation?.lastPathComponent ?? "Standard-Ort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Ändern") {
                    showFolderPicker = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 4)

            if let lastBackup = backupManager.lastBackupDate {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("Letztes Backup: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - iCloud Section

    @ViewBuilder
    private var iCloudSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("iCloud-Synchronisierung", systemImage: "icloud")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                compactToggle(isOn: $iCloudManager.iCloudEnabled, icon: "icloud")

                Text("iCloud-Sync aktivieren")
                    .font(.subheadline)

                Spacer()

                statusBadge
            }

            if iCloudManager.iCloudEnabled {
                HStack {
                    Button(action: { iCloudManager.forceSync() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Jetzt synchronisieren")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    if let lastSync = iCloudManager.lastSyncDate {
                        Text("Letzte Sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusIcon: String {
        switch iCloudManager.syncStatus {
        case .idle: return "circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch iCloudManager.syncStatus {
        case .idle: return .secondary
        case .syncing: return .blue
        case .synced: return .green
        case .error: return .orange
        }
    }

    private var statusText: String {
        switch iCloudManager.syncStatus {
        case .idle: return "Bereit"
        case .syncing: return "Sync..."
        case .synced: return "Sync OK"
        case .error(let msg): return msg
        }
    }

    // MARK: - Danger Zone

    @ViewBuilder
    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Gefahrenzone", systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)

            Button(action: {
                try? backupManager.deleteAllBackups()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Alle Backups löschen")
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Compact Toggle

    private func compactToggle(isOn: Binding<Bool>, icon: String) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isOn.wrappedValue ? .blue : .secondary)
                .frame(width: 24, height: 24)
                .background(isOn.wrappedValue ? Color.blue.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Folder Picker

struct FolderPickerView: View {
    let onSelect: (URL?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?

    var body: some View {
        VStack(spacing: 16) {
            Text("Backup-Ordner auswählen")
                .font(.headline)

            Button("Standard-Ort verwenden") {
                onSelect(nil)
                dismiss()
            }
            .buttonStyle(.bordered)

            Button("Benutzerdefinierten Ordner wählen...") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false

                if panel.runModal() == .OK, let url = panel.url {
                    onSelect(url)
                    dismiss()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
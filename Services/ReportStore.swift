import Foundation
import Observation

/// Saved reports, one JSON file each under Application Support.
@MainActor
@Observable
final class ReportStore {
    private(set) var reports: [SavedReport] = []
    /// Files that exist but could not be read. Shown on the home screen instead of being hidden.
    private(set) var unreadableCount = 0

    private let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL = ReportStore.defaultDirectory) {
        self.directory = directory
        load()
    }

    nonisolated static var defaultDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Reports", isDirectory: true)
    }

    func load() {
        var loaded: [SavedReport] = []
        var unreadable = 0
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "json" {
            do {
                loaded.append(try Self.decoder.decode(SavedReport.self, from: Data(contentsOf: file)))
            } catch {
                unreadable += 1
            }
        }
        reports = loaded.sorted { $0.createdAt > $1.createdAt }
        unreadableCount = unreadable
    }

    func report(id: UUID) -> SavedReport? {
        reports.first { $0.id == id }
    }

    /// Adds a report or replaces the one with the same id.
    func save(_ saved: SavedReport) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try Self.encoder.encode(saved).write(to: url(for: saved.id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        if let index = reports.firstIndex(where: { $0.id == saved.id }) {
            reports[index] = saved
        } else {
            reports.insert(saved, at: 0)
        }
    }

    func delete(id: UUID) throws {
        let file = url(for: id)
        if fileManager.fileExists(atPath: file.path) { try fileManager.removeItem(at: file) }
        reports.removeAll { $0.id == id }
    }

    func deleteAll() throws {
        if fileManager.fileExists(atPath: directory.path) { try fileManager.removeItem(at: directory) }
        reports = []
        unreadableCount = 0
    }

    private func url(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

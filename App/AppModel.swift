import Foundation
import Observation

/// Navigation state and the shared services of the app.
@MainActor
@Observable
final class AppModel {
    enum Screen: Hashable {
        case welcome
        case home
        case importChat
        case analyzing(ImportRequest)
        case who
        case story(UUID)
    }

    /// Why the last import failed, shown on the import screen.
    struct ImportProblem: Equatable {
        var failure: ImportFailure
        var fileName: String?
    }

    private(set) var stack: [Screen]
    var importProblem: ImportProblem?
    /// The chat waiting for the "who are you" answer. Not saved until a name is picked.
    var pendingImport: ImportedChat?

    let reports: ReportStore
    let premium: PremiumStore
    let roastService: RoastService
    let readingService: ReadingService

    init(
        reports: ReportStore? = nil,
        premium: PremiumStore? = nil,
        roastService: RoastService = RoastService(),
        readingService: ReadingService = ReadingService()
    ) {
        let store = reports ?? ReportStore()
        self.reports = store
        self.premium = premium ?? PremiumStore()
        self.roastService = roastService
        self.readingService = readingService
        stack = [store.reports.isEmpty ? .welcome : .home]
    }

    var current: Screen { stack.last ?? .home }

    func showHome() {
        stack = [.home]
    }

    func showImport() {
        importProblem = nil
        stack = [.home, .importChat]
    }

    func back() {
        if stack.count > 1 {
            stack.removeLast()
        } else {
            stack = [.home]
        }
    }

    func startImport(_ request: ImportRequest) {
        importProblem = nil
        stack = [.home, .importChat, .analyzing(request)]
    }

    /// A file handed over by another app, usually WhatsApp's "Export chat".
    func open(_ url: URL) {
        guard url.isFileURL else { return }
        startImport(.file(url))
    }

    func askWho(_ imported: ImportedChat) {
        pendingImport = imported
        stack = [.home, .who]
    }

    func finishImport(viewerName: String) {
        guard let pending = pendingImport else { return }
        let saved = SavedReport(report: pending.report, viewerName: viewerName, highlights: pending.highlights)
        do {
            try reports.save(saved)
            pendingImport = nil
            stack = [.home, .story(saved.id)]
        } catch {
            failImport(.unreadable, fileName: nil)
        }
    }

    func failImport(_ failure: ImportFailure, fileName: String?) {
        importProblem = ImportProblem(failure: failure, fileName: fileName)
        stack = [.home, .importChat]
    }

    func openReport(_ id: UUID) {
        stack = [.home, .story(id)]
    }
}

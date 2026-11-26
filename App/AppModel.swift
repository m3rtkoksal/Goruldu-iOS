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
        case story(UUID)
    }

    /// Why the last import failed, shown on the import screen.
    struct ImportProblem: Equatable {
        var failure: ImportFailure
        var fileName: String?
    }

    private(set) var stack: [Screen]
    var importProblem: ImportProblem?

    let reports: ReportStore
    let premium: PremiumStore
    let roastService: RoastService

    init(reports: ReportStore? = nil, premium: PremiumStore? = nil, roastService: RoastService = RoastService()) {
        let store = reports ?? ReportStore()
        self.reports = store
        self.premium = premium ?? PremiumStore()
        self.roastService = roastService
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

    func finishImport(_ report: ChatReport) {
        let saved = SavedReport(report: report)
        do {
            try reports.save(saved)
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

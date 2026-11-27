import SwiftUI

/// The report as one scrolling stack of cards.
struct StoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(ReportStore.self) private var reports
    @Environment(PremiumStore.self) private var premium

    let reportID: UUID

    @State private var roastState: RoastState = .loading
    @State private var roastAttempt = 0
    @State private var roastTask: Task<Void, Never>?
    @State private var showsPaywall = false
    @State private var sharedCard: StoryCard?

    private var roastKey: String { "\(reportID.uuidString)-\(roastAttempt)-\(L10n.apiLocale)" }

    var body: some View {
        Group {
            if let saved = reports.report(id: reportID) {
                pages(for: saved)
            } else {
                missing
            }
        }
        .onChange(of: roastKey, initial: true) { _, _ in
            startRoastLoad()
        }
        .onDisappear { roastTask?.cancel() }
    }

    private func pages(for saved: SavedReport) -> some View {
        let report = saved.report
        return ResultsView(
            report: report,
            viewer: saved.viewer(),
            highlights: saved.highlights,
            reading: saved.reading,
            isPremium: premium.isPremium,
            roastState: roastState,
            unlock: { showsPaywall = true },
            retryRoast: {
                roastState = .loading
                roastAttempt += 1
            },
            close: { model.showHome() },
            share: { sharedCard = StoryCard.cards(for: report, premium: premium.isPremium).last }
        )
        .task(id: "\(premium.isPremium)-\(L10n.apiLocale)") {
            guard premium.isPremium else { return }
            await loadReading(for: saved)
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView()
        }
        .fullScreenCover(item: $sharedCard) { card in
            ShareView(
                report: report,
                card: card,
                roasts: loadedRoasts,
                premium: premium.isPremium,
                viewerName: saved.viewer(),
                highlights: saved.highlights,
                reading: saved.reading
            )
        }
    }

    /// Matches the roast wording shipped with this build. Older saved lines are fetched again.
    private static let roastEdition = 2

    private var loadedRoasts: [Roast] {
        if case .loaded(let roasts) = roastState { return roasts }
        return []
    }

    /// The roast is asked for once and then kept with the report.
    /// A SwiftUI `.task` was cancelled whenever the screen refreshed, and the spinner never left.
    private func startRoastLoad() {
        roastTask?.cancel()
        guard let saved = reports.report(id: reportID) else { return }
        let locale = L10n.apiLocale
        let cached = saved.roasts ?? []
        let cacheFits = !cached.isEmpty && saved.roastEdition == Self.roastEdition
        if cacheFits {
            roastState = .loaded(cached)
            if saved.roastLocale == locale { return }
        } else {
            roastState = .loading
        }
        let report = saved.report
        let edition = Self.roastEdition
        roastTask = Task {
            do {
                let roasts = try await model.roastService.roasts(for: report, locale: locale)
                guard !Task.isCancelled else { return }
                roastState = .loaded(roasts)
                var updated = reports.report(id: reportID) ?? saved
                updated.roasts = roasts
                updated.roastEdition = edition
                updated.roastLocale = locale
                // A failed write only means the roast is asked for again next time.
                try? reports.save(updated)
            } catch is CancellationError {
                return
            } catch let failure as RoastService.Failure {
                guard !Task.isCancelled else { return }
                if case .loaded = roastState { return }
                roastState = .failed(failure)
            } catch {
                guard !Task.isCancelled else { return }
                if case .loaded = roastState { return }
                roastState = .failed(.badResponse)
            }
        }
    }

    /// Asked once the subscription is on. The lines were already chosen; the model only names them.
    private func loadReading(for saved: SavedReport) async {
        if let cached = saved.reading, saved.readingEdition == ReadingService.edition,
           saved.readingLocale == L10n.apiLocale, !cached.vibeTitle.isEmpty {
            return
        }
        do {
            let reading = try await model.readingService.reading(for: saved, locale: L10n.apiLocale)
            var updated = reports.report(id: saved.id) ?? saved
            updated.reading = reading
            updated.readingEdition = ReadingService.edition
            updated.readingLocale = L10n.apiLocale
            try? reports.save(updated)
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private var missing: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(verbatim: L10n.tr("story.missing.title"))
                .displayStyle(30, tracking: -0.035)
                .foregroundStyle(Palette.paper)
                .multilineTextAlignment(.center)
            Text(verbatim: L10n.tr("story.missing.text"))
                .font(.ui(15.5))
                .foregroundStyle(Palette.paper.opacity(0.72))
                .multilineTextAlignment(.center)
            Spacer()
            Button(L10n.tr("welcome.toHome")) { model.showHome() }
                .buttonStyle(PrimaryButtonStyle(kind: .lime))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
        .background(Palette.ink.ignoresSafeArea())
    }
}

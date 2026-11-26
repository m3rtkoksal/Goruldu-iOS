import SwiftUI

/// The report as tappable story pages.
struct StoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(ReportStore.self) private var reports
    @Environment(PremiumStore.self) private var premium

    let reportID: UUID

    @State private var index = 0
    @State private var roastState: RoastState = .loading
    @State private var roastAttempt = 0
    @State private var showsPaywall = false
    @State private var sharedCard: StoryCard?

    var body: some View {
        if let saved = reports.report(id: reportID) {
            pages(for: saved)
        } else {
            missing
        }
    }

    private func pages(for saved: SavedReport) -> some View {
        let report = saved.report
        let cards = StoryCard.cards(for: report, premium: premium.isPremium)
        let card = cards[min(index, cards.count - 1)]
        let theme = StoryTheme.theme(for: card)
        return GeometryReader { proxy in
            let compact = proxy.size.height < 700
            VStack(spacing: 0) {
                chrome(report: report, cards: cards, theme: theme)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                content(card, report: report, cards: cards, theme: theme, compact: compact)
                    .padding(.horizontal, 24)
                    .padding(.top, compact ? 10 : 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                HStack {
                    Button {
                        sharedCard = card
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: Symbol.upload).font(.system(size: 14, weight: .bold))
                            Text(verbatim: L10n.tr("story.share"))
                                .font(.ui(15, .bold))
                        }
                        .foregroundStyle(theme.onAccent)
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(theme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(verbatim: "\(index + 1) / \(cards.count)")
                        .font(.ui(13, .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.foreground.opacity(0.7))
                        .accessibilityLabel(Text(verbatim: L10n.tr("story.page", String(index + 1), String(cards.count))))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { tap in
                    if tap.location.x < proxy.size.width * 0.32 {
                        if index > 0 { index -= 1 }
                    } else if index < cards.count - 1 {
                        index += 1
                    }
                }
            )
        }
        .background(theme.background.ignoresSafeArea())
        .animation(.easeOut(duration: 0.2), value: index)
        .onChange(of: premium.isPremium) { _, unlocked in
            guard unlocked else { return }
            let next = StoryCard.cards(for: report, premium: true)
            if let role = next.firstIndex(of: .role) { index = role }
        }
        .statusBarHidden(true)
        .accessibilityAction(named: Text(verbatim: L10n.tr("story.next"))) {
            if index < cards.count - 1 { index += 1 }
        }
        .accessibilityAction(named: Text(verbatim: L10n.tr("story.previous"))) {
            if index > 0 { index -= 1 }
        }
        .task(id: roastAttempt) { await loadRoast(for: saved) }
        .task(id: premium.isPremium) {
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
                highlights: saved.highlights
            )
        }
    }

    private func chrome(report: ChatReport, cards: [StoryCard], theme: StoryTheme) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(cards.indices, id: \.self) { position in
                    Capsule()
                        .fill(theme.foreground.opacity(position <= index ? 1 : 0.28))
                        .frame(height: 3)
                }
            }
            .accessibilityHidden(true)
            HStack(spacing: 10) {
                Text(verbatim: Format.initials(report.title))
                    .font(.ui(12, .bold))
                    .foregroundStyle(theme.onAccent)
                    .frame(width: 34, height: 34)
                    .background(theme.accent, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: report.title)
                        .font(.ui(14, .bold))
                        .lineLimit(1)
                    Text(verbatim: L10n.tr("story.yearReport", report.year))
                        .font(.ui(12))
                        .opacity(0.72)
                        .lineLimit(1)
                }
                .foregroundStyle(theme.foreground)
                Spacer(minLength: 8)
                Button {
                    model.showHome()
                } label: {
                    Image(systemName: Symbol.close)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.foreground)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: L10n.tr("story.close")))
            }
        }
    }

    private func savedViewer(_ report: ChatReport) -> String {
        reports.report(id: reportID)?.viewer() ?? report.talker.name
    }

    private var savedHighlights: ChatHighlights? {
        reports.report(id: reportID)?.highlights
    }

    private var savedReading: ChatReading? {
        reports.report(id: reportID)?.reading
    }

    @ViewBuilder
    private func content(_ card: StoryCard, report: ChatReport, cards: [StoryCard], theme: StoryTheme, compact: Bool) -> some View {
        let number = StoryCard.awardNumber(of: card, in: cards)
        switch card {
        case .cover:
            CoverCard(report: report, theme: theme, compact: compact)
        case .talker:
            TalkerCard(report: report, number: number, theme: theme, compact: compact)
        case .slowReplier:
            if let slow = report.slowReplier {
                SlowReplierCard(slow: slow, number: number, theme: theme, compact: compact)
            }
        case .nightOwl:
            if let owl = report.nightOwl {
                NightOwlCard(owl: owl, number: number, theme: theme, compact: compact)
            }
        case .words:
            WordsCard(words: report.topWords, theme: theme, compact: compact)
        case .ceremony:
            CeremonyCard(awards: report.awards, isPremium: premium.isPremium, theme: theme) {
                showsPaywall = true
            }
        case .roast:
            RoastCard(
                state: roastState,
                isPremium: premium.isPremium,
                theme: theme,
                unlock: { showsPaywall = true },
                retry: {
                    roastState = .loading
                    roastAttempt += 1
                }
            )
        case .premiumGate:
            PremiumGateCard(theme: theme) { showsPaywall = true }
        case .role:
            RoleCard(report: report, viewer: savedViewer(report), highlights: savedHighlights, reading: savedReading, theme: theme)
        case .vibe:
            VibeCard(report: report, highlights: savedHighlights, reading: savedReading, theme: theme)
        case .cast:
            CastCard(report: report, viewer: savedViewer(report), highlights: savedHighlights, reading: savedReading, theme: theme)
        case .fastest:
            FastestCard(report: report, theme: theme)
        case .moments:
            MomentsCard(report: report, highlights: savedHighlights, reading: savedReading, theme: theme)
        case .archetypes:
            ArchetypeCard(highlights: savedHighlights, reading: savedReading, theme: theme)
        case .cliques:
            CliquesCard(pairs: reports.report(id: reportID)?.highlights?.pairs ?? [], reading: savedReading, theme: theme)
        }
    }

    /// Matches the roast wording shipped with this build. Older saved lines are fetched again.
    private static let roastEdition = 2

    private var loadedRoasts: [Roast] {
        if case .loaded(let roasts) = roastState { return roasts }
        return []
    }

    /// The roast is asked for once and then kept with the report.
    private func loadRoast(for saved: SavedReport) async {
        if let cached = saved.roasts, !cached.isEmpty, saved.roastEdition == Self.roastEdition {
            roastState = .loaded(cached)
            return
        }
        roastState = .loading
        do {
            let roasts = try await model.roastService.roasts(for: saved.report, locale: L10n.apiLocale)
            roastState = .loaded(roasts)
            var updated = saved
            updated.roasts = roasts
            updated.roastEdition = Self.roastEdition
            // A failed write only means the roast is asked for again next time.
            try? reports.save(updated)
        } catch is CancellationError {
            return
        } catch let failure as RoastService.Failure {
            roastState = .failed(failure)
        } catch {
            roastState = .failed(.badResponse)
        }
    }

    /// Asked once the subscription is on. The lines were already chosen; the model only names them.
    private func loadReading(for saved: SavedReport) async {
        if let cached = saved.reading, saved.readingEdition == ReadingService.edition, !cached.vibeTitle.isEmpty {
            return
        }
        do {
            let reading = try await model.readingService.reading(for: saved, locale: L10n.apiLocale)
            var updated = reports.report(id: saved.id) ?? saved
            updated.reading = reading
            updated.readingEdition = ReadingService.edition
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

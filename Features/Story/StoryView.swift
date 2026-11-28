import SwiftUI

/// The report as swipeable story pages. Each card has its own color.
struct StoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(ReportStore.self) private var reports
    @Environment(PremiumStore.self) private var premium

    let reportID: UUID

    @State private var index = 0
    @State private var forward = true
    @State private var roastState: RoastState = .loading
    @State private var roastAttempt = 0
    @State private var roastTask: Task<Void, Never>?
    @State private var showsPaywall = false
    @State private var sharedCard: StoryCard?
    @State private var lastTurn = Date.distantPast

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
            roastTask?.cancel()
            roastTask = nil
            startRoastLoad()
        }
        .onAppear {
            // A story transition can cancel the first request and never ask again.
            if roastTask == nil || roastTask?.isCancelled == true {
                startRoastLoad()
            }
        }
    }

    private func pages(for saved: SavedReport) -> some View {
        let report = saved.report
        let cards = StoryCard.cards(for: report, premium: premium.isPremium)
        let safeIndex = min(index, max(cards.count - 1, 0))
        let card = cards[safeIndex]
        let theme = StoryTheme.theme(for: card)
        return GeometryReader { proxy in
            let compact = proxy.size.height < 760
            VStack(spacing: 0) {
                chrome(report: report, cards: cards, theme: theme, index: safeIndex)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                ZStack {
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { turn(-1, count: cards.count) }
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { turn(1, count: cards.count) }
                    }
                    content(card, report: report, cards: cards, theme: theme, compact: compact)
                        .id(card)
                        .transition(.asymmetric(
                            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
                .padding(.horizontal, 24)
                .padding(.top, compact ? 8 : 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                footer(card: card, count: cards.count, theme: theme, index: safeIndex)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 36, coordinateSpace: .local).onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    turn(value.translation.width < 0 ? 1 : -1, count: cards.count)
                }
            )
        }
        .background(theme.background.ignoresSafeArea())
        .animation(.easeOut(duration: 0.22), value: safeIndex)
        .onAppear { startRoastLoad() }
        .onChange(of: premium.isPremium) { _, unlocked in
            guard unlocked else { return }
            let next = StoryCard.cards(for: report, premium: true)
            if let role = next.firstIndex(of: .role) { index = role }
        }
        .statusBarHidden(true)
        .accessibilityAction(named: Text(verbatim: L10n.tr("story.next"))) {
            turn(1, count: cards.count)
        }
        .accessibilityAction(named: Text(verbatim: L10n.tr("story.previous"))) {
            turn(-1, count: cards.count)
        }
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

    private func turn(_ delta: Int, count: Int) {
        let now = Date()
        guard now.timeIntervalSince(lastTurn) > 0.28 else { return }
        let current = min(index, max(count - 1, 0))
        let next = current + delta
        guard (0..<count).contains(next) else { return }
        lastTurn = now
        forward = delta > 0
        index = next
    }

    private func chrome(report: ChatReport, cards: [StoryCard], theme: StoryTheme, index: Int) -> some View {
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

    private func footer(card: StoryCard, count: Int, theme: StoryTheme, index: Int) -> some View {
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
            Text(verbatim: "\(index + 1) / \(count)")
                .font(.ui(13, .bold))
                .monospacedDigit()
                .foregroundStyle(theme.foreground.opacity(0.7))
                .accessibilityLabel(Text(verbatim: L10n.tr("story.page", String(index + 1), String(count))))
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func content(_ card: StoryCard, report: ChatReport, cards: [StoryCard], theme: StoryTheme, compact: Bool) -> some View {
        let number = StoryCard.awardNumber(of: card, in: cards)
        let viewer = reports.report(id: reportID)?.viewer() ?? report.talker.name
        let highlights = reports.report(id: reportID)?.highlights
        let reading = reports.report(id: reportID)?.reading
        switch card {
        case .cover:
            CoverCard(report: report, theme: theme, compact: compact)
        case .talker:
            TalkerCard(report: report, number: number, theme: theme, compact: compact, viewer: viewer)
        case .slowReplier:
            if let slow = report.slowReplier {
                SlowReplierCard(report: report, slow: slow, number: number, theme: theme, compact: compact)
            }
        case .nightOwl:
            if let owl = report.nightOwl {
                NightOwlCard(report: report, owl: owl, number: number, theme: theme, compact: compact)
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
            RoleCard(report: report, viewer: viewer, highlights: highlights, reading: reading, theme: theme)
        case .vibe:
            VibeCard(report: report, highlights: highlights, reading: reading, theme: theme)
        case .cast:
            CastCard(report: report, viewer: viewer, highlights: highlights, reading: reading, theme: theme)
        case .fastest:
            FastestCard(report: report, theme: theme)
        case .moments:
            MomentsCard(report: report, highlights: highlights, reading: reading, theme: theme)
        case .archetypes:
            ArchetypeCard(highlights: highlights, reading: reading, theme: theme)
        case .cliques:
            CliquesCard(pairs: highlights?.pairs ?? [], reading: reading, theme: theme)
        }
    }

    /// Matches the roast wording shipped with this build. Older saved lines are fetched again.
    private static let roastEdition = 2

    private var loadedRoasts: [Roast] {
        if case .loaded(let roasts) = roastState { return roasts }
        return []
    }

    /// The roast is asked for once and then kept with the report.
    /// Leaving the screen used to cancel that request and leave the spinner up.
    private func startRoastLoad() {
        if let roastTask, !roastTask.isCancelled { return }
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

import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(ReportStore.self) private var reports

    @State private var showsSettings = false
    @State private var pendingDelete: SavedReport?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                BrandMark(tone: .onLight)
                Spacer()
                IconButton(symbol: Symbol.more, label: L10n.tr("settings.title"), tone: .onLight) {
                    showsSettings = true
                }
            }
            .frame(height: 44)
            Text(verbatim: L10n.tr("home.title"))
                .displayStyle(44, tracking: -0.045)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 18)

            if reports.reports.isEmpty {
                emptyState
            } else {
                list
            }

            Button {
                model.showImport()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: reports.reports.isEmpty ? Symbol.upload : Symbol.plus)
                        .font(.system(size: 17, weight: .bold))
                    Text(verbatim: L10n.tr(reports.reports.isEmpty ? "home.cta.first" : "home.cta.new"))
                }
            }
            .buttonStyle(PrimaryButtonStyle(kind: .ink))
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.paper.ignoresSafeArea())
        .sheet(isPresented: $showsSettings) {
            SettingsSheet()
        }
        .confirmationDialog(
            L10n.tr("home.delete.title", pendingDelete?.report.title ?? ""),
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.tr("home.delete.confirm"), role: .destructive) {
                if let target = pendingDelete { delete(target) }
            }
            Button(L10n.tr("common.cancel"), role: .cancel) {}
        }
        .alert(
            L10n.tr("common.error.title"),
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button(L10n.tr("common.ok"), role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.pink)
                    .frame(width: 110, height: 146)
                    .rotationEffect(.degrees(-14))
                    .offset(x: -44)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.blue)
                    .frame(width: 110, height: 146)
                    .rotationEffect(.degrees(11))
                    .offset(x: 44)
                TicksIcon(size: 46)
                    .foregroundStyle(Palette.lime)
                    .frame(width: 110, height: 146)
                    .background(Palette.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .rotationEffect(.degrees(-2))
            }
            .frame(width: 200, height: 170)
            .accessibilityHidden(true)
            Text(verbatim: L10n.tr("home.empty.title"))
                .displayStyle(30, tracking: -0.035)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 28)
            Text(verbatim: L10n.tr("home.empty.text"))
                .font(.ui(15.5))
                .lineSpacing(4)
                .foregroundStyle(Palette.ink.opacity(0.66))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .padding(.top, 8)
            if reports.unreadableCount > 0 { unreadableNote.padding(.top, 16) }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(reports.reports.enumerated()), id: \.element.id) { index, saved in
                    ReportTile(saved: saved, tone: ReportTile.Tone.allCases[index % ReportTile.Tone.allCases.count]) {
                        model.openReport(saved.id)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            pendingDelete = saved
                        } label: {
                            Label(L10n.tr("home.delete.action"), systemImage: Symbol.trash)
                        }
                    }
                }
                if reports.unreadableCount > 0 { unreadableNote }
            }
            .padding(.top, 18)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var unreadableNote: some View {
        Text(verbatim: L10n.tr("home.unreadable", String(reports.unreadableCount)))
            .font(.ui(13.5, .semibold))
            .foregroundStyle(Palette.ink.opacity(0.66))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func delete(_ saved: SavedReport) {
        do {
            try reports.delete(id: saved.id)
        } catch {
            errorMessage = L10n.tr("home.delete.failed")
        }
        pendingDelete = nil
    }
}

private struct ReportTile: View {
    enum Tone: CaseIterable { case lime, pink, blue }

    let saved: SavedReport
    let tone: Tone
    let action: () -> Void

    var body: some View {
        let report = saved.report
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: report.participantCount == 2 ? Symbol.pair : Symbol.group)
                        .font(.system(size: 12, weight: .bold))
                    Text(verbatim: kind)
                        .labelStyle(12, tracking: 0.06)
                        .lineLimit(1)
                }
                .padding(.trailing, 46)
                Text(verbatim: report.title)
                    .displayStyle(32)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 8)
                    .padding(.trailing, 46)
                Text(verbatim: L10n.tr("home.tile.meta", Format.number(report.totalMessages), report.year))
                    .font(.ui(13.5, .semibold))
                    .opacity(0.72)
                    .padding(.top, 4)
                Text(verbatim: L10n.tr("home.tile.hook", report.talker.name, Format.percent(report.talker.sharePercent)))
                    .font(.ui(15, .semibold))
                    .lineSpacing(2)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 12)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(background, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Image(systemName: Symbol.arrowRight)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tone == .blue ? Palette.ink : Palette.paper)
                    .frame(width: 38, height: 38)
                    .background(tone == .blue ? Color.white : Palette.ink, in: Circle())
                    .padding(16)
            }
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var kind: String {
        saved.report.participantCount == 2
            ? L10n.tr("home.tile.pair")
            : L10n.tr("home.tile.group", String(saved.report.participantCount))
    }

    private var background: Color {
        switch tone {
        case .lime: return Palette.lime
        case .pink: return Palette.pink
        case .blue: return Palette.blue
        }
    }

    private var foreground: Color {
        tone == .blue ? .white : Palette.ink
    }
}

import SwiftUI

/// Reads the chat and shows progress. The work itself is quick; the screen stays for a moment
/// so the result does not flash by.
struct AnalyzingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let request: ImportRequest

    @State private var report: ChatReport?
    @State private var shownCount = 0
    @State private var stage = 0

    private static let stages = ["analyzing.step.count", "analyzing.step.replies", "analyzing.step.night", "analyzing.step.awards"]
    private static let minimumDuration: Duration = .milliseconds(1_800)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: Symbol.group).font(.system(size: 13, weight: .bold))
                Text(verbatim: chipText)
                    .font(.ui(13.5, .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.lime)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Palette.ink, in: Capsule())
            .padding(.top, 6)

            Spacer(minLength: 24).frame(maxHeight: 112)

            Text(verbatim: Format.number(shownCount))
                .displayStyle(92, tracking: -0.055)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .contentTransition(.numericText())
            Text(verbatim: L10n.tr("analyzing.unit"))
                .font(.ui(22, .bold))
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(Self.stages.enumerated()), id: \.offset) { index, key in
                    ChecklistRow(text: L10n.tr(key), state: index < stage ? .done : (index == stage ? .active : .waiting))
                }
            }
            .padding(.top, 44)

            Spacer(minLength: 16)

            ProgressView(value: Double(min(stage, Self.stages.count)), total: Double(Self.stages.count))
                .progressViewStyle(.linear)
                .tint(Palette.ink)
                .scaleEffect(x: 1, y: 2.5, anchor: .center)
                .accessibilityLabel(Text(verbatim: L10n.tr("analyzing.progress")))
            Text(verbatim: L10n.tr("analyzing.foot"))
                .font(.ui(13.5, .semibold))
                .opacity(0.62)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.lime.ignoresSafeArea())
        .task { await run() }
    }

    private var chipText: String {
        if let report {
            return L10n.tr("analyzing.chip", report.title, String(report.participantCount))
        }
        return request.fileName ?? ChatImporter.sampleTitle
    }

    private func run() async {
        let clock = ContinuousClock()
        let started = clock.now
        do {
            let imported = try await ChatImporter.loadImported(request, fallbackTitle: L10n.tr("common.chat"))
            report = imported.report
            await animate(to: imported.report.totalMessages)
            let remaining = Self.minimumDuration - (clock.now - started)
            if remaining > .zero { try await Task.sleep(for: remaining) }
            guard !Task.isCancelled else { return }
            model.askWho(imported)
        } catch let failure as ImportFailure {
            model.failImport(failure, fileName: request.fileName)
        } catch is CancellationError {
            return
        } catch {
            model.failImport(.unreadable, fileName: request.fileName)
        }
    }

    /// Counts up to the real total while the checklist advances.
    private func animate(to total: Int) async {
        let steps = Self.stages.count
        for step in 1...steps {
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
                shownCount = total * step / steps
                stage = step
            }
            try? await Task.sleep(for: .milliseconds(360))
        }
    }
}

private struct ChecklistRow: View {
    enum Phase { case waiting, active, done }

    let text: String
    let state: Phase

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                switch state {
                case .done:
                    Circle().fill(Palette.ink)
                    Image(systemName: Symbol.check)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Palette.lime)
                case .active:
                    Spinner(tint: Palette.ink).scaleEffect(0.8)
                case .waiting:
                    Circle().strokeBorder(Palette.ink.opacity(0.28), lineWidth: 2)
                }
            }
            .frame(width: 24, height: 24)
            Text(verbatim: text)
                .font(.ui(16.5, .semibold))
                .foregroundStyle(Palette.ink.opacity(state == .waiting ? 0.45 : 1))
        }
    }
}

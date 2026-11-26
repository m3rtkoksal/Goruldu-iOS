import Photos
import SwiftUI

struct ShareView: View {
    @Environment(\.dismiss) private var dismiss

    let report: ChatReport
    let card: StoryCard
    let roasts: [Roast]

    @State private var hidesNames = false
    @State private var export: Export = .rendering
    @State private var saveState: SaveState = .idle

    private enum Export: Equatable {
        case rendering
        case ready(URL)
        case failed
    }

    private enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case denied
        case failed
    }

    private var content: ShareContent {
        ShareContent.make(card: card, report: report, roasts: roasts, hideNames: hidesNames)
    }

    var body: some View {
        VStack(spacing: 0) {
            NavBar(
                title: L10n.tr("story.share"),
                leading: IconButton(symbol: Symbol.back, label: L10n.tr("common.back")) { dismiss() }
            )
            GeometryReader { proxy in
                let scale = min(proxy.size.height / ShareCardView.size.height, proxy.size.width / ShareCardView.size.width) * 0.9
                ShareCardView(content: content)
                    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    .scaleEffect(max(0.1, scale))
                    .rotationEffect(.degrees(-2))
                    .shadow(color: StoryTheme.theme(for: content.card).background.opacity(0.35), radius: 30, x: 0, y: 20)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .padding(.vertical, 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(content.label). \(content.name). \(content.stat). \(content.note)"))

            Toggle(isOn: $hidesNames) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: L10n.tr("share.hide.title"))
                        .font(.ui(15, .bold))
                        .foregroundStyle(Palette.paper)
                    Text(verbatim: L10n.tr("share.hide.hint", report.talker.name, Format.masked(report.talker.name)))
                        .font(.ui(12.5))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(2)
                }
            }
            .tint(Palette.lime)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.ink2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let message = statusMessage {
                Text(verbatim: message)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(saveState == .saved ? Palette.lime : Palette.pink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }

            HStack(spacing: 10) {
                shareButton
                Button {
                    save()
                } label: {
                    HStack(spacing: 8) {
                        if saveState == .saving {
                            Spinner(tint: Palette.paper)
                        } else {
                            Image(systemName: Symbol.download).font(.system(size: 16, weight: .bold))
                            Text(verbatim: L10n.tr("share.save"))
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle(kind: .ghost))
                .disabled(!isReady || saveState == .saving)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task(id: hidesNames) { render() }
    }

    @ViewBuilder private var shareButton: some View {
        if case .ready(let url) = export {
            ShareLink(item: url) {
                HStack(spacing: 8) {
                    Image(systemName: Symbol.upload).font(.system(size: 16, weight: .bold))
                    Text(verbatim: L10n.tr("story.share"))
                }
            }
            .buttonStyle(PrimaryButtonStyle(kind: .lime))
        } else {
            Button {} label: {
                if export == .rendering {
                    Spinner(tint: Palette.ink)
                } else {
                    Text(verbatim: L10n.tr("story.share"))
                }
            }
            .buttonStyle(PrimaryButtonStyle(kind: .lime))
            .disabled(true)
        }
    }

    private var isReady: Bool {
        if case .ready = export { return true }
        return false
    }

    private var statusMessage: String? {
        if export == .failed { return L10n.tr("share.error.render") }
        switch saveState {
        case .idle, .saving: return nil
        case .saved: return L10n.tr("share.saved")
        case .denied: return L10n.tr("share.error.denied")
        case .failed: return L10n.tr("share.error.save")
        }
    }

    /// Renders the card to a 1080 x 1920 PNG in the temporary folder.
    private func render() {
        export = .rendering
        saveState = .idle
        let renderer = ImageRenderer(content: ShareCardView(content: content))
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(ShareCardView.size)
        guard let data = renderer.uiImage?.pngData() else {
            export = .failed
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("goruldu-\(card.rawValue)\(hidesNames ? "-gizli" : "").png")
        do {
            try data.write(to: url, options: .atomic)
            export = .ready(url)
        } catch {
            export = .failed
        }
    }

    private func save() {
        guard case .ready(let url) = export else { return }
        saveState = .saving
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                saveState = .denied
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: url, options: nil)
                }
                saveState = .saved
            } catch {
                saveState = .failed
            }
        }
    }
}

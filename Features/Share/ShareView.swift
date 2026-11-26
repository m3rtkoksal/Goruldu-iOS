import Photos
import SwiftUI

/// Exports every story card and hands them to the share sheet together.
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
        case ready([URL])
        case failed
    }

    private enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case denied
        case failed
    }

    private var contents: [ShareContent] {
        ShareContent.pages(for: card, report: report, roasts: roasts, hideNames: hidesNames)
    }

    var body: some View {
        VStack(spacing: 0) {
            NavBar(
                title: L10n.tr("story.share"),
                leading: IconButton(symbol: Symbol.back, label: L10n.tr("common.back")) { dismiss() }
            )
            if contents.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(contents, id: \.card) { item in
                            preview(item, scale: previewScale, corner: 16)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: .infinity)
                Text(verbatim: L10n.tr("share.deck", String(contents.count)))
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else if let item = contents.first {
                GeometryReader { proxy in
                    let scale = min(proxy.size.height / ShareCardView.size.height, proxy.size.width / ShareCardView.size.width) * 0.9
                    ShareCardView(content: item)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .scaleEffect(max(0.1, scale))
                        .rotationEffect(.degrees(-2))
                        .shadow(color: StoryTheme.theme(for: item.card).background.opacity(0.35), radius: 30, x: 0, y: 20)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: "\(item.label). \(item.name). \(item.stat). \(item.note)"))
                }
                .padding(.vertical, 12)
            }

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

    private func preview(_ item: ShareContent, scale: CGFloat, corner: CGFloat) -> some View {
        ShareCardView(content: item)
            .scaleEffect(scale, anchor: .top)
            .frame(
                width: ShareCardView.size.width * scale,
                height: ShareCardView.size.height * scale,
                alignment: .top
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(item.label). \(item.name). \(item.stat). \(item.note)"))
    }

    @ViewBuilder private var shareButton: some View {
        if case .ready(let urls) = export, !urls.isEmpty {
            ShareLink(items: urls) {
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
        if case .ready(let urls) = export { return !urls.isEmpty }
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

    /// Renders every card to a 1080 x 1920 PNG. The share sheet receives the whole set.
    private func render() {
        export = .rendering
        saveState = .idle
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("goruldu-share", isDirectory: true)
        do {
            if FileManager.default.fileExists(atPath: folder.path) {
                try FileManager.default.removeItem(at: folder)
            }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var urls: [URL] = []
            for (index, item) in contents.enumerated() {
                let renderer = ImageRenderer(content: ShareCardView(content: item))
                renderer.scale = 3
                renderer.proposedSize = ProposedViewSize(ShareCardView.size)
                guard let data = renderer.uiImage?.pngData() else {
                    export = .failed
                    return
                }
                let url = folder.appendingPathComponent(String(format: "goruldu-%02d-%@.png", index + 1, item.card.rawValue))
                try data.write(to: url, options: .atomic)
                urls.append(url)
            }
            export = urls.isEmpty ? .failed : .ready(urls)
        } catch {
            export = .failed
        }
    }

    private func save() {
        guard case .ready(let urls) = export, !urls.isEmpty else { return }
        saveState = .saving
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                saveState = .denied
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    for url in urls {
                        PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: url, options: nil)
                    }
                }
                saveState = .saved
            } catch {
                saveState = .failed
            }
        }
    }

    private var previewScale: CGFloat { 0.34 }
}

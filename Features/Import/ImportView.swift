import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(AppModel.self) private var model

    @State private var showsPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavBar(
                title: L10n.tr("import.title"),
                leading: IconButton(symbol: Symbol.back, label: L10n.tr("common.back")) { model.back() }
            )
            if let problem = model.importProblem {
                ImportProblemCard(problem: problem)
                    .padding(.top, 24)
                Spacer(minLength: 16)
                VStack(spacing: 10) {
                    Button {
                        showsPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: Symbol.retry).font(.system(size: 16, weight: .bold))
                            Text(verbatim: L10n.tr("import.error.pickAnother"))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(kind: .lime))
                    Button(L10n.tr("import.error.howTo")) { model.importProblem = nil }
                        .buttonStyle(PrimaryButtonStyle(kind: .ghost))
                }
            } else {
                guide
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.ink.ignoresSafeArea())
        .fileImporter(isPresented: $showsPicker, allowedContentTypes: [.zip, .plainText, .text]) { result in
            switch result {
            case .success(let url):
                model.startImport(.file(url))
            case .failure:
                model.failImport(.unreadable, fileName: nil)
            }
        }
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(1...3, id: \.self) { number in
                        HStack(alignment: .top, spacing: 12) {
                            Text(verbatim: String(number))
                                .font(.ui(14, .bold))
                                .foregroundStyle(Palette.ink)
                                .frame(width: 28, height: 28)
                                .background(Palette.lime, in: Circle())
                            Text(Emphasis.attributed(L10n.tr("import.step.\(number)"), size: 15.5, strong: .white))
                                .font(.ui(15.5))
                                .lineSpacing(3)
                                .foregroundStyle(Palette.paper.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

            Button {
                showsPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: Symbol.file)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 54, height: 54)
                        .background(Palette.lime, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.bottom, 10)
                    Text(verbatim: L10n.tr("import.pick.title"))
                        .font(.ui(17, .bold))
                        .foregroundStyle(Palette.paper)
                    Text(verbatim: L10n.tr("import.pick.hint"))
                        .font(.ui(13.5))
                        .foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 170, maxHeight: 250)
                .background(Palette.lime.opacity(0.06), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Palette.lime.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                }
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            Button(L10n.tr("import.sample")) { model.startImport(.sample) }
                .buttonStyle(TextButtonStyle())
                .padding(.top, 4)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: Symbol.shield)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.lime)
                    .padding(.top, 1)
                Text(verbatim: L10n.tr("import.privacy"))
                    .font(.ui(12.5))
                    .lineSpacing(3)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
        }
    }
}

private struct ImportProblemCard: View {
    let problem: AppModel.ImportProblem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: Symbol.alert)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 52, height: 52)
                .background(Palette.pink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(verbatim: L10n.tr("import.error.\(code).title"))
                .displayStyle(28, tracking: -0.035)
                .foregroundStyle(Palette.paper)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            Text(verbatim: L10n.tr("import.error.\(code).text"))
                .font(.ui(15))
                .lineSpacing(4)
                .foregroundStyle(Palette.paper.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            if let fileName = problem.fileName {
                HStack(spacing: 8) {
                    Image(systemName: Symbol.file).font(.system(size: 13, weight: .semibold))
                    Text(verbatim: fileName)
                        .font(.ui(13.5, .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(Palette.paper)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Palette.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Palette.pink.opacity(0.42), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }

    private var code: String {
        switch problem.failure {
        case .unrecognized: return "unrecognized"
        case .tooShort: return "tooShort"
        case .unreadable: return "unreadable"
        case .tooLarge: return "tooLarge"
        }
    }
}

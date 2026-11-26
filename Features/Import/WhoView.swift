import SwiftUI

/// Asks which participant is holding the phone. Asked once, after the file is read.
struct WhoView: View {
    @Environment(AppModel.self) private var model

    @State private var selected: String = ""

    var body: some View {
        if let pending = model.pendingImport {
            form(pending.report)
        } else {
            Color.clear.onAppear { model.showHome() }
        }
    }

    private func form(_ report: ChatReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                IconButton(symbol: Symbol.back, label: L10n.tr("common.back"), tone: .onLight) { model.back() }
                Spacer()
            }
            .frame(height: 44)
            Text(verbatim: L10n.tr("who.title"))
                .font(.ui(34, .bold))
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: L10n.tr("who.lead"))
                .font(.ui(15))
                .foregroundStyle(Palette.ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(report.participants, id: \.name) { person in
                        row(person, picked: pickedName(in: report) == person.name)
                    }
                }
                .padding(2)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 16)
            Button(L10n.tr("who.continue")) {
                model.finishImport(viewerName: pickedName(in: report))
            }
            .buttonStyle(PrimaryButtonStyle(kind: .lime))
            .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.paper.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .onAppear {
            if selected.isEmpty { selected = report.participants.first?.name ?? "" }
        }
    }

    private func pickedName(in report: ChatReport) -> String {
        if report.participants.contains(where: { $0.name == selected }) { return selected }
        return report.participants.first?.name ?? ""
    }

    private func row(_ person: ChatReport.Participant, picked: Bool) -> some View {
        Button {
            selected = person.name
        } label: {
            HStack(spacing: 12) {
                Text(verbatim: String(person.name.prefix(1)).uppercased())
                    .font(.ui(15, .bold))
                    .frame(width: 40, height: 40)
                    .background(picked ? Palette.lime : Color(white: 0.93), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: person.name)
                        .font(.ui(16, .bold))
                    Text(verbatim: L10n.tr("who.messages", Format.number(person.messages)))
                        .font(.ui(13))
                        .foregroundStyle(Palette.ink.opacity(0.55))
                }
                Spacer(minLength: 8)
                Image(systemName: picked ? Symbol.check : "circle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(picked ? Palette.ink : Palette.ink.opacity(0.28))
                    .frame(width: 26, height: 26)
                    .background(picked ? Palette.lime : Color.clear, in: Circle())
                    .overlay { Circle().strokeBorder(picked ? Palette.lime : Palette.ink.opacity(0.18), lineWidth: 2) }
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(picked ? Palette.ink : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }
}

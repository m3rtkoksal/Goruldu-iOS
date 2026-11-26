import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(ReportStore.self) private var reports
    @Environment(PremiumStore.self) private var premium

    @State private var isRestoring = false
    @State private var notice: String?
    @State private var confirmsDeleteAll = false

    private let config = AppConfig.current

    var body: some View {
        @Bindable var premium = premium
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(verbatim: L10n.tr("settings.plan"))
                        Spacer()
                        Text(verbatim: L10n.tr(premium.isPremium ? "settings.plan.premium" : "settings.plan.free"))
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        restore()
                    } label: {
                        HStack {
                            Text(verbatim: L10n.tr("paywall.restore"))
                            Spacer()
                            if isRestoring { ProgressView() }
                        }
                    }
                    .disabled(isRestoring)
                }
                Section {
                    if let url = config.privacyURL {
                        Button(L10n.tr("settings.privacy")) { openURL(url) }
                    }
                    if let url = config.termsURL {
                        Button(L10n.tr("settings.terms")) { openURL(url) }
                    }
                } footer: {
                    Text(verbatim: L10n.tr("import.privacy"))
                }
                Section {
                    Button(L10n.tr("settings.deleteAll"), role: .destructive) {
                        confirmsDeleteAll = true
                    }
                    .disabled(reports.reports.isEmpty && reports.unreadableCount == 0)
                }
                #if DEBUG
                Section {
                    Toggle(L10n.tr("settings.debug.premium"), isOn: $premium.debugUnlocked)
                } header: {
                    Text(verbatim: "Debug")
                }
                #endif
                Section {
                    HStack {
                        Text(verbatim: L10n.tr("settings.version"))
                        Spacer()
                        Text(verbatim: version).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(L10n.tr("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("common.done")) { dismiss() }
                }
            }
            .confirmationDialog(L10n.tr("settings.deleteAll.title"), isPresented: $confirmsDeleteAll, titleVisibility: .visible) {
                Button(L10n.tr("settings.deleteAll.confirm"), role: .destructive) { deleteAll() }
                Button(L10n.tr("common.cancel"), role: .cancel) {}
            }
            .alert(
                L10n.tr("settings.title"),
                isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })
            ) {
                Button(L10n.tr("common.ok"), role: .cancel) {}
            } message: {
                Text(verbatim: notice ?? "")
            }
        }
        .tint(Palette.blue)
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(short) (\(build))"
    }

    private func restore() {
        isRestoring = true
        Task {
            let outcome = await premium.restore()
            isRestoring = false
            switch outcome {
            case .restored: notice = L10n.tr("paywall.restore.done")
            case .nothingToRestore: notice = L10n.tr("paywall.restore.nothing")
            case .failed: notice = L10n.tr("paywall.restore.failed")
            }
        }
    }

    private func deleteAll() {
        do {
            try reports.deleteAll()
        } catch {
            notice = L10n.tr("home.delete.failed")
        }
    }
}

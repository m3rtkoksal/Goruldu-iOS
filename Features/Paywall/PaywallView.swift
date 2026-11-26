import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(PremiumStore.self) private var premium

    @State private var selectedID = PremiumStore.yearlyID
    @State private var isWorking = false
    @State private var notice: String?

    private let config = AppConfig.current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavBar(trailing: IconButton(symbol: Symbol.close, label: L10n.tr("common.close")) { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    art
                        .frame(height: 168)
                        .accessibilityHidden(true)
                    Text(verbatim: L10n.tr("paywall.title"))
                        .displayStyle(38, tracking: -0.045)
                        .foregroundStyle(Palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(1...3, id: \.self) { number in
                            HStack(alignment: .top, spacing: 10) {
                                TicksIcon(size: 18).foregroundStyle(Palette.lime).padding(.top, 1)
                                Text(verbatim: L10n.tr("paywall.perk.\(number)"))
                                    .font(.ui(15))
                                    .lineSpacing(2)
                                    .foregroundStyle(Palette.paper.opacity(0.88))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

            store
                .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            if case .loaded = premium.productState { return }
            await premium.loadProducts()
        }
        .onChange(of: premium.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
        .alert(
            L10n.tr("paywall.title"),
            isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })
        ) {
            Button(L10n.tr("common.ok"), role: .cancel) {}
        } message: {
            Text(verbatim: notice ?? "")
        }
    }

    @ViewBuilder private var store: some View {
        switch premium.productState {
        case .loading:
            VStack(spacing: 12) {
                Spinner(tint: Palette.lime)
                Text(verbatim: L10n.tr("paywall.loading"))
                    .font(.ui(14))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
        case .unavailable:
            VStack(spacing: 14) {
                Text(verbatim: L10n.tr("paywall.unavailable"))
                    .font(.ui(15))
                    .lineSpacing(3)
                    .foregroundStyle(Palette.paper.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(L10n.tr("common.retry")) {
                    Task { await premium.loadProducts() }
                }
                .buttonStyle(PrimaryButtonStyle(kind: .ghost))
            }
            .frame(maxWidth: .infinity)
            footer
        case .loaded(let products):
            HStack(alignment: .top, spacing: 10) {
                ForEach(products, id: \.id) { product in
                    PlanTile(product: product, isSelected: product.id == selection(in: products)) {
                        selectedID = product.id
                    }
                }
            }
            .padding(.top, 11)
            Button {
                if let product = products.first(where: { $0.id == selection(in: products) }) { buy(product) }
            } label: {
                if isWorking {
                    Spinner(tint: Palette.ink)
                } else {
                    Text(verbatim: L10n.tr("paywall.cta"))
                }
            }
            .buttonStyle(PrimaryButtonStyle(kind: .lime))
            .disabled(isWorking)
            .padding(.top, 16)
            footer
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text(verbatim: L10n.tr("paywall.fine"))
                .font(.ui(12))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                Button(L10n.tr("paywall.restore")) { restore() }
                    .disabled(isWorking)
                if let url = config.termsURL {
                    Button(L10n.tr("settings.terms")) { openURL(url) }
                }
                if let url = config.privacyURL {
                    Button(L10n.tr("settings.privacy")) { openURL(url) }
                }
            }
            .font(.ui(12, .semibold))
            .buttonStyle(.plain)
            .foregroundStyle(Palette.paper.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var art: some View {
        ZStack {
            tease(L10n.tr("award.mediaSpammer.title"), background: Palette.pink, foreground: Palette.ink)
                .rotationEffect(.degrees(-7))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            tease(L10n.tr("award.drama.title"), background: Palette.lime, foreground: Palette.ink)
                .rotationEffect(.degrees(5))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            tease(L10n.tr("roast.eyebrow"), background: Palette.blue, foreground: .white)
                .rotationEffect(.degrees(-3))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 24)
                .padding(.bottom, 10)
            Image(systemName: Symbol.lock)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 64, height: 64)
                .background(Palette.paper, in: Circle())
                .overlay { Circle().stroke(Palette.ink.opacity(0.62), lineWidth: 8).padding(-4) }
        }
    }

    private func tease(_ text: String, background: Color, foreground: Color) -> some View {
        Text(verbatim: text)
            .displayStyle(20, tracking: -0.03)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .blur(radius: 2.5)
    }

    private func selection(in products: [Product]) -> String {
        products.contains { $0.id == selectedID } ? selectedID : (products.first?.id ?? selectedID)
    }

    private func buy(_ product: Product) {
        isWorking = true
        Task {
            let outcome = await premium.purchase(product)
            isWorking = false
            switch outcome {
            case .purchased, .cancelled: break
            case .pending: notice = L10n.tr("paywall.pending")
            case .failed: notice = L10n.tr("paywall.failed")
            }
        }
    }

    private func restore() {
        isWorking = true
        Task {
            let outcome = await premium.restore()
            isWorking = false
            switch outcome {
            case .restored: break
            case .nothingToRestore: notice = L10n.tr("paywall.restore.nothing")
            case .failed: notice = L10n.tr("paywall.restore.failed")
            }
        }
    }
}

private struct PlanTile: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let isYearly = product.id == PremiumStore.yearlyID
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: L10n.tr(isYearly ? "paywall.plan.yearly" : "paywall.plan.weekly"))
                    .font(.ui(14, .bold))
                    .foregroundStyle(Palette.paper.opacity(0.75))
                Text(verbatim: product.displayPrice)
                    .displayStyle(23, tracking: -0.03)
                    .foregroundStyle(Palette.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 4)
                Text(verbatim: caption(isYearly: isYearly))
                    .font(.ui(12.5))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 18)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .background(
                isSelected ? Palette.lime.opacity(0.1) : Palette.ink2,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? Palette.lime : Palette.ink3, lineWidth: 2)
            }
            .overlay(alignment: .topLeading) {
                if isYearly {
                    Text(verbatim: L10n.tr("paywall.plan.badge"))
                        .labelStyle(11, tracking: 0.04)
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Palette.lime, in: Capsule())
                        .offset(x: 12, y: -11)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The yearly plan shows its weekly equivalent, computed from the store price.
    private func caption(isYearly: Bool) -> String {
        guard isYearly else { return L10n.tr("paywall.plan.weekly.caption") }
        let weekly = product.price / 52
        return L10n.tr("paywall.plan.yearly.caption", weekly.formatted(product.priceFormatStyle))
    }
}

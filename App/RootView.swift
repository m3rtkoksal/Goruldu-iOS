import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            screen
                .id(model.current)
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
        }
        .animation(.easeOut(duration: 0.28), value: model.current)
        .preferredColorScheme(usesLightSurface ? .light : .dark)
    }

    @ViewBuilder private var screen: some View {
        switch model.current {
        case .welcome:
            WelcomeView()
        case .home:
            HomeView()
        case .importChat:
            ImportView()
        case .analyzing(let request):
            AnalyzingView(request: request)
        case .who:
            WhoView()
        case .story(let id):
            StoryView(reportID: id)
        }
    }

    private var usesLightSurface: Bool {
        switch model.current {
        case .home, .analyzing, .who: return true
        case .welcome, .importChat, .story: return false
        }
    }

    private var background: Color {
        switch model.current {
        case .home, .who: return Palette.paper
        case .analyzing: return Palette.lime
        case .welcome, .importChat, .story: return Palette.ink
        }
    }
}

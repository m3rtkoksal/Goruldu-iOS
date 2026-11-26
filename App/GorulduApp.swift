import SwiftUI

@main
struct GorulduApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.reports)
                .environment(model.premium)
                .onOpenURL { url in model.open(url) }
        }
    }
}

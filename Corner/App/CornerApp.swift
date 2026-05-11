import SwiftUI

@main
struct CornerApp: App {
    @StateObject private var env = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .injecting(env)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background || phase == .inactive {
                        env.statistics.checkpoint()
                    }
                }
        }
    }
}

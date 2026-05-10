import SwiftUI

/// App‑level navigation state. The screensaver is always the root; the menu is a
/// shallow overlay presented *over* it (one level deep — no `NavigationStack`,
/// since the structure is flat and tvOS back‑button handling is then explicit
/// and predictable); onboarding (first launch only) covers everything.
@MainActor
final class Router: ObservableObject {

    /// Pages reachable inside the menu overlay.
    enum MenuPage: Hashable, CaseIterable {
        case home          // the menu itself
        case themes
        case customize     // the deep settings screen
        case statistics
        case about
    }

    @Published var inOnboarding: Bool
    @Published private(set) var isMenuPresented = false
    @Published var menuPage: MenuPage = .home

    init(startInOnboarding: Bool) {
        self.inOnboarding = startInOnboarding
    }

    // Onboarding
    func completeOnboarding() { inOnboarding = false }

    // Menu
    func presentMenu() {
        guard !inOnboarding else { return }
        menuPage = .home
        isMenuPresented = true
    }
    func dismissMenu() {
        isMenuPresented = false
        menuPage = .home
    }
    func toggleMenu() { isMenuPresented ? dismissMenu() : presentMenu() }
    func go(to page: MenuPage) { menuPage = page }

    /// Handle the Siri Remote "Menu/Back" press given the current state.
    /// Returns `true` if it was consumed.
    @discardableResult
    func handleExitCommand() -> Bool {
        if inOnboarding { return false }                // onboarding handles its own
        if !isMenuPresented { presentMenu(); return true }
        if menuPage != .home { menuPage = .home; return true }
        dismissMenu()
        return true
    }
}

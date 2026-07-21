import SwiftUI

private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

// Main entry point view - shows onboarding on first launch, then HomeView
struct ContentView: View {
    @AppStorage(hasCompletedOnboardingKey) private var hasCompletedOnboarding = false
    @StateObject private var knowledgeSession = KnowledgeSession()

    // Transition when HomeView appears after completing onboarding.
    private static let onboardingToHomeTransition = AnyTransition.asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.94)).combined(with: .offset(y: 24)),
        removal: .opacity.combined(with: .scale(scale: 0.98))
    )

    // Transition when OnboardingView is replaced by HomeView.
    private static let onboardingRemovalTransition = AnyTransition.asymmetric(
        insertion: .opacity,
        removal: .opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: -20))
    )

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView()
                    .environmentObject(knowledgeSession)
                    .transition(Self.onboardingToHomeTransition)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(Self.onboardingRemovalTransition)
            }
        }
        .animation(.easeOut(duration: 0.45), value: hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}

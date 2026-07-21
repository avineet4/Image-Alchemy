import SwiftUI

@MainActor
final class KnowledgeSession: ObservableObject {
    let flashcardsViewModel = FlashcardsViewModel()
    let quizViewModel = QuizViewModel()
    let matchTheFollowingViewModel = MatchTheFollowingViewModel()
    let fillInTheBlanksViewModel = FillInTheBlanksViewModel()
}

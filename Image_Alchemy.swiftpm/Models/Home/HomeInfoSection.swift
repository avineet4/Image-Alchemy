import Foundation

struct HomeInfoSection: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let intro: String
    let keyPoints: [String]
}

extension HomeInfoSection {
    static let why = HomeInfoSection(
        id: "why",
        title: "Why this exists",
        intro: "Diffusion models power systems like Stable Diffusion and DALL·E, but for learners—especially those who understand best by doing—the underlying math and architecture can feel intimidating. Most resources are dense papers, static diagrams, or long videos you can't interact with. Image Alchemy is an interactive, beginner‑friendly playground that turns those abstract ideas into something visual and intuitive: something you can explore, manipulate, and truly understand.",
        keyPoints: [
            "Step‑by‑step pipeline with interactive visuals so each part feels concrete.",
            "Interactive maths: probability surfaces, loss landscapes, latent spaces.",
            "Flashcards, quizzes, matching, and fill‑in‑the‑blanks—generated on‑device—to reinforce learning.",
            "Built for students, beginners, study groups, and educators who learn by doing.",
            "The tool I wish I had when I first encountered diffusion models."
        ]
    )

    static let fromDeveloper = HomeInfoSection(
        id: "from",
        title: "From the developer",
        intro: "I'm specializing in AI and ML, and diffusion was one of the hardest topics to wrap my head around—especially when preparing for exams. I built Image Alchemy out of that need and validated it with educators before sharing it. My classmates and I use it to walk through the pipeline, test each other with quizzes, and revise together. Seeing the moment when something \"clicks\" for someone else is what made this worth building. If the app makes these ideas feel less intimidating and more accessible, it has done its job.",
        keyPoints: [
            "Start with Full Pipeline for the big picture.",
            "Use Related Maths when you want to dig into the equations.",
            "Test Your Knowledge when you're ready to check what stuck.",
            "Explore at your own pace—no rush.",
            "Feedback and ideas are always welcome."
        ]
    )

    static let all: [HomeInfoSection] = [
        .why,
        .fromDeveloper
    ]
}

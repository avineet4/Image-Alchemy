import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Transferable word (drag-and-drop)

// A word used in fill-in-the-blank drag-and-drop; conforms to Transferable for SwiftUI.
struct FillInBlankWord: Hashable, Transferable, Codable {
    let word: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Question structure

// A segment of a fill-in-the-blank sentence (either text or a blank slot)
enum FillInBlankSegment: Equatable {
    case text(String)
    case blank(Int)
}

// A fill-in-the-blank question with a sentence containing blanks
struct FillInBlankQuestion: Identifiable {
    let id: UUID
    let segments: [FillInBlankSegment]
    let answers: [String]
    
    init(id: UUID = UUID(), segments: [FillInBlankSegment], answers: [String]) {
        self.id = id
        self.segments = segments
        self.answers = answers
    }
    
    var wordBank: [String] {
        answers
    }
}

// MARK: - Static Sample Data

extension FillInBlankQuestion {
    static let sampleQuestions: [FillInBlankQuestion] = [
        FillInBlankQuestion(
            segments: [
                .text("The "),
                .blank(0),
                .text(" process adds "),
                .blank(1),
                .text(" noise to an image over T timesteps.")
            ],
            answers: ["forward", "Gaussian"]
        ),
        FillInBlankQuestion(
            segments: [
                .text("The "),
                .blank(0),
                .text(" predicts the noise "),
                .blank(1),
                .text(" at each denoising step.")
            ],
            answers: ["U-Net", "ε"]
        ),
        FillInBlankQuestion(
            segments: [
                .text("The "),
                .blank(0),
                .text(" schedule (βₜ) controls how much noise is added at each "),
                .blank(1),
                .text(".")
            ],
            answers: ["noise", "timestep"]
        ),
        FillInBlankQuestion(
            segments: [
                .text("At t = 0 the image is "),
                .blank(0),
                .text(", and at t = T it is pure "),
                .blank(1),
                .text(".")
            ],
            answers: ["clean", "noise"]
        ),
    ]
}

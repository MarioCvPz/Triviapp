import Foundation

struct AnswerOption {
    let text: String
    let isCorrect: Bool
}

struct Question {
    let text: String
    let options: [AnswerOption] // exactamente 4
}

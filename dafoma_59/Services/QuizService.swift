//
//  QuizService.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation
import SwiftUI

class QuizService: ObservableObject {
    static let shared = QuizService()
    
    @Published var currentQuiz: Quiz?
    @Published var quizResults: [QuizResult] = []
    
    private init() {}
    
    // MARK: - Quiz Generation
    func generateQuiz(for languageCode: String, difficulty: Language.Difficulty, questionCount: Int = 10) -> Quiz {
        let lessons = DataService.shared.getLessons(for: languageCode)
        let filteredLessons = lessons.filter { $0.difficulty == difficulty || difficulty == .beginner }
        
        var allExercises: [Exercise] = []
        for lesson in filteredLessons {
            allExercises.append(contentsOf: lesson.exercises)
        }
        
        // Shuffle and take requested number of questions
        let selectedExercises = Array(allExercises.shuffled().prefix(questionCount))
        
        let quiz = Quiz(
            languageCode: languageCode,
            difficulty: difficulty,
            questions: selectedExercises,
            timeLimit: questionCount * 30 // 30 seconds per question
        )
        
        self.currentQuiz = quiz
        return quiz
    }
    
    func generateDailyChallenge(for languageCode: String) -> Quiz {
        let lessons = DataService.shared.getLessons(for: languageCode)
        var challengeExercises: [Exercise] = []
        
        // Mix different types of exercises for variety
        for lesson in lessons.prefix(5) { // Use first 5 lessons for daily challenge
            if let exercise = lesson.exercises.randomElement() {
                challengeExercises.append(exercise)
            }
        }
        
        // Add some bonus difficult questions
        challengeExercises.append(contentsOf: generateBonusQuestions(for: languageCode))
        
        let quiz = Quiz(
            languageCode: languageCode,
            difficulty: .intermediate,
            questions: challengeExercises.shuffled(),
            timeLimit: challengeExercises.count * 45, // 45 seconds per question for challenge
            isDailyChallenge: true,
            bonusPoints: 50
        )
        
        self.currentQuiz = quiz
        return quiz
    }
    
    private func generateBonusQuestions(for languageCode: String) -> [Exercise] {
        switch languageCode {
        case "es":
            return [
                Exercise(
                    type: .multipleChoice,
                    question: "Which verb form is correct? 'Yo _____ español'",
                    options: ["hablo", "hablas", "habla", "hablamos"],
                    correctAnswer: "hablo",
                    explanation: "'Hablo' is the first person singular form of 'hablar' (to speak).",
                    points: 20
                ),
                Exercise(
                    type: .translation,
                    question: "Translate: 'I would like to order a coffee'",
                    options: ["Me gustaría pedir un café", "Quiero café", "Necesito café", "Café por favor"],
                    correctAnswer: "Me gustaría pedir un café",
                    explanation: "'Me gustaría pedir' is the polite way to say 'I would like to order'.",
                    points: 25
                )
            ]
        case "fr":
            return [
                Exercise(
                    type: .multipleChoice,
                    question: "Which article is correct? '_____ maison'",
                    options: ["la", "le", "les", "un"],
                    correctAnswer: "la",
                    explanation: "'Maison' is feminine, so it takes the feminine article 'la'.",
                    points: 20
                ),
                Exercise(
                    type: .fillInTheBlank,
                    question: "Complete: 'Je _____ français' (I speak French)",
                    options: ["parle", "parles", "parlons", "parlent"],
                    correctAnswer: "parle",
                    explanation: "'Parle' is the first person singular form of 'parler'.",
                    points: 25
                )
            ]
        default:
            return [
                Exercise(
                    type: .multipleChoice,
                    question: "What is the most polite way to greet someone?",
                    options: ["Hello", "Hi", "Hey", "Good morning"],
                    correctAnswer: "Good morning",
                    explanation: "Time-specific greetings like 'Good morning' are generally more formal and polite.",
                    points: 15
                )
            ]
        }
    }
    
    // MARK: - Quiz Management
    func submitAnswer(questionIndex: Int, selectedAnswer: String) -> Bool {
        guard let quiz = currentQuiz,
              questionIndex < quiz.questions.count else { return false }
        
        let question = quiz.questions[questionIndex]
        let isCorrect = selectedAnswer == question.correctAnswer
        
        // Update quiz with answer
        var updatedQuiz = quiz
        updatedQuiz.userAnswers[questionIndex] = selectedAnswer
        
        if isCorrect {
            updatedQuiz.score += question.points
            updatedQuiz.correctAnswers += 1
        }
        
        self.currentQuiz = updatedQuiz
        return isCorrect
    }
    
    func completeQuiz() -> QuizResult {
        guard let quiz = currentQuiz else {
            return QuizResult(quiz: Quiz(languageCode: "unknown", difficulty: .beginner, questions: [], timeLimit: 0), completionDate: Date())
        }
        
        let result = QuizResult(quiz: quiz, completionDate: Date())
        quizResults.append(result)
        
        // Update user progress
        let totalPoints = quiz.score + (quiz.isDailyChallenge ? quiz.bonusPoints : 0)
        DataService.shared.updateProgress(for: quiz.languageCode, lessonNumber: 0, points: totalPoints)
        
        // Clear current quiz
        self.currentQuiz = nil
        
        return result
    }
    
    func getQuizHistory(for languageCode: String? = nil) -> [QuizResult] {
        if let languageCode = languageCode {
            return quizResults.filter { $0.quiz.languageCode == languageCode }
        }
        return quizResults
    }
    
    func getAverageScore(for languageCode: String) -> Double {
        let languageQuizzes = getQuizHistory(for: languageCode)
        guard !languageQuizzes.isEmpty else { return 0.0 }
        
        let totalScore = languageQuizzes.reduce(0) { $0 + $1.quiz.score }
        return Double(totalScore) / Double(languageQuizzes.count)
    }
    
    // MARK: - Statistics
    func getQuizStatistics(for languageCode: String) -> QuizStatistics {
        let history = getQuizHistory(for: languageCode)
        
        let totalQuizzes = history.count
        let totalQuestions = history.reduce(0) { $0 + $1.quiz.questions.count }
        let totalCorrect = history.reduce(0) { $0 + $1.quiz.correctAnswers }
        let averageScore = getAverageScore(for: languageCode)
        
        let accuracy = totalQuestions > 0 ? Double(totalCorrect) / Double(totalQuestions) * 100 : 0.0
        
        return QuizStatistics(
            totalQuizzes: totalQuizzes,
            totalQuestions: totalQuestions,
            correctAnswers: totalCorrect,
            averageScore: averageScore,
            accuracy: accuracy,
            bestScore: history.max(by: { $0.quiz.score < $1.quiz.score })?.quiz.score ?? 0,
            recentImprovement: calculateImprovement(from: history)
        )
    }
    
    private func calculateImprovement(from history: [QuizResult]) -> Double {
        guard history.count >= 2 else { return 0.0 }
        
        let recent = Array(history.suffix(3)) // Last 3 quizzes
        let older = Array(history.prefix(max(1, history.count - 3))) // Earlier quizzes
        
        let recentAverage = recent.isEmpty ? 0.0 : Double(recent.reduce(0) { $0 + $1.quiz.score }) / Double(recent.count)
        let olderAverage = older.isEmpty ? 0.0 : Double(older.reduce(0) { $0 + $1.quiz.score }) / Double(older.count)
        
        return recentAverage - olderAverage
    }
}

// MARK: - Quiz Models
struct Quiz: Identifiable, Codable {
    let id = UUID()
    let languageCode: String
    let difficulty: Language.Difficulty
    let questions: [Exercise]
    let timeLimit: Int // in seconds
    var isDailyChallenge: Bool = false
    var bonusPoints: Int = 0
    
    // Quiz state
    var currentQuestionIndex: Int = 0
    var score: Int = 0
    var correctAnswers: Int = 0
    var userAnswers: [Int: String] = [:] // Question index -> User answer
    var startTime: Date = Date()
    var isCompleted: Bool = false
    
    var progress: Double {
        guard !questions.isEmpty else { return 0.0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var timeRemaining: Int {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        return max(0, timeLimit - elapsed)
    }
    
    var accuracy: Double {
        guard currentQuestionIndex > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(currentQuestionIndex) * 100
    }
}

struct QuizResult: Identifiable, Codable {
    let id = UUID()
    let quiz: Quiz
    let completionDate: Date
    
    var percentage: Double {
        guard !quiz.questions.isEmpty else { return 0.0 }
        return Double(quiz.correctAnswers) / Double(quiz.questions.count) * 100
    }
    
    var grade: String {
        switch percentage {
        case 90...100: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        case 50..<60: return "D"
        default: return "F"
        }
    }
    
    var isPassed: Bool {
        return percentage >= 60.0
    }
}

struct QuizStatistics: Codable {
    let totalQuizzes: Int
    let totalQuestions: Int
    let correctAnswers: Int
    let averageScore: Double
    let accuracy: Double
    let bestScore: Int
    let recentImprovement: Double
    
    var performanceLevel: String {
        switch accuracy {
        case 90...100: return "Excellent"
        case 80..<90: return "Very Good"
        case 70..<80: return "Good"
        case 60..<70: return "Fair"
        default: return "Needs Improvement"
        }
    }
}

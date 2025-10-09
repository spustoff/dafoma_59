//
//  QuizViewModel.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation
import SwiftUI

class QuizViewModel: ObservableObject {
    @Published var currentQuiz: Quiz?
    @Published var selectedAnswer: String?
    @Published var showResult = false
    @Published var isAnswerCorrect = false
    @Published var timeRemaining = 0
    @Published var quizResults: [QuizResult] = []
    @Published var showQuizComplete = false
    @Published var finalResult: QuizResult?
    
    private let quizService = QuizService.shared
    private var timer: Timer?
    
    init() {
        loadQuizHistory()
    }
    
    // MARK: - Quiz Management
    func startQuiz(for languageCode: String, difficulty: Language.Difficulty, questionCount: Int = 10) {
        let quiz = quizService.generateQuiz(for: languageCode, difficulty: difficulty, questionCount: questionCount)
        currentQuiz = quiz
        resetQuizState()
        startTimer()
    }
    
    func startDailyChallenge(for languageCode: String) {
        let quiz = quizService.generateDailyChallenge(for: languageCode)
        currentQuiz = quiz
        resetQuizState()
        startTimer()
    }
    
    func submitAnswer() {
        guard let quiz = currentQuiz,
              let answer = selectedAnswer else { return }
        
        isAnswerCorrect = quizService.submitAnswer(
            questionIndex: quiz.currentQuestionIndex,
            selectedAnswer: answer
        )
        
        showResult = true
        
        // Auto-advance after showing result
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.nextQuestion()
        }
    }
    
    func nextQuestion() {
        guard var quiz = currentQuiz else { return }
        
        showResult = false
        selectedAnswer = nil
        
        if quiz.currentQuestionIndex < quiz.questions.count - 1 {
            quiz.currentQuestionIndex += 1
            currentQuiz = quiz
        } else {
            completeQuiz()
        }
    }
    
    func completeQuiz() {
        stopTimer()
        
        guard let quiz = currentQuiz else { return }
        
        var completedQuiz = quiz
        completedQuiz.isCompleted = true
        currentQuiz = completedQuiz
        
        let result = quizService.completeQuiz()
        finalResult = result
        quizResults.append(result)
        showQuizComplete = true
    }
    
    func resetQuiz() {
        currentQuiz = nil
        resetQuizState()
        stopTimer()
    }
    
    private func resetQuizState() {
        selectedAnswer = nil
        showResult = false
        isAnswerCorrect = false
        showQuizComplete = false
        finalResult = nil
        
        if let quiz = currentQuiz {
            timeRemaining = quiz.timeLimit
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimer()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let quiz = currentQuiz else {
            stopTimer()
            return
        }
        
        timeRemaining = quiz.timeRemaining
        
        if timeRemaining <= 0 {
            // Time's up - auto-submit or move to next question
            if selectedAnswer == nil {
                selectedAnswer = "" // Empty answer for timeout
            }
            
            if !showResult {
                submitAnswer()
            }
        }
    }
    
    // MARK: - Answer Selection
    func selectAnswer(_ answer: String) {
        guard !showResult else { return }
        selectedAnswer = answer
    }
    
    func isAnswerSelected(_ answer: String) -> Bool {
        return selectedAnswer == answer
    }
    
    // MARK: - Quiz Information
    func getCurrentQuestion() -> Exercise? {
        guard let quiz = currentQuiz,
              quiz.currentQuestionIndex < quiz.questions.count else { return nil }
        
        return quiz.questions[quiz.currentQuestionIndex]
    }
    
    func getQuestionNumber() -> String {
        guard let quiz = currentQuiz else { return "0/0" }
        return "\(quiz.currentQuestionIndex + 1)/\(quiz.questions.count)"
    }
    
    func getProgressPercentage() -> Double {
        guard let quiz = currentQuiz else { return 0.0 }
        return quiz.progress
    }
    
    func getTimeRemainingFormatted() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getScoreInfo() -> (current: Int, total: Int, percentage: Double) {
        guard let quiz = currentQuiz else { return (0, 0, 0.0) }
        
        let totalPossible = quiz.questions.reduce(0) { $0 + $1.points }
        let percentage = totalPossible > 0 ? Double(quiz.score) / Double(totalPossible) * 100 : 0.0
        
        return (quiz.score, totalPossible, percentage)
    }
    
    // MARK: - Quiz History
    func loadQuizHistory() {
        quizResults = quizService.quizResults
    }
    
    func getQuizHistory(for languageCode: String? = nil) -> [QuizResult] {
        return quizService.getQuizHistory(for: languageCode)
    }
    
    func getQuizStatistics(for languageCode: String) -> QuizStatistics {
        return quizService.getQuizStatistics(for: languageCode)
    }
    
    // MARK: - Performance Analysis
    func getWeakAreas(for languageCode: String) -> [Exercise.ExerciseType] {
        let history = getQuizHistory(for: languageCode)
        var typePerformance: [Exercise.ExerciseType: (correct: Int, total: Int)] = [:]
        
        for result in history {
            for (index, question) in result.quiz.questions.enumerated() {
                let userAnswer = result.quiz.userAnswers[index] ?? ""
                let isCorrect = userAnswer == question.correctAnswer
                
                if typePerformance[question.type] == nil {
                    typePerformance[question.type] = (0, 0)
                }
                
                typePerformance[question.type]?.total += 1
                if isCorrect {
                    typePerformance[question.type]?.correct += 1
                }
            }
        }
        
        // Return types with accuracy below 70%
        return typePerformance.compactMap { type, performance in
            let accuracy = Double(performance.correct) / Double(performance.total)
            return accuracy < 0.7 ? type : nil
        }
    }
    
    func getRecommendations(for languageCode: String) -> [String] {
        let weakAreas = getWeakAreas(for: languageCode)
        var recommendations: [String] = []
        
        for area in weakAreas {
            switch area {
            case .multipleChoice:
                recommendations.append("Practice more vocabulary recognition exercises")
            case .fillInTheBlank:
                recommendations.append("Focus on grammar and sentence structure")
            case .translation:
                recommendations.append("Spend more time on translation exercises")
            case .pronunciation:
                recommendations.append("Practice pronunciation with audio exercises")
            case .listening:
                recommendations.append("Improve listening skills with dialogue practice")
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("Great job! Keep up the consistent practice")
            recommendations.append("Try increasing the difficulty level")
        }
        
        return recommendations
    }
    
    // MARK: - Achievements
    func checkForAchievements(result: QuizResult) -> [Achievement] {
        var newAchievements: [Achievement] = []
        
        // Perfect score achievement
        if result.percentage == 100.0 {
            newAchievements.append(Achievement(
                title: "Perfect Score!",
                description: "Got 100% on a quiz",
                icon: "star.fill",
                requirement: 1,
                isUnlocked: true,
                unlockedDate: Date(),
                category: .points
            ))
        }
        
        // Speed achievement
        let timePerQuestion = Double(result.quiz.timeLimit) / Double(result.quiz.questions.count)
        let actualTimePerQuestion = Date().timeIntervalSince(result.quiz.startTime) / Double(result.quiz.questions.count)
        
        if actualTimePerQuestion < timePerQuestion * 0.5 {
            newAchievements.append(Achievement(
                title: "Speed Demon",
                description: "Completed quiz in record time",
                icon: "bolt.fill",
                requirement: 1,
                isUnlocked: true,
                unlockedDate: Date(),
                category: .points
            ))
        }
        
        // Streak achievements
        let totalQuizzes = getQuizHistory(for: result.quiz.languageCode).count
        if totalQuizzes == 5 {
            newAchievements.append(Achievement(
                title: "Quiz Master",
                description: "Completed 5 quizzes",
                icon: "graduationcap.fill",
                requirement: 5,
                isUnlocked: true,
                unlockedDate: Date(),
                category: .points
            ))
        }
        
        return newAchievements
    }
    
    deinit {
        stopTimer()
    }
}

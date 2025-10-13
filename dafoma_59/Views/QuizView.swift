//
//  QuizView.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @State private var showQuizSetup = true
    @State private var selectedLanguage: String = "es"
    @State private var selectedDifficulty: Language.Difficulty = .beginner
    @State private var questionCount = 10
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "02102b")
                    .ignoresSafeArea()
                
                if showQuizSetup {
                    quizSetupView
                } else if viewModel.showQuizComplete {
                    quizCompletionView
                } else {
                    quizContentView
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Quiz Setup View
    private var quizSetupView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("🧠")
                        .font(.system(size: 60))
                    
                    Text("Quiz Time!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Test your knowledge and earn points")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Quiz Options
                VStack(spacing: 20) {
                    // Language Selection
                    QuizOptionCard(title: "Language", subtitle: "Choose your language") {
                        LanguageSelector(selectedLanguage: $selectedLanguage)
                    }
                    
                    // Difficulty Selection
                    QuizOptionCard(title: "Difficulty", subtitle: "Select challenge level") {
                        DifficultySelector(selectedDifficulty: $selectedDifficulty)
                    }
                    
                    // Question Count
                    QuizOptionCard(title: "Questions", subtitle: "Number of questions") {
                        QuestionCountSelector(questionCount: $questionCount)
                    }
                }
                
                // Start Buttons
                VStack(spacing: 15) {
                    // Regular Quiz
                    NeumorphicButton(
                        title: "Start Quiz",
                        backgroundColor: Color(hex: "bd0e1b"),
                        foregroundColor: .white
                    ) {
                        startRegularQuiz()
                    }
                    
                    // Daily Challenge
                    NeumorphicButton(
                        title: "Daily Challenge 🏆",
                        backgroundColor: Color(hex: "ffbe00"),
                        foregroundColor: Color(hex: "02102b")
                    ) {
                        startDailyChallenge()
                    }
                }
                .padding(.top, 20)
                
                // Quiz History
                QuizHistoryPreview(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Quiz Content View
    private var quizContentView: some View {
        VStack(spacing: 0) {
            // Header
            quizHeader
            
            // Question Content
            ScrollView {
                VStack(spacing: 25) {
                    if let question = viewModel.getCurrentQuestion() {
                        QuestionCard(
                            question: question,
                            selectedAnswer: viewModel.selectedAnswer,
                            showResult: viewModel.showResult,
                            isCorrect: viewModel.isAnswerCorrect
                        ) { answer in
                            viewModel.selectAnswer(answer)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            
            // Submit Button
            if !viewModel.showResult && viewModel.selectedAnswer != nil {
                NeumorphicButton(
                    title: "Submit Answer",
                    backgroundColor: Color(hex: "ffbe00"),
                    foregroundColor: Color(hex: "02102b")
                ) {
                    viewModel.submitAnswer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var quizHeader: some View {
        VStack(spacing: 15) {
            HStack {
                Button(action: {
                    viewModel.resetQuiz()
                    showQuizSetup = true
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack {
                    Text("Quiz")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(viewModel.getQuestionNumber())
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(viewModel.getTimeRemainingFormatted())
                        .font(.headline)
                        .foregroundColor(Color(hex: "ffbe00"))
                    
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
            
            // Progress Bar
            ProgressBarView(progress: viewModel.getProgressPercentage())
            
            // Score
            let scoreInfo = viewModel.getScoreInfo()
            HStack {
                Text("Score: \(scoreInfo.current)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(scoreInfo.percentage))%")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "ffbe00"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    // MARK: - Quiz Completion View
    private var quizCompletionView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Celebration
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 80))
                    
                    Text("Quiz Complete!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    if let result = viewModel.finalResult {
                        VStack(spacing: 10) {
                            Text("Your Score")
                                .font(.headline)
                                .foregroundColor(Color.white.opacity(0.8))
                            
                            Text("\(result.quiz.score) points")
                                .font(.title)
                                .foregroundColor(Color(hex: "ffbe00"))
                            
                            Text("\(Int(result.percentage))% • Grade: \(result.grade)")
                                .font(.subheadline)
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                }
                .padding(.top, 40)
                
                // Results Summary
                if let result = viewModel.finalResult {
                    QuizResultCard(result: result)
                }
                
                // Action Buttons
                VStack(spacing: 15) {
                    NeumorphicButton(
                        title: "Take Another Quiz",
                        backgroundColor: Color(hex: "bd0e1b"),
                        foregroundColor: .white
                    ) {
                        viewModel.resetQuiz()
                        showQuizSetup = true
                    }
                    
                    NeumorphicButton(
                        title: "View Results",
                        backgroundColor: Color(hex: "0a1a3b"),
                        foregroundColor: .white
                    ) {
                        // Show detailed results
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Helper Methods
    private func startRegularQuiz() {
        viewModel.startQuiz(for: selectedLanguage, difficulty: selectedDifficulty, questionCount: questionCount)
        showQuizSetup = false
    }
    
    private func startDailyChallenge() {
        viewModel.startDailyChallenge(for: selectedLanguage)
        showQuizSetup = false
    }
}

// MARK: - Supporting Views

struct QuizOptionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
        )
    }
}

struct LanguageSelector: View {
    @Binding var selectedLanguage: String
    
    private let languages = [
        ("es", "🇪🇸", "Spanish"),
        ("fr", "🇫🇷", "French"),
        ("de", "🇩🇪", "German"),
        ("it", "🇮🇹", "Italian")
    ]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(languages, id: \.0) { code, flag, name in
                Button(action: {
                    selectedLanguage = code
                }) {
                    VStack(spacing: 5) {
                        Text(flag)
                            .font(.title2)
                        
                        Text(name)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedLanguage == code ? Color(hex: "ffbe00") : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedLanguage == code ? Color(hex: "bd0e1b") : Color.clear)
                    )
                }
            }
        }
    }
}

struct DifficultySelector: View {
    @Binding var selectedDifficulty: Language.Difficulty
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Language.Difficulty.allCases, id: \.self) { difficulty in
                Button(action: {
                    selectedDifficulty = difficulty
                }) {
                    Text(difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(selectedDifficulty == difficulty ? Color(hex: "02102b") : Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedDifficulty == difficulty ? Color(hex: "ffbe00") : Color(hex: "02102b").opacity(0.3))
                        )
                }
            }
        }
    }
}

struct QuestionCountSelector: View {
    @Binding var questionCount: Int
    
    private let counts = [5, 10, 15, 20]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(counts, id: \.self) { count in
                Button(action: {
                    questionCount = count
                }) {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(questionCount == count ? Color(hex: "02102b") : Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(questionCount == count ? Color(hex: "ffbe00") : Color(hex: "02102b").opacity(0.3))
                        )
                }
            }
        }
    }
}

struct QuestionCard: View {
    let question: Exercise
    let selectedAnswer: String?
    let showResult: Bool
    let isCorrect: Bool
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Question Type Badge
            HStack {
                Text(question.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "bd0e1b"))
                    )
                
                Spacer()
                
                Text("\(question.points) pts")
                    .font(.caption)
                    .foregroundColor(Color(hex: "ffbe00"))
            }
            
            // Question Text
            Text(question.question)
                .font(.title3)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
            
            // Answer Options
            VStack(spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    AnswerOptionView(
                        option: option,
                        isSelected: selectedAnswer == option,
                        showResult: showResult,
                        isCorrect: option == question.correctAnswer,
                        isUserAnswer: selectedAnswer == option
                    ) {
                        if !showResult {
                            onAnswerSelected(option)
                        }
                    }
                }
            }
            
            // Result Explanation
            if showResult {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? Color.green : Color.red)
                            .font(.title2)
                        
                        Text(isCorrect ? "Correct!" : "Incorrect")
                            .font(.headline)
                            .foregroundColor(isCorrect ? Color.green : Color.red)
                        
                        Spacer()
                    }
                    
                    Text(question.explanation)
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "02102b").opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 6, y: 6)
                .shadow(color: Color.white.opacity(0.1), radius: 12, x: -6, y: -6)
        )
    }
}

struct AnswerOptionView: View {
    let option: String
    let isSelected: Bool
    let showResult: Bool
    let isCorrect: Bool
    let isUserAnswer: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.body)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if showResult && isUserAnswer && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                } else if isSelected {
                    Image(systemName: "circle.fill")
                        .foregroundColor(Color(hex: "ffbe00"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .disabled(showResult)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if showResult {
            if isCorrect {
                return Color.green.opacity(0.2)
            } else if isUserAnswer {
                return Color.red.opacity(0.2)
            }
        }
        
        return isSelected ? Color(hex: "bd0e1b").opacity(0.3) : Color(hex: "02102b").opacity(0.3)
    }
    
    private var borderColor: Color {
        if showResult {
            if isCorrect {
                return Color.green
            } else if isUserAnswer {
                return Color.red
            }
        }
        
        return isSelected ? Color(hex: "ffbe00") : Color.white.opacity(0.2)
    }
    
    private var textColor: Color {
        if showResult {
            if isCorrect {
                return Color.green
            } else if isUserAnswer {
                return Color.red
            }
        }
        
        return .white
    }
}

struct QuizResultCard: View {
    let result: QuizResult
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Results Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack {
                    Text("\(result.quiz.correctAnswers)")
                        .font(.title2)
                        .foregroundColor(Color(hex: "ffbe00"))
                    
                    Text("Correct")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack {
                    Text("\(result.quiz.questions.count - result.quiz.correctAnswers)")
                        .font(.title2)
                        .foregroundColor(Color.red.opacity(0.8))
                    
                    Text("Incorrect")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack {
                    Text(result.grade)
                        .font(.title2)
                        .foregroundColor(result.isPassed ? Color.green : Color.red)
                    
                    Text("Grade")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
        )
    }
}

struct QuizHistoryPreview: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Quizzes")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.quizResults.isEmpty {
                Text("No quizzes taken yet")
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.quizResults.suffix(3).reversed()), id: \.id) { result in
                        QuizHistoryRow(result: result)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
        )
    }
}

struct QuizHistoryRow: View {
    let result: QuizResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Quiz • \(result.quiz.questions.count) questions")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(DateFormatter.shortDate.string(from: result.completionDate))
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(result.percentage))%")
                    .font(.caption)
                    .foregroundColor(Color(hex: "ffbe00"))
                
                Text(result.grade)
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "02102b").opacity(0.3))
        )
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    QuizView()
}


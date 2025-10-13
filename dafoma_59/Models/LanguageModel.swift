//
//  LanguageModel.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation

// MARK: - Language Model
struct Language: Identifiable, Codable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
    let difficulty: Difficulty
    let totalLessons: Int
    
    enum Difficulty: String, CaseIterable, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }
}

// MARK: - Lesson Model
struct Lesson: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let languageCode: String
    let lessonNumber: Int
    let vocabulary: [VocabularyItem]
    let dialogues: [Dialogue]
    let exercises: [Exercise]
    let isCompleted: Bool
    let difficulty: Language.Difficulty
}

// MARK: - Vocabulary Item
struct VocabularyItem: Identifiable, Codable {
    let id = UUID()
    let word: String
    let translation: String
    let pronunciation: String
    let audioURL: String?
    let example: String
    let exampleTranslation: String
}

// MARK: - Dialogue Model
struct Dialogue: Identifiable, Codable {
    let id = UUID()
    let title: String
    let scenario: String
    let participants: [String]
    let lines: [DialogueLine]
}

struct DialogueLine: Identifiable, Codable {
    let id = UUID()
    let speaker: String
    let text: String
    let translation: String
    let audioURL: String?
}

// MARK: - Exercise Model
struct Exercise: Identifiable, Codable {
    let id = UUID()
    let type: ExerciseType
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let points: Int
    
    enum ExerciseType: String, CaseIterable, Codable {
        case multipleChoice = "Multiple Choice"
        case fillInTheBlank = "Fill in the Blank"
        case translation = "Translation"
        case pronunciation = "Pronunciation"
        case listening = "Listening"
    }
}

// MARK: - Progress Model
struct LearningProgress: Codable {
    var languageCode: String
    var completedLessons: Set<Int>
    var currentStreak: Int
    var totalPoints: Int
    var lastStudyDate: Date?
    var weeklyGoal: Int
    var studyTimeThisWeek: TimeInterval
    
    var completionPercentage: Double {
        guard !completedLessons.isEmpty else { return 0.0 }
        return Double(completedLessons.count) / 50.0 * 100.0 // Assuming 50 lessons per language
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    let isUnlocked: Bool
    let unlockedDate: Date?
    let category: AchievementCategory
    
    enum AchievementCategory: String, CaseIterable, Codable {
        case streak = "Streak"
        case lessons = "Lessons"
        case points = "Points"
        case vocabulary = "Vocabulary"
        case pronunciation = "Pronunciation"
    }
}


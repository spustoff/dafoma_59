//
//  UserModel.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String?
    var profileImageURL: String?
    var dateJoined: Date
    var selectedLanguages: [String] // Language codes
    var nativeLanguage: String
    var learningGoals: LearningGoals
    var preferences: UserPreferences
    var progress: [String: LearningProgress] // Language code -> Progress
    var achievements: [Achievement]
    var statistics: UserStatistics
    
    init(name: String, nativeLanguage: String = "en") {
        self.name = name
        self.dateJoined = Date()
        self.selectedLanguages = []
        self.nativeLanguage = nativeLanguage
        self.learningGoals = LearningGoals()
        self.preferences = UserPreferences()
        self.progress = [:]
        self.achievements = []
        self.statistics = UserStatistics()
    }
}

// MARK: - Learning Goals
struct LearningGoals: Codable {
    var dailyGoalMinutes: Int = 15
    var weeklyGoalLessons: Int = 5
    var targetProficiency: Language.Difficulty = .intermediate
    var reminderTime: Date?
    var isReminderEnabled: Bool = false
    
    enum GoalType: String, CaseIterable, Codable {
        case casual = "Casual Learning"
        case regular = "Regular Practice"
        case intensive = "Intensive Study"
        
        var dailyMinutes: Int {
            switch self {
            case .casual: return 10
            case .regular: return 20
            case .intensive: return 45
            }
        }
        
        var weeklyLessons: Int {
            switch self {
            case .casual: return 3
            case .regular: return 7
            case .intensive: return 14
            }
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var theme: AppTheme = .dark
    var soundEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true
    var autoPlayAudio: Bool = true
    var showTranslations: Bool = true
    var difficultyLevel: Language.Difficulty = .beginner
    var notificationsEnabled: Bool = true
    var dataUsageMode: DataUsageMode = .standard
    
    enum AppTheme: String, CaseIterable, Codable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
    
    enum DataUsageMode: String, CaseIterable, Codable {
        case minimal = "Minimal"
        case standard = "Standard"
        case unlimited = "Unlimited"
    }
}

// MARK: - User Statistics
struct UserStatistics: Codable {
    var totalStudyTime: TimeInterval = 0
    var totalLessonsCompleted: Int = 0
    var totalWordsLearned: Int = 0
    var totalQuizzesTaken: Int = 0
    var averageQuizScore: Double = 0.0
    var longestStreak: Int = 0
    var currentStreak: Int = 0
    var totalPoints: Int = 0
    var rank: UserRank = .novice
    var studyDays: Set<String> = [] // Date strings in "yyyy-MM-dd" format
    
    enum UserRank: String, CaseIterable, Codable {
        case novice = "Novice"
        case apprentice = "Apprentice"
        case scholar = "Scholar"
        case expert = "Expert"
        case master = "Master"
        case grandmaster = "Grandmaster"
        
        var pointsRequired: Int {
            switch self {
            case .novice: return 0
            case .apprentice: return 500
            case .scholar: return 1500
            case .expert: return 3000
            case .master: return 6000
            case .grandmaster: return 10000
            }
        }
        
        var icon: String {
            switch self {
            case .novice: return "star"
            case .apprentice: return "star.fill"
            case .scholar: return "graduationcap"
            case .expert: return "crown"
            case .master: return "crown.fill"
            case .grandmaster: return "sparkles"
            }
        }
    }
    
    mutating func updateRank() {
        let ranks = UserRank.allCases.reversed()
        for rank in ranks {
            if totalPoints >= rank.pointsRequired {
                self.rank = rank
                break
            }
        }
    }
}

// MARK: - Onboarding State
struct OnboardingState: Codable {
    var isCompleted: Bool = false
    var currentStep: Int = 0
    var selectedLanguage: String?
    var selectedGoal: LearningGoals.GoalType?
    var userName: String?
    var nativeLanguage: String = "en"
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case nameInput = 1
        case languageSelection = 2
        case goalSetting = 3
        case preferences = 4
        case completion = 5
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to LinguetaKan!"
            case .nameInput: return "What's your name?"
            case .languageSelection: return "Choose your language"
            case .goalSetting: return "Set your goals"
            case .preferences: return "Customize your experience"
            case .completion: return "You're all set!"
            }
        }
        
        var description: String {
            switch self {
            case .welcome: return "Your journey to language mastery starts here"
            case .nameInput: return "We'd love to know what to call you"
            case .languageSelection: return "Which language would you like to learn?"
            case .goalSetting: return "How often would you like to practice?"
            case .preferences: return "Let's personalize your learning experience"
            case .completion: return "Ready to start your language learning adventure!"
            }
        }
    }
}


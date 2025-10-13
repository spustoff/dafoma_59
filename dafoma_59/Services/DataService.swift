//
//  DataService.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation
import SwiftUI

class DataService: ObservableObject {
    static let shared = DataService()
    
    @Published var availableLanguages: [Language] = []
    @Published var currentUser: User?
    @Published var lessons: [String: [Lesson]] = [:] // Language code -> Lessons
    
    private let userDefaultsKey = "LinguetaKanUser"
    private let onboardingKey = "LinguetaKanOnboarding"
    
    private init() {
        loadUser()
        loadAvailableLanguages()
        loadLessons()
    }
    
    // MARK: - User Management
    func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
    }
    
    func saveUser(_ user: User) {
        self.currentUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userDefaultsKey)
        }
    }
    
    func createUser(name: String, nativeLanguage: String = "en") -> User {
        let user = User(name: name, nativeLanguage: nativeLanguage)
        saveUser(user)
        return user
    }
    
    func deleteUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        self.currentUser = nil
    }
    
    // MARK: - Onboarding Management
    func getOnboardingState() -> OnboardingState {
        if let data = UserDefaults.standard.data(forKey: onboardingKey),
           let state = try? JSONDecoder().decode(OnboardingState.self, from: data) {
            return state
        }
        return OnboardingState()
    }
    
    func saveOnboardingState(_ state: OnboardingState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: onboardingKey)
        }
    }
    
    // MARK: - Language Data
    func loadAvailableLanguages() {
        availableLanguages = [
            Language(name: "Spanish", code: "es", flag: "🇪🇸", difficulty: .beginner, totalLessons: 50),
            Language(name: "French", code: "fr", flag: "🇫🇷", difficulty: .beginner, totalLessons: 50),
            Language(name: "German", code: "de", flag: "🇩🇪", difficulty: .intermediate, totalLessons: 50),
            Language(name: "Italian", code: "it", flag: "🇮🇹", difficulty: .beginner, totalLessons: 50),
            Language(name: "Portuguese", code: "pt", flag: "🇵🇹", difficulty: .beginner, totalLessons: 50),
            Language(name: "Japanese", code: "ja", flag: "🇯🇵", difficulty: .advanced, totalLessons: 75),
            Language(name: "Korean", code: "ko", flag: "🇰🇷", difficulty: .advanced, totalLessons: 75),
            Language(name: "Chinese", code: "zh", flag: "🇨🇳", difficulty: .advanced, totalLessons: 75),
            Language(name: "Russian", code: "ru", flag: "🇷🇺", difficulty: .intermediate, totalLessons: 60),
            Language(name: "Arabic", code: "ar", flag: "🇸🇦", difficulty: .advanced, totalLessons: 75)
        ]
    }
    
    func getLanguage(by code: String) -> Language? {
        return availableLanguages.first { $0.code == code }
    }
    
    // MARK: - Lesson Management
    func loadLessons() {
        // Load sample lessons for each language
        for language in availableLanguages {
            lessons[language.code] = generateSampleLessons(for: language)
        }
    }
    
    func getLessons(for languageCode: String) -> [Lesson] {
        return lessons[languageCode] ?? []
    }
    
    func getLesson(languageCode: String, lessonNumber: Int) -> Lesson? {
        return lessons[languageCode]?.first { $0.lessonNumber == lessonNumber }
    }
    
    // MARK: - Progress Management
    func updateProgress(for languageCode: String, lessonNumber: Int, points: Int) {
        guard var user = currentUser else { return }
        
        if user.progress[languageCode] == nil {
            user.progress[languageCode] = LearningProgress(
                languageCode: languageCode,
                completedLessons: [],
                currentStreak: 0,
                totalPoints: 0,
                weeklyGoal: user.learningGoals.weeklyGoalLessons,
                studyTimeThisWeek: 0
            )
        }
        
        user.progress[languageCode]?.completedLessons.insert(lessonNumber)
        user.progress[languageCode]?.totalPoints += points
        user.progress[languageCode]?.lastStudyDate = Date()
        
        // Update overall statistics
        user.statistics.totalLessonsCompleted += 1
        user.statistics.totalPoints += points
        user.statistics.updateRank()
        
        // Update streak
        updateStreak(for: &user)
        
        saveUser(user)
    }
    
    private func updateStreak(for user: inout User) {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        let yesterdayString = dateFormatter.string(from: yesterday)
        
        user.statistics.studyDays.insert(todayString)
        
        if user.statistics.studyDays.contains(yesterdayString) || user.statistics.currentStreak == 0 {
            user.statistics.currentStreak += 1
        } else {
            user.statistics.currentStreak = 1
        }
        
        if user.statistics.currentStreak > user.statistics.longestStreak {
            user.statistics.longestStreak = user.statistics.currentStreak
        }
    }
    
    // MARK: - Sample Data Generation
    private func generateSampleLessons(for language: Language) -> [Lesson] {
        let lessonsCount = min(10, language.totalLessons) // Generate first 10 lessons
        var generatedLessons: [Lesson] = []
        
        for i in 1...lessonsCount {
            let lesson = generateSampleLesson(for: language, lessonNumber: i)
            generatedLessons.append(lesson)
        }
        
        return generatedLessons
    }
    
    private func generateSampleLesson(for language: Language, lessonNumber: Int) -> Lesson {
        let vocabulary = generateVocabulary(for: language, lessonNumber: lessonNumber)
        let dialogues = generateDialogues(for: language, lessonNumber: lessonNumber)
        let exercises = generateExercises(for: language, vocabulary: vocabulary)
        
        return Lesson(
            title: "Lesson \(lessonNumber): \(getLessonTitle(for: language, lessonNumber: lessonNumber))",
            description: getLessonDescription(for: language, lessonNumber: lessonNumber),
            languageCode: language.code,
            lessonNumber: lessonNumber,
            vocabulary: vocabulary,
            dialogues: dialogues,
            exercises: exercises,
            isCompleted: false,
            difficulty: lessonNumber <= 3 ? .beginner : lessonNumber <= 7 ? .intermediate : .advanced
        )
    }
    
    private func getLessonTitle(for language: Language, lessonNumber: Int) -> String {
        let titles = [
            "Basic Greetings", "Introducing Yourself", "Numbers and Time",
            "Family and Friends", "Food and Drinks", "Shopping and Money",
            "Directions and Transportation", "Weather and Seasons", "Hobbies and Interests",
            "Travel and Accommodation"
        ]
        return titles[min(lessonNumber - 1, titles.count - 1)]
    }
    
    private func getLessonDescription(for language: Language, lessonNumber: Int) -> String {
        let descriptions = [
            "Learn essential greetings and polite expressions",
            "Master self-introduction and personal information",
            "Practice numbers, telling time, and dates",
            "Describe family relationships and friendships",
            "Order food and discuss dietary preferences",
            "Navigate shopping situations and handle money",
            "Ask for directions and use public transportation",
            "Discuss weather conditions and seasonal activities",
            "Talk about your interests and free time activities",
            "Plan trips and communicate at hotels"
        ]
        return descriptions[min(lessonNumber - 1, descriptions.count - 1)]
    }
    
    private func generateVocabulary(for language: Language, lessonNumber: Int) -> [VocabularyItem] {
        // Sample vocabulary based on language and lesson
        switch language.code {
        case "es": return generateSpanishVocabulary(lessonNumber: lessonNumber)
        case "fr": return generateFrenchVocabulary(lessonNumber: lessonNumber)
        case "de": return generateGermanVocabulary(lessonNumber: lessonNumber)
        default: return generateDefaultVocabulary(lessonNumber: lessonNumber)
        }
    }
    
    private func generateSpanishVocabulary(lessonNumber: Int) -> [VocabularyItem] {
        switch lessonNumber {
        case 1:
            return [
                VocabularyItem(word: "Hola", translation: "Hello", pronunciation: "OH-lah", audioURL: nil, example: "Hola, ¿cómo estás?", exampleTranslation: "Hello, how are you?"),
                VocabularyItem(word: "Gracias", translation: "Thank you", pronunciation: "GRAH-see-ahs", audioURL: nil, example: "Gracias por tu ayuda", exampleTranslation: "Thank you for your help"),
                VocabularyItem(word: "Por favor", translation: "Please", pronunciation: "por fah-VOR", audioURL: nil, example: "Un café, por favor", exampleTranslation: "A coffee, please"),
                VocabularyItem(word: "Adiós", translation: "Goodbye", pronunciation: "ah-DYOHS", audioURL: nil, example: "Adiós, hasta mañana", exampleTranslation: "Goodbye, see you tomorrow"),
                VocabularyItem(word: "Disculpe", translation: "Excuse me", pronunciation: "dees-KOOL-peh", audioURL: nil, example: "Disculpe, ¿dónde está el baño?", exampleTranslation: "Excuse me, where is the bathroom?")
            ]
        default:
            return [
                VocabularyItem(word: "Buenos días", translation: "Good morning", pronunciation: "BWAY-nohs DEE-ahs", audioURL: nil, example: "Buenos días, señora", exampleTranslation: "Good morning, ma'am"),
                VocabularyItem(word: "Buenas tardes", translation: "Good afternoon", pronunciation: "BWAY-nahs TAR-dehs", audioURL: nil, example: "Buenas tardes, doctor", exampleTranslation: "Good afternoon, doctor")
            ]
        }
    }
    
    private func generateFrenchVocabulary(lessonNumber: Int) -> [VocabularyItem] {
        switch lessonNumber {
        case 1:
            return [
                VocabularyItem(word: "Bonjour", translation: "Hello", pronunciation: "bon-ZHOOR", audioURL: nil, example: "Bonjour, comment allez-vous?", exampleTranslation: "Hello, how are you?"),
                VocabularyItem(word: "Merci", translation: "Thank you", pronunciation: "mer-SEE", audioURL: nil, example: "Merci beaucoup", exampleTranslation: "Thank you very much"),
                VocabularyItem(word: "S'il vous plaît", translation: "Please", pronunciation: "seel voo PLEH", audioURL: nil, example: "Un café, s'il vous plaît", exampleTranslation: "A coffee, please"),
                VocabularyItem(word: "Au revoir", translation: "Goodbye", pronunciation: "oh ruh-VWAR", audioURL: nil, example: "Au revoir, à bientôt", exampleTranslation: "Goodbye, see you soon"),
                VocabularyItem(word: "Excusez-moi", translation: "Excuse me", pronunciation: "ek-skew-zay MWAH", audioURL: nil, example: "Excusez-moi, où sont les toilettes?", exampleTranslation: "Excuse me, where are the restrooms?")
            ]
        default:
            return [
                VocabularyItem(word: "Bonsoir", translation: "Good evening", pronunciation: "bon-SWAHR", audioURL: nil, example: "Bonsoir, madame", exampleTranslation: "Good evening, ma'am")
            ]
        }
    }
    
    private func generateGermanVocabulary(lessonNumber: Int) -> [VocabularyItem] {
        switch lessonNumber {
        case 1:
            return [
                VocabularyItem(word: "Hallo", translation: "Hello", pronunciation: "HAH-loh", audioURL: nil, example: "Hallo, wie geht es dir?", exampleTranslation: "Hello, how are you?"),
                VocabularyItem(word: "Danke", translation: "Thank you", pronunciation: "DAHN-keh", audioURL: nil, example: "Danke schön", exampleTranslation: "Thank you very much"),
                VocabularyItem(word: "Bitte", translation: "Please", pronunciation: "BIT-teh", audioURL: nil, example: "Ein Kaffee, bitte", exampleTranslation: "A coffee, please"),
                VocabularyItem(word: "Auf Wiedersehen", translation: "Goodbye", pronunciation: "owf VEE-der-zayn", audioURL: nil, example: "Auf Wiedersehen, bis morgen", exampleTranslation: "Goodbye, see you tomorrow"),
                VocabularyItem(word: "Entschuldigung", translation: "Excuse me", pronunciation: "ent-SHOOL-dee-goong", audioURL: nil, example: "Entschuldigung, wo ist die Toilette?", exampleTranslation: "Excuse me, where is the restroom?")
            ]
        default:
            return [
                VocabularyItem(word: "Guten Morgen", translation: "Good morning", pronunciation: "GOO-ten MOR-gen", audioURL: nil, example: "Guten Morgen, Herr Schmidt", exampleTranslation: "Good morning, Mr. Schmidt")
            ]
        }
    }
    
    private func generateDefaultVocabulary(lessonNumber: Int) -> [VocabularyItem] {
        return [
            VocabularyItem(word: "Hello", translation: "Hello", pronunciation: "heh-LOH", audioURL: nil, example: "Hello, how are you?", exampleTranslation: "Hello, how are you?"),
            VocabularyItem(word: "Thank you", translation: "Thank you", pronunciation: "THANK you", audioURL: nil, example: "Thank you for your help", exampleTranslation: "Thank you for your help")
        ]
    }
    
    private func generateDialogues(for language: Language, lessonNumber: Int) -> [Dialogue] {
        let dialogue = Dialogue(
            title: "Basic Conversation",
            scenario: "Meeting someone for the first time",
            participants: ["Alex", "Maria"],
            lines: [
                DialogueLine(speaker: "Alex", text: getGreeting(for: language.code), translation: "Hello!", audioURL: nil),
                DialogueLine(speaker: "Maria", text: getGreetingResponse(for: language.code), translation: "Hello! How are you?", audioURL: nil),
                DialogueLine(speaker: "Alex", text: getWellResponse(for: language.code), translation: "I'm fine, thank you. And you?", audioURL: nil),
                DialogueLine(speaker: "Maria", text: getWellToo(for: language.code), translation: "I'm well too, thanks!", audioURL: nil)
            ]
        )
        return [dialogue]
    }
    
    private func getGreeting(for languageCode: String) -> String {
        switch languageCode {
        case "es": return "¡Hola!"
        case "fr": return "Bonjour!"
        case "de": return "Hallo!"
        case "it": return "Ciao!"
        case "pt": return "Olá!"
        default: return "Hello!"
        }
    }
    
    private func getGreetingResponse(for languageCode: String) -> String {
        switch languageCode {
        case "es": return "¡Hola! ¿Cómo estás?"
        case "fr": return "Bonjour! Comment allez-vous?"
        case "de": return "Hallo! Wie geht es dir?"
        case "it": return "Ciao! Come stai?"
        case "pt": return "Olá! Como está?"
        default: return "Hello! How are you?"
        }
    }
    
    private func getWellResponse(for languageCode: String) -> String {
        switch languageCode {
        case "es": return "Estoy bien, gracias. ¿Y tú?"
        case "fr": return "Je vais bien, merci. Et vous?"
        case "de": return "Mir geht es gut, danke. Und dir?"
        case "it": return "Sto bene, grazie. E tu?"
        case "pt": return "Estou bem, obrigado. E você?"
        default: return "I'm fine, thank you. And you?"
        }
    }
    
    private func getWellToo(for languageCode: String) -> String {
        switch languageCode {
        case "es": return "¡Yo también estoy bien, gracias!"
        case "fr": return "Je vais bien aussi, merci!"
        case "de": return "Mir geht es auch gut, danke!"
        case "it": return "Anch'io sto bene, grazie!"
        case "pt": return "Eu também estou bem, obrigada!"
        default: return "I'm well too, thanks!"
        }
    }
    
    private func generateExercises(for language: Language, vocabulary: [VocabularyItem]) -> [Exercise] {
        var exercises: [Exercise] = []
        
        // Multiple choice exercise
        if let firstWord = vocabulary.first {
            exercises.append(Exercise(
                type: .multipleChoice,
                question: "What does '\(firstWord.word)' mean?",
                options: [firstWord.translation, "Goodbye", "Please", "Thank you"],
                correctAnswer: firstWord.translation,
                explanation: "'\(firstWord.word)' means '\(firstWord.translation)' in English.",
                points: 10
            ))
        }
        
        // Translation exercise
        if vocabulary.count > 1 {
            let secondWord = vocabulary[1]
            exercises.append(Exercise(
                type: .translation,
                question: "How do you say '\(secondWord.translation)' in \(language.name)?",
                options: [secondWord.word, vocabulary.first?.word ?? "", "incorrect", "wrong"],
                correctAnswer: secondWord.word,
                explanation: "'\(secondWord.translation)' is '\(secondWord.word)' in \(language.name).",
                points: 15
            ))
        }
        
        return exercises
    }
}


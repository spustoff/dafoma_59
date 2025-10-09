//
//  LanguageViewModel.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation
import SwiftUI
import AVFoundation

class LanguageViewModel: ObservableObject {
    @Published var selectedLanguage: Language?
    @Published var currentLesson: Lesson?
    @Published var lessons: [Lesson] = []
    @Published var currentVocabularyIndex = 0
    @Published var currentDialogueIndex = 0
    @Published var currentDialogueLineIndex = 0
    @Published var isPlayingAudio = false
    @Published var showTranslations = true
    @Published var lessonProgress: Double = 0.0
    @Published var isLessonCompleted = false
    @Published var earnedPoints = 0
    
    private let dataService = DataService.shared
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        loadUserLanguages()
    }
    
    // MARK: - Language Management
    func loadUserLanguages() {
        guard let user = dataService.currentUser else { return }
        
        if let firstLanguageCode = user.selectedLanguages.first {
            selectLanguage(code: firstLanguageCode)
        }
    }
    
    func selectLanguage(code: String) {
        selectedLanguage = dataService.getLanguage(by: code)
        loadLessons(for: code)
    }
    
    func loadLessons(for languageCode: String) {
        lessons = dataService.getLessons(for: languageCode)
    }
    
    // MARK: - Lesson Management
    func startLesson(_ lesson: Lesson) {
        currentLesson = lesson
        currentVocabularyIndex = 0
        currentDialogueIndex = 0
        currentDialogueLineIndex = 0
        lessonProgress = 0.0
        isLessonCompleted = false
        earnedPoints = 0
        
        updateProgress()
    }
    
    func completeLesson() {
        guard let lesson = currentLesson,
              let language = selectedLanguage else { return }
        
        isLessonCompleted = true
        earnedPoints = calculateLessonPoints(lesson)
        
        // Update user progress
        dataService.updateProgress(for: language.code, lessonNumber: lesson.lessonNumber, points: earnedPoints)
        
        // Mark lesson as completed in local array
        if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
            lessons[index] = Lesson(
                title: lesson.title,
                description: lesson.description,
                languageCode: lesson.languageCode,
                lessonNumber: lesson.lessonNumber,
                vocabulary: lesson.vocabulary,
                dialogues: lesson.dialogues,
                exercises: lesson.exercises,
                isCompleted: true,
                difficulty: lesson.difficulty
            )
        }
    }
    
    private func calculateLessonPoints(_ lesson: Lesson) -> Int {
        let basePoints = 50
        let vocabularyBonus = lesson.vocabulary.count * 5
        let dialogueBonus = lesson.dialogues.count * 10
        let exerciseBonus = lesson.exercises.reduce(0) { $0 + $1.points }
        
        return basePoints + vocabularyBonus + dialogueBonus + exerciseBonus
    }
    
    // MARK: - Vocabulary Navigation
    func nextVocabularyItem() {
        guard let lesson = currentLesson else { return }
        
        if currentVocabularyIndex < lesson.vocabulary.count - 1 {
            currentVocabularyIndex += 1
        } else {
            // Move to dialogues section
            currentVocabularyIndex = 0
            if !lesson.dialogues.isEmpty {
                currentDialogueIndex = 0
                currentDialogueLineIndex = 0
            }
        }
        
        updateProgress()
    }
    
    func previousVocabularyItem() {
        if currentVocabularyIndex > 0 {
            currentVocabularyIndex -= 1
            updateProgress()
        }
    }
    
    func getCurrentVocabularyItem() -> VocabularyItem? {
        guard let lesson = currentLesson,
              currentVocabularyIndex < lesson.vocabulary.count else { return nil }
        
        return lesson.vocabulary[currentVocabularyIndex]
    }
    
    // MARK: - Dialogue Navigation
    func nextDialogueLine() {
        guard let lesson = currentLesson,
              currentDialogueIndex < lesson.dialogues.count else { return }
        
        let currentDialogue = lesson.dialogues[currentDialogueIndex]
        
        if currentDialogueLineIndex < currentDialogue.lines.count - 1 {
            currentDialogueLineIndex += 1
        } else if currentDialogueIndex < lesson.dialogues.count - 1 {
            currentDialogueIndex += 1
            currentDialogueLineIndex = 0
        } else {
            // Dialogue section completed
            completeLesson()
        }
        
        updateProgress()
    }
    
    func previousDialogueLine() {
        if currentDialogueLineIndex > 0 {
            currentDialogueLineIndex -= 1
        } else if currentDialogueIndex > 0 {
            currentDialogueIndex -= 1
            if let lesson = currentLesson,
               currentDialogueIndex < lesson.dialogues.count {
                currentDialogueLineIndex = lesson.dialogues[currentDialogueIndex].lines.count - 1
            }
        }
        
        updateProgress()
    }
    
    func getCurrentDialogueLine() -> DialogueLine? {
        guard let lesson = currentLesson,
              currentDialogueIndex < lesson.dialogues.count else { return nil }
        
        let dialogue = lesson.dialogues[currentDialogueIndex]
        guard currentDialogueLineIndex < dialogue.lines.count else { return nil }
        
        return dialogue.lines[currentDialogueLineIndex]
    }
    
    func getCurrentDialogue() -> Dialogue? {
        guard let lesson = currentLesson,
              currentDialogueIndex < lesson.dialogues.count else { return nil }
        
        return lesson.dialogues[currentDialogueIndex]
    }
    
    // MARK: - Audio & Speech
    func playVocabularyAudio(for item: VocabularyItem) {
        speakText(item.word, languageCode: selectedLanguage?.code ?? "en")
    }
    
    func playDialogueAudio(for line: DialogueLine) {
        speakText(line.text, languageCode: selectedLanguage?.code ?? "en")
    }
    
    private func speakText(_ text: String, languageCode: String) {
        guard !isPlayingAudio else { return }
        
        isPlayingAudio = true
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = 0.5 // Slower rate for learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
        
        // Reset playing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.1 + 1.0) {
            self.isPlayingAudio = false
        }
    }
    
    func stopAudio() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isPlayingAudio = false
    }
    
    // MARK: - Progress Tracking
    private func updateProgress() {
        guard let lesson = currentLesson else { return }
        
        let totalItems = lesson.vocabulary.count + lesson.dialogues.reduce(0) { $0 + $1.lines.count }
        guard totalItems > 0 else { return }
        
        let completedVocabulary = currentVocabularyIndex
        let completedDialogueLines = lesson.dialogues.prefix(currentDialogueIndex).reduce(0) { $0 + $1.lines.count } + currentDialogueLineIndex
        
        let completedItems = completedVocabulary + completedDialogueLines
        lessonProgress = Double(completedItems) / Double(totalItems)
    }
    
    // MARK: - User Progress
    func getUserProgress(for languageCode: String) -> LearningProgress? {
        return dataService.currentUser?.progress[languageCode]
    }
    
    func getCompletedLessonsCount(for languageCode: String) -> Int {
        return getUserProgress(for: languageCode)?.completedLessons.count ?? 0
    }
    
    func isLessonCompleted(_ lessonNumber: Int, for languageCode: String) -> Bool {
        return getUserProgress(for: languageCode)?.completedLessons.contains(lessonNumber) ?? false
    }
    
    func getNextLesson(for languageCode: String) -> Lesson? {
        let completedLessons = getUserProgress(for: languageCode)?.completedLessons ?? []
        let availableLessons = dataService.getLessons(for: languageCode)
        
        return availableLessons.first { !completedLessons.contains($0.lessonNumber) }
    }
    
    // MARK: - Settings
    func toggleTranslations() {
        showTranslations.toggle()
        
        // Save to user preferences
        if var user = dataService.currentUser {
            user.preferences.showTranslations = showTranslations
            dataService.saveUser(user)
        }
    }
    
    func updateAudioSettings(_ enabled: Bool) {
        if var user = dataService.currentUser {
            user.preferences.autoPlayAudio = enabled
            dataService.saveUser(user)
        }
    }
    
    // MARK: - Statistics
    func getLanguageStatistics(for languageCode: String) -> LanguageStatistics {
        let progress = getUserProgress(for: languageCode)
        let totalLessons = dataService.getLanguage(by: languageCode)?.totalLessons ?? 0
        
        return LanguageStatistics(
            languageCode: languageCode,
            totalLessons: totalLessons,
            completedLessons: progress?.completedLessons.count ?? 0,
            totalPoints: progress?.totalPoints ?? 0,
            currentStreak: progress?.currentStreak ?? 0,
            studyTimeThisWeek: progress?.studyTimeThisWeek ?? 0,
            completionPercentage: progress?.completionPercentage ?? 0.0
        )
    }
}

// MARK: - Statistics Model
struct LanguageStatistics {
    let languageCode: String
    let totalLessons: Int
    let completedLessons: Int
    let totalPoints: Int
    let currentStreak: Int
    let studyTimeThisWeek: TimeInterval
    let completionPercentage: Double
    
    var averagePointsPerLesson: Double {
        guard completedLessons > 0 else { return 0.0 }
        return Double(totalPoints) / Double(completedLessons)
    }
    
    var estimatedTimeToComplete: TimeInterval {
        guard completedLessons > 0, studyTimeThisWeek > 0 else { return 0 }
        
        let averageTimePerLesson = studyTimeThisWeek / Double(completedLessons)
        let remainingLessons = totalLessons - completedLessons
        
        return averageTimePerLesson * Double(remainingLessons)
    }
    
    var proficiencyLevel: String {
        switch completionPercentage {
        case 0..<20: return "Beginner"
        case 20..<50: return "Elementary"
        case 50..<75: return "Intermediate"
        case 75..<90: return "Advanced"
        case 90...100: return "Expert"
        default: return "Beginner"
        }
    }
}

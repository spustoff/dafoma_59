//
//  LessonDetailView.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    @ObservedObject var viewModel: LanguageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentSection = 0 // 0: vocabulary, 1: dialogue, 2: exercises
    @State private var currentVocabularyIndex = 0
    @State private var currentDialogueIndex = 0
    @State private var currentDialogueLineIndex = 0
    @State private var lessonProgress: Double = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "02102b")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Progress Bar
                    ProgressBarView(progress: lessonProgress)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 15)
                    
                    // Content
                    contentView
                    
                    // Navigation Controls
                    navigationControls
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .onAppear {
            initializeLesson()
        }
    }
    
    private func initializeLesson() {
        // Initialize local state
        currentVocabularyIndex = 0
        currentDialogueIndex = 0
        currentDialogueLineIndex = 0
        lessonProgress = 0.0
        
        // Set the current lesson in viewModel
        viewModel.currentLesson = lesson
        
        // Ensure language is selected
        if viewModel.selectedLanguage?.code != lesson.languageCode {
            viewModel.selectLanguage(code: lesson.languageCode)
        }
        
        updateProgress()
    }
    
    private func updateProgress() {
        let totalItems = lesson.vocabulary.count + lesson.dialogues.reduce(0) { $0 + $1.lines.count }
        guard totalItems > 0 else { return }
        
        let completedVocabulary = currentVocabularyIndex
        let completedDialogueLines = lesson.dialogues.prefix(currentDialogueIndex).reduce(0) { $0 + $1.lines.count } + currentDialogueLineIndex
        
        let completedItems = completedVocabulary + completedDialogueLines
        lessonProgress = Double(completedItems) / Double(totalItems)
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack {
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(sectionTitle)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.toggleTranslations()
                }) {
                    Image(systemName: viewModel.showTranslations ? "eye.fill" : "eye.slash.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "ffbe00"))
                }
            }
            
            // Section Indicator
            HStack(spacing: 20) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentSection >= index ? Color(hex: "ffbe00") : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    private var sectionTitle: String {
        switch currentSection {
        case 0: 
            return "Vocabulary (\(currentVocabularyIndex + 1)/\(lesson.vocabulary.count))"
        case 1: 
            return "Dialogue (\(currentDialogueIndex + 1)/\(lesson.dialogues.count))"
        case 2: return "Practice"
        default: return ""
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch currentSection {
                case 0:
                    vocabularyContent
                case 1:
                    dialogueContent
                case 2:
                    exerciseContent
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private var vocabularyContent: some View {
        VStack(spacing: 20) {
            if !lesson.vocabulary.isEmpty {
                let safeIndex = max(0, min(currentVocabularyIndex, lesson.vocabulary.count - 1))
                let item = lesson.vocabulary[safeIndex]
                VocabularyDetailCard(item: item, viewModel: viewModel)
            } else {
                Text("No vocabulary available")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(.vertical, 50)
            }
        }
    }
    
    private var dialogueContent: some View {
        VStack(spacing: 20) {
            if !lesson.dialogues.isEmpty {
                let safeIndex = max(0, min(currentDialogueIndex, lesson.dialogues.count - 1))
                let dialogue = lesson.dialogues[safeIndex]
                DialogueDetailView(
                    dialogue: dialogue, 
                    currentLineIndex: $currentDialogueLineIndex,
                    viewModel: viewModel
                )
            } else {
                Text("No dialogue available")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(.vertical, 50)
            }
        }
    }
    
    private var exerciseContent: some View {
        VStack(spacing: 20) {
            Text("🎉 Great Job!")
                .font(.largeTitle)
                .foregroundColor(Color(hex: "ffbe00"))
            
            Text("You've completed the lesson!")
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if viewModel.isLessonCompleted {
                VStack(spacing: 15) {
                    Text("Points Earned: \(viewModel.earnedPoints)")
                        .font(.headline)
                        .foregroundColor(Color(hex: "ffbe00"))
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Continue Learning")
                            .font(.headline)
                            .foregroundColor(Color(hex: "02102b"))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(hex: "ffbe00"))
                            )
                    }
                }
                .padding(.top, 20)
            }
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 20) {
            Button(action: previousAction) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "0a1a3b"))
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)
                        .shadow(color: Color.white.opacity(0.1), radius: 4, x: -2, y: -2)
                )
            }
            .disabled(!canGoPrevious)
            .opacity(canGoPrevious ? 1.0 : 0.5)
            
            Spacer()
            
            Button(action: nextAction) {
                HStack {
                    Text(nextButtonTitle)
                    Image(systemName: "chevron.right")
                }
                .font(.headline)
                .foregroundColor(Color(hex: "02102b"))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "ffbe00"))
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)
                        .shadow(color: Color.white.opacity(0.1), radius: 4, x: -2, y: -2)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private var canGoPrevious: Bool {
        switch currentSection {
        case 0: return currentVocabularyIndex > 0
        case 1: return currentDialogueIndex > 0 || currentDialogueLineIndex > 0
        case 2: return true
        default: return false
        }
    }
    
    private var nextButtonTitle: String {
        switch currentSection {
        case 0:
            if currentVocabularyIndex < lesson.vocabulary.count - 1 {
                return "Next"
            } else {
                return lesson.dialogues.isEmpty ? "Complete" : "Dialogue"
            }
        case 1:
            if !lesson.dialogues.isEmpty && currentDialogueIndex < lesson.dialogues.count {
                let dialogue = lesson.dialogues[currentDialogueIndex]
                if currentDialogueLineIndex < dialogue.lines.count - 1 ||
                   currentDialogueIndex < lesson.dialogues.count - 1 {
                    return "Next"
                } else {
                    return "Complete"
                }
            } else {
                return "Complete"
            }
        case 2:
            return "Finish"
        default:
            return "Next"
        }
    }
    
    private func previousAction() {
        switch currentSection {
        case 0:
            if currentVocabularyIndex > 0 {
                currentVocabularyIndex -= 1
                updateProgress()
            }
        case 1:
            if currentDialogueLineIndex > 0 {
                currentDialogueLineIndex -= 1
            } else if currentDialogueIndex > 0 {
                currentDialogueIndex -= 1
                if !lesson.dialogues.isEmpty && currentDialogueIndex < lesson.dialogues.count {
                    currentDialogueLineIndex = lesson.dialogues[currentDialogueIndex].lines.count - 1
                }
            }
            updateProgress()
        case 2:
            currentSection = lesson.dialogues.isEmpty ? 0 : 1
        default:
            break
        }
    }
    
    private func nextAction() {
        switch currentSection {
        case 0:
            if currentVocabularyIndex < lesson.vocabulary.count - 1 {
                currentVocabularyIndex += 1
                updateProgress()
            } else {
                currentSection = lesson.dialogues.isEmpty ? 2 : 1
                if currentSection == 2 {
                    viewModel.completeLesson()
                }
            }
        case 1:
            if !lesson.dialogues.isEmpty && currentDialogueIndex < lesson.dialogues.count {
                let currentDialogue = lesson.dialogues[currentDialogueIndex]
                if currentDialogueLineIndex < currentDialogue.lines.count - 1 {
                    currentDialogueLineIndex += 1
                } else if currentDialogueIndex < lesson.dialogues.count - 1 {
                    currentDialogueIndex += 1
                    currentDialogueLineIndex = 0
                } else {
                    currentSection = 2
                    viewModel.completeLesson()
                }
                updateProgress()
            }
        case 2:
            dismiss()
        default:
            break
        }
    }
}

// MARK: - Supporting Views

struct VocabularyDetailCard: View {
    let item: VocabularyItem
    @ObservedObject var viewModel: LanguageViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            // Main Word
            VStack(spacing: 15) {
                HStack {
                    Text(item.word)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        viewModel.playVocabularyAudio(for: item)
                    }) {
                        Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "ffbe00"))
                    }
                }
                
                Text(item.pronunciation)
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.8))
                    .italic()
                
                Text(item.translation)
                    .font(.title2)
                    .foregroundColor(Color(hex: "ffbe00"))
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0a1a3b"))
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 6, y: 6)
                    .shadow(color: Color.white.opacity(0.1), radius: 12, x: -6, y: -6)
            )
            
            // Example
            VStack(alignment: .leading, spacing: 10) {
                Text("Example")
                    .font(.headline)
                    .foregroundColor(Color(hex: "ffbe00"))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.example)
                        .font(.body)
                        .foregroundColor(.white)
                    
                    if viewModel.showTranslations {
                        Text(item.exampleTranslation)
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.7))
                            .italic()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "02102b").opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct DialogueDetailView: View {
    let dialogue: Dialogue
    @Binding var currentLineIndex: Int
    @ObservedObject var viewModel: LanguageViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Dialogue Header
            VStack(spacing: 10) {
                Text(dialogue.title)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(dialogue.scenario)
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "0a1a3b"))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
            )
            
            // Current Dialogue Line
            if !dialogue.lines.isEmpty {
                let safeIndex = max(0, min(currentLineIndex, dialogue.lines.count - 1))
                let currentLine = dialogue.lines[safeIndex]
                DialogueLineDetailView(line: currentLine, viewModel: viewModel)
            }
            
            // All Dialogue Lines (for context)
            VStack(spacing: 10) {
                Text("Full Conversation")
                    .font(.headline)
                    .foregroundColor(Color(hex: "ffbe00"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(Array(dialogue.lines.enumerated()), id: \.element.id) { index, line in
                    DialogueContextLine(
                        line: line,
                        isCurrentLine: index == currentLineIndex,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "02102b").opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct DialogueLineDetailView: View {
    let line: DialogueLine
    @ObservedObject var viewModel: LanguageViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Speaker
            HStack {
                Circle()
                    .fill(Color(hex: "bd0e1b"))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(line.speaker.prefix(1)))
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(line.speaker)
                        .font(.headline)
                        .foregroundColor(Color(hex: "ffbe00"))
                    
                    Text("Speaking...")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.playDialogueAudio(for: line)
                }) {
                    Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title)
                        .foregroundColor(Color(hex: "ffbe00"))
                }
            }
            
            // Dialogue Text
            VStack(spacing: 15) {
                Text(line.text)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if viewModel.showTranslations {
                    Text(line.translation)
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.7))
                        .italic()
                        .multilineTextAlignment(.center)
                }
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

struct DialogueContextLine: View {
    let line: DialogueLine
    let isCurrentLine: Bool
    @ObservedObject var viewModel: LanguageViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isCurrentLine ? Color(hex: "ffbe00") : Color(hex: "bd0e1b"))
                .frame(width: 25, height: 25)
                .overlay(
                    Text(String(line.speaker.prefix(1)))
                        .font(.caption2)
                        .foregroundColor(isCurrentLine ? Color(hex: "02102b") : .white)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(line.speaker)
                    .font(.caption)
                    .foregroundColor(isCurrentLine ? Color(hex: "ffbe00") : Color.white.opacity(0.8))
                
                Text(line.text)
                    .font(.caption)
                    .foregroundColor(isCurrentLine ? .white : Color.white.opacity(0.6))
                
                if viewModel.showTranslations {
                    Text(line.translation)
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.5))
                        .italic()
                }
            }
            
            Spacer()
        }
        .opacity(isCurrentLine ? 1.0 : 0.6)
        .scaleEffect(isCurrentLine ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isCurrentLine)
    }
}

#Preview {
    LessonDetailView(
        lesson: Lesson(
            title: "Basic Greetings",
            description: "Learn essential greetings",
            languageCode: "es",
            lessonNumber: 1,
            vocabulary: [
                VocabularyItem(
                    word: "Hola",
                    translation: "Hello",
                    pronunciation: "OH-lah",
                    audioURL: nil,
                    example: "Hola, ¿cómo estás?",
                    exampleTranslation: "Hello, how are you?"
                )
            ],
            dialogues: [
                Dialogue(
                    title: "Basic Greeting",
                    scenario: "Meeting someone",
                    participants: ["Alex", "Maria"],
                    lines: [
                        DialogueLine(
                            speaker: "Alex",
                            text: "Hola",
                            translation: "Hello",
                            audioURL: nil
                        )
                    ]
                )
            ],
            exercises: [],
            isCompleted: false,
            difficulty: .beginner
        ),
        viewModel: LanguageViewModel()
    )
}


//
//  LanguageLearningView.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import SwiftUI

struct LanguageLearningView: View {
    @StateObject private var viewModel = LanguageViewModel()
    @State private var selectedTab = 0
    @State private var showLessonDetail = false
    @State private var selectedLesson: Lesson?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "02102b")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        dialoguesView
                            .tag(0)
                        
                        progressView
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadUserLanguages()
        }
        .sheet(isPresented: $showLessonDetail) {
            if let lesson = selectedLesson {
                LessonDetailView(lesson: lesson, viewModel: viewModel)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            HStack {
                if let language = viewModel.selectedLanguage {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Learning \(language.name)")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        if let progress = viewModel.getUserProgress(for: language.code) {
                            Text("\(progress.completedLessons.count) lessons completed")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Text(language.flag)
                        .font(.system(size: 40))
                }
            }
            
            // Progress Bar
            if let language = viewModel.selectedLanguage,
               let progress = viewModel.getUserProgress(for: language.code) {
                ProgressBarView(progress: progress.completionPercentage / 100.0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 5) {
                        Image(systemName: tabIcon(for: index))
                            .font(.title2)
                        
                        Text(tabTitle(for: index))
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == index ? Color(hex: "ffbe00") : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "book.fill"
        case 1: return "bubble.left.and.bubble.right.fill"
        case 2: return "chart.bar.fill"
        default: return "circle"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Lessons"
        case 1: return "Dialogues"
        case 2: return "Progress"
        default: return ""
        }
    }
    
    // MARK: - Lessons View
    private var lessonsView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(viewModel.lessons) { lesson in
                    LessonCard(
                        lesson: lesson,
                        isCompleted: viewModel.isLessonCompleted(lesson.lessonNumber, for: lesson.languageCode)
                    ) {
                        selectedLesson = lesson
                        showLessonDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
    
    
    // MARK: - Dialogues View
    private var dialoguesView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(viewModel.lessons) { lesson in
                    ForEach(lesson.dialogues) { dialogue in
                        DialogueCard(dialogue: dialogue, viewModel: viewModel)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let language = viewModel.selectedLanguage {
                    let stats = viewModel.getLanguageStatistics(for: language.code)
                    
                    // Statistics Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        StatCard(title: "Lessons", value: "\(stats.completedLessons)", subtitle: "of \(stats.totalLessons)")
                        StatCard(title: "Points", value: "\(stats.totalPoints)", subtitle: "earned")
                        StatCard(title: "Streak", value: "\(stats.currentStreak)", subtitle: "days")
                        StatCard(title: "Level", value: stats.proficiencyLevel, subtitle: "")
                    }
                    
                    // Weekly Progress
                    WeeklyProgressView(stats: stats)
                    
                    // Achievements Preview
                    AchievementsPreview()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Supporting Views

struct LessonCard: View {
    let lesson: Lesson
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Lesson Number
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color(hex: "ffbe00") : Color(hex: "0a1a3b"))
                        .frame(width: 50, height: 50)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(hex: "02102b"))
                            .font(.title2)
                    } else {
                        Text("\(lesson.lessonNumber)")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                
                // Lesson Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(lesson.description)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack {
                        DifficultyBadge(difficulty: lesson.difficulty)
                        
                        Spacer()
                        
                        Text("\(lesson.vocabulary.count) words")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.white.opacity(0.5))
                    .font(.caption)
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct VocabularySection: View {
    let lesson: Lesson
    let viewModel: LanguageViewModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color.white.opacity(0.7))
                        .font(.caption)
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
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(lesson.vocabulary) { item in
                        VocabularyItemView(item: item, viewModel: viewModel)
                    }
                }
                .padding(.top, 5)
            }
        }
    }
}

struct VocabularyItemView: View {
    let item: VocabularyItem
    let viewModel: LanguageViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(item.word)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        viewModel.playVocabularyAudio(for: item)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(Color(hex: "ffbe00"))
                            .font(.caption)
                    }
                }
                
                Text(item.translation)
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.8))
                
                Text(item.pronunciation)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                    .italic()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "02102b").opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct DialogueCard: View {
    let dialogue: Dialogue
    let viewModel: LanguageViewModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(dialogue.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(dialogue.scenario)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color.white.opacity(0.7))
                        .font(.caption)
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
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(dialogue.lines) { line in
                        DialogueLineView(line: line, viewModel: viewModel)
                    }
                }
                .padding(.top, 5)
            }
        }
    }
}

struct DialogueLineView: View {
    let line: DialogueLine
    let viewModel: LanguageViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Speaker Avatar
            Circle()
                .fill(Color(hex: "bd0e1b"))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(line.speaker.prefix(1)))
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(line.speaker)
                        .font(.caption)
                        .foregroundColor(Color(hex: "ffbe00"))
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.playDialogueAudio(for: line)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(Color(hex: "ffbe00"))
                            .font(.caption)
                    }
                }
                
                Text(line.text)
                    .font(.body)
                    .foregroundColor(.white)
                
                if viewModel.showTranslations {
                    Text(line.translation)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "02102b").opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.7))
            
            Text(value)
                .font(.title2)
                .foregroundColor(.white)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
        )
    }
}

struct WeeklyProgressView: View {
    let stats: LanguageStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Study Time")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    Text("\(Int(stats.studyTimeThisWeek / 60)) min")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    Text("\(Int(stats.completionPercentage))%")
                        .font(.title3)
                        .foregroundColor(Color(hex: "ffbe00"))
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

struct AchievementsPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Achievements")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                AchievementBadge(icon: "star.fill", title: "First Lesson", isUnlocked: true)
                AchievementBadge(icon: "flame.fill", title: "3 Day Streak", isUnlocked: true)
                AchievementBadge(icon: "crown.fill", title: "Quiz Master", isUnlocked: false)
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

struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? Color(hex: "ffbe00") : Color.white.opacity(0.3))
            
            Text(title)
                .font(.caption2)
                .foregroundColor(isUnlocked ? .white : Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DifficultyBadge: View {
    let difficulty: Language.Difficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(difficultyColor)
            )
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .beginner: return Color(hex: "ffbe00")
        case .intermediate: return Color(hex: "bd0e1b")
        case .advanced: return Color(hex: "0a1a3b")
        }
    }
}

#Preview {
    LanguageLearningView()
}


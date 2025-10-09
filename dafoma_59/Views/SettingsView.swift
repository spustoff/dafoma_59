//
//  SettingsView.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataService = DataService.shared
    @State private var showDeleteConfirmation = false
    @State private var showLanguageSelection = false
    @State private var tempUser: User?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "02102b")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Profile Section
                        profileSection
                        
                        // Learning Preferences
                        learningPreferencesSection
                        
                        // App Preferences
                        appPreferencesSection
                        
                        // Notifications
                        // Data & Privacy
                        
                        // About
                        
                        // Danger Zone
                        dangerZoneSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .navigationTitle("Settings")
        .onAppear {
            tempUser = dataService.currentUser
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete all your progress and data. This action cannot be undone.")
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionSheet(user: $tempUser)
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        SettingsSection(title: "Profile") {
            VStack(spacing: 15) {
                // Profile Picture & Name
                HStack(spacing: 15) {
                    // Avatar
                    Circle()
                        .fill(Color(hex: "bd0e1b"))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(dataService.currentUser?.name.prefix(1).uppercased() ?? "U")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("Name", text: Binding(
                            get: { tempUser?.name ?? "" },
                            set: { newName in
                                tempUser?.name = newName
                                saveUserChanges()
                            }
                        ))
                        .font(.headline)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                        
                        Text("Member since \(memberSinceText)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Statistics
                if let user = dataService.currentUser {
                    HStack {
                        StatItem(title: "Rank", value: user.statistics.rank.rawValue, icon: user.statistics.rank.icon)
                        
                        Spacer()
                        
                        StatItem(title: "Points", value: "\(user.statistics.totalPoints)", icon: "star.fill")
                        
                        Spacer()
                        
                        StatItem(title: "Streak", value: "\(user.statistics.currentStreak)", icon: "flame.fill")
                    }
                }
            }
        }
    }
    
    // MARK: - Learning Preferences
    private var learningPreferencesSection: some View {
        SettingsSection(title: "Learning Preferences") {
            VStack(spacing: 15) {
                // Selected Languages
                SettingsRow(
                    title: "Languages",
                    subtitle: languagesText,
                    icon: "globe"
                ) {
                    showLanguageSelection = true
                }
                
                // Daily Goal
                SettingsRow(
                    title: "Daily Goal",
                    subtitle: "\(tempUser?.learningGoals.dailyGoalMinutes ?? 15) minutes",
                    icon: "target"
                ) {
                    // Show daily goal picker
                }
                
                // Weekly Goal
                SettingsRow(
                    title: "Weekly Goal",
                    subtitle: "\(tempUser?.learningGoals.weeklyGoalLessons ?? 5) lessons",
                    icon: "calendar"
                ) {
                    // Show weekly goal picker
                }
                
                // Difficulty Level
                SettingsRow(
                    title: "Difficulty Level",
                    subtitle: tempUser?.preferences.difficultyLevel.rawValue ?? "Beginner",
                    icon: "chart.bar.fill"
                ) {
                    // Show difficulty picker
                }
            }
        }
    }
    
    // MARK: - App Preferences
    private var appPreferencesSection: some View {
        SettingsSection(title: "App Preferences") {
            VStack(spacing: 15) {
                // Theme
                SettingsRow(
                    title: "Theme",
                    subtitle: tempUser?.preferences.theme.rawValue ?? "Dark",
                    icon: "paintbrush.fill"
                ) {
                    // Show theme picker
                }
                
                // Sound Effects
                SettingsToggleRow(
                    title: "Sound Effects",
                    subtitle: "Play audio for words and phrases",
                    icon: "speaker.wave.2.fill",
                    isOn: Binding(
                        get: { tempUser?.preferences.soundEnabled ?? true },
                        set: { newValue in
                            tempUser?.preferences.soundEnabled = newValue
                            saveUserChanges()
                        }
                    )
                )
                
                // Haptic Feedback
                SettingsToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Vibration for interactions",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: Binding(
                        get: { tempUser?.preferences.hapticFeedbackEnabled ?? true },
                        set: { newValue in
                            tempUser?.preferences.hapticFeedbackEnabled = newValue
                            saveUserChanges()
                        }
                    )
                )
                
                // Auto-play Audio
                SettingsToggleRow(
                    title: "Auto-play Audio",
                    subtitle: "Automatically play pronunciation",
                    icon: "play.circle.fill",
                    isOn: Binding(
                        get: { tempUser?.preferences.autoPlayAudio ?? true },
                        set: { newValue in
                            tempUser?.preferences.autoPlayAudio = newValue
                            saveUserChanges()
                        }
                    )
                )
                
                // Show Translations
                SettingsToggleRow(
                    title: "Show Translations",
                    subtitle: "Display translations in lessons",
                    icon: "textformat.abc",
                    isOn: Binding(
                        get: { tempUser?.preferences.showTranslations ?? true },
                        set: { newValue in
                            tempUser?.preferences.showTranslations = newValue
                            saveUserChanges()
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Notifications
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            VStack(spacing: 15) {
                SettingsToggleRow(
                    title: "Push Notifications",
                    subtitle: "Receive learning reminders",
                    icon: "bell.fill",
                    isOn: Binding(
                        get: { tempUser?.preferences.notificationsEnabled ?? true },
                        set: { newValue in
                            tempUser?.preferences.notificationsEnabled = newValue
                            saveUserChanges()
                        }
                    )
                )
                
                SettingsToggleRow(
                    title: "Daily Reminders",
                    subtitle: "Remind me to practice daily",
                    icon: "clock.fill",
                    isOn: Binding(
                        get: { tempUser?.learningGoals.isReminderEnabled ?? false },
                        set: { newValue in
                            tempUser?.learningGoals.isReminderEnabled = newValue
                            saveUserChanges()
                        }
                    )
                )
                
                if tempUser?.learningGoals.isReminderEnabled == true {
                    SettingsRow(
                        title: "Reminder Time",
                        subtitle: reminderTimeText,
                        icon: "alarm.fill"
                    ) {
                        // Show time picker
                    }
                }
            }
        }
    }
    
    // MARK: - Data & Privacy
    private var dataPrivacySection: some View {
        SettingsSection(title: "Data & Privacy") {
            VStack(spacing: 15) {
                SettingsRow(
                    title: "Data Usage",
                    subtitle: tempUser?.preferences.dataUsageMode.rawValue ?? "Standard",
                    icon: "wifi"
                ) {
                    // Show data usage picker
                }
                
                SettingsRow(
                    title: "Export Data",
                    subtitle: "Download your learning data",
                    icon: "square.and.arrow.up"
                ) {
                    exportUserData()
                }
                
                SettingsRow(
                    title: "Privacy Policy",
                    subtitle: "View our privacy policy",
                    icon: "hand.raised.fill"
                ) {
                    // Open privacy policy
                }
            }
        }
    }
    
    // MARK: - About
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 15) {
                SettingsRow(
                    title: "Version",
                    subtitle: "1.0.0",
                    icon: "info.circle.fill"
                ) { }
                
                SettingsRow(
                    title: "Rate App",
                    subtitle: "Leave a review on the App Store",
                    icon: "star.fill"
                ) {
                    rateApp()
                }
                
                SettingsRow(
                    title: "Contact Support",
                    subtitle: "Get help with the app",
                    icon: "questionmark.circle.fill"
                ) {
                    contactSupport()
                }
                
                SettingsRow(
                    title: "Terms of Service",
                    subtitle: "View terms and conditions",
                    icon: "doc.text.fill"
                ) {
                    // Open terms of service
                }
            }
        }
    }
    
    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        SettingsSection(title: "Danger Zone") {
            VStack(spacing: 15) {
                SettingsRow(
                    title: "Reset Progress",
                    subtitle: "Clear all learning progress",
                    icon: "arrow.counterclockwise",
                    titleColor: .orange
                ) {
                    resetProgress()
                }
                
                SettingsRow(
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    icon: "trash.fill",
                    titleColor: .red
                ) {
                    showDeleteConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var memberSinceText: String {
        guard let user = dataService.currentUser else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: user.dateJoined)
    }
    
    private var languagesText: String {
        guard let user = dataService.currentUser else { return "None selected" }
        if user.selectedLanguages.isEmpty {
            return "None selected"
        }
        
        let languageNames = user.selectedLanguages.compactMap { code in
            dataService.getLanguage(by: code)?.name
        }
        
        return languageNames.joined(separator: ", ")
    }
    
    private var reminderTimeText: String {
        guard let reminderTime = tempUser?.learningGoals.reminderTime else {
            return "Not set"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminderTime)
    }
    
    // MARK: - Helper Methods
    private func saveUserChanges() {
        guard let user = tempUser else { return }
        dataService.saveUser(user)
    }
    
    private func deleteAccount() {
        dataService.deleteUser()
    }
    
    private func resetProgress() {
        guard var user = dataService.currentUser else { return }
        user.progress = [:]
        user.statistics = UserStatistics()
        dataService.saveUser(user)
        tempUser = user
    }
    
    private func exportUserData() {
        // Implementation for exporting user data
        print("Exporting user data...")
    }
    
    private func rateApp() {
        // Implementation for rating the app
        print("Opening App Store for rating...")
    }
    
    private func contactSupport() {
        // Implementation for contacting support
        print("Opening support contact...")
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "ffbe00"))
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "0a1a3b"))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
            )
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var titleColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: "ffbe00"))
                    .frame(width: 25)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(titleColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "ffbe00"))
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "ffbe00")))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "ffbe00"))
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.7))
        }
    }
}

struct LanguageSelectionSheet: View {
    @Binding var user: User?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguages: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "02102b")
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(DataService.shared.availableLanguages) { language in
                            LanguageCard(
                                language: language,
                                isSelected: selectedLanguages.contains(language.code)
                            ) {
                                if selectedLanguages.contains(language.code) {
                                    selectedLanguages.remove(language.code)
                                } else {
                                    selectedLanguages.insert(language.code)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("Select Languages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    user?.selectedLanguages = Array(selectedLanguages)
                    if let user = user {
                        DataService.shared.saveUser(user)
                    }
                    dismiss()
                }
                .disabled(selectedLanguages.isEmpty)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            selectedLanguages = Set(user?.selectedLanguages ?? [])
        }
    }
}

struct LanguageCard: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(language.flag)
                    .font(.system(size: 40))
                
                Text(language.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(language.difficulty.rawValue)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color(hex: "bd0e1b") : Color(hex: "0a1a3b"))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color(hex: "ffbe00") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}

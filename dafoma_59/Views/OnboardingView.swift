//
//  OnboardingView.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "02102b")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                ProgressBarView(progress: viewModel.getProgressPercentage())
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        currentStepView
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                }
                
                // Navigation Buttons
                navigationButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        let stepInfo = viewModel.getCurrentStepInfo()
        
        VStack(spacing: 25) {
            // Step Icon
            stepIcon
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "ffbe00"))
                .padding(.top, 20)
            
            // Title and Description
            VStack(spacing: 15) {
                Text(stepInfo.title)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(stepInfo.description)
                    .font(.body)
                    .foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Step Content
            stepContent
        }
    }
    
    @ViewBuilder
    private var stepIcon: some View {
        switch OnboardingState.OnboardingStep(rawValue: viewModel.onboardingState.currentStep) {
        case .welcome:
            Image(systemName: "hand.wave.fill")
        case .nameInput:
            Image(systemName: "person.fill")
        case .languageSelection:
            Image(systemName: "globe")
        case .goalSetting:
            Image(systemName: "target")
        case .preferences:
            Image(systemName: "gearshape.fill")
        case .completion:
            Image(systemName: "checkmark.circle.fill")
        default:
            Image(systemName: "star.fill")
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch OnboardingState.OnboardingStep(rawValue: viewModel.onboardingState.currentStep) {
        case .welcome:
            welcomeContent
        case .nameInput:
            nameInputContent
        case .languageSelection:
            languageSelectionContent
        case .goalSetting:
            goalSettingContent
        case .preferences:
            preferencesContent
        case .completion:
            completionContent
        default:
            EmptyView()
        }
    }
    
    private var welcomeContent: some View {
        VStack(spacing: 20) {
            Text("🎯 Interactive Lessons")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("🎮 Gamified Quizzes")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("📊 Progress Tracking")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("🏆 Achievements")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.vertical, 20)
    }
    
    private var nameInputContent: some View {
        VStack(spacing: 20) {
            NeumorphicTextField(
                text: Binding(
                    get: { viewModel.onboardingState.userName ?? "" },
                    set: { viewModel.setUserName($0) }
                ),
                placeholder: "Enter your name"
            )
            
            if let message = viewModel.getValidationMessage() {
                Text(message)
                    .font(.caption)
                    .foregroundColor(Color(hex: "bd0e1b"))
            }
        }
    }
    
    private var languageSelectionContent: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            ForEach(viewModel.availableLanguages) { language in
                LanguageSelectionCard(
                    language: language,
                    isSelected: viewModel.onboardingState.selectedLanguage == language.code
                ) {
                    viewModel.selectLanguage(language.code)
                }
            }
        }
    }
    
    private var goalSettingContent: some View {
        VStack(spacing: 15) {
            ForEach(LearningGoals.GoalType.allCases, id: \.self) { goal in
                GoalSelectionCard(
                    goal: goal,
                    isSelected: viewModel.onboardingState.selectedGoal == goal
                ) {
                    viewModel.selectGoal(goal)
                }
            }
        }
    }
    
    private var preferencesContent: some View {
        VStack(spacing: 20) {
            Text("We'll set up your preferences based on your selections. You can always change these later in Settings.")
                .font(.body)
                .foregroundColor(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                PreferenceRow(title: "Sound Effects", isEnabled: true)
                PreferenceRow(title: "Daily Reminders", isEnabled: true)
                PreferenceRow(title: "Show Translations", isEnabled: true)
            }
        }
    }
    
    private var completionContent: some View {
        VStack(spacing: 20) {
            if let selectedLanguage = viewModel.getSelectedLanguage() {
                Text("You're ready to start learning \(selectedLanguage.name)!")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("\(selectedLanguage.flag)")
                    .font(.system(size: 80))
            }
            
            Text("Your learning journey begins now. Good luck!")
                .font(.body)
                .foregroundColor(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 15) {
            if viewModel.onboardingState.currentStep > 0 {
                NeumorphicButton(
                    title: "Back",
                    backgroundColor: Color(hex: "0a1a3b"),
                    foregroundColor: .white
                ) {
                    viewModel.previousStep()
                }
            }
            
            Spacer()
            
            if viewModel.onboardingState.currentStep < OnboardingState.OnboardingStep.allCases.count - 1 {
                NeumorphicButton(
                    title: "Next",
                    backgroundColor: Color(hex: "bd0e1b"),
                    foregroundColor: .white,
                    isDisabled: !viewModel.canProceedFromCurrentStep()
                ) {
                    viewModel.nextStep()
                }
            } else {
                NeumorphicButton(
                    title: "Get Started",
                    backgroundColor: Color(hex: "ffbe00"),
                    foregroundColor: Color(hex: "02102b"),
                    isDisabled: !viewModel.canProceedFromCurrentStep()
                ) {
                    viewModel.completeOnboarding()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProgressBarView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "0a1a3b"))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "ffbe00"))
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

struct NeumorphicTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "0a1a3b"))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
            )
            .foregroundColor(.white)
            .font(.body)
    }
}

struct LanguageSelectionCard: View {
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalSelectionCard: View {
    let goal: LearningGoals.GoalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(goal.dailyMinutes) min/day • \(goal.weeklyLessons) lessons/week")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "ffbe00"))
                        .font(.title2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color(hex: "bd0e1b") : Color(hex: "0a1a3b"))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreferenceRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? Color(hex: "ffbe00") : Color.white.opacity(0.5))
                .font(.title2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "0a1a3b"))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
                .shadow(color: Color.white.opacity(0.1), radius: 4, x: -2, y: -2)
        )
    }
}

struct NeumorphicButton: View {
    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isDisabled ? foregroundColor.opacity(0.5) : foregroundColor)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isDisabled ? backgroundColor.opacity(0.5) : backgroundColor)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 4, y: 4)
                        .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
                )
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
}


//
//  OnboardingViewModel.swift
//  dafoma_59
//
//  Created by Вячеслав on 10/9/25.
//

import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var onboardingState: OnboardingState
    @Published var availableLanguages: [Language] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService = DataService.shared
    
    init() {
        self.onboardingState = dataService.getOnboardingState()
        self.availableLanguages = dataService.availableLanguages
    }
    
    // MARK: - Navigation
    func nextStep() {
        guard onboardingState.currentStep < OnboardingState.OnboardingStep.allCases.count - 1 else {
            completeOnboarding()
            return
        }
        
        onboardingState.currentStep += 1
        saveState()
    }
    
    func previousStep() {
        guard onboardingState.currentStep > 0 else { return }
        onboardingState.currentStep -= 1
        saveState()
    }
    
    func goToStep(_ step: OnboardingState.OnboardingStep) {
        onboardingState.currentStep = step.rawValue
        saveState()
    }
    
    // MARK: - User Input
    func setUserName(_ name: String) {
        onboardingState.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        saveState()
    }
    
    func selectLanguage(_ languageCode: String) {
        onboardingState.selectedLanguage = languageCode
        saveState()
    }
    
    func selectGoal(_ goal: LearningGoals.GoalType) {
        onboardingState.selectedGoal = goal
        saveState()
    }
    
    func setNativeLanguage(_ languageCode: String) {
        onboardingState.nativeLanguage = languageCode
        saveState()
    }
    
    // MARK: - Validation
    func canProceedFromCurrentStep() -> Bool {
        let currentStep = OnboardingState.OnboardingStep(rawValue: onboardingState.currentStep)
        
        switch currentStep {
        case .welcome:
            return true
        case .nameInput:
            return !(onboardingState.userName?.isEmpty ?? true)
        case .languageSelection:
            return onboardingState.selectedLanguage != nil
        case .goalSetting:
            return onboardingState.selectedGoal != nil
        case .preferences:
            return true
        case .completion:
            return true
        case .none:
            return false
        }
    }
    
    func getValidationMessage() -> String? {
        let currentStep = OnboardingState.OnboardingStep(rawValue: onboardingState.currentStep)
        
        switch currentStep {
        case .nameInput:
            if onboardingState.userName?.isEmpty ?? true {
                return "Please enter your name to continue"
            }
        case .languageSelection:
            if onboardingState.selectedLanguage == nil {
                return "Please select a language to learn"
            }
        case .goalSetting:
            if onboardingState.selectedGoal == nil {
                return "Please choose your learning goal"
            }
        default:
            break
        }
        
        return nil
    }
    
    // MARK: - Completion
    func completeOnboarding() {
        guard let userName = onboardingState.userName,
              let selectedLanguage = onboardingState.selectedLanguage,
              let selectedGoal = onboardingState.selectedGoal else {
            errorMessage = "Please complete all required steps"
            return
        }
        
        isLoading = true
        
        // Create user with onboarding data
        var user = dataService.createUser(name: userName, nativeLanguage: onboardingState.nativeLanguage)
        
        // Set up user preferences based on onboarding choices
        user.selectedLanguages = [selectedLanguage]
        user.learningGoals.dailyGoalMinutes = selectedGoal.dailyMinutes
        user.learningGoals.weeklyGoalLessons = selectedGoal.weeklyLessons
        
        // Initialize progress for selected language
        user.progress[selectedLanguage] = LearningProgress(
            languageCode: selectedLanguage,
            completedLessons: [],
            currentStreak: 0,
            totalPoints: 0,
            weeklyGoal: selectedGoal.weeklyLessons,
            studyTimeThisWeek: 0
        )
        
        dataService.saveUser(user)
        
        // Mark onboarding as completed
        onboardingState.isCompleted = true
        saveState()
        
        isLoading = false
    }
    
    func skipOnboarding() {
        // Create default user
        let user = dataService.createUser(name: "User")
        dataService.saveUser(user)
        
        onboardingState.isCompleted = true
        saveState()
    }
    
    // MARK: - Helper Methods
    private func saveState() {
        dataService.saveOnboardingState(onboardingState)
    }
    
    func getCurrentStepInfo() -> (title: String, description: String) {
        guard let step = OnboardingState.OnboardingStep(rawValue: onboardingState.currentStep) else {
            return ("Welcome", "Let's get started!")
        }
        
        return (step.title, step.description)
    }
    
    func getProgressPercentage() -> Double {
        let totalSteps = OnboardingState.OnboardingStep.allCases.count
        return Double(onboardingState.currentStep + 1) / Double(totalSteps)
    }
    
    func getSelectedLanguage() -> Language? {
        guard let languageCode = onboardingState.selectedLanguage else { return nil }
        return availableLanguages.first { $0.code == languageCode }
    }
    
    func resetOnboarding() {
        onboardingState = OnboardingState()
        saveState()
    }
}

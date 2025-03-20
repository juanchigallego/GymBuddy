import SwiftUI

enum Constants {
    // App-wide constants
    enum App {
        static let name = "GymBuddy"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // Layout constants
    enum Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let tabBarHeight: CGFloat = 49
        static let miniTrackerHeight: CGFloat = 60
    }
    
    // Animation constants
    enum Animation {
        static let standard = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let fast = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.8)
        static let slow = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
    
    // Color constants
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.orange
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
    }
    
    // Timer constants
    enum Timer {
        static let defaultRestTime: TimeInterval = 60
        static let minRestTime: TimeInterval = 15
        static let maxRestTime: TimeInterval = 300
    }
    
    // Storage keys
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastTrainingDate = "lastTrainingDate"
        static let userWeightUnit = "userWeightUnit"
    }
    
    // Notification names
    enum NotificationNames {
        static let didCompleteWorkout = Notification.Name("didCompleteWorkout")
        static let didUpdateExercise = Notification.Name("didUpdateExercise")
    }
} 
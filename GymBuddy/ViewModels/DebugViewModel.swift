import Foundation
import SwiftUI
import CoreData

class DebugViewModel: ObservableObject {
    @Published var showingResetConfirmation = false
    
    func resetCoreData() {
        PersistenceController.shared.resetAllData()
        // Could add additional notification to refresh views if needed
    }
}

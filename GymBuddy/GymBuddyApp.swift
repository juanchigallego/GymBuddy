//
//  GymBuddyApp.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 11/12/2024.
//

import SwiftUI
import ActivityKit

@main
struct GymBuddyApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var viewModel: RoutineViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: RoutineViewModel(context: context))
        
        if #available(iOS 16.1, *) {
            Task {
                let granted = await ActivityAuthorizationInfo().areActivitiesEnabled
                print("Live Activities authorized: \(granted)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
        }
    }
}

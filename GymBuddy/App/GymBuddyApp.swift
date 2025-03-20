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
    
    init() {
        // Setup logging
        let logger = Logger(category: "GymBuddyApp")
        logger.info("App initializing")
        
        if #available(iOS 16.1, *) {
            Task {
                let granted = await ActivityAuthorizationInfo().areActivitiesEnabled
                logger.info("Live Activities authorized: \(granted)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

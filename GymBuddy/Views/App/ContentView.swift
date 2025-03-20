//
//  ContentView.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 11/12/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var routineViewModel: RoutineViewModel
    @StateObject private var workoutViewModel: WorkoutViewModel
    @StateObject private var progressViewModel: ProgressViewModel
    
    init(context: NSManagedObjectContext) {
        self._routineViewModel = StateObject(wrappedValue: RoutineViewModel(context: context))
        self._workoutViewModel = StateObject(wrappedValue: WorkoutViewModel(context: context))
        self._progressViewModel = StateObject(wrappedValue: ProgressViewModel(context: context))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MainTabView(
                routineViewModel: routineViewModel,
                workoutViewModel: workoutViewModel,
                progressViewModel: progressViewModel
            )
            
            // Workout tracking overlay
            WorkoutOverlayView(
                workoutViewModel: workoutViewModel,
                progressViewModel: progressViewModel
            )
        }
        .environmentObject(routineViewModel)
        .environmentObject(workoutViewModel)
        .environmentObject(progressViewModel)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    return ContentView(context: context)
        .environment(\.managedObjectContext, context)
}

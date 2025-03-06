import Foundation
import CoreData
import SwiftUI

@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var searchText: String = ""
    @Published var selectedMuscleFilter: Muscle? = nil
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchExercises()
    }
    
    var filteredExercises: [Exercise] {
        var filtered = exercises
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.exerciseName.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by selected muscle
        if let muscle = selectedMuscleFilter {
            filtered = filtered.filter { 
                $0.exerciseTargetMuscles.contains(muscle.rawValue)
            }
        }
        
        return filtered.sorted { $0.exerciseName < $1.exerciseName }
    }
    
    func fetchExercises() {
        let request = Exercise.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        
        do {
            // Fetch all exercises
            let allExercises = try viewContext.fetch(request)
            
            // Create a dictionary to store unique exercises by name
            var uniqueExercises: [String: Exercise] = [:]
            
            // For each exercise, keep the one that's not in a block (library version)
            // or the first one we find if all instances are in blocks
            for exercise in allExercises {
                let name = exercise.exerciseName
                if let existing = uniqueExercises[name] {
                    // If we already have this exercise, prefer the one not in a block
                    if existing.block != nil && exercise.block == nil {
                        uniqueExercises[name] = exercise
                    }
                } else {
                    uniqueExercises[name] = exercise
                }
            }
            
            // Convert back to array
            exercises = Array(uniqueExercises.values)
                .sorted { $0.exerciseName < $1.exerciseName }
        } catch {
            print("Error fetching exercises: \(error)")
        }
    }
    
    func addExercise(name: String, targetMuscles: [Muscle], notes: String = "") {
        let newExercise = Exercise(context: viewContext)
        newExercise.id = UUID()
        newExercise.name = name
        newExercise.targetMuscles = targetMuscles.map { $0.rawValue } as NSArray
        newExercise.repsPerSet = 0
        newExercise.weight = 0.0
        newExercise.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            fetchExercises()
        } catch {
            print("Error saving exercise: \(error)")
        }
    }
    
    func updateExercise(_ exercise: Exercise, name: String, targetMuscles: [Muscle], notes: String) {
        exercise.name = name
        exercise.exerciseTargetMuscles = targetMuscles.map { $0.rawValue }
        exercise.notes = notes
        
        saveContext()
        fetchExercises()
    }
    
    func deleteExercise(_ exercise: Exercise) {
        viewContext.delete(exercise)
        saveContext()
        fetchExercises()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
} 
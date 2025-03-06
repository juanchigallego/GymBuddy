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
        request.predicate = NSPredicate(format: "block == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        
        do {
            exercises = try viewContext.fetch(request)
        } catch {
            print("Error fetching exercises: \(error)")
        }
    }
    
    func addExercise(name: String, targetMuscles: [Muscle], repsPerSet: Int16 = 0, weight: Double = 0.0, notes: String = "") {
        let newExercise = Exercise(context: viewContext)
        newExercise.id = UUID()
        newExercise.name = name
        newExercise.exerciseTargetMuscles = targetMuscles.map { $0.rawValue }
        newExercise.repsPerSet = repsPerSet
        newExercise.weight = weight
        newExercise.notes = notes
        
        saveContext()
        fetchExercises()
    }
    
    func updateExercise(_ exercise: Exercise, name: String, targetMuscles: [Muscle], repsPerSet: Int16, weight: Double, notes: String) {
        exercise.name = name
        exercise.exerciseTargetMuscles = targetMuscles.map { $0.rawValue }
        exercise.repsPerSet = repsPerSet
        exercise.weight = weight
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
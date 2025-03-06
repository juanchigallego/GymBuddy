import Foundation
import CoreData
import SwiftUI

/// Sample data for SwiftUI previews
struct SampleData {
    
    // MARK: - Create ViewContext
    static var previewContext: NSManagedObjectContext = {
        let container = NSPersistentContainer(name: "GymBuddy")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        let context = container.viewContext
        createSampleData(in: context)
        return context
    }()
    
    // MARK: - Sample Routines
    static var sampleRoutines: [Routine] = {
        let fetchRequest: NSFetchRequest<Routine> = Routine.fetchRequest() as! NSFetchRequest<Routine>
        return (try? previewContext.fetch(fetchRequest)) ?? []
    }()
    
    static var sampleRoutine: Routine {
        sampleRoutines.first ?? createRoutine(in: previewContext)
    }
    
    // MARK: - Sample Blocks
    static var sampleBlocks: [Block] {
        let fetchRequest: NSFetchRequest<Block> = Block.fetchRequest() as! NSFetchRequest<Block>
        return (try? previewContext.fetch(fetchRequest)) ?? []
    }
    
    static var sampleBlock: Block {
        sampleBlocks.first ?? createBlock(in: previewContext)
    }
    
    // MARK: - Sample Exercises
    static var sampleExercises: [Exercise] {
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest() as! NSFetchRequest<Exercise>
        return (try? previewContext.fetch(fetchRequest)) ?? []
    }
    
    static var sampleExercise: Exercise {
        sampleExercises.first ?? createExercise(in: previewContext)
    }
    
    // MARK: - Sample Completed Workouts
    static var sampleCompletedWorkouts: [CompletedWorkout] {
        let fetchRequest: NSFetchRequest<CompletedWorkout> = CompletedWorkout.fetchRequest() as! NSFetchRequest<CompletedWorkout>
        return (try? previewContext.fetch(fetchRequest)) ?? []
    }
    
    static var sampleCompletedWorkout: CompletedWorkout {
        sampleCompletedWorkouts.first ?? createCompletedWorkout(in: previewContext)
    }
    
    // MARK: - Create Sample Data
    private static func createSampleData(in context: NSManagedObjectContext) {
        // Create Push Day Routine
        let pushRoutine = createRoutine(in: context, name: "Push Day", 
                                       muscles: [Muscle.chest, Muscle.shoulders, Muscle.triceps])
        
        // Create Chest Block
        let chestBlock = createBlock(in: context, name: "Chest", sets: 4, rest: 90, routine: pushRoutine)
        
        // Create Chest Exercises
        createExercise(in: context, name: "Bench Press", reps: 8, weight: 185.0, 
                      muscles: [Muscle.chest, Muscle.triceps], block: chestBlock)
        createExercise(in: context, name: "Incline Dumbbell Press", reps: 10, weight: 65.0, 
                      muscles: [Muscle.chest, Muscle.shoulders], block: chestBlock)
        
        // Create Shoulder Block
        let shoulderBlock = createBlock(in: context, name: "Shoulders", sets: 3, rest: 60, routine: pushRoutine)
        
        // Create Shoulder Exercises
        createExercise(in: context, name: "Overhead Press", reps: 8, weight: 135.0, 
                      muscles: [Muscle.shoulders, Muscle.triceps], block: shoulderBlock)
        createExercise(in: context, name: "Lateral Raises", reps: 12, weight: 20.0, 
                      muscles: [Muscle.shoulders], block: shoulderBlock)
        
        // Create Pull Day Routine
        let pullRoutine = createRoutine(in: context, name: "Pull Day", 
                                       muscles: [Muscle.back, Muscle.biceps, Muscle.traps])
        
        // Create Back Block
        let backBlock = createBlock(in: context, name: "Back", sets: 4, rest: 90, routine: pullRoutine)
        
        // Create Back Exercises
        createExercise(in: context, name: "Deadlift", reps: 5, weight: 225.0, 
                      muscles: [Muscle.back, Muscle.hamstrings, Muscle.glutes], block: backBlock)
        createExercise(in: context, name: "Pull-ups", reps: 10, weight: 0.0, 
                      muscles: [Muscle.back, Muscle.biceps], block: backBlock)
        
        // Create Biceps Block
        let bicepsBlock = createBlock(in: context, name: "Biceps", sets: 3, rest: 60, routine: pullRoutine)
        
        // Create Biceps Exercises
        createExercise(in: context, name: "Barbell Curls", reps: 10, weight: 65.0, 
                      muscles: [Muscle.biceps, Muscle.forearms], block: bicepsBlock)
        createExercise(in: context, name: "Hammer Curls", reps: 12, weight: 30.0, 
                      muscles: [Muscle.biceps, Muscle.forearms], block: bicepsBlock)
        
        // Create Leg Day Routine
        let legRoutine = createRoutine(in: context, name: "Leg Day", 
                                      muscles: [Muscle.legs, Muscle.quadriceps, Muscle.hamstrings, Muscle.calves])
        
        // Create Quads Block
        let quadsBlock = createBlock(in: context, name: "Quads", sets: 4, rest: 120, routine: legRoutine)
        
        // Create Quad Exercises
        createExercise(in: context, name: "Squats", reps: 8, weight: 225.0, 
                      muscles: [Muscle.quadriceps, Muscle.glutes], block: quadsBlock)
        createExercise(in: context, name: "Leg Press", reps: 10, weight: 360.0, 
                      muscles: [Muscle.quadriceps, Muscle.glutes], block: quadsBlock)
        
        // Create Hamstrings Block
        let hamstringsBlock = createBlock(in: context, name: "Hamstrings", sets: 3, rest: 90, routine: legRoutine)
        
        // Create Hamstring Exercises
        createExercise(in: context, name: "Romanian Deadlift", reps: 10, weight: 185.0, 
                      muscles: [Muscle.hamstrings, Muscle.glutes, Muscle.back], block: hamstringsBlock)
        createExercise(in: context, name: "Leg Curls", reps: 12, weight: 110.0, 
                      muscles: [Muscle.hamstrings], block: hamstringsBlock)
        
        // Create Sample Completed Workout
        createCompletedWorkout(in: context, routineName: "Push Day", date: Date().addingTimeInterval(-86400))
        
        try? context.save()
    }
    
    // MARK: - Helper Methods
    private static func createRoutine(in context: NSManagedObjectContext, name: String = "Sample Routine", 
                                     muscles: [Muscle] = [.chest, .back]) -> Routine {
        let routine = Routine(context: context)
        routine.id = UUID()
        routine.day = name
        routine.targetMuscleGroups = muscles.map { $0.rawValue } as NSArray
        routine.notes = "Sample routine notes"
        return routine
    }
    
    private static func createBlock(in context: NSManagedObjectContext, name: String = "Sample Block", 
                                   sets: Int16 = 3, rest: Int16 = 60, routine: Routine? = nil) -> Block {
        let block = Block(context: context)
        block.id = UUID()
        block.name = name
        block.sets = sets
        block.completedSets = 0
        block.restSeconds = rest
        if let routine = routine {
            block.routine = routine
        }
        return block
    }
    
    private static func createExercise(in context: NSManagedObjectContext, name: String = "Sample Exercise", 
                                      reps: Int16 = 10, weight: Double = 100.0, 
                                      muscles: [Muscle] = [.chest], block: Block? = nil) -> Exercise {
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.repsPerSet = reps
        exercise.weight = weight
        exercise.notes = "Sample exercise notes"
        exercise.targetMuscles = muscles.map { $0.rawValue } as NSArray
        if let block = block {
            exercise.block = block
        }
        return exercise
    }
    
    private static func createCompletedWorkout(in context: NSManagedObjectContext, 
                                             routineName: String = "Sample Workout", 
                                             date: Date = Date()) -> CompletedWorkout {
        let workout = CompletedWorkout(context: context)
        workout.id = UUID()
        workout.date = date
        workout.endDate = date.addingTimeInterval(3600) // 1 hour workout
        workout.routineName = routineName
        workout.totalTime = 3600
        return workout
    }
    
    // MARK: - Preview Helpers
    static func previewContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "GymBuddy")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        let context = container.viewContext
        createSampleData(in: context)
        return container
    }
}

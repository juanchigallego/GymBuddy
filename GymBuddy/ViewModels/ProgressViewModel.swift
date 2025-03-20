import SwiftUI
import CoreData
import os

@MainActor
class ProgressViewModel: ObservableObject {
    // Logger for this class
    private let logger = Logger(category: "ProgressViewModel")
    
    @Published var progressData: [ExerciseProgress] = []
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchProgressData()
        
        // Set up notification observers
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWorkoutCompleted),
            name: Constants.NotificationNames.didCompleteWorkout,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExerciseUpdated),
            name: Constants.NotificationNames.didUpdateExercise,
            object: nil
        )
    }
    
    @objc private func handleWorkoutCompleted(notification: Notification) {
        // Process completed workout to update progress data
        if let workout = notification.userInfo?["workout"] as? CompletedWorkout {
            logger.info("Processing completed workout for progress tracking")
            processCompletedWorkout(workout)
        }
    }
    
    private func processCompletedWorkout(_ workout: CompletedWorkout) {
        // Logic to extract exercise data from the workout and update progress
        for block in workout.blockArray {
            if !block.isSkipped {
                for exercise in block.exerciseArray {
                    // Create a progress entry for each completed exercise
                    // We need to find the original exercise to link them
                    let request = NSFetchRequest<Exercise>(entityName: "Exercise")
                    request.predicate = NSPredicate(format: "name == %@", exercise.exerciseName ?? "")
                    request.fetchLimit = 1
                    
                    do {
                        let results = try viewContext.fetch(request)
                        if let originalExercise = results.first {
                            // Create progress entry
                            createProgressEntryForExercise(exercise: originalExercise, completedExercise: exercise)
                        }
                    } catch {
                        logger.error("Error finding original exercise: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @objc private func handleExerciseUpdated(notification: Notification) {
        // Update progress data if needed when an exercise is updated
        if let exercise = notification.userInfo?["exercise"] as? Exercise {
            logger.info("Exercise updated: \(exercise.exerciseName)")
            fetchProgressData()
        }
    }
    
    func fetchProgressData() {
        let request = NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
        
        do {
            progressData = try viewContext.fetch(request)
            logger.info("Fetched \(progressData.count) exercise progress records")
        } catch {
            logger.error("Error fetching exercise progress: \(error.localizedDescription)")
        }
    }
    
    func getProgressForExercise(_ exerciseName: String) -> ExerciseProgress? {
        return progressData.first { $0.exerciseName == exerciseName }
    }
    
    func getProgressEntriesForExercise(exerciseName: String) -> [ExerciseProgress] {
        let request = NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
        request.predicate = NSPredicate(format: "exerciseName == %@", exerciseName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseProgress.date, ascending: true)]
        
        do {
            let results = try viewContext.fetch(request)
            logger.info("Fetched \(results.count) progress entries for exercise \(exerciseName)")
            return results
        } catch {
            logger.error("Error fetching progress entries: \(error.localizedDescription)")
            return []
        }
    }
    
    func createProgressEntryForExercise(exercise: Exercise, completedExercise: CompletedExercise) {
        // Check if progress already exists for this exercise
        let request = NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
        request.predicate = NSPredicate(format: "exerciseName == %@", exercise.exerciseName)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            let progress: ExerciseProgress
            
            if let existingProgress = results.first {
                // Update existing progress
                progress = existingProgress
                logger.info("Updating existing progress for \(exercise.exerciseName)")
            } else {
                // Create new progress record
                progress = ExerciseProgress(context: viewContext)
                progress.id = UUID()
                progress.exerciseName = exercise.exerciseName
                progress.date = Date()
                progress.weight = completedExercise.weight
                progress.reps = completedExercise.repsPerSet
                progress.notes = completedExercise.notes
                progress.exercise = exercise
                progress.completedExercise = completedExercise
                logger.info("Creating new progress record for \(exercise.exerciseName)")
            }
            
            try viewContext.save()
            fetchProgressData()
            logger.info("Added progress entry for \(exercise.exerciseName): \(completedExercise.repsPerSet) reps at \(completedExercise.weight) weight")
            
        } catch {
            logger.error("Error creating progress entry: \(error.localizedDescription)")
        }
    }
    
    func getRecommendedWeight(for exercise: Exercise) -> Double {
        // Find the most recent progress entry for this exercise
        let request = NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
        request.predicate = NSPredicate(format: "exerciseName == %@ AND exercise == %@", exercise.exerciseName, exercise)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseProgress.date, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let latestProgress = results.first {
                logger.debug("Recommending weight \(latestProgress.weight) for \(exercise.exerciseName) based on last progress")
                return latestProgress.weight
            }
        } catch {
            logger.error("Error fetching recommended weight: \(error.localizedDescription)")
        }
        
        return exercise.weight
    }
    
    func deleteProgressData(for exercise: Exercise) {
        let request = NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
        request.predicate = NSPredicate(format: "exerciseName == %@", exercise.exerciseName)
        
        do {
            let results = try viewContext.fetch(request)
            for progress in results {
                viewContext.delete(progress)
            }
            try viewContext.save()
            fetchProgressData()
            logger.info("Deleted progress data for \(exercise.exerciseName)")
        } catch {
            logger.error("Error deleting progress data: \(error.localizedDescription)")
        }
    }
    
    // Get progress chart data for an exercise
    func getProgressChartData(for exerciseName: String) -> [(date: Date, weight: Double, reps: Int16)] {
        let request = NSFetchRequest<ExerciseProgress>(entityName: "ExerciseProgress")
        request.predicate = NSPredicate(format: "exerciseName == %@", exerciseName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseProgress.date, ascending: true)]
        
        do {
            let results = try viewContext.fetch(request)
            return results.compactMap { progress in
                guard let date = progress.date else { return nil }
                return (date: date, weight: progress.weight, reps: progress.reps)
            }
        } catch {
            logger.error("Error fetching progress chart data: \(error.localizedDescription)")
            return []
        }
    }
} 

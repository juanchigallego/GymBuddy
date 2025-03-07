import SwiftUI
import CoreData

struct LogWeightSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var exercise: Exercise
    @State private var weight: Double
    @State private var reps: Int16
    @State private var notes: String = ""
    
    init(exercise: Exercise) {
        self.exercise = exercise
        // Initialize with current values
        _weight = State(initialValue: exercise.weight)
        _reps = State(initialValue: exercise.repsPerSet)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Weight and Reps") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                    }
                    
                    Stepper("Reps: \(reps)", value: $reps, in: 1...50)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button("Log Progress") {
                        saveProgress()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveProgress() {
        viewContext.performAndWait {
            // Create new progress entry
            let entityDescription = NSEntityDescription.entity(forEntityName: "ExerciseProgress", in: viewContext)!
            let progress = ExerciseProgress(entity: entityDescription, insertInto: viewContext)
            
            progress.id = UUID()
            progress.date = Date()
            progress.weight = weight
            progress.reps = reps
            progress.exerciseName = exercise.exerciseName
            progress.notes = notes.isEmpty ? nil : notes
            progress.exercise = exercise
            
            // Update the exercise's weight and reps for next time
            exercise.weight = weight
            exercise.repsPerSet = reps
            
            // Save context
            do {
                try viewContext.save()
            } catch {
                print("Error saving progress: \(error)")
            }
        }
    }
} 
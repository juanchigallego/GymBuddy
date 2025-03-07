import SwiftUI
import CoreData

struct ExerciseCard: View {
    @ObservedObject var exercise: Exercise
    @State private var showingLogSheet = false
    
    var body: some View {
        Button {
            showingLogSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Label("\(exercise.repsPerSet) reps", systemImage: "repeat")
                    Spacer()
                    Label("\(String(format: "%.1f", exercise.weight))kg", systemImage: "scalemass.fill")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingLogSheet) {
            LogWeightSheet(exercise: exercise)
                .environment(\.managedObjectContext, exercise.managedObjectContext!)
        }
    }
} 
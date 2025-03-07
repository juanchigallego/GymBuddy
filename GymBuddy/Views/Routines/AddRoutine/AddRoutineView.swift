import SwiftUI
import CoreData

struct AddRoutineView: View {
    @ObservedObject var viewModel: RoutineViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var day = ""
    @State private var muscleGroups = ""
    @State private var notes = ""
    @State private var blocks: [Block] = []
    @State private var showingAddBlock = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Details") {
                    TextField("Day (e.g. Monday)", text: $day)
                    TextField("Muscle Groups (comma separated)", text: $muscleGroups)
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section("Blocks") {
                    ForEach(blocks, id: \.blockID) { block in
                        BlockRowView(block: block)
                    }
                    
                    Button("Add Block") {
                        showingAddBlock = true
                    }
                }
            }
            .navigationTitle("New Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .disabled(day.isEmpty || blocks.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddBlock) {
                AddBlockView(blocks: $blocks, viewContext: viewContext)
            }
        }
    }
    
    private func saveRoutine() {
        let muscleGroupsArray = muscleGroups.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        viewModel.addRoutine(
            day: day,
            muscleGroups: muscleGroupsArray,
            blocks: blocks,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
} 
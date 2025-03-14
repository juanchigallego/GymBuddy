//
//  BlockCard.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 13/03/2025.
//
import SwiftUI

// Block card component
struct BlockCard: View {
    let block: Block
    @ObservedObject var viewModel: RoutineViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            // Block header
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(block.blockName)
                        .font(.title3)
                    HStack(spacing: 8) {
                        Label("\(block.sets) sets", systemImage: "repeat")
                            .font(.footnote)
                        
                        Label("\(block.restSeconds) seconds", systemImage: "timer")
                            .font(.footnote)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.blockToEdit = block
                    viewModel.isEditingBlock = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.circle)
            }
            .padding(16)
            
            // Exercises
            ForEach(Array(block.exerciseArray.enumerated()), id: \.element.exerciseID) { index, exercise in
                ExerciseRowView(
                    exercise: exercise,
                    backgroundColor: index % 2 == 0 ? Color(.tertiarySystemBackground) : nil,
                    paddingBottom: index == block.exerciseArray.count - 1 ? 16 : nil
                )
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
        .sheet(isPresented: $viewModel.isEditingBlock) {
            if let blockToEdit = viewModel.blockToEdit {
                EditBlockView(viewModel: viewModel, block: blockToEdit)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    let block = Block(context: context)
    block.blockName = "Chest"
    block.sets = 5
    block.restSeconds = 120
    
    // Create sample exercises for the block
    let exercise1 = Exercise(context: context)
    exercise1.id = UUID()
    exercise1.name = "Bench Press"
    exercise1.repsPerSet = 8
    exercise1.weight = 80.0
    exercise1.block = block
    
    let exercise2 = Exercise(context: context)
    exercise2.id = UUID()
    exercise2.name = "Incline Dumbbell Press"
    exercise2.repsPerSet = 10
    exercise2.weight = 30.0
    exercise2.block = block
    
    // Save context
    try? context.save()
    
    // Create a view model
    let viewModel = RoutineViewModel(context: context)
    
    return NavigationStack {
        BlockCard(block: block, viewModel: viewModel)
            .environment(\.managedObjectContext, context)
    }
}

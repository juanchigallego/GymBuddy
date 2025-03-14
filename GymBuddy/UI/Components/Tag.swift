//
//  Tag.swift
//  GymBuddy
//
//  Created by Juanchi Gallego on 14/03/2025.
//

import SwiftUI

struct Tag: View {
    var label: String = ""
    var active: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(label)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(active ? .accentColor : Color(.secondarySystemBackground))
        .foregroundStyle(active ? .primary : .tertiary)
        .cornerRadius(999)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // Save context
    try? context.save()
    
    // Create a view model
    let viewModel = RoutineViewModel(context: context)
    
    return HStack {
        Tag(label: "Upper body")
            .environment(\.managedObjectContext, context)
        Tag(label: "Lower body", active: true)
            .environment(\.managedObjectContext, context)
    }
}

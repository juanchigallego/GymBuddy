import Foundation

enum Muscle: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case calves = "Calves"
    case abs = "Abs"
    case forearms = "Forearms"
    case traps = "Traps"
    case glutes = "Glutes"
    case hamstrings = "Hamstrings"
    case quadriceps = "Quadriceps"
    
    var id: String { self.rawValue }
    
    static var allCases: [Muscle] {
        return [
            .chest, .back, .shoulders, 
            .biceps, .triceps, .legs, 
            .calves, .abs, .forearms, 
            .traps, .glutes, .hamstrings, 
            .quadriceps
        ]
    }
} 
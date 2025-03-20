import SwiftUI

#if DEBUG
struct DebugMenu: View {
    @StateObject private var debugViewModel = DebugViewModel()
    
    var body: some View {
        Button("Reset Data") {
            debugViewModel.showingResetConfirmation = true
        }
        .foregroundColor(.red)
        .alert("Reset Database", isPresented: $debugViewModel.showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                debugViewModel.resetCoreData()
            }
        } message: {
            Text("This will delete all data. Are you sure?")
        }
    }
}
#endif

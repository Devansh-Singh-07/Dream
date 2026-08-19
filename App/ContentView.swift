import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MovieLibraryView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Movie.self, StudentProfile.self])
}

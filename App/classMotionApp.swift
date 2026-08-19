import SwiftUI
import SwiftData

@main
struct ClassMotionApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Movie.self, StudentProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            Task { @MainActor in DemoDataManager.loadDemoDataIfNeeded(context: container.mainContext) }
            return container
        } catch {
            // Schema changed — delete old store and retry
            print("⚠️ SwiftData migration failed, resetting database: \(error)")
            let urls = [
                config.url,
                config.url.deletingPathExtension().appendingPathExtension("sqlite-wal"),
                config.url.deletingPathExtension().appendingPathExtension("sqlite-shm")
            ]
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                let container = try ModelContainer(for: schema, configurations: [config])
                Task { @MainActor in DemoDataManager.loadDemoDataIfNeeded(context: container.mainContext) }
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

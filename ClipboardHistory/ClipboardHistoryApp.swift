import SwiftUI
import SwiftData

/// 剪贴板历史 App 入口
/// 要求 iOS 17+（SwiftData），Xcode 15+
@main
struct ClipboardHistoryApp: App {
    @StateObject private var monitor = PasteboardMonitor()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("无法创建数据库：\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .onAppear {
                    monitor.configure(context: sharedModelContainer.mainContext)
                    monitor.start()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

import SwiftUI
import UIKit
import SwiftData

/// 剪贴板监听器
///
/// 做法：
/// - App 回到前台时立刻读一次剪贴板
/// - 前台运行时每 1 秒轮询一次（用 changeCount 判断有没有新内容）
/// - 同时监听 UIPasteboard.changedNotification
///
/// iOS 限制（必须如实说明）：
/// - App 在后台时读不到剪贴板，iOS 根本不给后台 App 访问剪贴板；
///   所以“实时”只在 App 打开着的时候成立，退到后台就停了。
/// - iOS 16+ 第一次读取会弹系统授权框，用户点“允许”之后才能读。
@MainActor
final class PasteboardMonitor: ObservableObject {
    @Published var lastCheck: Date?
    @Published var isMonitoring = false

    private var modelContext: ModelContext?
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var lastChangeCount: Int = UIPasteboard.general.changeCount
    private var lastSavedHash: Int?

    func configure(context: ModelContext) {
        self.modelContext = context
    }

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = UIPasteboard.general.changeCount

        observers.append(NotificationCenter.default.addObserver(
            forName: UIPasteboard.changedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.checkNow() }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.checkNow() }
        })

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkNow() }
        }

        checkNow()
    }

    func stop() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    /// 读一次当前剪贴板，有新内容就存一条
    func checkNow() {
        lastCheck = Date()
        let board = UIPasteboard.general
        guard board.changeCount != lastChangeCount else { return }
        lastChangeCount = board.changeCount
        saveCurrentIfNew(board: board)
    }

    private func saveCurrentIfNew(board: UIPasteboard) {
        guard let context = modelContext else { return }

        // 1. 图片优先
        if let image = board.image,
           let data = image.jpegData(compressionQuality: 0.85) ?? image.pngData() {
            let hash = data.hashValue
            guard hash != lastSavedHash else { return }
            lastSavedHash = hash
            context.insert(ClipboardItem(kind: .image, imageData: data))
            try? context.save()
            return
        }

        // 2. 链接（从 Safari 等 App 复制的 URL）
        if let url = board.url {
            let text = url.absoluteString
            guard text.hashValue != lastSavedHash else { return }
            lastSavedHash = text.hashValue
            context.insert(ClipboardItem(kind: .url, text: text, urlString: text))
            try? context.save()
            return
        }

        // 3. 文字；整段就是链接时按链接存
        if let string = board.string, !string.isEmpty {
            guard string.hashValue != lastSavedHash else { return }
            lastSavedHash = string.hashValue
            if let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
               let scheme = url.scheme, scheme == "http" || scheme == "https" {
                context.insert(ClipboardItem(kind: .url, text: string, urlString: url.absoluteString))
            } else {
                context.insert(ClipboardItem(kind: .text, text: string))
            }
            try? context.save()
        }
    }
}

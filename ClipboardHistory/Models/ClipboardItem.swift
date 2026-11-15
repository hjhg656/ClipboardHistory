import Foundation
import SwiftData

/// 一条剪贴板记录：文字 / 图片 / 链接三种
@Model
final class ClipboardItem {
    enum Kind: String, Codable, CaseIterable {
        case text   // 纯文字
        case image  // 图片
        case url    // 链接
    }

    var id: UUID
    var createdAt: Date
    var kindRaw: String
    var text: String?
    var imageData: Data?
    var urlString: String?

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    init(kind: Kind, text: String? = nil, imageData: Data? = nil, urlString: String? = nil, createdAt: Date = Date()) {
        self.id = UUID()
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.text = text
        self.imageData = imageData
        self.urlString = urlString
    }

    /// 列表里显示的标题
    var title: String {
        switch kind {
        case .text:
            return text ?? ""
        case .url:
            return urlString ?? text ?? ""
        case .image:
            return "图片"
        }
    }

    /// 列表里显示的副标题
    var subtitle: String {
        switch kind {
        case .text:
            return text ?? ""
        case .url:
            return urlString ?? ""
        case .image:
            if let data = imageData {
                return "\(data.count / 1024) KB"
            }
            return ""
        }
    }
}

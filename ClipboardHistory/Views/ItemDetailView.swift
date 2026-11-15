import SwiftUI
import UIKit

/// 一条记录的详情页：文字可复制，图片可存相册，链接可打开
struct ItemDetailView: View {
    let item: ClipboardItem
    @State private var savedHint: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                + Text("  ")
                + Text(item.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                switch item.kind {
                case .text:
                    Text(item.text ?? "")
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        UIPasteboard.general.string = item.text
                        savedHint = "已复制"
                    } label: {
                        Label("复制这段文字", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                case .image:
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                        Button {
                            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                            savedHint = "已保存到相册"
                        } label: {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                case .url:
                    if let urlString = item.urlString {
                        Text(urlString)
                            .font(.body)
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                        Link(destination: URL(string: urlString) ?? URL(string: "https://example.com")!) {
                            Label("在 Safari 中打开", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            UIPasteboard.general.string = urlString
                            savedHint = "已复制链接"
                        } label: {
                            Label("复制链接", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let hint = savedHint {
                Text(hint)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .onAppear {
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            savedHint = nil
                        }
                    }
            }
        }
    }

    private var title: String {
        switch item.kind {
        case .text: return "文字"
        case .image: return "图片"
        case .url: return "链接"
        }
    }
}

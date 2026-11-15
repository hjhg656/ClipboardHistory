import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var monitor: PasteboardMonitor
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var items: [ClipboardItem]

    @State private var searchText = ""
    @State private var selectedKind: ClipboardItem.Kind? = nil
    @State private var showClearConfirm = false
    @State private var copiedHint: String? = nil

    private var filteredItems: [ClipboardItem] {
        items.filter { item in
            if let kind = selectedKind, item.kind != kind { return false }
            if searchText.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 类型筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "全部", kind: nil)
                        filterChip(title: "文字", kind: .text)
                        filterChip(title: "图片", kind: .image)
                        filterChip(title: "链接", kind: .url)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("还没有记录")
                            .font(.headline)
                        Text("复制一段文字、一张图或一个链接，\n再回到这个 App，就会自动存下来。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                rowView(item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(item)
                                    try? modelContext.save()
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    copyBack(item)
                                } label: {
                                    Label("复制", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                // 底部状态栏
                HStack {
                    Circle()
                        .fill(monitor.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(monitor.isMonitoring ? "监听中（App 打开时）" : "已停止")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("共 \(items.count) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("剪贴板历史")
            .searchable(text: $searchText, prompt: "搜索历史")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("清空全部", systemImage: "trash")
                        }
                        Button {
                            monitor.checkNow()
                        } label: {
                            Label("立即读取一次", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("清空全部记录？", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    for item in items { modelContext.delete(item) }
                    try? modelContext.save()
                }
            }
            .overlay(alignment: .top) {
                if let hint = copiedHint {
                    Text(hint)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                }
            }
        }
    }

    private func filterChip(title: String, kind: ClipboardItem.Kind?) -> some View {
        Button {
            selectedKind = kind
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedKind == kind ? Color.blue : Color(.systemGray5), in: Capsule())
                .foregroundStyle(selectedKind == kind ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func rowView(_ item: ClipboardItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: item.kind))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                if item.kind == .image, let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Text(item.title)
                        .lineLimit(2)
                        .font(.body)
                }
                Text(item.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func icon(for kind: ClipboardItem.Kind) -> String {
        switch kind {
        case .text: return "doc.text"
        case .image: return "photo"
        case .url: return "link"
        }
    }

    /// 点“复制”把这条重新放回剪贴板
    private func copyBack(_ item: ClipboardItem) {
        let board = UIPasteboard.general
        switch item.kind {
        case .text:
            board.string = item.text
        case .url:
            if let urlString = item.urlString, let url = URL(string: urlString) {
                board.url = url
            } else {
                board.string = item.text
            }
        case .image:
            if let data = item.imageData, let image = UIImage(data: data) {
                board.image = image
            }
        }
        copiedHint = "已复制回剪贴板"
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copiedHint = nil
        }
    }
}

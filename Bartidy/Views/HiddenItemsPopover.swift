//
//  HiddenItemsPopover.swift
//  Bartidy
//
//  노치에 가려진 메뉴바 앱 목록 팝업. 클릭 즉시 로딩 상태로 떠서 체감 지연을 없애고,
//  스캔이 끝나면 model.items가 채워지며 목록으로 갱신된다. 행 클릭 시 onSelect를 호출한다.
//

import SwiftUI

/// 팝업 내용 상태. items가 nil이면 아직 스캔 중(로딩).
@MainActor
final class HiddenItemsModel: ObservableObject {
    @Published var items: [HiddenMenuItem]?
}

struct HiddenItemsPopover: View {
    @ObservedObject var model: HiddenItemsModel
    let onSelect: (HiddenMenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("노치에 가려진 아이콘")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            content
        }
        .frame(width: 240)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var content: some View {
        if let items = model.items {
            if items.isEmpty {
                Text("노치에 가려진 아이콘이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HStack(spacing: 8) {
                            if let icon = item.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            Text(item.appName)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("찾는 중…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

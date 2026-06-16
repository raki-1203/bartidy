//
//  HiddenItemsPopover.swift
//  Bartidy
//
//  노치에 가려진 메뉴바 앱 목록 팝업. 행을 클릭하면 onSelect 콜백을 호출한다.
//

import SwiftUI

struct HiddenItemsPopover: View {
    let items: [HiddenMenuItem]
    let onSelect: (HiddenMenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("노치에 가려진 아이콘")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

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
        }
        .frame(width: 240)
        .padding(.bottom, 6)
    }
}

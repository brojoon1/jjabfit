// ExercisePickerView.swift — choose exercises from catalog (by part / by equipment)

import SwiftUI

struct ExercisePickerView: View {
    @EnvironmentObject var model: AppModel
    var onClose: () -> Void

    @State private var mode = "부위"        // 부위 | 도구
    @State private var category = "전체"
    @State private var query = ""
    @State private var picked: [String] = []

    private var categories: [String] {
        ["전체"] + (mode == "부위" ? Catalog.parts : Catalog.equips)
    }
    private var list: [CatalogItem] {
        Catalog.all.filter { c in
            if !query.isEmpty && !c.name.localizedCaseInsensitiveContains(query) { return false }
            if category == "전체" { return true }
            return mode == "부위" ? c.part == category : c.equip == category
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            T.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                NavBar(title: "운동 추가", onBack: onClose) {
                    Button("닫기") { onClose() }.font(.system(size: 16, weight: .semibold)).foregroundStyle(T.accent)
                }

                searchField.padding(.horizontal, 16).padding(.bottom, 12)
                modeToggle.padding(.horizontal, 16).padding(.bottom, 10)
                categoryChips.padding(.bottom, 10)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(list) { c in row(c) }
                        if list.isEmpty {
                            EmptyStateView(systemIcon: "magnifyingglass", title: "검색 결과가 없어요",
                                           desc: "다른 부위나 키워드로 찾아보세요.")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            if !picked.isEmpty {
                EFButton(title: "\(picked.count)개 운동 추가", full: true) {
                    model.addExercises(picked.compactMap { Catalog.item($0) })
                }
                .padding(.horizontal, 16).padding(.bottom, 30).padding(.top, 12)
                .background(LinearGradient(colors: [.clear, T.bg], startPoint: .top, endPoint: .bottom))
            }
        }
        .onChange(of: mode) { _ in category = "전체" }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .semibold)).foregroundStyle(T.text4)
            TextField("운동 이름 검색", text: $query)
                .font(.system(size: 16)).foregroundStyle(T.text).tint(T.accent)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(T.text4)
                }
            }
        }
        .padding(.horizontal, 12).frame(height: 42)
        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(["부위", "도구"], id: \.self) { m in
                Button { mode = m } label: {
                    Text(mode == m ? m : m + "별")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(mode == m ? T.text : T.text4)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(mode == m ? T.surface3 : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(T.surface).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { c in
                    let active = category == c
                    let col = (mode == "부위" && c != "전체") ? PartColor.of(c) : T.accent
                    Button { Haptic.tap(); category = c } label: {
                        Text(c).font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(active ? (c == "전체" ? .white : Color(hex: "0c0c0e")) : T.text3)
                            .padding(.horizontal, 14).frame(height: 34)
                            .background(active ? col : T.surface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func row(_ c: CatalogItem) -> some View {
        let on = picked.contains(c.id)
        return Button {
            Haptic.tap()
            if on { picked.removeAll { $0 == c.id } } else { picked.append(c.id) }
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(PartColor.of(c.part).opacity(0.18)).frame(width: 38, height: 38)
                    Image(systemName: "dumbbell.fill").font(.system(size: 17)).foregroundStyle(PartColor.of(c.part))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(T.text)
                    Text("\(c.part) · \(c.equip)").font(.system(size: 13)).foregroundStyle(T.text4)
                }
                Spacer()
                ZStack {
                    Circle().fill(on ? T.accent : .clear).frame(width: 26, height: 26)
                        .overlay(Circle().stroke(T.hairline2, lineWidth: on ? 0 : 2))
                    if on { Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)).foregroundStyle(.white) }
                }
            }
            .padding(.vertical, 11).padding(.horizontal, 4)
            .overlay(Rectangle().fill(T.hairline).frame(height: 0.5), alignment: .bottom)
        }
        .buttonStyle(.plain)
    }
}

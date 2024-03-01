//
//  ReorderableForEach.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.02.24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers


struct ReorderableForEach<Item: Any, Content: View>: View {
    @Binding var items: [ReorderableItem<Item>]
    var defaultItem: ReorderableItem<Item>
    var content: (Int, Item) -> Content
    
    @State var draggedItemId: UUID? = nil
    @State var allowDeletion: Bool = false
    
    var body: some View {
        VStack {
            ForEach(Array(zip(items.indices, items)), id: \.1.id) { ix, item in
                HStack {
                    if allowDeletion {
                        Button {
                            items.remove(at: ix)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .padding(5)
                                .bold()
                        }.buttonStyle(.plain)
                    }
                    HStack {
                        content(ix, item.item)
                        Image(systemName: "line.3.horizontal")
                            .padding(5)
                    }
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.background)
                            .ignoresSafeArea()
                    )
                }
                .onDrag {
                    self.draggedItemId = item.id
                    return NSItemProvider(item: nil, typeIdentifier: item.id.uuidString)
                } preview: {
                    EmptyView()
                }
                .onDrop(of: [.plainText], delegate: DropViewDelegate(targetId: item.id, sourceId: $draggedItemId, items: $items))
            }
            HStack {
                Button {
                    allowDeletion.toggle()
                } label: {
                    Text(allowDeletion ? "Disable deletion" : "Enable deletion")
                        .bold()
                }
                .tint(Color.red)
                Spacer()
                Button {
                    items.append(defaultItem)
                } label: {
                    Image(systemName: "plus")
                        .bold()
                        .padding(.vertical, 2)
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
            }.padding(.top, 3)
        }.animation(.default, value: allowDeletion)
    }
}


struct ReorderableItem<Item: Any>: Identifiable {
    let id = UUID()
    var item: Item
    
    static func list(items: [Item]) -> [ReorderableItem] {
        items.map({ item in ReorderableItem(item: item) })
    }
    
    static func items(_ reorderableItems: [ReorderableItem]) -> [Item] {
        reorderableItems.map { $0.item }
    }
}


struct DropViewDelegate<Item: Any>: DropDelegate {
    let targetId: UUID
    @Binding var sourceId : UUID?
    @Binding var items: [ReorderableItem<Item>]

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let sourceId = self.sourceId else {
            return
        }

        if sourceId != targetId {
            guard let sourceIndex = items.firstIndex(where: { $0.id == sourceId }),
                  let targetIndex = items.firstIndex(where: { $0.id == targetId })
            else { return }
            withAnimation(.default) {
                self.items.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex)
            }
        }
    }
}

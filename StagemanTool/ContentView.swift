//
//  ContentView.swift
//  StagemanTool
//
//  Created by F7urry on 12/10/25.
//
import SwiftUI

// sidebar selection: a section, or the cross-section "Modified" filter
enum SidebarItem: Hashable {
    case section(WMSection)
    case modified
}

struct ContentView: View {
    @ObservedObject var service: WindowManagerService
    @State private var selection: SidebarItem? = .section(WMSection.all[0])
    @State private var search = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(service: service, selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            SectionPane(service: service, item: selection ?? .section(WMSection.all[0]), search: search)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ActionBar(service: service)
                }
        }
        .searchable(text: $search, placement: .sidebar, prompt: "Search settings")
        .navigationTitle("Stage Manager Settings")
        .navigationSubtitle(subtitle)
        .frame(minWidth: 720, minHeight: 560)
        .onAppear {
            service.loadDefaults()
        }
        .background(shortcuts)
    }

    private var subtitle: String {
        switch selection {
        case .section(let section): return section.name
        case .modified: return "Modified"
        case nil: return ""
        }
    }

    // hidden buttons that provide ⌘1–⌘6 section shortcuts
    private var shortcuts: some View {
        ZStack {
            ForEach(Array(WMSection.all.enumerated()), id: \.offset) { index, section in
                Button("") { selection = .section(section); search = "" }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
        }
        .opacity(0)
        .accessibilityHidden(true)
    }
}

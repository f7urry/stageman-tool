import SwiftUI

struct SidebarView: View {
    @ObservedObject var service: WindowManagerService
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(WMSection.all) { section in
                    Label(section.name, systemImage: section.icon)
                        .badge(service.modifiedCount(in: section.name))
                        .tag(SidebarItem.section(section))
                        .accessibilityIdentifier("ui-sidebar-\(section.name)")
                }
            }
            Section("Overview") {
                Label("Modified", systemImage: "dot.circle")
                    .badge(WMSetting.all.filter(service.isModified).count)
                    .tag(SidebarItem.modified)
                    .accessibilityIdentifier("ui-sidebar-modified")
            }
        }
        .listStyle(.sidebar)
    }
}

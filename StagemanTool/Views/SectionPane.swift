import SwiftUI

// One card worth of rows, already filtered for the current view.
struct CardModel: Identifiable {
    let title: String
    let icon: String
    let subtitle: String
    let settings: [WMSetting]

    var id: String { title }
}

struct SectionPane: View {
    @ObservedObject var service: WindowManagerService
    let item: SidebarItem
    let search: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if cards.isEmpty {
                    emptyState
                }
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    SettingsCard(service: service, card: card)
                        .opacity(appeared || reduceMotion ? 1 : 0)
                        .offset(y: appeared || reduceMotion ? 0 : 8)
                        .animation(.easeOut(duration: 0.22).delay(Double(index) * 0.03), value: appeared)
                }
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .redacted(reason: service.isLoaded ? [] : .placeholder)
        .disabled(service.isApplying)
        .onAppear { appeared = true }
        .onChange(of: item) { replayAppear() }
    }

    private func replayAppear() {
        appeared = false
        DispatchQueue.main.async { appeared = true }
    }

    // MARK: - Content

    private var title: String {
        if !search.isEmpty { return "Search Results" }
        switch item {
        case .section(let section): return section.name
        case .modified: return "Modified"
        }
    }

    private var summary: String {
        if !search.isEmpty { return "Settings matching “\(search)”." }
        switch item {
        case .section(let section): return section.summary
        case .modified: return "Settings that differ from the system default, or have unsaved edits."
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(summary)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: search.isEmpty ? "checkmark.circle" : "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(search.isEmpty ? "Everything is at its system default." : "No settings found.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var cards: [CardModel] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        let sections: [WMSection]
        if !query.isEmpty {
            sections = WMSection.all
        } else if case .section(let section) = item {
            sections = [section]
        } else {
            sections = WMSection.all
        }

        var result: [CardModel] = []
        for section in sections {
            for card in section.cards {
                let settings = WMSetting.all.filter { setting in
                    guard setting.section == section.name, setting.card == card.title else { return false }
                    if !query.isEmpty {
                        return setting.label.lowercased().contains(query) || setting.key.lowercased().contains(query)
                    }
                    if case .modified = item { return service.isModified(setting) }
                    return true
                }
                if !settings.isEmpty {
                    // prefix with the section when cards from several sections are mixed
                    let mixed = sections.count > 1
                    result.append(CardModel(title: mixed ? "\(section.name) · \(card.title)" : card.title,
                                            icon: card.icon, subtitle: card.subtitle, settings: settings))
                }
            }
        }
        return result
    }
}

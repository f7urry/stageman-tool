import SwiftUI

struct SettingsCard: View {
    @ObservedObject var service: WindowManagerService
    let card: CardModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(service: service, card: card)
                .padding(.bottom, 8)
            ForEach(Array(card.settings.enumerated()), id: \.element.id) { index, setting in
                SettingRow(service: service, setting: setting)
                if index < card.settings.count - 1 {
                    Divider().padding(.leading, 18)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(card.title)
        .accessibilityIdentifier("ui-card-\(card.title)")
    }
}

struct CardHeader: View {
    @ObservedObject var service: WindowManagerService
    let card: CardModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: card.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(card.title).font(.headline)
                Text(card.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if card.settings.contains(where: service.isModified) {
                Button("Reset Card") {
                    card.settings.filter(service.isModified).forEach(service.revert)
                }
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityIdentifier("ui-reset-card-\(card.title)")
            }
        }
    }
}

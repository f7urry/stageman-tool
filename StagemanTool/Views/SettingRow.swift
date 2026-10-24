import SwiftUI

struct SettingRow: View {
    @ObservedObject var service: WindowManagerService
    let setting: WMSetting

    @State private var hovering = false

    private var enabled: Bool { service.isEnabled(setting) }
    private var saved: Bool { service.present.contains(setting.key) }
    private var unsaved: Bool { service.dirty.contains(setting.key) }

    var body: some View {
        HStack(spacing: 12) {
            ModifiedDot(saved: saved, unsaved: unsaved)

            VStack(alignment: .leading, spacing: 2) {
                Text(setting.label)
                if let caption = setting.caption {
                    Text(caption).font(.caption).foregroundStyle(.secondary)
                }
                if setting.ignoredOnThisOS {
                    Label("Ignored by macOS 27", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 12)

            control
                .disabled(!enabled)

            revertSlot
        }
        .frame(minHeight: 36)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.04 : 0))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // clicking a toggle row's label flips the switch
            if setting.kind == .bool, enabled {
                service.boolBinding(for: setting).wrappedValue.toggle()
            }
        }
        .onHover { over in
            withAnimation(.easeOut(duration: 0.12)) { hovering = over }
        }
        .opacity(enabled ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.2), value: enabled)
        .help(setting.key)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(setting.label + (saved || unsaved ? ", modified" : ""))
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(setting.ignoredOnThisOS ? "Ignored by macOS 27" : (setting.caption ?? ""))
        .accessibilityIdentifier("ui-row-\(setting.key)")
    }

    @ViewBuilder
    private var control: some View {
        switch setting.kind {
        case .bool:
            Toggle("", isOn: service.boolBinding(for: setting))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .accessibilityIdentifier("ui-toggle-\(setting.key)")
        case .choice:
            Picker("", selection: Binding(
                get: { Int(service.value(setting)) },
                set: { service.binding(for: setting).wrappedValue = Double($0) }
            )) {
                ForEach(Array(setting.options.enumerated()), id: \.offset) { index, option in
                    Text(option).tag(index)
                }
            }
            .labelsHidden()
            .controlSize(.small)
            .fixedSize()
            .accessibilityIdentifier("ui-picker-\(setting.key)")
        case .int, .float:
            NumberField(setting: setting, value: service.binding(for: setting))
        }
    }

    private var revertSlot: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { service.revert(setting) }
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .frame(width: 20)
        .opacity(saved || unsaved ? (hovering ? 1 : 0.6) : 0)
        .disabled(!(saved || unsaved))
        .help("Revert \(setting.key) to the system default")
        .accessibilityLabel("Revert \(setting.label) to system default")
        .accessibilityIdentifier("ui-revert-\(setting.key)")
    }

    private var accessibilityValue: String {
        let value = service.value(setting)
        if setting.kind == .bool { return value != 0 ? "On" : "Off" }
        if setting.kind == .choice, setting.options.indices.contains(Int(value)) { return setting.options[Int(value)] }
        return "\(NumberField.format(value, kind: setting.kind)) \(setting.unit ?? "")"
    }
}

// 6pt dot: solid = saved override, ring = unsaved edit
struct ModifiedDot: View {
    let saved: Bool
    let unsaved: Bool

    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.orange, lineWidth: 1.5).opacity(unsaved ? 1 : 0)
            Circle().fill(Color.orange).opacity(saved && !unsaved ? 1 : 0)
        }
        .frame(width: 6, height: 6)
        .animation(.spring(response: 0.3), value: saved)
        .animation(.spring(response: 0.3), value: unsaved)
        .accessibilityHidden(true)
    }
}

// Locale-independent numeric field with unit and stepper.
struct NumberField: View {
    let setting: WMSetting
    @Binding var value: Double

    @State private var text = ""
    @State private var invalid = false
    @State private var shake: CGFloat = 0
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func format(_ value: Double, kind: WMSetting.Kind) -> String {
        if kind == .int || value == value.rounded() { return String(Int(value)) }
        var s = String(format: "%.3f", value)
        while s.hasSuffix("0") { s.removeLast() }
        return s
    }

    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 64)
                .focused($focused)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red, lineWidth: invalid ? 1 : 0)
                )
                .offset(x: shake)
                .onSubmit(commit)
                .onChange(of: focused) { if !focused { commit() } }
                .accessibilityIdentifier("ui-field-\(setting.key)")

            Text(setting.unit ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Stepper("", value: $value, step: setting.step)
                .labelsHidden()
                .controlSize(.small)
                .accessibilityIdentifier("ui-stepper-\(setting.key)")
        }
        .onAppear { text = Self.format(value, kind: setting.kind) }
        .onChange(of: value) { if !focused { text = Self.format(value, kind: setting.kind) } }
    }

    private func commit() {
        // accept both "0.1" and "0,1", always display with "."
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if let parsed = Double(normalized), parsed >= 0 {
            let newValue = setting.kind == .int ? parsed.rounded() : parsed
            if newValue != value { value = newValue }
            invalid = false
            text = Self.format(newValue, kind: setting.kind)
        } else {
            NSSound.beep()
            invalid = true
            text = Self.format(value, kind: setting.kind)
            if !reduceMotion { runShake() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { invalid = false }
        }
    }

    private func runShake() {
        let steps: [CGFloat] = [-4, 4, -4, 0]
        for (i, x) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.linear(duration: 0.05)) { shake = x }
            }
        }
    }
}

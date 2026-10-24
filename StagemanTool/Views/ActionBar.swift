import SwiftUI

struct ActionBar: View {
    @ObservedObject var service: WindowManagerService
    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                status
                Spacer()

                Menu("More") {
                    Button("Force Enable Stage Manager") {
                        service.forceEnableStageManager()
                    }
                    .accessibilityIdentifier("ui-btn-force-enable")
                    Divider()
                    Button("Reset All…", role: .destructive) {
                        confirmReset = true
                    }
                    .accessibilityIdentifier("ui-btn-reset-all")
                }
                .fixedSize()
                .accessibilityIdentifier("ui-menu-more")

                Button("Reload") {
                    service.loadDefaults()
                }
                .controlSize(.large)
                .keyboardShortcut("r", modifiers: .command)
                .accessibilityIdentifier("ui-btn-reload")

                Button {
                    service.applyDefaults()
                } label: {
                    if service.isApplying {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Applying…")
                        }
                    } else {
                        Text("Apply")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("s", modifiers: .command)
                .disabled(service.dirty.isEmpty || service.isApplying)
                .accessibilityIdentifier("ui-btn-apply")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.bar)
        .confirmationDialog("Reset all Stage Manager settings?", isPresented: $confirmReset) {
            Button("Reset All", role: .destructive) {
                service.resetStageManager()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { service.loadDefaults() }
            }
        } message: {
            Text("This deletes every com.apple.WindowManager preference and restarts Stage Manager and the Dock.")
        }
    }

    private var status: some View {
        let count = service.dirty.count
        return HStack(spacing: 6) {
            Circle()
                .fill(count > 0 ? Color.orange : Color.green)
                .frame(width: 6, height: 6)
            Text(count > 0 ? "\(count) unsaved change\(count == 1 ? "" : "s")" : "All changes applied")
                .font(.callout)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.default, value: count)
        }
    }
}

import Foundation
import SwiftUI
import Combine

// A single com.apple.WindowManager preference key.
// Keys were sourced from the WindowManagerPreferences table in WindowManager.framework (macOS 27.2).
struct WMSetting: Identifiable {
    enum Kind { case bool, int, float, choice }

    let key: String
    let label: String
    let section: String
    let card: String
    let kind: Kind
    let defaultValue: Double
    var unit: String? = nil
    var caption: String? = nil
    // labels for a .choice setting, indexed by its Int raw value
    var options: [String] = []
    // key of a bool setting that must be on for this one to matter
    var dependsOn: String? = nil

    var id: String { key }

    // macOS 27 only reads UserSetting keys from defaults; InternalSetting keys are honored on
    // Apple-internal builds only (see docs/macos27-key-map.md)
    static let userSettingKeys: Set<String> = [
        "GloballyEnabled", "AppWindowGroupingBehavior", "StageManagerMinimizationBehavior",
        "AutoHide", "HideDesktop", "StandardHideDesktopIcons", "StageManagerHideWidgets",
        "StandardHideWidgets", "EnableStandardClickToShowDesktop", "EnableStageManagerClickToEmptyStage",
        "EnableTilingByEdgeDrag", "EnableTopTilingByEdgeDrag", "EnableTilingOptionAccelerator",
        "EnableTiledWindowMargins",
    ]

    var ignoredOnThisOS: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
            && !Self.userSettingKeys.contains(key)
    }

    var step: Double {
        switch kind {
        case .bool, .int, .choice: return 1
        case .float: return unit == "s" ? 0.05 : 0.1
        }
    }
}

struct WMSection: Identifiable, Hashable {
    let name: String
    let icon: String
    let summary: String
    // card title -> (icon, subtitle), in display order
    let cards: [(title: String, icon: String, subtitle: String)]

    var id: String { name }

    static func == (lhs: WMSection, rhs: WMSection) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

extension WMSection {
    static let all: [WMSection] = [
        .init(name: "General", icon: "gearshape", summary: "Turn Stage Manager on and control how the strip hides.", cards: [
            ("Stage Manager", "rectangle.3.group", "Core behaviour and animation"),
            ("Auto Hide", "eye.slash", "When the recent apps strip slides away"),
            ("Window Sets", "square.stack.3d.up", "How windows join and stay in a set"),
        ]),
        .init(name: "Desktop & Widgets", icon: "menubar.dock.rectangle", summary: "What shows on the desktop and what clicking the wallpaper does.", cards: [
            ("Desktop Items", "doc.on.doc", "Files and folders on the desktop"),
            ("Widgets", "square.grid.2x2", "Desktop widgets visibility"),
            ("Click Wallpaper", "cursorarrow.click", "Clicking empty wallpaper"),
        ]),
        .init(name: "Strip Layout", icon: "sidebar.left", summary: "Size, spacing and capacity of the recent apps strip.", cards: [
            ("Rows", "list.number", "How many groups the strip holds"),
            ("Spacing & Insets", "arrow.left.and.right", "Gaps around and between items"),
            ("Item Size", "rectangle.expand.vertical", "Thumbnail dimensions"),
            ("App Icon", "app.badge", "Icon badge on each thumbnail"),
        ]),
        .init(name: "Strip Appearance", icon: "paintbrush", summary: "Shadows, corners and the 3D tilt of strip thumbnails.", cards: [
            ("Shadows", "shadow", "Drop shadow under thumbnails"),
            ("Corners", "square.on.circle", "Thumbnail corner rounding"),
            ("3D & Hover", "cube.transparent", "Perspective tilt and hover zoom"),
        ]),
        .init(name: "Tiling", icon: "rectangle.split.2x1", summary: "Window tiling gestures and tiled window look.", cards: [
            ("Gestures", "hand.draw", "Ways to trigger tiling"),
            ("Look", "rectangle.split.2x2", "Tiled window spacing and feedback"),
        ]),
        .init(name: "Misc", icon: "ellipsis.circle", summary: "Other window management features.", cards: [
            ("System Features", "macwindow.on.rectangle", "Related window manager features"),
        ]),
    ]
}

extension WMSetting {
    static let all: [WMSetting] = [
        // General
        .init(key: "GloballyEnabled", label: "Stage Manager Enabled", section: "General", card: "Stage Manager", kind: .bool, defaultValue: 0),
        .init(key: "AppWindowGroupingBehavior", label: "Show App Windows", section: "General", card: "Stage Manager", kind: .choice, defaultValue: 1,
              options: ["One at a Time", "All at Once", "One at a Time, Promote on Click"]),
        .init(key: "StageManagerMinimizationBehavior", label: "Minimize Windows To", section: "General", card: "Stage Manager", kind: .choice, defaultValue: 0,
              options: ["Strip", "Bottom of Strip", "Dock"]),
        .init(key: "AnimationSpeed", label: "Animation Speed", section: "General", card: "Stage Manager", kind: .float, defaultValue: 8, unit: "×"),
        .init(key: "AutoHide", label: "Auto Hide Strip", section: "General", card: "Auto Hide", kind: .bool, defaultValue: 0),
        .init(key: "AutoHideWhenOccluded", label: "Hide When Occluded", section: "General", card: "Auto Hide", kind: .bool, defaultValue: 0, caption: "Hide when a window covers the strip"),
        .init(key: "AutoHideDelay", label: "Delay", section: "General", card: "Auto Hide", kind: .float, defaultValue: 0.1, unit: "s"),
        .init(key: "AutoHideOverlapThreshold", label: "Overlap Threshold", section: "General", card: "Auto Hide", kind: .int, defaultValue: 52, unit: "pt"),
        .init(key: "ShiftClickToAddToSet", label: "Shift-Click Adds to Set", section: "General", card: "Window Sets", kind: .bool, defaultValue: 1),
        .init(key: "EnableAutomaticNewWindowAddToWindowSet", label: "Auto Add New Windows", section: "General", card: "Window Sets", kind: .bool, defaultValue: 0),
        .init(key: "ShouldPersistLeftStripOrdering", label: "Persist Strip Ordering", section: "General", card: "Window Sets", kind: .bool, defaultValue: 1),

        // Desktop & Widgets
        .init(key: "HideDesktop", label: "Hide in Stage Manager", section: "Desktop & Widgets", card: "Desktop Items", kind: .bool, defaultValue: 0),
        .init(key: "StandardHideDesktopIcons", label: "Hide in Standard Windowing", section: "Desktop & Widgets", card: "Desktop Items", kind: .bool, defaultValue: 0),
        .init(key: "StageManagerHideWidgets", label: "Hide in Stage Manager", section: "Desktop & Widgets", card: "Widgets", kind: .bool, defaultValue: 0),
        .init(key: "StandardHideWidgets", label: "Hide in Standard Windowing", section: "Desktop & Widgets", card: "Widgets", kind: .bool, defaultValue: 0),
        .init(key: "EnableStandardClickToShowDesktop", label: "Shows Desktop", section: "Desktop & Widgets", card: "Click Wallpaper", kind: .bool, defaultValue: 1, caption: "Standard windowing"),
        .init(key: "EnableStageManagerClickToEmptyStage", label: "Empties Stage", section: "Desktop & Widgets", card: "Click Wallpaper", kind: .bool, defaultValue: 1, caption: "Stage Manager"),

        // Strip Layout
        .init(key: "LeftStripMaximumRowCount", label: "Max Rows", section: "Strip Layout", card: "Rows", kind: .int, defaultValue: 18, unit: "rows"),
        .init(key: "LeftStripMinimumRowCount", label: "Min Rows", section: "Strip Layout", card: "Rows", kind: .int, defaultValue: 0, unit: "rows"),
        .init(key: "LeftStripPileMaximumWindowCount", label: "Max Windows per Pile", section: "Strip Layout", card: "Rows", kind: .int, defaultValue: 3, unit: "windows"),
        .init(key: "LeftStripPileVerticalSpacing", label: "Vertical Spacing", section: "Strip Layout", card: "Spacing & Insets", kind: .int, defaultValue: 12, unit: "pt"),
        .init(key: "LeftStripPileInterItemHorizontalSpacing", label: "Pile Horizontal Spacing", section: "Strip Layout", card: "Spacing & Insets", kind: .float, defaultValue: 0, unit: "pt"),
        .init(key: "LeftStripEdgeHorizontalInset", label: "Edge Inset", section: "Strip Layout", card: "Spacing & Insets", kind: .int, defaultValue: 10, unit: "pt"),
        .init(key: "HorizontalInsetFromStrip", label: "Horizontal Inset", section: "Strip Layout", card: "Spacing & Insets", kind: .int, defaultValue: 0, unit: "pt"),
        .init(key: "StageFrameMinimumHorizontalInset", label: "Stage Min Inset", section: "Strip Layout", card: "Spacing & Insets", kind: .float, defaultValue: 0, unit: "pt", caption: "Gap between strip and stage"),
        .init(key: "HiddenStripPeekWidth", label: "Hidden Peek Width", section: "Strip Layout", card: "Spacing & Insets", kind: .float, defaultValue: 0, unit: "pt", caption: "Visible sliver when auto-hidden"),
        .init(key: "MaximumItemHeight", label: "Max Height", section: "Strip Layout", card: "Item Size", kind: .int, defaultValue: 52, unit: "pt"),
        .init(key: "PreferredMinimumItemHeight", label: "Preferred Min Height", section: "Strip Layout", card: "Item Size", kind: .float, defaultValue: 0, unit: "pt"),
        .init(key: "ItemWidth", label: "Width", section: "Strip Layout", card: "Item Size", kind: .int, defaultValue: 0, unit: "pt", caption: "0 = automatic"),
        .init(key: "InterItemVerticalSpacing", label: "Inter-Item Vertical", section: "Strip Layout", card: "Item Size", kind: .float, defaultValue: 0, unit: "pt"),
        .init(key: "InterItemHorizontalSpacing", label: "Inter-Item Horizontal", section: "Strip Layout", card: "Item Size", kind: .float, defaultValue: 0, unit: "pt"),
        .init(key: "AppIconSize", label: "Size", section: "Strip Layout", card: "App Icon", kind: .int, defaultValue: 32, unit: "pt"),
        .init(key: "LeftStripAppIconLeftOffset", label: "Left Offset", section: "Strip Layout", card: "App Icon", kind: .float, defaultValue: 0, unit: "pt"),
        .init(key: "LeftStripAppIconBottomOffset", label: "Bottom Offset", section: "Strip Layout", card: "App Icon", kind: .float, defaultValue: 0, unit: "pt"),

        // Strip Appearance
        .init(key: "EnableStripShadows", label: "Strip Shadows", section: "Strip Appearance", card: "Shadows", kind: .bool, defaultValue: 1),
        .init(key: "StripWindowShadowDensityMultiplier", label: "Density", section: "Strip Appearance", card: "Shadows", kind: .float, defaultValue: 1, unit: "×", dependsOn: "EnableStripShadows"),
        .init(key: "EnableStripCornerRadius", label: "Rounded Corners", section: "Strip Appearance", card: "Corners", kind: .bool, defaultValue: 1),
        .init(key: "StripCornerRadius", label: "Radius", section: "Strip Appearance", card: "Corners", kind: .float, defaultValue: 0, unit: "pt", dependsOn: "EnableStripCornerRadius"),
        .init(key: "EnableStrip3DTransform", label: "3D Tilt Effect", section: "Strip Appearance", card: "3D & Hover", kind: .bool, defaultValue: 1),
        .init(key: "PilePerspectiveDistance", label: "Perspective Distance", section: "Strip Appearance", card: "3D & Hover", kind: .float, defaultValue: 0, unit: "pt", dependsOn: "EnableStrip3DTransform"),
        .init(key: "LeftStripStackDepthStepValue", label: "Stack Depth Step", section: "Strip Appearance", card: "3D & Hover", kind: .float, defaultValue: 0, dependsOn: "EnableStrip3DTransform"),
        .init(key: "StripHoverScaleDistance", label: "Hover Scale", section: "Strip Appearance", card: "3D & Hover", kind: .float, defaultValue: 0, unit: "pt"),
        .init(key: "AppIconHoverScaleDistance", label: "Icon Hover Scale", section: "Strip Appearance", card: "3D & Hover", kind: .float, defaultValue: 0, unit: "pt"),

        // Tiling
        .init(key: "EnableTilingByEdgeDrag", label: "Drag to Screen Edge", section: "Tiling", card: "Gestures", kind: .bool, defaultValue: 1),
        .init(key: "EnableTopTilingByEdgeDrag", label: "Drag to Top to Fill", section: "Tiling", card: "Gestures", kind: .bool, defaultValue: 1),
        .init(key: "EnableTilingOptionAccelerator", label: "Hold Option While Dragging", section: "Tiling", card: "Gestures", kind: .bool, defaultValue: 1),
        .init(key: "EnableTiledWindowMargins", label: "Tiled Window Margins", section: "Tiling", card: "Look", kind: .bool, defaultValue: 1),
        .init(key: "TiledWindowSpacing", label: "Spacing", section: "Tiling", card: "Look", kind: .float, defaultValue: 0, unit: "pt", dependsOn: "EnableTiledWindowMargins"),
        .init(key: "ShowTiledWindowBorder", label: "Show Border", section: "Tiling", card: "Look", kind: .bool, defaultValue: 0),
        .init(key: "DisableTilingAnimations", label: "Disable Animations", section: "Tiling", card: "Look", kind: .bool, defaultValue: 0),
        .init(key: "TilingHotzoneDelay", label: "Hotzone Delay", section: "Tiling", card: "Look", kind: .float, defaultValue: 0, unit: "s"),

        // Misc
        .init(key: "EnableShowDesktop", label: "Show Desktop", section: "Misc", card: "System Features", kind: .bool, defaultValue: 1),
        .init(key: "EnableMissionControl", label: "Mission Control", section: "Misc", card: "System Features", kind: .bool, defaultValue: 1),
        .init(key: "EnableAppExpose", label: "App Exposé", section: "Misc", card: "System Features", kind: .bool, defaultValue: 1),
        .init(key: "SlowAnimationsWhileShiftHeld", label: "Slow Animations with Shift", section: "Misc", card: "System Features", kind: .bool, defaultValue: 0),
    ]
}

class WindowManagerService: ObservableObject {
    @Published var values: [String: Double] = [:]
    // keys explicitly set in the defaults domain (others are using system defaults)
    @Published var present: Set<String> = []
    @Published var dirty: Set<String> = []
    @Published var isApplying = false
    @Published var isLoaded = false

    private let domain = "com.apple.WindowManager"

    // MARK: - Public API

    func value(_ setting: WMSetting) -> Double {
        values[setting.key] ?? setting.defaultValue
    }

    func binding(for setting: WMSetting) -> Binding<Double> {
        Binding(
            get: { self.value(setting) },
            set: { newValue in
                self.values[setting.key] = newValue
                self.dirty.insert(setting.key)
            }
        )
    }

    func boolBinding(for setting: WMSetting) -> Binding<Bool> {
        Binding(
            get: { self.value(setting) != 0 },
            set: { self.binding(for: setting).wrappedValue = $0 ? 1 : 0 }
        )
    }

    func loadDefaults() {
        // read the whole domain in one call instead of one process per key
        var plist: [String: Any] = [:]
        if let output = runCommandAndGetOutput("defaults export \(domain) -"),
           let data = output.data(using: .utf8),
           let parsed = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            plist = parsed
        }

        var newValues: [String: Double] = [:]
        var newPresent: Set<String> = []
        for setting in WMSetting.all {
            if let number = plist[setting.key] as? NSNumber {
                newValues[setting.key] = number.doubleValue
                newPresent.insert(setting.key)
            } else if let string = plist[setting.key] as? String, let number = Double(string) {
                newValues[setting.key] = number
                newPresent.insert(setting.key)
            } else {
                newValues[setting.key] = setting.defaultValue
            }
        }
        values = newValues
        present = newPresent
        dirty = []
        isLoaded = true
    }

    func applyDefaults() {
        var commands: [String] = []
        for setting in WMSetting.all where dirty.contains(setting.key) {
            let value = value(setting)
            switch setting.kind {
            case .bool:  commands.append("defaults write \(domain) \(setting.key) -bool \(value != 0 ? "true" : "false")")
            case .int, .choice: commands.append("defaults write \(domain) \(setting.key) -int \(Int(value))")
            case .float: commands.append("defaults write \(domain) \(setting.key) -float \(value)")
            }
        }
        commands += ["killall -9 WindowManager", "killall -9 Dock"]

        isApplying = true
        let applied = dirty
        // run off the main thread so the UI can show progress while WindowManager restarts
        DispatchQueue.global(qos: .userInitiated).async {
            commands.forEach(Self.run)
            Thread.sleep(forTimeInterval: 1.5)
            DispatchQueue.main.async {
                self.present.formUnion(applied)
                self.dirty.subtract(applied)
                self.isApplying = false
            }
        }
    }

    func isModified(_ setting: WMSetting) -> Bool {
        present.contains(setting.key) || dirty.contains(setting.key)
    }

    func isEnabled(_ setting: WMSetting) -> Bool {
        guard let parent = setting.dependsOn,
              let parentSetting = WMSetting.all.first(where: { $0.key == parent }) else { return true }
        return value(parentSetting) != 0
    }

    func modifiedCount(in section: String) -> Int {
        WMSetting.all.filter { $0.section == section && isModified($0) }.count
    }

    // remove an override so the system default applies again
    func revert(_ setting: WMSetting) {
        if present.contains(setting.key) {
            runCommand("defaults delete \(domain) \(setting.key)")
        }
        values[setting.key] = setting.defaultValue
        present.remove(setting.key)
        dirty.remove(setting.key)
    }

    func forceEnableStageManager() {
        runCommand("defaults write \(domain) GloballyEnabled -int 1")
    }
    func resetStageManager() {
        let baseConfig = [
            "defaults delete \(domain)",
            "rm ~/Library/Containers/com.apple.WindowManager/Data/Library/Preferences/com.apple.WindowManager.plist",
            "defaults write \(domain) AppWindowGroupingBehavior -int 1",
            "defaults write \(domain) AutoHide -int 0",
            "defaults write \(domain) GloballyEnabled -int 1",
            "defaults write \(domain) GloballyEnabledEver -int 1",
            "defaults write \(domain) HideDesktop -int 1",
            "defaults write \(domain) StageManagerHideWidgets -int 0",
            "defaults write \(domain) StandardHideWidgets -int 0"
        ]

        baseConfig.forEach(runCommand)
        reloadStageManager()
    }

    // MARK: - Stage Manager Reload

    private func reloadStageManager() {
        let toggleCommands = [
            "killall -9 WindowManager",
            "killall -9 Dock"
        ]
        toggleCommands.forEach(runCommand)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("Stage Manager reloaded.")
        }
    }

    // MARK: - Command helpers

    private func runCommand(_ command: String) {
        Self.run(command)
    }

    nonisolated private static func run(_ command: String) {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        process.launch()
        process.waitUntilExit()
    }

    private func runCommandAndGetOutput(_ command: String) -> String? {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["bash", "-lc", command]  // use login shell for correct HOME, PATH
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.environment = ["HOME": NSHomeDirectory()] // ensure correct user home
        process.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }

}

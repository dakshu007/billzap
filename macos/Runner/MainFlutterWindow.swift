import Cocoa
import FlutterMacOS

// MainFlutterWindow
// ─────────────────────────────────────────────────────────────────────
// BillZap's macOS window is configured for the "Liquid Glass" look:
//   * the NSWindow background is transparent
//   * the window's content view sits on top of an NSVisualEffectView
//     using the .underWindowBackground material so the desktop wall‑
//     paper shows through with a subtle macOS-native blur
//   * the title bar is fused into the content area (full‑size content
//     view + transparent titlebar) — gives the modern Apple feel
//
// Flutter still owns layout & rendering; this just configures the
// shell window so Flutter widgets that use semi‑transparent surfaces
// (see _GlassSidebar / GlassSurface) actually look frosted instead of
// flat on a solid background.

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // ─── Window chrome ─────────────────────────────────────────────
    // Title bar transparent + content view spans full window — modern
    // Apple "vibrant" pattern (Reminders.app, Settings.app, Mail).
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    // Sensible starting size for desktop billing — comfortable for
    // sidebar + content + dashboard cards.
    self.setContentSize(NSSize(width: 1180, height: 760))
    self.minSize = NSSize(width: 960, height: 640)

    // ─── Translucent background — the "liquid glass" effect ────────
    // We make the window background transparent and slot an
    // NSVisualEffectView behind Flutter's content. The effect view
    // gives a real-time blur of whatever's behind the window
    // (desktop wallpaper, other apps), tinted in macOS-native colors.
    self.backgroundColor = .clear
    self.isOpaque = false
    self.hasShadow = true

    let effectView = NSVisualEffectView()
    effectView.material = .underWindowBackground
    effectView.blendingMode = .behindWindow
    effectView.state = .active
    effectView.translatesAutoresizingMaskIntoConstraints = false

    if let contentView = self.contentView {
      contentView.wantsLayer = true
      contentView.layer?.backgroundColor = .clear

      let flutterView = flutterViewController.view
      // Insert the effect view *below* Flutter's view so Flutter's
      // (potentially semi-transparent) widgets composite over the
      // native blur.
      contentView.addSubview(effectView, positioned: .below, relativeTo: flutterView)

      NSLayoutConstraint.activate([
        effectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        effectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        effectView.topAnchor.constraint(equalTo: contentView.topAnchor),
        effectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

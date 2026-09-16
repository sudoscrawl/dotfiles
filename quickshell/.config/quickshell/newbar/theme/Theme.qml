pragma Singleton
import QtQuick

QtObject {
    // ─────────────────────────────────────────────────────────────
    // FOREST GRUVBOX COLOR PALETTE
    // ─────────────────────────────────────────────────────────────

    // Backgrounds
    readonly property color bg: "#1d2021"               // Base dark background
    readonly property color bgAlpha: "#E61d2021"          // 90% opacity for floating bar
    readonly property color bgCard: "#F21d2021"           // 95% opacity for popups
    readonly property color bgAlt: "#282828"            // Capsule & pill background
    readonly property color bgAltAlpha: "#99282828"       // Translucent pill background
    readonly property color bgLight: "#3c3836"          // Hover background
    readonly property color bgLighter: "#504945"        // Active / pressed background
    readonly property color bgSubtle: "#32302f"         // Subtle card element background

    // Foregrounds & Text
    readonly property color fg: "#d5c6a5"               // Primary text (SwayNC @fg)
    readonly property color fgBright: "#fbf1c7"         // Bright high-contrast text
    readonly property color fgMuted: "#a79983"          // Secondary / muted text (SwayNC @fg-muted)
    readonly property color fgDark: "#685c55"           // Dark subdued text / dividers
    readonly property color fgSubdued: "#504945"        // Deep muted elements

    // Accent Colors
    readonly property color accent: "#9c8166"           // Warm earth accent (SwayNC @accent)
    readonly property color accentAlt: "#79740e"        // Forest moss accent (SwayNC @accent-alt)
    readonly property color yellow: "#fabd2f"          // Gruvbox gold / bright yellow
    readonly property color yellowDim: "#d79921"       // Warm dark yellow
    readonly property color green: "#b8bb26"           // Gruvbox bright green
    readonly property color greenDim: "#7f8c5a"        // SwayNC green
    readonly property color red: "#fb4934"             // Alert / critical red
    readonly property color redDim: "#9d0006"          // Dark red (SwayNC @red)
    readonly property color aqua: "#8ec07c"            // Aqua / cyan
    readonly property color orange: "#fe8019"          // Gruvbox orange
    readonly property color purple: "#d3869b"          // Gruvbox purple
    readonly property color blue: "#83a598"            // Gruvbox blue

    // Borders
    readonly property color border: "#33d5c6a5"         // Subtle warm border (SwayNC & Wofi style)
    readonly property color borderHover: "#66d5c6a5"    // Hover border
    readonly property color borderFocus: "#77fabd2f"    // Highlighted border
    readonly property color borderSubtle: "#18d5c6a5"   // Subtle inner divider

    // ─────────────────────────────────────────────────────────────
    // GEOMETRY & RADII
    // ─────────────────────────────────────────────────────────────
    readonly property int radiusBar: 12                 // Main bar radius
    readonly property int radiusPill: 7                 // Capsule / pill radius
    readonly property int radiusPopup: 16               // Popup window radius
    readonly property int radiusInner: 10               // Inner card elements

    readonly property int barHeight: 36                 // Bar height
    readonly property int capsuleHeight: 26             // Standard capsule height

    // ─────────────────────────────────────────────────────────────
    // TYPOGRAPHY
    // ─────────────────────────────────────────────────────────────
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontSans: "JetBrainsMono Nerd Font"

    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 10
    readonly property int fontSizeRegular: 11
    readonly property int fontSizeMd: 13
    readonly property int fontSizeLg: 15
    readonly property int fontSizeXl: 22
    readonly property int fontSizeTitle: 30

    readonly property int iconSizeSm: 12
    readonly property int iconSizeRegular: 14
    readonly property int iconSizeMd: 15
    readonly property int iconSizeLg: 20
}

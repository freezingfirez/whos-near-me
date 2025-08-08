import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    // Fallback to system colors if named assets are missing
    let accent = Color("AccentColor", bundle: .main).resolve(or: .blue)
    let accentLight = Color("AccentColorLight", bundle: .main).resolve(or: Color.blue.opacity(0.12))
    let background = Color("BackgroundColor", bundle: .main).resolve(or: Color(UIColor.secondarySystemBackground))
    let green = Color("GreenColor", bundle: .main).resolve(or: .green)
    let red = Color("RedColor", bundle: .main).resolve(or: .red)
    let secondaryText = Color("SecondaryTextColor", bundle: .main).resolve(or: .secondary)
}

private extension Color {
    func resolve(or fallback: Color) -> Color {
        // Attempt to read description to decide if the named color exists; if not, use fallback.
        // This is a lightweight heuristic; Color doesn't expose existence directly.
        let description = String(describing: self)
        if description.contains("named(\"") { return self }
        return fallback
    }
}

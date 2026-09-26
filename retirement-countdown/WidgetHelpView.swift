import SwiftUI

struct WidgetHelpView: View {
    @State private var expanded = false

    var body: some View {
        DisclosureGroup("Add to your screens", isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 12) {
                helpRow(symbol: "rectangle.stack",
                        text: "Long-press the Home Screen → tap + → search \"Retirement Countdown\"")
                helpRow(symbol: "lock.rectangle",
                        text: "Edit the Lock Screen → tap Add Widgets below the clock")
                helpRow(symbol: "applewatch",
                        text: "In the Watch app on iPhone → choose a watch face → add a complication")
            }
            .padding(.top, 8)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func helpRow(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
    }
}

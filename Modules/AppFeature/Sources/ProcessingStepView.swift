import SwiftUI

struct ProcessingStepView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(Color.accentColor)

            Text("We\'re translating the menu, gathering dish descriptions, and sourcing imagery.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(progressLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var progressLabel: String {
        let percent = Int(progress * 100)
        return "Processing… \(percent)%"
    }
}

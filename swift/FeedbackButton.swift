import SwiftUI

// MARK: - FeedbackButton
// A card-style button that opens the feedback sheet when tapped.
// Configurable text and icon -- pass your own strings to localize or customize.

struct FeedbackButton: View {
    var icon: String = "\u{1F4A1}"
    var title: String = "Have an idea?"
    var subtitle: String = "Share your ideas with us"

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            FeedbackSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    VStack {
        FeedbackButton()
            .padding()

        FeedbackButton(
            icon: "\u{2728}",
            title: "Missing a feature?",
            subtitle: "Tell us what to build next"
        )
        .padding(.horizontal)
    }
}

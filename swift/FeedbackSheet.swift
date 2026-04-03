import SwiftUI

// MARK: - FeedbackSheet
// A bottom sheet with a feedback text field, optional email field,
// send button with cooldown, and character counter.

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Configurable strings
    var feedbackPlaceholder: String = "What's on your mind?"
    var emailPlaceholder: String = "Leave your email if you'd like us to follow up (totally optional)"
    var sendButtonText: String = "Send"
    var successMessage: String = "Thank you for your feedback!"
    var errorMessage: String = "Could not send feedback. Please check your connection and try again."

    @State private var feedbackText = ""
    @State private var emailText = ""
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var cooldownRemaining = 0
    @State private var cooldownTimer: Timer?

    @FocusState private var focusedField: Field?

    private let maxCharacters = 2000
    private let cooldownDuration = 60
    private let cooldownKey = "feedpush_last_send_timestamp"

    private enum Field {
        case feedback, email
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    feedbackField
                    emailField
                    sendButton
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear { startCooldownIfNeeded() }
            .onDisappear { cooldownTimer?.invalidate() }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = nil }
        }
    }

    // MARK: - Feedback Text Field

    private var feedbackField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $feedbackText)
                .focused($focusedField, equals: .feedback)
                .frame(minHeight: 120)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: feedbackText) { _, newValue in
                    if newValue.count > maxCharacters {
                        feedbackText = String(newValue.prefix(maxCharacters))
                    }
                }
                .overlay(alignment: .topLeading) {
                    if feedbackText.isEmpty {
                        Text(feedbackPlaceholder)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Spacer()
                Text("\(feedbackText.count) / \(maxCharacters)")
                    .font(.caption)
                    .foregroundStyle(feedbackText.count > maxCharacters ? .red : .secondary)
            }
        }
    }

    // MARK: - Email Field

    private var emailField: some View {
        TextField(emailPlaceholder, text: $emailText)
            .focused($focusedField, equals: .email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            Task { await sendFeedback() }
        } label: {
            Group {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else if cooldownRemaining > 0 {
                    Text("\(sendButtonText) (\(cooldownRemaining)s)")
                } else {
                    Text(sendButtonText)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(isSendDisabled ? Color.gray : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSendDisabled)
    }

    private var isSendDisabled: Bool {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || feedbackText.count > maxCharacters
        || isSending
        || cooldownRemaining > 0
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text(successMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
        .padding()
    }

    // MARK: - Send Logic

    private func sendFeedback() async {
        focusedField = nil
        isSending = true

        let email = emailText.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await FeedbackService.send(
                text: feedbackText,
                email: email.isEmpty ? nil : email
            )
            triggerHaptic()
            withAnimation { showSuccess = true }
            saveCooldownTimestamp()
            startCooldownTimer()
            feedbackText = ""
            emailText = ""

            try? await Task.sleep(for: .seconds(2))
            dismiss()
        } catch {
            showError = true
        }

        isSending = false
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Cooldown

    private func saveCooldownTimestamp() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cooldownKey)
    }

    private func startCooldownIfNeeded() {
        let lastSend = UserDefaults.standard.double(forKey: cooldownKey)
        guard lastSend > 0 else { return }

        let elapsed = Int(Date().timeIntervalSince1970 - lastSend)
        let remaining = cooldownDuration - elapsed

        if remaining > 0 {
            cooldownRemaining = remaining
            startCooldownTimer()
        }
    }

    private func startCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if cooldownRemaining > 0 {
                cooldownRemaining -= 1
            } else {
                cooldownTimer?.invalidate()
            }
        }
    }
}

#Preview {
    FeedbackSheet()
}

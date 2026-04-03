import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - FeedbackService
// Sends feedback to a Telegram bot using the Telegram Bot API.
// Uses native URLSession with async/await -- no third-party dependencies.

enum FeedbackError: LocalizedError {
    case emptyFeedback
    case invalidURL
    case serverError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyFeedback:
            return "Feedback text cannot be empty."
        case .invalidURL:
            return "Invalid Telegram API URL."
        case .serverError(let message):
            return "Telegram API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

enum FeedbackService {

    /// Sends feedback to the configured Telegram bot.
    /// - Parameters:
    ///   - text: The feedback message (max 2000 characters).
    ///   - email: Optional email for follow-up.
    ///   - session: URLSession to use (injectable for testing).
    static func send(text: String, email: String? = nil, session: URLSession = .shared) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FeedbackError.emptyFeedback }

        let message = buildMessage(text: trimmed, email: email)

        let token = FeedbackConfig.botToken
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage") else {
            throw FeedbackError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "chat_id": FeedbackConfig.chatID,
            "text": message,
            "parse_mode": "Markdown"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FeedbackError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.serverError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FeedbackError.serverError(responseBody)
        }
    }

    // MARK: - Internal (visible for testing)

    static func buildMessage(text: String, email: String?) -> String {
        let appName = FeedbackConfig.appName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        #if os(iOS)
        let platformEmoji = "\u{1F34E}" // apple emoji
        let platform = "iOS \(UIDevice.current.systemVersion)"
        #else
        let platformEmoji = "\u{1F4F1}"
        let platform = osVersion
        #endif

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let timestamp = formatter.string(from: Date())

        var lines = [
            "\u{1F4F1} App: \(appName)",
            "\u{1F4E6} Version: \(appVersion)",
            "\(platformEmoji) Platform: \(platform)",
            "\u{1F554} Time: \(timestamp) UTC",
            "",
            "\u{1F4AC} Feedback:",
            text
        ]

        let emailValue = email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if emailValue.isEmpty {
            lines.append("\n\u{1F4E7} Email: (not provided)")
        } else {
            lines.append("\n\u{1F4E7} Email: \(emailValue)")
        }

        return lines.joined(separator: "\n")
    }
}

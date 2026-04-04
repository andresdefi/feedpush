import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - FeedbackService
// Sends feedback via Telegram, Discord, or Slack depending on FeedbackConfig.channel.
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
            return "Invalid API URL."
        case .serverError(let message):
            return "API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

enum FeedbackService {

    /// Sends feedback using the configured delivery channel.
    static func send(text: String, session: URLSession = .shared) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FeedbackError.emptyFeedback }

        let message = buildMessage(text: trimmed)

        let request: URLRequest
        switch FeedbackConfig.channel {
        case .telegram:
            request = try buildTelegramRequest(message: message)
        case .discord:
            request = try buildDiscordRequest(message: message)
        case .slack:
            request = try buildSlackRequest(message: message)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FeedbackError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.serverError("Invalid response")
        }

        // Discord returns 204 No Content on success
        let isSuccess = httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
        if !isSuccess {
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw FeedbackError.serverError(responseBody)
        }
    }

    // MARK: - Request Builders

    private static func buildTelegramRequest(message: String) throws -> URLRequest {
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
        return request
    }

    private static func buildDiscordRequest(message: String) throws -> URLRequest {
        let webhookURL = FeedbackConfig.webhookURL
        guard let url = URL(string: webhookURL) else {
            throw FeedbackError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["content": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func buildSlackRequest(message: String) throws -> URLRequest {
        let webhookURL = FeedbackConfig.webhookURL
        guard let url = URL(string: webhookURL) else {
            throw FeedbackError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Message Formatting

    static func buildMessage(text: String) -> String {
        let appName = FeedbackConfig.appName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        #if os(iOS)
        let platformEmoji = "\u{1F34E}"
        let platform = "iOS \(UIDevice.current.systemVersion)"
        #else
        let platformEmoji = "\u{1F4F1}"
        let platform = osVersion
        #endif

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let timestamp = formatter.string(from: Date())

        let lines = [
            "\u{1F4F1} App: \(appName)",
            "\u{1F4E6} Version: \(appVersion)",
            "\(platformEmoji) Platform: \(platform)",
            "\u{1F554} Time: \(timestamp) UTC",
            "",
            "\u{1F4AC} Feedback:",
            text
        ]

        return lines.joined(separator: "\n")
    }
}

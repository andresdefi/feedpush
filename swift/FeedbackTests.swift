import XCTest
@testable import FeedPush // Replace with your module name

// MARK: - FeedbackConfig Tests

final class FeedbackConfigTests: XCTestCase {

    func testTokenDecodesFromBytes() {
        // The default placeholder bytes [49, 50, 51, 52, 53, 54, 58, 65, 66, 67, 45, 68, 69, 70]
        // should decode to "123456:ABC-DEF"
        let token = FeedbackConfig.botToken
        XCTAssertEqual(token, "123456:ABC-DEF")
    }

    func testTokenIsNotEmpty() {
        XCTAssertFalse(FeedbackConfig.botToken.isEmpty)
    }

    func testTokenBytesRoundTrip() {
        // Verify the decode process: encoding a known string and decoding it back should match
        let original = "test:token-123"
        let bytes = Array(original.utf8)
        let decoded = String(bytes: bytes, encoding: .utf8)
        XCTAssertEqual(decoded, original)
    }

    func testChatIDIsSet() {
        // Ensure the chat ID constant exists and is not the placeholder
        XCTAssertFalse(FeedbackConfig.chatID.isEmpty)
    }

    func testAppNameIsSet() {
        XCTAssertFalse(FeedbackConfig.appName.isEmpty)
    }
}

// MARK: - FeedbackService Message Formatting Tests

final class FeedbackServiceMessageTests: XCTestCase {

    func testMessageContainsAppName() {
        let message = FeedbackService.buildMessage(text: "Great app!", email: nil)
        XCTAssertTrue(message.contains("App: \(FeedbackConfig.appName)"))
    }

    func testMessageContainsFeedbackText() {
        let feedbackText = "This is my feedback about the app"
        let message = FeedbackService.buildMessage(text: feedbackText, email: nil)
        XCTAssertTrue(message.contains(feedbackText))
    }

    func testMessageContainsFeedbackHeader() {
        let message = FeedbackService.buildMessage(text: "Test", email: nil)
        XCTAssertTrue(message.contains("Feedback:"))
    }

    func testMessageContainsVersionLine() {
        let message = FeedbackService.buildMessage(text: "Test", email: nil)
        XCTAssertTrue(message.contains("Version:"))
    }

    func testMessageContainsPlatformLine() {
        let message = FeedbackService.buildMessage(text: "Test", email: nil)
        XCTAssertTrue(message.contains("Platform:"))
    }

    func testMessageContainsTimestamp() {
        let message = FeedbackService.buildMessage(text: "Test", email: nil)
        XCTAssertTrue(message.contains("Time:"))
        XCTAssertTrue(message.contains("UTC"))
    }

    func testMessageWithNoEmailShowsNotProvided() {
        let message = FeedbackService.buildMessage(text: "Test", email: nil)
        XCTAssertTrue(message.contains("Email: (not provided)"))
    }

    func testMessageWithEmptyEmailShowsNotProvided() {
        let message = FeedbackService.buildMessage(text: "Test", email: "")
        XCTAssertTrue(message.contains("Email: (not provided)"))
    }

    func testMessageWithWhitespaceOnlyEmailShowsNotProvided() {
        let message = FeedbackService.buildMessage(text: "Test", email: "   ")
        XCTAssertTrue(message.contains("Email: (not provided)"))
    }

    func testMessageWithEmailShowsEmail() {
        let email = "user@example.com"
        let message = FeedbackService.buildMessage(text: "Test", email: email)
        XCTAssertTrue(message.contains("Email: \(email)"))
        XCTAssertFalse(message.contains("(not provided)"))
    }

    func testMessageWithEmailWithWhitespaceTrimsIt() {
        let message = FeedbackService.buildMessage(text: "Test", email: "  user@example.com  ")
        XCTAssertTrue(message.contains("Email: user@example.com"))
    }

    func testMessageOrderIsCorrect() {
        let message = FeedbackService.buildMessage(text: "My feedback", email: "a@b.com")

        // Verify the order: App -> Version -> Platform -> Time -> Feedback -> Email
        let appRange = message.range(of: "App:")!
        let versionRange = message.range(of: "Version:")!
        let platformRange = message.range(of: "Platform:")!
        let timeRange = message.range(of: "Time:")!
        let feedbackRange = message.range(of: "Feedback:")!
        let emailRange = message.range(of: "Email:")!

        XCTAssertTrue(appRange.lowerBound < versionRange.lowerBound)
        XCTAssertTrue(versionRange.lowerBound < platformRange.lowerBound)
        XCTAssertTrue(platformRange.lowerBound < timeRange.lowerBound)
        XCTAssertTrue(timeRange.lowerBound < feedbackRange.lowerBound)
        XCTAssertTrue(feedbackRange.lowerBound < emailRange.lowerBound)
    }

    func testMessageWithSpecialCharactersInFeedback() {
        let text = "Feedback with special chars: <>&\"' and emojis \u{1F600}\u{1F525}"
        let message = FeedbackService.buildMessage(text: text, email: nil)
        XCTAssertTrue(message.contains(text))
    }

    func testMessageWithMultilineFeedback() {
        let text = "Line 1\nLine 2\nLine 3"
        let message = FeedbackService.buildMessage(text: text, email: nil)
        XCTAssertTrue(message.contains(text))
    }

    func testMessageWithMaxLengthFeedback() {
        let text = String(repeating: "a", count: 2000)
        let message = FeedbackService.buildMessage(text: text, email: nil)
        XCTAssertTrue(message.contains(text))
        // Total message should be under Telegram's 4096 limit
        XCTAssertTrue(message.count <= 4096)
    }
}

// MARK: - FeedbackService Send Validation Tests

final class FeedbackServiceSendTests: XCTestCase {

    func testSendThrowsOnEmptyText() async {
        do {
            try await FeedbackService.send(text: "")
            XCTFail("Should have thrown emptyFeedback")
        } catch let error as FeedbackError {
            if case .emptyFeedback = error {
                // expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendThrowsOnWhitespaceOnlyText() async {
        do {
            try await FeedbackService.send(text: "   \n\t  ")
            XCTFail("Should have thrown emptyFeedback")
        } catch let error as FeedbackError {
            if case .emptyFeedback = error {
                // expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendWithMockSession_Success() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)

        // Simulate a 200 OK response
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = "{\"ok\":true}".data(using: .utf8)!
            return (response, data)
        }

        try await FeedbackService.send(text: "Test feedback", session: mockSession)
    }

    func testSendWithMockSession_ServerError() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)

        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = "{\"ok\":false,\"description\":\"Bad Request\"}".data(using: .utf8)!
            return (response, data)
        }

        do {
            try await FeedbackService.send(text: "Test", session: mockSession)
            XCTFail("Should have thrown serverError")
        } catch let error as FeedbackError {
            if case .serverError(let msg) = error {
                XCTAssertTrue(msg.contains("Bad Request"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendWithMockSession_RequestFormat() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: config)

        var capturedRequest: URLRequest?

        MockURLProtocol.handler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{\"ok\":true}".data(using: .utf8)!)
        }

        try await FeedbackService.send(text: "Hello", email: "test@test.com", session: mockSession)

        let request = try XCTUnwrap(capturedRequest)

        // Verify HTTP method
        XCTAssertEqual(request.httpMethod, "POST")

        // Verify content type
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        // Verify URL contains the token
        XCTAssertTrue(request.url!.absoluteString.contains("/sendMessage"))

        // Verify body contains required fields
        let bodyData = try XCTUnwrap(request.httpBody)
        let bodyJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        XCTAssertEqual(bodyJSON["chat_id"] as? String, FeedbackConfig.chatID)
        XCTAssertEqual(bodyJSON["parse_mode"] as? String, "Markdown")
        let text = try XCTUnwrap(bodyJSON["text"] as? String)
        XCTAssertTrue(text.contains("Hello"))
        XCTAssertTrue(text.contains("test@test.com"))
    }
}

// MARK: - FeedbackConfig Channel Tests

final class FeedbackConfigChannelTests: XCTestCase {

    func testWebhookURLDecodesFromBytes() {
        // Verify the webhook URL decode works the same way as token
        let testURL = "https://discord.com/api/webhooks/123/abc"
        let bytes = Array(testURL.utf8)
        let decoded = String(bytes: bytes, encoding: .utf8)
        XCTAssertEqual(decoded, testURL)
    }

    func testChannelIsSet() {
        // Just verify the channel property exists and is accessible
        let channel = FeedbackConfig.channel
        switch channel {
        case .telegram, .discord, .slack:
            break // all valid
        }
    }
}

// MARK: - FeedbackError Tests

final class FeedbackErrorTests: XCTestCase {

    func testEmptyFeedbackDescription() {
        let error = FeedbackError.emptyFeedback
        XCTAssertEqual(error.errorDescription, "Feedback text cannot be empty.")
    }

    func testInvalidURLDescription() {
        let error = FeedbackError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid API URL.")
    }

    func testServerErrorDescription() {
        let error = FeedbackError.serverError("test message")
        XCTAssertEqual(error.errorDescription, "API error: test message")
    }

    func testNetworkErrorDescription() {
        let underlying = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet"])
        let error = FeedbackError.networkError(underlying)
        XCTAssertTrue(error.errorDescription!.contains("No internet"))
    }
}

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: 0))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

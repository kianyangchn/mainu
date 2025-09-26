import Foundation

public struct MenuProcessingDebugClient: Sendable {
    private let endpoint: URL
    private let token: String
    private let logger: @Sendable (String) -> Void

    public init(
        endpoint: URL = URL(string: "https://ai-proxy-production-c3e8.up.railway.app/v1/menu")!,
        token: String,
        logger: @escaping @Sendable (String) -> Void = { message in print(message) }
    ) {
        self.endpoint = endpoint
        self.token = token
        self.logger = logger
    }

    @discardableResult
    public func sendMenuText(
        _ text: String,
        langIn: String,
        langOut: String
    ) async -> DebugPayload? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        let payload = ProxyPayload(text: trimmedText, langOut: langOut, langIn: langIn)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        do {
            request.httpBody = try encoder.encode(payload)
            logger("[MenuDebug] Calling proxy (lang_in=\(langIn), lang_out=\(langOut))")
        } catch {
            logger("[MenuDebug] Failed to encode payload: \(error)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                logger("[MenuDebug] Missing HTTP response")
                return nil
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let snippet = String(data: data, encoding: .utf8)?.prefix(200) ?? "<no body>"
                logger("[MenuDebug] Unexpected status code \(httpResponse.statusCode): \(snippet)")
                return nil
            }

            let decoder = JSONDecoder()
            let proxyResponse = try decoder.decode(ProxyResponse.self, from: data)
            if let text = proxyResponse.debugTextSnippet {
                logger("[MenuDebug] Response snippet: \(text)")
                return DebugPayload(langIn: langIn, langOut: langOut, text: text)
            } else {
                let fallback = String(data: data, encoding: .utf8)?.prefix(200)
                let fallbackString = fallback.flatMap { String($0).trimmedNonEmpty } ?? "<unreadable body>"
                logger("[MenuDebug] Response missing expected content. Fallback: \(fallbackString)")
                guard fallbackString != "<unreadable body>" else { return nil }
                return DebugPayload(langIn: langIn, langOut: langOut, text: fallbackString)
            }
        } catch {
            logger("[MenuDebug] Call failed: \(error)")
            return nil
        }
    }
}

private struct ProxyPayload: Encodable {
    let text: String
    let langOut: String
    let langIn: String
}

public struct DebugPayload: Equatable, Sendable {
    public let langIn: String
    public let langOut: String
    public let text: String

    public init(langIn: String, langOut: String, text: String) {
        self.langIn = langIn
        self.langOut = langOut
        self.text = text
    }
}

private struct ProxyResponse: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let text: String?
        }

        let content: [Content]?

        init(from decoder: Decoder) throws {
            if let container = try? decoder.container(keyedBy: CodingKeys.self) {
                content = try container.decodeIfPresent([Content].self, forKey: .content)
            } else {
                content = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case content
        }
    }

    let output: [Output]?

    var debugTextSnippet: String? {
        guard let outputs = output else { return nil }

        // Try the requested slot first.
        if outputs.indices.contains(1),
           let text = outputs[1].content?.first?.text?.trimmedNonEmpty {
            return String(text.prefix(200))
        }

        // Fallback: first non-empty text anywhere in the payload.
        for output in outputs {
            if let match = output.content?.compactMap({ $0.text?.trimmedNonEmpty }).first {
                return String(match.prefix(200))
            }
        }

        return nil
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

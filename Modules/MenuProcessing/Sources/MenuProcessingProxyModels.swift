import Foundation

struct MenuProxyPayload: Encodable {
    let text: String
    let langOut: String
    let langIn: String
}

struct MenuProxyResponse: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let text: String?
        }

        let content: [Content]?
    }

    let output: [Output]?

    func text(at index: Int) -> String? {
        guard let output else { return nil }
        guard output.indices.contains(index) else { return nil }
        return output[index].content?.compactMap { $0.text?.trimmedNonEmpty }.first
    }

    var firstAvailableText: String? {
        guard let output else { return nil }
        for entry in output {
            if let match = entry.content?.compactMap({ $0.text?.trimmedNonEmpty }).first {
                return match
            }
        }
        return nil
    }

    var menuJSONText: String? {
        text(at: 1) ?? firstAvailableText
    }

    func debugSnippet(maxLength: Int = 200) -> String? {
        guard let text = firstAvailableText else { return nil }
        return String(text.prefix(maxLength))
    }
}

extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

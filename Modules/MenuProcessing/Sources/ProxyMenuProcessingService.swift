import Foundation

public struct ProxyMenuProcessingService: MenuProcessingService, Sendable {
    public enum ServiceError: Error, Equatable {
        case emptyRecognizedText
        case invalidStatusCode(Int)
        case invalidResponse
        case missingMenuPayload
        case malformedMenuJSON
        case emptyMenu
        case pollingUnsupported
    }

    private let endpoint: URL
    private let token: String
    private let performRequest: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let logger: @Sendable (String) -> Void

    private let encoder: JSONEncoder
    private let proxyDecoder: JSONDecoder
    private let menuDecoder: JSONDecoder

    public init(
        endpoint: URL = URL(string: "https://ai-proxy-production-c3e8.up.railway.app/v1/menu")!,
        token: String,
        performRequest: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = { request in
            try await URLSession.shared.data(for: request)
        },
        logger: @escaping @Sendable (String) -> Void = { message in print("[MenuProxy] \(message)") }
    ) {
        self.endpoint = endpoint
        self.token = token
        self.performRequest = performRequest
        self.logger = logger

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder

        self.proxyDecoder = JSONDecoder()
        self.menuDecoder = JSONDecoder()
    }

    public func submit(_ request: MenuProcessingRequest) async throws -> MenuTemplate {
        let normalizedText = request.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            logger("Submit aborted: empty recognized text")
            throw ServiceError.emptyRecognizedText
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 120

        let payload = MenuProxyPayload(
            text: normalizedText,
            langOut: request.languageOut ?? Locale.preferredLanguages.first ?? "en",
            langIn: request.languageIn ?? Locale.current.identifier
        )

        do {
            urlRequest.httpBody = try encoder.encode(payload)
            logger("Submitting menu text (pages=\(request.pageCount))")
        } catch {
            logger("Encoding failure: \(error)")
            throw ServiceError.invalidResponse
        }

        let (data, response) = try await performRequest(urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger("Missing HTTP response")
            throw ServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let snippet = String(data: data, encoding: .utf8)?.prefix(200) ?? "<no body>"
            logger("Unexpected status code \(httpResponse.statusCode): \(snippet)")
            throw ServiceError.invalidStatusCode(httpResponse.statusCode)
        }

        let proxyResponse = try proxyDecoder.decode(MenuProxyResponse.self, from: data)
        guard let menuJSONString = proxyResponse.menuJSONText, let menuData = menuJSONString.data(using: .utf8) else {
            logger("No menu payload found in proxy response")
            throw ServiceError.missingMenuPayload
        }

        let payloadContainer: MenuItemsPayload
        do {
            payloadContainer = try menuDecoder.decode(MenuItemsPayload.self, from: menuData)
        } catch {
            logger("Failed to decode menu JSON: \(error)")
            throw ServiceError.malformedMenuJSON
        }

        guard !payloadContainer.items.isEmpty else {
            logger("Menu payload contained no dishes")
            throw ServiceError.emptyMenu
        }

        let template = MenuTemplate(
            id: request.uploadID,
            sections: buildSections(from: payloadContainer.items)
        )
        return template
    }

    public func pollStatus(for templateID: UUID) async throws -> MenuProcessingState {
        throw ServiceError.pollingUnsupported
    }

    private func buildSections(from items: [MenuItemPayload]) -> [MenuSection] {
        var orderedSections: [String] = []
        var dishesBySection: [String: [MenuDish]] = [:]

        for item in items {
            let sectionName = item.section ?? item.category ?? "Menu"
            if !orderedSections.contains(sectionName) {
                orderedSections.append(sectionName)
            }

            let dish = item.asMenuDish()
            dishesBySection[sectionName, default: []].append(dish)
        }

        return orderedSections.map { title in
            MenuSection(title: title, dishes: dishesBySection[title] ?? [])
        }
    }
}

private struct MenuItemsPayload: Decodable {
    let items: [MenuItemPayload]
}

private struct MenuItemPayload: Decodable {
    let originalName: String
    let translatedName: String
    let description: String?
    let category: String?
    let section: String?
    let price: String?
    let allergens: [String]
    let spiceLevel: String?
    let recommendedPairing: String?

    enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case translatedName = "translated_name"
        case description
        case category
        case section
        case price
        case allergens
        case spiceLevel = "spice_level"
        case recommendedPairing = "recommended_pairing"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalName = try container.decode(String.self, forKey: .originalName)
        translatedName = try container.decode(String.self, forKey: .translatedName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        section = try container.decodeIfPresent(String.self, forKey: .section)
        price = try container.decodeIfPresent(String.self, forKey: .price)?.trimmedNonEmpty

        if let array = try container.decodeIfPresent([String].self, forKey: .allergens) {
            allergens = array.compactMap { $0.trimmedNonEmpty }
        } else if let singleString = try container.decodeIfPresent(String.self, forKey: .allergens) {
            allergens = singleString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        } else {
            allergens = []
        }

        spiceLevel = try container.decodeIfPresent(String.self, forKey: .spiceLevel)
        recommendedPairing = try container.decodeIfPresent(String.self, forKey: .recommendedPairing)?.trimmedNonEmpty
    }

    func asMenuDish() -> MenuDish {
        MenuDish(
            originalName: originalName,
            localizedName: translatedName,
            description: description?.trimmedNonEmpty ?? "",
            price: price,
            allergens: allergens,
            spiceLevel: SpiceLevel(spiceLevelString: spiceLevel),
            imageURL: nil,
            recommendedPairing: recommendedPairing
        )
    }
}

private extension SpiceLevel {
    init?(spiceLevelString: String?) {
        guard let value = spiceLevelString?.trimmedNonEmpty?.lowercased() else { return nil }
        switch value {
        case "none": self = .none
        case "mild": self = .mild
        case "medium": self = .medium
        case "hot", "spicy": self = .hot
        default: return nil
        }
    }
}

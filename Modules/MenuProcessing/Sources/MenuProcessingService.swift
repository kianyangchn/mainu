import Foundation

public struct MenuProcessingRequest: Equatable, Sendable {
    public let uploadID: UUID
    public let pageCount: Int
    public let recognizedText: String

    public init(uploadID: UUID = UUID(), pageCount: Int, recognizedText: String = "") {
        self.uploadID = uploadID
        self.pageCount = pageCount
        self.recognizedText = recognizedText
    }
}

public enum MenuProcessingState: Equatable, Sendable {
    case queued
    case processing(progress: Double)
    case ready(MenuTemplate)
    case failed(String)
}

public struct MenuTemplate: Equatable, Sendable {
    public let id: UUID
    public let sections: [MenuSection]

    public init(id: UUID, sections: [MenuSection]) {
        self.id = id
        self.sections = sections
    }
}

public struct MenuSection: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let dishes: [MenuDish]

    public init(id: UUID = UUID(), title: String, dishes: [MenuDish]) {
        self.id = id
        self.title = title
        self.dishes = dishes
    }
}

public enum SpiceLevel: String, CaseIterable, Sendable {
    case none
    case mild
    case medium
    case hot

    public var localizedDescription: String {
        switch self {
        case .none: return "Not spicy"
        case .mild: return "Mild"
        case .medium: return "Medium"
        case .hot: return "Hot"
        }
    }
}

public struct MenuDish: Equatable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let originalName: String
    public let localizedName: String
    public let description: String
    public let price: String?
    public let allergens: [String]
    public let spiceLevel: SpiceLevel?
    public let imageURL: URL?
    public let recommendedPairing: String?

    public init(
        id: UUID = UUID(),
        originalName: String,
        localizedName: String,
        description: String,
        price: String? = nil,
        allergens: [String] = [],
        spiceLevel: SpiceLevel? = nil,
        imageURL: URL? = nil,
        recommendedPairing: String? = nil
    ) {
        self.id = id
        self.originalName = originalName
        self.localizedName = localizedName
        self.description = description
        self.price = price
        self.allergens = allergens
        self.spiceLevel = spiceLevel
        self.imageURL = imageURL
        self.recommendedPairing = recommendedPairing
    }
}

public protocol MenuProcessingService: Sendable {
    func submit(_ request: MenuProcessingRequest) async throws -> MenuTemplate
    func pollStatus(for templateID: UUID) async throws -> MenuProcessingState
}

public struct MockMenuProcessingService: MenuProcessingService {
    public init() {}

    public func submit(_ request: MenuProcessingRequest) async throws -> MenuTemplate {
        try await Task.sleep(for: .milliseconds(600))
        return MenuTemplate.sample.withID(request.uploadID)
    }

    public func pollStatus(for templateID: UUID) async throws -> MenuProcessingState {
        .ready(MenuTemplate.sample.withID(templateID))
    }
}

public extension MenuTemplate {
    static let sample = MenuTemplate(
        id: UUID(uuidString: "A49FBA6C-5602-4DF6-8AB2-99E62B26E2FE") ?? UUID(),
        sections: [
            MenuSection(
                title: "Antipasti",
                dishes: [
                    MenuDish(
                        originalName: "Bruschetta al Pomodoro",
                        localizedName: "Tomato Bruschetta",
                        description: "Toasted sourdough topped with vine tomatoes, basil, and garlic-infused olive oil.",
                        price: "€7",
                        allergens: ["Gluten"],
                        imageURL: nil,
                        recommendedPairing: "Pair with the house prosecco."
                    ),
                    MenuDish(
                        originalName: "Carpaccio di Manzo",
                        localizedName: "Beef Carpaccio",
                        description: "Thinly sliced raw beef with arugula, Parmigiano Reggiano, and lemon aioli.",
                        price: "€14",
                        allergens: ["Dairy"],
                        imageURL: nil
                    )
                ]
            ),
            MenuSection(
                title: "Primi",
                dishes: [
                    MenuDish(
                        originalName: "Cacio e Pepe",
                        localizedName: "Cacio e Pepe",
                        description: "Handmade tonnarelli pasta tossed with pecorino romano and cracked black pepper.",
                        price: "€16",
                        allergens: ["Dairy", "Gluten"],
                        spiceLevel: .mild,
                        imageURL: nil
                    ),
                    MenuDish(
                        originalName: "Risotto ai Funghi Porcini",
                        localizedName: "Porcini Mushroom Risotto",
                        description: "Creamy carnaroli rice simmered with wild porcini mushrooms and thyme.",
                        price: "€18",
                        allergens: ["Dairy"],
                        imageURL: nil,
                        recommendedPairing: "Try with the Barolo by the glass."
                    )
                ]
            ),
            MenuSection(
                title: "Secondi",
                dishes: [
                    MenuDish(
                        originalName: "Saltimbocca alla Romana",
                        localizedName: "Prosciutto Sage Veal",
                        description: "Veal cutlets wrapped in prosciutto and sage, finished with white wine butter sauce.",
                        price: "€22",
                        allergens: ["Dairy"],
                        imageURL: nil
                    ),
                    MenuDish(
                        originalName: "Branzino al Limone",
                        localizedName: "Lemon Sea Bass",
                        description: "Whole Mediterranean sea bass roasted with Amalfi lemons and herbs.",
                        price: "€26",
                        allergens: ["Fish"],
                        imageURL: nil
                    )
                ]
            ),
            MenuSection(
                title: "Dolci",
                dishes: [
                    MenuDish(
                        originalName: "Tiramisù della Casa",
                        localizedName: "House Tiramisu",
                        description: "Layers of espresso-soaked savoiardi, mascarpone cream, and cocoa.",
                        price: "€9",
                        allergens: ["Dairy", "Eggs", "Gluten"],
                        imageURL: nil
                    ),
                    MenuDish(
                        originalName: "Gelato Artigianale",
                        localizedName: "Artisanal Gelato",
                        description: "Daily selection of house-made gelato flavors. Ask for today's options.",
                        price: "€7",
                        allergens: [],
                        imageURL: nil
                    )
                ]
            )
        ]
    )

    func withID(_ newID: UUID) -> MenuTemplate {
        MenuTemplate(id: newID, sections: sections)
    }
}

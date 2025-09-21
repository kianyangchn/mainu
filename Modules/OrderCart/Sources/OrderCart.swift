import Foundation
import MenuProcessing

public struct OrderCart: Equatable {
    public private(set) var selections: [MenuDish: Int]

    public init(selections: [MenuDish: Int] = [:]) {
        self.selections = selections
    }

    public var isEmpty: Bool {
        selections.isEmpty
    }

    public var totalItems: Int {
        selections.values.reduce(0, +)
    }

    public func quantity(for dish: MenuDish) -> Int {
        selections[dish] ?? 0
    }

    public mutating func toggle(_ dish: MenuDish) {
        if quantity(for: dish) > 0 {
            selections[dish] = nil
        } else {
            selections[dish] = 1
        }
    }

    public mutating func increment(_ dish: MenuDish) {
        let next = quantity(for: dish) + 1
        selections[dish] = next
    }

    public mutating func decrement(_ dish: MenuDish) {
        let next = quantity(for: dish) - 1
        if next <= 0 {
            selections[dish] = nil
        } else {
            selections[dish] = next
        }
    }

    public mutating func setQuantity(_ quantity: Int, for dish: MenuDish) {
        guard quantity > 0 else {
            selections[dish] = nil
            return
        }
        selections[dish] = quantity
    }

    public func summaryLines() -> [String] {
        selections.map { dish, quantity in
            "\(quantity) × \(dish.originalName)"
        }.sorted()
    }
}

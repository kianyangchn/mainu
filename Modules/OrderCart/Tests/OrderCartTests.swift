import XCTest
@testable import OrderCart
import MenuProcessing

final class OrderCartTests: XCTestCase {
    func testSummaryLinesSorted() {
        var cart = OrderCart()
        let dishA = MenuDish(originalName: "Bruschetta", localizedName: "Bruschetta", description: "Tomato crostini")
        let dishB = MenuDish(originalName: "Carbonara", localizedName: "Carbonara", description: "Pasta")
        cart.setQuantity(2, for: dishB)
        cart.setQuantity(1, for: dishA)
        XCTAssertEqual(cart.summaryLines(), ["1 × Bruschetta", "2 × Carbonara"])
    }
}

    func testIncrementDecrement() {
        var cart = OrderCart()
        let dish = MenuDish(originalName: "Test", localizedName: "Test", description: "Desc")
        cart.increment(dish)
        XCTAssertEqual(cart.quantity(for: dish), 1)
        cart.increment(dish)
        XCTAssertEqual(cart.totalItems, 2)
        cart.decrement(dish)
        XCTAssertEqual(cart.quantity(for: dish), 1)
        cart.decrement(dish)
        XCTAssertTrue(cart.isEmpty)
    }
}

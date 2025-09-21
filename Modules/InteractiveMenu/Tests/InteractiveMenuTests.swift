import XCTest
import SwiftUI
@testable import InteractiveMenu
import MenuProcessing

final class InteractiveMenuTests: XCTestCase {
    func testViewInitializesWithTemplate() {
        let dish = MenuDish(originalName: "Cacio e Pepe", localizedName: "Cacio e Pepe", description: "Roman pasta")
        let section = MenuSection(title: "Pasta", dishes: [dish])
        let template = MenuTemplate(id: UUID(), sections: [section])
        let view = InteractiveMenuView(template: template)
        XCTAssertNotNil(view.body)
    }
}

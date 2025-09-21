import SwiftUI
import MenuProcessing
import OrderCart

struct CartSummaryView: View {
    let cart: OrderCart
    let onIncrement: (MenuDish) -> Void
    let onDecrement: (MenuDish) -> Void

    private var orderedDishes: [(MenuDish, Int)] {
        cart.selections.sorted { lhs, rhs in
            lhs.key.localizedName < rhs.key.localizedName
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Group Order") {
                    if cart.isEmpty {
                        Text("Your cart is empty. Add dishes from the menu to build the group order.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(orderedDishes, id: \.0.id) { dish, quantity in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(dish.localizedName)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(quantity) ×")
                                        .font(.subheadline.monospacedDigit())
                                }

                                if let price = dish.price {
                                    Text(price)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 16) {
                                    Button(action: { onDecrement(dish) }) {
                                        Image(systemName: "minus.circle")
                                    }
                                    .disabled(quantity == 0)

                                    Button(action: { onIncrement(dish) }) {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                                .font(.title2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !cart.isEmpty {
                    Section("Waiter summary") {
                        ForEach(cart.summaryLines(), id: \.self) { line in
                            Text(line)
                                .font(.body.monospaced())
                        }
                    }
                }
            }
            .navigationTitle("Order summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Total items: \(cart.totalItems)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

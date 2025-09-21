import SwiftUI
import MenuProcessing

struct DishDetailView: View {
    let dish: MenuDish
    let quantity: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onClear: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    description
                    meta
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(dish.localizedName)
            .toolbar { ToolbarItem(placement: .principal) { Text(dish.localizedName).font(.headline) } }
            .safeAreaInset(edge: .bottom) {
                actionBar
                    .padding()
                    .background(.regularMaterial)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dish.localizedName != dish.originalName {
                Text(dish.originalName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            if let price = dish.price {
                Text(price)
                    .font(.title3.weight(.semibold))
            }
        }
    }

    private var description: some View {
        Text(dish.description)
            .font(.body)
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let pairing = dish.recommendedPairing {
                Label(pairing, systemImage: "wineglass")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let spice = dish.spiceLevel {
                Label("Spice level: \(spice.localizedDescription)", systemImage: "flame")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if !dish.allergens.isEmpty {
                Label("Allergens: \(dish.allergens.joined(separator: ", "))", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.accentColor.opacity(0.1)))
                }
                .disabled(quantity == 0)

                Text("\(quantity)")
                    .font(.title2.monospacedDigit())
                    .frame(minWidth: 44)

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.accentColor.opacity(0.1)))
                }
            }

            Button(action: onIncrement) {
                Label(quantity == 0 ? "Add to order" : "Add another", systemImage: "cart.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if quantity > 0 {
                Button(role: .destructive, action: onClear) {
                    Label("Remove from order", systemImage: "cart.badge.minus")
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

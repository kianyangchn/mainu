import SwiftUI
import MenuProcessing
import DesignSystem

public struct InteractiveMenuView: View {
    private let template: MenuTemplate
    private let debugInfo: DebugPayload?
    private let quantityProvider: (MenuDish) -> Int
    private let onDishTapped: (MenuDish) -> Void
    private let onQuickAdd: (MenuDish) -> Void
    private let onQuickRemove: (MenuDish) -> Void

    public init(
        template: MenuTemplate,
        debugInfo: DebugPayload? = nil,
        quantityProvider: @escaping (MenuDish) -> Int = { _ in 0 },
        onDishTapped: @escaping (MenuDish) -> Void = { _ in },
        onQuickAdd: @escaping (MenuDish) -> Void = { _ in },
        onQuickRemove: @escaping (MenuDish) -> Void = { _ in }
    ) {
        self.template = template
        if let debugInfo {
            let trimmedText = debugInfo.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText.isEmpty {
                self.debugInfo = nil
            } else {
                self.debugInfo = DebugPayload(
                    langIn: debugInfo.langIn,
                    langOut: debugInfo.langOut,
                    text: trimmedText
                )
            }
        } else {
            self.debugInfo = nil
        }
        self.quantityProvider = quantityProvider
        self.onDishTapped = onDishTapped
        self.onQuickAdd = onQuickAdd
        self.onQuickRemove = onQuickRemove
    }

    public var body: some View {
        List {
            if let debugInfo {
                Section("Backend Response") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("lang_in: \(debugInfo.langIn)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("lang_out: \(debugInfo.langOut)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Divider()
                        Text(debugInfo.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ForEach(template.sections) { section in
                Section(section.title) {
                    ForEach(section.dishes) { dish in
                        MenuDishRow(
                            dish: dish,
                            quantity: quantityProvider(dish),
                            onTap: { onDishTapped(dish) }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                onQuickAdd(dish)
                            } label: {
                                Label("Add", systemImage: "plus")
                            }
                            .tint(.green)

                            if quantityProvider(dish) > 0 {
                                Button {
                                    onQuickRemove(dish)
                                } label: {
                                    Label("Remove", systemImage: "minus")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

private struct MenuDishRow: View {
    let dish: MenuDish
    let quantity: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                DishThumbnail(symbol: symbolName(for: dish))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(dish.localizedName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if let price = dish.price {
                            Text(price)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }

                    if dish.localizedName != dish.originalName {
                        Text(dish.originalName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(dish.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DishMetaView(dish: dish)
                }

                if quantity > 0 {
                    Text("\(quantity)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Capsule().fill(Color.accentColor))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func symbolName(for dish: MenuDish) -> String {
        if dish.spiceLevel == .hot { return "flame.fill" }
        if dish.allergens.contains("Fish") { return "fish" }
        if dish.allergens.contains("Gluten") { return "leaf" }
        return "fork.knife"
    }
}

private struct DishThumbnail: View {
    let symbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius / 2)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 52, height: 52)

            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)
        }
    }
}

private struct DishMetaView: View {
    let dish: MenuDish

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let pairing = dish.recommendedPairing {
                Text(pairing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let spice = dish.spiceLevel {
                Text("Spice level: \(spice.localizedDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !dish.allergens.isEmpty {
                Text("Allergens: \(dish.allergens.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

import SwiftUI
import ShareLink

struct ShareLinkSheet: View {
    let link: MenuShareLink

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)

                Text("Share this menu with your travel group")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                SwiftUI.ShareLink(item: link.url) {
                    Label(link.url.absoluteString, systemImage: "link")
                        .font(.callout)
                        .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)

                Text("Link expires \(link.expiresDescription). Group members can browse without installing the app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Share menu")
        }
    }
}

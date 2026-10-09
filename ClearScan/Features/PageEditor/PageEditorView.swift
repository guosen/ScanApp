import SwiftUI

struct PageEditorView: View {
    @EnvironmentObject private var repository: DocumentRepository
    @EnvironmentObject private var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    let documentID: UUID
    let pageID: UUID

    @State private var showProSheet = false

    private var page: ScanPageMetadata? {
        repository.document(id: documentID)?.pages.first { $0.id == pageID }
    }

    var body: some View {
        Group {
            if let page, let source = repository.loadUIImage(for: page) {
                editor(page: page, source: source)
            } else {
                ContentUnavailableView(String(localized: "Page not found"), systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(String(localized: "Edit page"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProUpgradeView()
            }
        }
    }

    @ViewBuilder
    private func editor(page: ScanPageMetadata, source: UIImage) -> some View {
        let preview = ImageProcessor.processedImage(
            from: source,
            rotationDegrees: page.rotationDegrees,
            filter: page.filter
        )

        VStack(spacing: 16) {
            Image(uiImage: preview)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 420)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

            Picker(String(localized: "Filter"), selection: filterBinding(page: page)) {
                ForEach(PageFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button {
                    rotate(page: page, by: -90)
                } label: {
                    Label(String(localized: "Rotate left"), systemImage: "rotate.left")
                }
                .buttonStyle(.bordered)

                Button {
                    rotate(page: page, by: 90)
                } label: {
                    Label(String(localized: "Rotate right"), systemImage: "rotate.right")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }

    private func filterBinding(page: ScanPageMetadata) -> Binding<PageFilter> {
        Binding(
            get: { page.filter },
            set: { newFilter in
                if newFilter.isProOnly, !purchaseService.canUse(filter: newFilter) {
                    showProSheet = true
                    return
                }
                var updated = page
                updated.filter = newFilter
                repository.updatePage(in: documentID, page: updated)
            }
        )
    }

    private func rotate(page: ScanPageMetadata, by degrees: Int) {
        var updated = page
        updated.rotationDegrees = (page.rotationDegrees + degrees + 360) % 360
        repository.updatePage(in: documentID, page: updated)
    }
}

import SwiftUI

struct DocumentPreviewView: View {
    @EnvironmentObject private var repository: DocumentRepository
    @EnvironmentObject private var scanCoordinator: ScanCoordinator

    let documentID: UUID

    private var document: ScanDocumentMetadata? {
        repository.document(id: documentID)
    }

    var body: some View {
        Group {
            if let document {
                content(document: document)
            } else {
                ContentUnavailableView(
                    String(localized: "Document not found"),
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .navigationTitle(document?.name ?? String(localized: "Preview"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(document: ScanDocumentMetadata) -> some View {
        VStack(spacing: 0) {
            if document.pages.isEmpty {
                ContentUnavailableView(
                    String(localized: "No pages"),
                    systemImage: "doc",
                    description: Text(String(localized: "Scan or import pages to continue."))
                )
            } else {
                List {
                    ForEach(document.sortedPages) { page in
                        PageThumbnailRow(
                            page: page,
                            image: repository.loadUIImage(for: page)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            scanCoordinator.openPageEditor(documentID: documentID, pageID: page.id)
                        }
                    }
                    .onMove { source, destination in
                        repository.reorderPages(documentID: documentID, from: source, to: destination)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let page = document.sortedPages[index]
                            repository.deletePage(documentID: documentID, pageID: page.id)
                        }
                    }
                }
                .listStyle(.plain)
            }

            actionBar(document: document)
        }
        .toolbar {
            EditButton()
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Export")) {
                    scanCoordinator.openExport(documentID: documentID)
                }
                .disabled(document.pages.isEmpty)
            }
        }
    }

    private func actionBar(document: ScanDocumentMetadata) -> some View {
        HStack {
            Button {
                scanCoordinator.continueScanning(documentID: documentID)
            } label: {
                Label(String(localized: "Add pages"), systemImage: "plus.viewfinder")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                scanCoordinator.openExport(documentID: documentID)
            } label: {
                Label(String(localized: "Create PDF"), systemImage: "doc.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(document.pages.isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

struct PageThumbnailRow: View {
    let page: ScanPageMetadata
    let image: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            if let image {
                Image(uiImage: ImageProcessor.processedImage(
                    from: image,
                    rotationDegrees: page.rotationDegrees,
                    filter: page.filter
                ))
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 56, height: 72)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Page \(page.sortOrder + 1)"))
                    .font(.headline)
                Text(page.filter.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

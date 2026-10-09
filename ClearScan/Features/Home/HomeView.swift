import PhotosUI
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var repository: DocumentRepository
    @EnvironmentObject private var scanCoordinator: ScanCoordinator
    @EnvironmentObject private var purchaseService: PurchaseService

    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showSettings = false
    @State private var renameTarget: ScanDocumentMetadata?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $scanCoordinator.navigationPath) {
            Group {
                if repository.recentDocuments().isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle("ClearScan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(String(localized: "Settings"))
                }
            }
            .safeAreaInset(edge: .bottom) {
                scanBar
            }
            .navigationDestination(for: ScanCoordinator.FlowStep.self) { step in
                switch step {
                case .preview(let documentID):
                    DocumentPreviewView(documentID: documentID)
                case .pageEditor(let documentID, let pageID):
                    PageEditorView(documentID: documentID, pageID: pageID)
                case .export(let documentID):
                    ExportView(documentID: documentID)
                }
            }
            .fullScreenCover(isPresented: $scanCoordinator.showScanner) {
                DocumentScannerView(
                    onFinish: { scan in
                        scanCoordinator.showScanner = false
                        if let scan {
                            scanCoordinator.handleScanResult(scan, repository: repository)
                        }
                    },
                    onCancel: {
                        scanCoordinator.showScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .alert(
                String(localized: "Notice"),
                isPresented: Binding(
                    get: { scanCoordinator.alertMessage != nil },
                    set: { if !$0 { scanCoordinator.alertMessage = nil } }
                )
            ) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(scanCoordinator.alertMessage ?? "")
            }
            .alert(String(localized: "Rename document"), isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField(String(localized: "Name"), text: $renameText)
                Button(String(localized: "Save")) {
                    if let target = renameTarget {
                        repository.renameDocument(id: target.id, name: renameText)
                    }
                    renameTarget = nil
                }
                Button(String(localized: "Cancel"), role: .cancel) {
                    renameTarget = nil
                }
            }
            .onChange(of: photoPickerItems) { _, items in
                Task { await importPhotos(items) }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "No scans yet"), systemImage: "doc.viewfinder")
        } description: {
            Text(String(localized: "Tap Scan to capture a document, or import photos from your library."))
        }
    }

    private var documentList: some View {
        List {
            Section(String(localized: "Recent")) {
                ForEach(repository.recentDocuments()) { doc in
                    Button {
                        scanCoordinator.openDocument(doc.id)
                    } label: {
                        DocumentRowView(document: doc)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            repository.deleteDocument(id: doc.id)
                        } label: {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                        Button {
                            renameTarget = doc
                            renameText = doc.name
                        } label: {
                            Label(String(localized: "Rename"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var scanBar: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 20, matching: .images) {
                Label(String(localized: "Import"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                scanCoordinator.startNewScan(repository: repository)
            } label: {
                Label(String(localized: "Scan"), systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!ScannerService.isAvailable)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    @MainActor
    private func importPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        let doc = repository.createDocument(name: String(localized: "Imported scan"))
        scanCoordinator.activeDocumentID = doc.id
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                try? repository.addPage(to: doc.id, image: image)
            }
        }
        photoPickerItems = []
        scanCoordinator.openDocument(doc.id)
    }
}

struct DocumentRowView: View {
    let document: ScanDocumentMetadata

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(document.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(String(localized: "\(document.pages.count) page(s)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if document.exportedPDFFilename != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

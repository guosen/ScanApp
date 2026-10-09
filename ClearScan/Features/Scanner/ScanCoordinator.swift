import SwiftUI
import UIKit
import VisionKit

@MainActor
final class ScanCoordinator: ObservableObject {
    enum FlowStep: Hashable {
        case preview(documentID: UUID)
        case pageEditor(documentID: UUID, pageID: UUID)
        case export(documentID: UUID)
    }

    @Published var activeDocumentID: UUID?
    @Published var showScanner = false
    @Published var navigationPath = NavigationPath()
    @Published var alertMessage: String?

    func startNewScan(repository: DocumentRepository) {
        let doc = repository.createDocument()
        activeDocumentID = doc.id
        if ScannerService.isAvailable {
            showScanner = true
        } else {
            alertMessage = String(localized: "Document scanning is not available on this device.")
        }
    }

    func continueScanning(documentID: UUID) {
        activeDocumentID = documentID
        showScanner = true
    }

    func handleScanResult(
        _ scan: VNDocumentCameraScanWrapper,
        repository: DocumentRepository
    ) {
        guard let documentID = activeDocumentID else { return }
        do {
            for index in 0..<scan.pageCount {
                let image = scan.image(at: index)
                try repository.addPage(to: documentID, image: image)
            }
            navigationPath.append(FlowStep.preview(documentID: documentID))
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func openDocument(_ id: UUID) {
        activeDocumentID = id
        navigationPath.append(FlowStep.preview(documentID: id))
    }

    func openExport(documentID: UUID) {
        navigationPath.append(FlowStep.export(documentID: documentID))
    }

    func openPageEditor(documentID: UUID, pageID: UUID) {
        navigationPath.append(FlowStep.pageEditor(documentID: documentID, pageID: pageID))
    }
}

/// Testable wrapper around VisionKit scan results.
struct VNDocumentCameraScanWrapper {
    let pageCount: Int
    let imageAtIndex: (Int) -> UIImage

    init(pageCount: Int, imageAtIndex: @escaping (Int) -> UIImage) {
        self.pageCount = pageCount
        self.imageAtIndex = imageAtIndex
    }

    func image(at index: Int) -> UIImage {
        imageAtIndex(index)
    }
}

extension VNDocumentCameraScanWrapper {
    init(scan: VNDocumentCameraScan) {
        self.init(pageCount: scan.pageCount) { scan.imageOfPage(at: $0) }
    }
}

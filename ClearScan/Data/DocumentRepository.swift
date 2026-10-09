import Foundation
import UIKit

@MainActor
final class DocumentRepository: ObservableObject {
    @Published private(set) var documents: [ScanDocumentMetadata] = []

    private let storage = FileStorage.shared
    private let indexFilename = "documents.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadIndex()
    }

    func recentDocuments(limit: Int = 50) -> [ScanDocumentMetadata] {
        Array(documents.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }

    func document(id: UUID) -> ScanDocumentMetadata? {
        documents.first { $0.id == id }
    }

    @discardableResult
    func createDocument(name: String? = nil) -> ScanDocumentMetadata {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let defaultName = String(localized: "Scan") + " " + formatter.string(from: Date())
        let doc = ScanDocumentMetadata(name: name ?? defaultName)
        documents.insert(doc, at: 0)
        persistIndex()
        return doc
    }

    func updateDocument(_ document: ScanDocumentMetadata) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        var updated = document
        updated.updatedAt = Date()
        documents[index] = updated
        persistIndex()
    }

    func deleteDocument(id: UUID) {
        guard let doc = document(id: id) else { return }
        for page in doc.pages {
            if let url = try? storage.urlForSource(filename: page.sourceImageFilename) {
                storage.removeItem(at: url)
            }
        }
        if let pdfName = doc.exportedPDFFilename,
           let pdfURL = try? storage.urlForExport(filename: pdfName) {
            storage.removeItem(at: pdfURL)
        }
        documents.removeAll { $0.id == id }
        persistIndex()
    }

    func renameDocument(id: UUID, name: String) {
        guard var doc = document(id: id), !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        doc.name = name.trimmingCharacters(in: .whitespaces)
        updateDocument(doc)
    }

    @discardableResult
    func addPage(to documentID: UUID, image: UIImage) throws -> ScanPageMetadata {
        guard var doc = document(id: documentID) else {
            throw FileStorageError.directoryUnavailable
        }
        guard let jpeg = image.jpegData(compressionQuality: 0.92) else {
            throw FileStorageError.writeFailed
        }
        let filename = "\(documentID.uuidString)-\(UUID().uuidString).jpg"
        let dir = try storage.sourcesDirectory()
        _ = try storage.writeJPEG(jpeg, filename: filename, in: dir)
        let order = (doc.pages.map(\.sortOrder).max() ?? -1) + 1
        let page = ScanPageMetadata(sourceImageFilename: filename, sortOrder: order)
        doc.pages.append(page)
        updateDocument(doc)
        return page
    }

    func updatePage(in documentID: UUID, page: ScanPageMetadata) {
        guard var doc = document(id: documentID),
              let idx = doc.pages.firstIndex(where: { $0.id == page.id }) else { return }
        doc.pages[idx] = page
        updateDocument(doc)
    }

    func deletePage(documentID: UUID, pageID: UUID) {
        guard var doc = document(id: documentID) else { return }
        guard let page = doc.pages.first(where: { $0.id == pageID }) else { return }
        if let url = try? storage.urlForSource(filename: page.sourceImageFilename) {
            storage.removeItem(at: url)
        }
        doc.pages.removeAll { $0.id == pageID }
        doc.pages = doc.sortedPages.enumerated().map { index, p in
            var copy = p
            copy.sortOrder = index
            return copy
        }
        updateDocument(doc)
    }

    func reorderPages(documentID: UUID, from source: IndexSet, to destination: Int) {
        guard var doc = document(id: documentID) else { return }
        var ordered = doc.sortedPages
        var items = ordered
        var moving: [ScanPageMetadata] = []
        for index in source.sorted(by: >) {
            moving.insert(items.remove(at: index), at: 0)
        }
        let insertIndex = destination > source.min()! ? destination - source.count : destination
        items.insert(contentsOf: moving, at: min(max(insertIndex, 0), items.count))
        ordered = items
        doc.pages = ordered.enumerated().map { index, page in
            var copy = page
            copy.sortOrder = index
            return copy
        }
        updateDocument(doc)
    }

    func setExportedPDF(documentID: UUID, filename: String) {
        guard var doc = document(id: documentID) else { return }
        if let old = doc.exportedPDFFilename,
           let oldURL = try? storage.urlForExport(filename: old), old != filename {
            storage.removeItem(at: oldURL)
        }
        doc.exportedPDFFilename = filename
        updateDocument(doc)
    }

    func loadUIImage(for page: ScanPageMetadata) -> UIImage? {
        guard let url = try? storage.urlForSource(filename: page.sourceImageFilename),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func exportURL(for document: ScanDocumentMetadata) -> URL? {
        guard let name = document.exportedPDFFilename else { return nil }
        return try? storage.urlForExport(filename: name)
    }

    private func indexURL() throws -> URL {
        try storage.applicationSupportURL.appendingPathComponent(indexFilename)
    }

    private func loadIndex() {
        guard let url = try? indexURL(),
              let data = try? Data(contentsOf: url),
              let index = try? decoder.decode(DocumentIndex.self, from: data) else {
            documents = []
            return
        }
        documents = index.documents
    }

    private func persistIndex() {
        guard let url = try? indexURL() else { return }
        let index = DocumentIndex(documents: documents)
        guard let data = try? encoder.encode(index) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

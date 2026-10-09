import Foundation

enum PageFilter: String, Codable, CaseIterable, Identifiable {
    case original
    case enhanced
    case blackAndWhite
    case grayscale

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return String(localized: "Original")
        case .enhanced: return String(localized: "Enhanced")
        case .blackAndWhite: return String(localized: "Black & White")
        case .grayscale: return String(localized: "Grayscale")
        }
    }

    var isProOnly: Bool {
        self == .enhanced
    }
}

struct ScanPageMetadata: Identifiable, Codable, Equatable {
    var id: UUID
    var sourceImageFilename: String
    var rotationDegrees: Int
    var filter: PageFilter
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        sourceImageFilename: String,
        rotationDegrees: Int = 0,
        filter: PageFilter = .original,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.sourceImageFilename = sourceImageFilename
        self.rotationDegrees = rotationDegrees
        self.filter = filter
        self.sortOrder = sortOrder
    }
}

struct ScanDocumentMetadata: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var pages: [ScanPageMetadata]
    var exportedPDFFilename: String?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        pages: [ScanPageMetadata] = [],
        exportedPDFFilename: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pages = pages
        self.exportedPDFFilename = exportedPDFFilename
    }

    var sortedPages: [ScanPageMetadata] {
        pages.sorted { $0.sortOrder < $1.sortOrder }
    }
}

struct DocumentIndex: Codable {
    var documents: [ScanDocumentMetadata]

    static let empty = DocumentIndex(documents: [])
}

import PDFKit
import UIKit

enum PDFExporterError: LocalizedError {
    case noPages
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .noPages:
            return String(localized: "Add at least one page before exporting.")
        case .generationFailed:
            return String(localized: "Could not create PDF.")
        }
    }
}

enum PDFExporter {
    /// Builds a PDF by rendering one page at a time to limit memory use.
    static func export(
        document: ScanDocumentMetadata,
        loadImage: (ScanPageMetadata) -> UIImage?,
        proOptions: PDFExportOptions = .standard
    ) throws -> Data {
        let pages = document.sortedPages
        guard !pages.isEmpty else { throw PDFExporterError.noPages }

        let pdfMeta = [
            kCGPDFContextCreator: "ClearScan",
            kCGPDFContextTitle: document.name
        ] as [String: Any]

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, .zero, pdfMeta)
        defer { UIGraphicsEndPDFContext() }

        for pageMeta in pages {
            guard let source = loadImage(pageMeta) else { continue }
            let image = ImageProcessor.processedImage(
                from: source,
                rotationDegrees: pageMeta.rotationDegrees,
                filter: pageMeta.filter
            )
            let pageRect = CGRect(origin: .zero, size: image.size)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            image.draw(in: pageRect)
        }

        guard data.length > 0 else { throw PDFExporterError.generationFailed }

        if proOptions.compressImages {
            return try compressPDFData(data as Data) ?? (data as Data)
        }
        return data as Data
    }

    private static func compressPDFData(_ data: Data) throws -> Data? {
        guard let doc = PDFDocument(data: data) else { return nil }
        return doc.dataRepresentation()
    }
}

struct PDFExportOptions {
    var compressImages: Bool

    static let standard = PDFExportOptions(compressImages: false)
    static let pro = PDFExportOptions(compressImages: true)
}

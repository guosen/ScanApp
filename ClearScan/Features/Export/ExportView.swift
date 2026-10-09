import PDFKit
import SwiftUI

struct ExportView: View {
    @EnvironmentObject private var repository: DocumentRepository
    @EnvironmentObject private var purchaseService: PurchaseService

    let documentID: UUID

    @State private var fileName: String = ""
    @State private var pdfData: Data?
    @State private var pdfURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var useProCompression = false
    @State private var showProSheet = false

    private var document: ScanDocumentMetadata? {
        repository.document(id: documentID)
    }

    var body: some View {
        Form {
            if let document {
                Section(String(localized: "File name")) {
                    TextField(String(localized: "Name"), text: $fileName)
                        .textInputAutocapitalization(.words)
                }

                Section(String(localized: "Options")) {
                    Toggle(String(localized: "Optimize PDF size (Pro)"), isOn: $useProCompression)
                        .disabled(!purchaseService.isProUnlocked)
                        .onChange(of: useProCompression) { _, enabled in
                            if enabled, !purchaseService.canUse(proPDFOptions: true) {
                                useProCompression = false
                                showProSheet = true
                            }
                        }
                }

                Section {
                    Button {
                        generatePDF(document: document)
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Label(String(localized: "Generate PDF"), systemImage: "doc.badge.gearshape")
                        }
                    }
                    .disabled(isGenerating || document.pages.isEmpty)
                }

                if let pdfData {
                    Section(String(localized: "Preview")) {
                        PDFPreviewRepresentable(data: pdfData)
                            .frame(minHeight: 320)
                    }

                    Section(String(localized: "Share")) {
                        if let pdfURL {
                            ShareLink(item: pdfURL, subject: Text(fileName)) {
                                Label(String(localized: "Share PDF"), systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Export"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fileName = document?.name ?? String(localized: "Scan")
            if let doc = document, let existing = repository.exportURL(for: doc) {
                pdfURL = existing
                pdfData = try? Data(contentsOf: existing)
            }
        }
        .alert(String(localized: "Export failed"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showProSheet) {
            NavigationStack {
                ProUpgradeView()
            }
        }
    }

    private func generatePDF(document: ScanDocumentMetadata) {
        isGenerating = true
        let name = fileName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            repository.renameDocument(id: documentID, name: name)
        }
        Task { @MainActor in
            defer { isGenerating = false }
            do {
                let options: PDFExportOptions = useProCompression && purchaseService.isProUnlocked ? .pro : .standard
                let data = try PDFExporter.export(
                    document: repository.document(id: documentID) ?? document,
                    loadImage: { repository.loadUIImage(for: $0) },
                    proOptions: options
                )
                let filename = "\(documentID.uuidString).pdf"
                let url = try FileStorage.shared.writePDF(data, filename: filename)
                repository.setExportedPDF(documentID: documentID, filename: filename)
                pdfData = data
                pdfURL = url
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct PDFPreviewRepresentable: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

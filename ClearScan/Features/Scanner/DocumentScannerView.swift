import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var onFinish: (VNDocumentCameraScanWrapper?) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: (VNDocumentCameraScanWrapper?) -> Void
        let onCancel: () -> Void

        init(onFinish: @escaping (VNDocumentCameraScanWrapper?) -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            onFinish(VNDocumentCameraScanWrapper(scan: scan))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onFinish(nil)
        }
    }
}

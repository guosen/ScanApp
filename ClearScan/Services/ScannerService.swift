import UIKit
import VisionKit

enum ScannerService {
    static var isAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }
}

# ClearScan — Simple PDF Scanner (iOS MVP)

Minimal document scanner for iPhone, aligned with the product spec: **VisionKit scanning**, **local-first storage**, **watermark-free PDF export**, and optional **ClearScan Pro** one-time purchase (StoreKit 2).

## Requirements

- macOS with **Xcode 15+**
- iPhone or simulator on **iOS 17+** (VisionKit document camera requires a real device for full scanning)

## Open the project

**Option A — use the included Xcode project**

1. Clone this repository.
2. Open `ClearScan.xcodeproj` in Xcode.
3. Set your **Team** under Signing & Capabilities.
4. Run on a physical iPhone to test the document camera.

**Option B — regenerate with XcodeGen**

```bash
brew install xcodegen
xcodegen generate
open ClearScan.xcodeproj
```

## Architecture (MVP)

| Layer | Responsibility |
| --- | --- |
| `Features/` | SwiftUI: Home, Scanner, Page editor, Preview, Export, Settings |
| `ScanCoordinator` | Scan flow and navigation |
| `ScannerService` + `DocumentScannerView` | VisionKit `VNDocumentCameraViewController` |
| `ImageProcessor` | Rotation and Core Image filters |
| `PDFExporter` | Multi-page PDF generation (page-by-page) |
| `DocumentRepository` + `FileStorage` | Codable index + on-disk JPEG/PDF |

## StoreKit testing

1. In Xcode: **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration** → select `ClearScan/Configuration/Products.storekit`.
2. Product ID: `com.clearscan.app.pro` (non-consumable, $4.99 test price in the configuration file).
3. Create the same product in **App Store Connect** before release.

## App Store checklist (from spec)

- [ ] Apple Developer Program + App Store Connect app record
- [ ] English privacy policy URL (update placeholders in Settings)
- [ ] Camera / photo library usage strings (already in build settings)
- [ ] App Privacy questionnaire (no document upload; minimal analytics recommended for v1)
- [ ] TestFlight with real scan → PDF → share flow on device
- [ ] App icon 1024×1024 in `AppIcon.appiconset`

## Out of scope for v1 (by design)

OCR, cloud sync, accounts, subscriptions, fax, e-sign, AI features.

## License

Proprietary — adjust as needed for your release.

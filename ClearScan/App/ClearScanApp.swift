import SwiftUI

@main
struct ClearScanApp: App {
    @StateObject private var repository = DocumentRepository()
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var scanCoordinator = ScanCoordinator()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(repository)
                .environmentObject(purchaseService)
                .environmentObject(scanCoordinator)
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ProUpgradeView()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ClearScan Pro")
                                .font(.headline)
                            Text(purchaseService.isProUnlocked
                                 ? String(localized: "Unlocked")
                                 : String(localized: "One-time purchase"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if purchaseService.isProUnlocked {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            Section(String(localized: "Privacy")) {
                Text(String(localized: "Scans stay on your device by default. ClearScan does not require an account and does not upload your documents."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Support")) {
                Link(String(localized: "Privacy policy"), destination: URL(string: "https://example.com/clearscan/privacy")!)
                Link(String(localized: "Contact support"), destination: URL(string: "mailto:support@example.com")!)
            }

            Section(String(localized: "About")) {
                LabeledContent(String(localized: "Version"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Done")) { dismiss() }
            }
        }
    }
}

struct ProUpgradeView: View {
    @EnvironmentObject private var purchaseService: PurchaseService

    var body: some View {
        List {
            Section {
                Text(String(localized: "Unlock advanced enhancement, optimized PDF export, and future offline Pro features with a single purchase."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "Includes")) {
                Label(String(localized: "Enhanced scan filter"), systemImage: "wand.and.stars")
                Label(String(localized: "Optimized PDF export"), systemImage: "doc.zipper")
                Label(String(localized: "Future Pro tools (no subscription)"), systemImage: "lock.open")
            }

            Section {
                if purchaseService.isProUnlocked {
                    Label(String(localized: "You own ClearScan Pro"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if let product = purchaseService.proProduct {
                    Button {
                        Task { await purchaseService.purchasePro() }
                    } label: {
                        if purchaseService.purchaseInProgress {
                            ProgressView()
                        } else {
                            Text(String(localized: "Unlock for \(product.displayPrice)"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(purchaseService.purchaseInProgress)
                } else {
                    Text(String(localized: "Pro is not configured in App Store Connect yet."))
                        .foregroundStyle(.secondary)
                }

                Button(String(localized: "Restore purchases")) {
                    Task { await purchaseService.restorePurchases() }
                }
                .disabled(purchaseService.purchaseInProgress)
            }

            if let message = purchaseService.lastErrorMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("ClearScan Pro")
        .navigationBarTitleDisplayMode(.inline)
    }
}

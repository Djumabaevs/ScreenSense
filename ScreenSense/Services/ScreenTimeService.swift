import Foundation
import FamilyControls

@Observable
final class ScreenTimeService {
    static let shared = ScreenTimeService()

    var isAuthorized = false
    var authorizationError: Error?

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
                self.authorizationError = nil
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
                self.authorizationError = error
            }
        }
    }

    func checkAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
    }
}

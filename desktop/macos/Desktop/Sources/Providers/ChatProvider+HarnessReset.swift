import Foundation

extension ChatProvider {
  /// Execute exactly one credential-free reset control transaction under a
  /// temporary non-production owner. The control clear resets the projection
  /// only after the daemon confirms deletion; a second model-ready clear would
  /// target an already-cleared generation checkpoint and fail the fault flow.
  static func withHarnessResetOwner<Result: Sendable>(
    bundleIdentifier: String?,
    clear: @MainActor @escaping () async -> Result
  ) async -> Result {
    let bundleScope = (bundleIdentifier ?? "desktop")
      .replacingOccurrences(of: ".", with: "-")
    let resetOwnerID = "desktop-harness-reset-\(bundleScope)"
    return await RuntimeOwnerIdentity.withAutomationOwnerIfMissing(resetOwnerID) {
      await clear()
    }
  }

  /// Reset isolation must clear the same kernel-owned surface the flow will
  /// exercise. Fault bundles intentionally have no authenticated owner, so
  /// establish a temporary non-production owner for this transaction rather
  /// than bypassing the owner boundary or carrying a synthetic session forward.
  func automationResetMainChatForHarness() async -> String? {
    guard AppBuild.isNonProduction else { return nil }
    return await Self.withHarnessResetOwner(bundleIdentifier: Bundle.main.bundleIdentifier) { [self] in
      let clear = await automationClearOwnerSurfaceState(chatId: "default")
      return clear["error"]
    }
  }
}

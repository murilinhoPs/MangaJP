import receive_sharing_intent

/// M0.8 share target: Photos / Files **Share → MangaJP** copies the image into
/// the App Group and opens the host app (parity with Android SEND image/*).
class ShareViewController: RSIShareViewController {
  override func shouldAutoRedirect() -> Bool {
    true
  }
}

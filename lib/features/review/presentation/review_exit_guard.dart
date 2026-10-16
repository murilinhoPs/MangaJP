import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/opaque_cupertino_page.dart';

/// Per-scope exit flags for `/review` (dialog lock, one-shot confirm, swipe
/// restore). Replaces process-wide statics so a leftover flag cannot skip the
/// next session's confirm, and tests get a fresh instance per [ProviderScope].
class ReviewExitGuard {
  bool leaveDialogOpen = false;
  bool allowNextExit = false;
  final BlockedPopRestorer popRestorer = BlockedPopRestorer();

  bool consumeAllowNextExit() {
    if (!allowNextExit) {
      return false;
    }
    allowNextExit = false;
    return true;
  }

  void resetSessionFlags() {
    leaveDialogOpen = false;
    allowNextExit = false;
  }
}

final reviewExitGuardProvider = Provider<ReviewExitGuard>((ref) {
  return ReviewExitGuard();
});

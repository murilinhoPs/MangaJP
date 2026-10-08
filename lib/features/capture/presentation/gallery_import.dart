import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/routes.dart';
import '../data/image_source_service.dart';

/// Home **Galeria** / command-bar **Abrir galeria**: pick → `/capture`.
Future<void> importFromGallery(BuildContext context, WidgetRef ref) async {
  final picked = await ref.read(imageSourceServiceProvider).pickFromGallery();
  if (!context.mounted || picked == null) {
    return;
  }
  await CaptureRoute($extra: picked).push<void>(context);
}

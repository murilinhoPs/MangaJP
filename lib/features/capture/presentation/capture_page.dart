import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/router/routes.dart';
import '../../../core/shell/shell_layout.dart';
import '../../../core/shell/shell_nav.dart';
import '../../../core/shell/shell_registry.dart';
import '../../../core/shell/task_dock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/hashing.dart';
import '../../../core/utils/ids.dart';
import '../../../core/widgets/crop_number_badge.dart';
import '../../ocr/data/ocr_repository.dart';
import '../../ocr/domain/ocr_result.dart';
import '../../pages/data/pages_repository.dart';
import '../data/image_source_service.dart';
import '../domain/capture_labels.dart';
import '../domain/capture_shot.dart';
import '../domain/crop_image.dart';
import '../domain/crop_order.dart';
import '../domain/crop_rect.dart';
import '../domain/incoming_image.dart';
import 'crop_overlay.dart';

/// Keys for the capture path test (fixture → ≥1 rect → OCR → `/pages/:id`).
abstract final class CaptureKeys {
  static const page = Key('capture-page');
  static const confirm = Key('capture-confirm');
  static const cropBytes = Key('capture-crop-bytes');
  static const ocrText = Key('capture-ocr-text');
  static const pickGallery = Key('capture-pick-gallery');
  static const overlay = Key('capture-overlay');
  static const recortesPanel = Key('capture-recortes-panel');
  static const discardDialog = Key('capture-discard-dialog');
  static const discardCancel = Key('capture-discard-cancel');
  static const discardConfirm = Key('capture-discard-confirm');

  static Key cropNumber(int number) => Key('capture-crop-number-$number');
  static Key recorteRow(int number) => Key('capture-recorte-row-$number');
}

/// `/capture` — share / Home Galeria extra / empty-state gallery pick → crop ≥1.
class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({
    super.key,
    this.image,
    this.onCropped,
    this.initialCrops,
    this.initialActiveIndex = 0,
  });

  final IncomingImage? image;
  final ValueChanged<Uint8List>? onCropped;

  /// Test / screenshot seed. When null, uses [CropRect.initial] (or the shot).
  final List<CropRect>? initialCrops;
  final int initialActiveIndex;

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  IncomingImage? _incoming;
  Uint8List? _bytes;
  Size _imageSize = Size.zero;
  List<CropRect> _crops = const [CropRect.initial];
  int _activeIndex = 0;
  CropPng? _cropped;
  OcrResult? _ocr;
  String? _pageId;
  String? _error;
  bool _busy = false;
  bool _exitDialogOpen = false;
  bool _dirty = false;
  final _savedCropKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _incoming = widget.image;
    _applyInitialCrops();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _load();
      if (kCaptureShotExitDialog && mounted) {
        _dirty = true;
        await _requestExit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CapturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _incoming = widget.image;
      _crops = const [CropRect.initial];
      _activeIndex = 0;
      _dirty = false;
      _savedCropKeys.clear();
      _load();
    }
  }

  void _applyInitialCrops() {
    final seeded = widget.initialCrops;
    if (seeded != null && seeded.isNotEmpty) {
      _crops = List.of(seeded);
      _activeIndex = widget.initialActiveIndex.clamp(0, _crops.length - 1);
      return;
    }
    if (kCaptureShotCrops > 0) {
      _crops = List.of(captureShotRects());
      _activeIndex = captureShotActiveIndex().clamp(0, _crops.length - 1);
    }
  }

  Future<void> _load() async {
    final incoming = _incoming;
    if (incoming == null) {
      setState(() {
        _bytes = null;
        _cropped = null;
        _ocr = null;
        _pageId = null;
        _error = null;
        _imageSize = Size.zero;
      });
      return;
    }
    try {
      final bytes = incoming.bytes ?? await XFile(incoming.path!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FormatException('Could not decode image');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _cropped = null;
        _ocr = null;
        _pageId = null;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = null;
        _error = '$error';
      });
    }
  }

  Future<void> _pickGallery() async {
    final picked = await ref.read(imageSourceServiceProvider).pickFromGallery();
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _incoming = picked;
      _crops = const [CropRect.initial];
      _activeIndex = 0;
      _dirty = false;
      _savedCropKeys.clear();
    });
    await _load();
  }

  /// True after the user moves, creates, or deletes a crop. The automatic
  /// initial rect does not count.
  bool get _shouldConfirmExit => _dirty;

  void _leave() => popTaskOrHome(context);

  static String _geometryKey(CropRect rect) {
    return '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
  }

  /// Esc, dock X, and Android back. Confirm only after a real crop edit.
  Future<void> _requestExit() async {
    if (_exitDialogOpen) {
      return;
    }
    if (!_shouldConfirmExit) {
      _leave();
      return;
    }
    _exitDialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tokens = dialogContext.tokens;
        return AlertDialog(
          key: CaptureKeys.discardDialog,
          title: const Text(CaptureLabels.descartarTitulo),
          content: const Text(CaptureLabels.descartarCorpo),
          actions: [
            TextButton(
              key: CaptureKeys.discardCancel,
              style: TextButton.styleFrom(foregroundColor: tokens.text2),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(CaptureLabels.cancelar),
            ),
            TextButton(
              key: CaptureKeys.discardConfirm,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                CaptureLabels.descartar,
                style: TextStyle(color: tokens.coral),
              ),
            ),
          ],
        );
      },
    );
    _exitDialogOpen = false;
    if (!mounted || discard != true) {
      return;
    }
    _leave();
  }

  Future<void> _confirm() async {
    final bytes = _bytes;
    if (bytes == null || _crops.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = rtlCropOrder(_crops);
      CropPng? last;
      OcrResult? lastOcr;
      final pageId = _pageId ??= newId();
      final sha = sha256Hex(bytes);
      for (final index in order) {
        final rect = _crops[index];
        final key = _geometryKey(rect);
        if (_savedCropKeys.contains(key)) {
          continue;
        }
        final cropped = cropToPng(bytes, rect);
        last = cropped;
        widget.onCropped?.call(cropped.bytes);
        final ocr = await ref
            .read(ocrRepositoryProvider)
            .recognize(cropped.bytes);
        lastOcr = ocr;
        await ref
            .read(pagesRepositoryProvider)
            .saveRecognizedCrop(
              pageId: pageId,
              sourceSha256: sha,
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              ocrText: ocr.fullText,
              engineId: ocr.engineId,
            );
        _savedCropKeys.add(key);
        debugPrint('M1.1 OCR ${ocr.engineId}: ${ocr.fullText}');
      }
      debugPrint('M0.8 crop PNG bytes.length=${last?.bytes.length}');
      if (!mounted) {
        return;
      }
      if (GoRouter.maybeOf(context) != null) {
        PageDetailRoute(id: pageId).go(context);
        return;
      }
      setState(() {
        _cropped = last;
        _ocr = lastOcr;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cropped = _cropped;
    final wide = ShellLayout.isWide(context);
    final canConfirm = _bytes != null && _crops.isNotEmpty && !_busy;
    final count = _bytes == null ? 0 : _crops.length;
    final meta = CaptureLabels.recortesMeta(count);
    final hint = count == 0 ? null : CaptureLabels.arrasteParaCriar;
    final task = ShellTask(
      meta: meta.isEmpty ? null : meta,
      metaHint: hint,
      actions: [
        ShellAction(
          id: 'cancel',
          label: CaptureLabels.cancelar,
          shortcut: 'Esc',
          onPressed: _requestExit,
        ),
        ShellAction(
          id: 'confirm',
          label: CaptureLabels.confirmar,
          primary: true,
          enabled: canConfirm,
          onPressed: _confirm,
        ),
      ],
    );
    return ShellBinder(
      task: task,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _CaptureExitIntent(),
        },
        child: Actions(
          actions: {
            _CaptureExitIntent: CallbackAction<_CaptureExitIntent>(
              onInvoke: (_) {
                _requestExit();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) {
                  return;
                }
                _requestExit();
              },
              child: Column(
                key: CaptureKeys.page,
                children: [
                  Expanded(
                    child: _workspace(wide: wide, tokens: tokens),
                  ),
                  if (cropped != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Crop PNG: ${cropped.bytes.length} bytes '
                        '(${cropped.width}×${cropped.height})',
                        key: CaptureKeys.cropBytes,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_ocr != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'OCR (${_ocr!.engineId}): ${_ocr!.fullText}',
                        key: CaptureKeys.ocrText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!wide) ...[
                    if (meta.isNotEmpty)
                      Padding(
                        key: ShellKeys.dockMeta,
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypeScale.metadados12.copyWith(
                                  color: tokens.text2,
                                ),
                              ),
                            ),
                            if (hint != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                hint,
                                style: AppTypeScale.metadados11.copyWith(
                                  color: tokens.text3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    TaskDock(
                      leading: [
                        DockIconButton(
                          key: ShellKeys.dockAction('close'),
                          icon: Icons.close,
                          tooltip: CaptureLabels.cancelar,
                          onPressed: _requestExit,
                        ),
                      ],
                      trailing: [
                        DockTextButton(
                          key: CaptureKeys.confirm,
                          label: CaptureLabels.confirmar,
                          primary: true,
                          enabled: canConfirm,
                          onPressed: canConfirm ? _confirm : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _workspace({required bool wide, required MangaJpTokens tokens}) {
    final canvas = _body();
    if (!wide || _bytes == null) {
      return canvas;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Captura',
            style: AppTypeScale.ui14.copyWith(
              color: tokens.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: canvas),
              _RecortesPanel(
                crops: _crops,
                activeIndex: _activeIndex,
                onSelect: (index) => setState(() => _activeIndex = index),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body() {
    final bytes = _bytes;
    if (bytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nenhuma imagem. Compartilhe um screenshot para MangaJP '
                'ou escolha da galeria.',
                textAlign: TextAlign.center,
                style: AppTypeScale.ui14.copyWith(color: context.tokens.text2),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                key: CaptureKeys.pickGallery,
                onPressed: _pickGallery,
                child: const Text(CaptureLabels.escolherGaleria),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
        CropOverlay(
          imageSize: _imageSize,
          crops: _crops,
          activeIndex: _activeIndex,
          onChanged: (crops, active) {
            final edited =
                crops.length != _crops.length ||
                !_cropListEquals(crops, _crops);
            setState(() {
              _crops = crops;
              _activeIndex = active;
              if (edited) {
                _dirty = true;
              }
            });
          },
        ),
      ],
    );
  }
}

/// Desktop Recortes inspector (Deck Captura). Balloon OCR text is not available
/// until confirm, so rows are numbered labels only.
class _RecortesPanel extends StatelessWidget {
  const _RecortesPanel({
    required this.crops,
    required this.activeIndex,
    required this.onSelect,
  });

  final List<CropRect> crops;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  /// Deck inspector width. Not in `tokens.json`.
  static const double width = 280;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final numbers = rtlCropNumbers(crops);
    final order = rtlCropOrder(crops);
    return Material(
      key: CaptureKeys.recortesPanel,
      color: tokens.bg,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tokens.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Text(
                    CaptureLabels.recortes,
                    style: AppTypeScale.ui14.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CaptureLabels.recortesCountHint(crops.length),
                    style: AppTypeScale.metadados11.copyWith(
                      color: tokens.text3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: order.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final index = order[i];
                  final number = numbers[index];
                  final selected = index == activeIndex;
                  return Material(
                    key: CaptureKeys.recorteRow(number),
                    color: selected ? tokens.overlayPrimaria : tokens.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.linha),
                      side: BorderSide(
                        color: selected ? tokens.coral : tokens.border,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onSelect(index),
                      borderRadius: BorderRadius.circular(AppRadius.linha),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            CropNumberBadge(number: number),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                CaptureLabels.recorteRow(number),
                                style: AppTypeScale.ui13.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: tokens.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _cropListEquals(List<CropRect> a, List<CropRect> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

class _CaptureExitIntent extends Intent {
  const _CaptureExitIntent();
}

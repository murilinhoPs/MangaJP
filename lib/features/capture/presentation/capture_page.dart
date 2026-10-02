import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../data/image_source_service.dart';
import '../domain/crop_image.dart';
import '../domain/crop_rect.dart';
import '../domain/incoming_image.dart';
import 'crop_overlay.dart';

/// Keys for the M0.8 smoke test (fixture → 1 rect → bytes).
abstract final class CaptureKeys {
  static const confirm = Key('capture-confirm');
  static const cropBytes = Key('capture-crop-bytes');
  static const pickGallery = Key('capture-pick-gallery');
}

/// `/capture` — share target / gallery stub / crop ≥1 rect (not a bottom tab).
class CapturePage extends ConsumerStatefulWidget {
  const CapturePage({super.key, this.image, this.onCropped});

  final IncomingImage? image;
  final ValueChanged<Uint8List>? onCropped;

  @override
  ConsumerState<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends ConsumerState<CapturePage> {
  IncomingImage? _incoming;
  Uint8List? _bytes;
  Size _imageSize = Size.zero;
  CropRect _rect = CropRect.initial;
  CropPng? _cropped;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _incoming = widget.image;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant CapturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _incoming = widget.image;
      _load();
    }
  }

  Future<void> _load() async {
    final incoming = _incoming;
    if (incoming == null) {
      setState(() {
        _bytes = null;
        _cropped = null;
        _error = null;
        _imageSize = Size.zero;
      });
      return;
    }
    try {
      final bytes = incoming.bytes ?? await File(incoming.path!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FormatException('Could not decode image');
      }
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _rect = CropRect.initial;
        _cropped = null;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _error = '$error';
      });
    }
  }

  Future<void> _pickGallery() async {
    final picked = await ref.read(imageSourceServiceProvider).pickFromGallery();
    if (!mounted || picked == null) return;
    setState(() => _incoming = picked);
    await _load();
  }

  void _confirm() {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cropped = cropToPng(bytes, _rect);
      setState(() {
        _cropped = cropped;
        _busy = false;
      });
      debugPrint('M0.8 crop PNG bytes.length=${cropped.bytes.length}');
      widget.onCropped?.call(cropped.bytes);
    } catch (error) {
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropped = _cropped;
    return Scaffold(
      appBar: AppBar(title: const Text('Captura')),
      body: Column(
        children: [
          Expanded(child: _body()),
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: CaptureKeys.confirm,
                  onPressed: _bytes == null || _busy ? null : _confirm,
                  child: const Text('Confirmar crop'),
                ),
              ),
            ),
          ),
        ],
      ),
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
              const Text(
                'Nenhuma imagem. Compartilhe um screenshot para MangaJP '
                'ou escolha da galeria.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                key: CaptureKeys.pickGallery,
                onPressed: _pickGallery,
                child: const Text('Escolher da galeria'),
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
          rect: _rect,
          onChanged: (rect) => setState(() => _rect = rect),
        ),
      ],
    );
  }
}

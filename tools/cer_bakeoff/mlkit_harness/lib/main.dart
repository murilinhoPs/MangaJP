import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('cer_bakeoff/mlkit_ja');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HarnessApp());
}

class HarnessApp extends StatelessWidget {
  const HarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ML Kit JA CER',
      home: HarnessPage(),
    );
  }
}

class HarnessPage extends StatefulWidget {
  const HarnessPage({super.key});

  @override
  State<HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends State<HarnessPage> {
  String _status = 'starting';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final paths = await _channel.invokeMapMethod<String, dynamic>('paths');
      final cropsDir = paths?['cropsDir'] as String? ?? '';
      final outPath = paths?['outPath'] as String? ?? '';
      setState(() => _status = 'OCR $cropsDir → $outPath');
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'runBakeoff',
        <String, String>{'cropsDir': cropsDir, 'outPath': outPath},
      );
      setState(() => _status = 'done $result');
    } on PlatformException catch (e) {
      setState(() => _status = 'error ${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _status = 'error $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ML Kit JA CER')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_status),
      ),
    );
  }
}

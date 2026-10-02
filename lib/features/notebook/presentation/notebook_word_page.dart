import 'package:flutter/material.dart';

import '../../../core/widgets/stub_page.dart';

class NotebookWordPage extends StatelessWidget {
  const NotebookWordPage({super.key, required this.wordId});

  final String wordId;

  @override
  Widget build(BuildContext context) {
    return ShellStubBody(message: '/notebook/word/$wordId — stub (M0.1)');
  }
}

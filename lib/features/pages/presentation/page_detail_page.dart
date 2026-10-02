import 'package:flutter/material.dart';

import '../../../core/widgets/stub_page.dart';

class PageDetailPage extends StatelessWidget {
  const PageDetailPage({super.key, required this.pageId});

  final String pageId;

  @override
  Widget build(BuildContext context) {
    return ShellStubBody(message: '/pages/$pageId — stub (M0.1)');
  }
}

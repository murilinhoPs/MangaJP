import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';

/// Close a task screen: pop if possible, otherwise go Home.
void popTaskOrHome(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return;
  }
  if (router.canPop()) {
    router.pop();
    return;
  }
  const HomeRoute().go(context);
}

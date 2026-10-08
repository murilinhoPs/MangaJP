import 'package:flutter/material.dart';

/// One command for the mobile task dock and/or the desktop command bar.
class ShellAction {
  const ShellAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.shortcut,
    this.icon,
    this.primary = false,
    this.enabled = true,
  });

  final String id;
  final String label;
  final VoidCallback onPressed;
  final String? shortcut;
  final IconData? icon;
  final bool primary;
  final bool enabled;

  @override
  bool operator ==(Object other) {
    return other is ShellAction &&
        other.id == id &&
        other.label == label &&
        other.shortcut == shortcut &&
        other.icon == icon &&
        other.primary == primary &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(id, label, shortcut, icon, primary, enabled);
}

/// Task-screen chrome the current page publishes (dock meta + extra actions).
class ShellTask {
  const ShellTask({this.meta, this.metaHint, this.actions = const []});

  final String? meta;
  final String? metaHint;
  final List<ShellAction> actions;

  @override
  bool operator ==(Object other) {
    return other is ShellTask &&
        other.meta == meta &&
        other.metaHint == metaHint &&
        _listEquals(other.actions, actions);
  }

  @override
  int get hashCode => Object.hash(meta, metaHint, Object.hashAll(actions));
}

bool _listEquals(List<ShellAction> a, List<ShellAction> b) {
  if (identical(a, b)) {
    return true;
  }
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

class ShellRegistry extends ChangeNotifier {
  ShellTask? _task;
  ShellTask? get task => _task;
  bool _notifyScheduled = false;
  bool _disposed = false;

  void bind(ShellTask task) {
    if (_disposed) {
      return;
    }
    final changed = _task != task;
    _task = task;
    if (changed) {
      _scheduleNotify();
    }
  }

  void unbind(ShellTask task) {
    if (_disposed || _task != task) {
      return;
    }
    _task = null;
    _scheduleNotify();
  }

  void _scheduleNotify() {
    if (_disposed || _notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Passes [registry] without subscribing (avoids bind→rebuild loops).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.registry, required super.child});

  final ShellRegistry registry;

  static ShellRegistry? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ShellScope>()?.registry;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) {
    return oldWidget.registry != registry;
  }
}

/// Binds [task] while this subtree is mounted.
class ShellBinder extends StatefulWidget {
  const ShellBinder({super.key, required this.task, required this.child});

  final ShellTask task;
  final Widget child;

  @override
  State<ShellBinder> createState() => _ShellBinderState();
}

class _ShellBinderState extends State<ShellBinder> {
  ShellRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ShellScope.maybeOf(context);
    if (!identical(next, _registry)) {
      _registry?.unbind(widget.task);
      _registry = next;
    }
    _registry?.bind(widget.task);
  }

  @override
  void didUpdateWidget(covariant ShellBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task != widget.task) {
      _registry?.unbind(oldWidget.task);
      _registry?.bind(widget.task);
    }
  }

  @override
  void dispose() {
    _registry?.unbind(widget.task);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'rules.dart';

/// One deinflection of [text], with Yomitan-style condition bitflags.
class DeinflectedText {
  const DeinflectedText({required this.text, required this.conditions});

  /// Surface after this transform step (dictionary form, intermediate, or original).
  final String text;

  /// Bitflags compiled from Yomitan condition ids (`v1`, `v5`, `-て`, …).
  final int conditions;
}

/// Japanese deinflector. Port of Yomitan `LanguageTransformer`
/// (`ext/js/language/language-transformer.js`) using the Japanese suffix /
/// whole-word rules in [japaneseTransforms].
///
/// Domain is Dart-only (no Flutter import), matching `lib/core/srs/`.
class Deinflector {
  const Deinflector();

  static final LanguageTransformer _japanese = LanguageTransformer.japanese();

  /// Unique candidate strings, original surface first.
  ///
  /// Includes intermediate forms (て-form, ます-stem, …). M1 lookup may filter
  /// these against JMdict `forms` / `sense_pos`; this method does not.
  List<String> candidates(String surface) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in _japanese.transform(surface)) {
      if (seen.add(item.text)) {
        out.add(item.text);
      }
    }
    return out;
  }

  /// Full transform trace, matching Yomitan `LanguageTransformer.transform`.
  List<DeinflectedText> transform(String surface) =>
      _japanese.transform(surface);

  /// Bitflags for Yomitan condition ids (`v1`, `v5`, `adj-i`, …).
  int flagsFor(Iterable<String> conditionIds) =>
      _japanese.flagsFor(conditionIds);
}

/// Compiled transform table + BFS deinflection (Yomitan `LanguageTransformer`).
class LanguageTransformer {
  LanguageTransformer._(this._transforms, this.conditionFlags);

  factory LanguageTransformer.japanese() {
    return LanguageTransformer.fromSpecs(
      japaneseConditions,
      japaneseTransforms,
    );
  }

  factory LanguageTransformer.fromSpecs(
    Map<String, ConditionSpec> conditions,
    List<TransformSpec> transforms,
  ) {
    final flags = _conditionFlagsMap(conditions);
    final compiled = <_CompiledTransform>[];
    for (final spec in transforms) {
      final rules = <_CompiledRule>[];
      for (final rule in spec.rules) {
        rules.add(
          _CompiledRule(
            kind: rule.kind,
            inflected: rule.inflected,
            deinflected: rule.deinflected,
            conditionsIn: _flagsFor(flags, rule.conditionsIn),
            conditionsOut: _flagsFor(flags, rule.conditionsOut),
          ),
        );
      }
      compiled.add(_CompiledTransform(id: spec.id, rules: rules));
    }
    return LanguageTransformer._(compiled, flags);
  }

  final List<_CompiledTransform> _transforms;
  final Map<String, int> conditionFlags;

  /// Combined bitflags for condition ids. Unknown ids contribute 0.
  int flagsFor(Iterable<String> ids) => _flagsFor(conditionFlags, ids);

  List<DeinflectedText> transform(String sourceText) {
    final results = <_Work>[
      _Work(text: sourceText, conditions: 0, trace: const []),
    ];
    for (var i = 0; i < results.length; i++) {
      final current = results[i];
      for (final transform in _transforms) {
        if (!_heuristicMatches(transform, current.text)) {
          continue;
        }
        for (var j = 0; j < transform.rules.length; j++) {
          final rule = transform.rules[j];
          if (!_conditionsMatch(current.conditions, rule.conditionsIn)) {
            continue;
          }
          if (!_isInflected(rule, current.text)) {
            continue;
          }
          final isCycle = current.trace.any(
            (frame) =>
                frame.transformId == transform.id &&
                frame.ruleIndex == j &&
                frame.text == current.text,
          );
          if (isCycle) {
            continue;
          }
          results.add(
            _Work(
              text: _deinflect(rule, current.text),
              conditions: rule.conditionsOut,
              trace: [
                _TraceFrame(
                  transformId: transform.id,
                  ruleIndex: j,
                  text: current.text,
                ),
                ...current.trace,
              ],
            ),
          );
        }
      }
    }
    return [
      for (final item in results)
        DeinflectedText(text: item.text, conditions: item.conditions),
    ];
  }

  static bool _heuristicMatches(_CompiledTransform transform, String text) {
    for (final rule in transform.rules) {
      if (_isInflected(rule, text)) {
        return true;
      }
    }
    return false;
  }

  static bool _isInflected(_CompiledRule rule, String text) {
    return switch (rule.kind) {
      InflectionKind.suffix =>
        rule.inflected.isNotEmpty && text.endsWith(rule.inflected),
      InflectionKind.wholeWord => text == rule.inflected,
    };
  }

  static String _deinflect(_CompiledRule rule, String text) {
    return switch (rule.kind) {
      InflectionKind.suffix =>
        text.substring(0, text.length - rule.inflected.length) +
            rule.deinflected,
      InflectionKind.wholeWord => rule.deinflected,
    };
  }

  /// Yomitan: if `currentConditions` is 0, any next rule is allowed.
  static bool _conditionsMatch(int current, int next) {
    return current == 0 || (current & next) != 0;
  }

  static Map<String, int> _conditionFlagsMap(
    Map<String, ConditionSpec> conditions,
  ) {
    final conditionFlagsMap = <String, int>{};
    var nextFlagIndex = 0;
    var targets = conditions.entries.toList();
    while (targets.isNotEmpty) {
      final nextTargets = <MapEntry<String, ConditionSpec>>[];
      for (final target in targets) {
        final sub = target.value.subConditions;
        late final int flags;
        if (sub == null) {
          if (nextFlagIndex >= 32) {
            throw StateError('Maximum number of conditions was exceeded');
          }
          flags = 1 << nextFlagIndex;
          nextFlagIndex++;
        } else {
          final multi = _strictFlags(conditionFlagsMap, sub);
          if (multi == null) {
            nextTargets.add(target);
            continue;
          }
          flags = multi;
        }
        conditionFlagsMap[target.key] = flags;
      }
      if (nextTargets.length == targets.length) {
        throw StateError('Cycle in condition subConditions');
      }
      targets = nextTargets;
    }
    return conditionFlagsMap;
  }

  static int? _strictFlags(Map<String, int> map, List<String> types) {
    var flags = 0;
    for (final type in types) {
      final next = map[type];
      if (next == null) {
        return null;
      }
      flags |= next;
    }
    return flags;
  }

  static int _flagsFor(Map<String, int> map, List<String> types) {
    var flags = 0;
    for (final type in types) {
      flags |= map[type] ?? 0;
    }
    return flags;
  }
}

class _CompiledTransform {
  const _CompiledTransform({required this.id, required this.rules});

  final String id;
  final List<_CompiledRule> rules;
}

class _CompiledRule {
  const _CompiledRule({
    required this.kind,
    required this.inflected,
    required this.deinflected,
    required this.conditionsIn,
    required this.conditionsOut,
  });

  final InflectionKind kind;
  final String inflected;
  final String deinflected;
  final int conditionsIn;
  final int conditionsOut;
}

class _TraceFrame {
  const _TraceFrame({
    required this.transformId,
    required this.ruleIndex,
    required this.text,
  });

  final String transformId;
  final int ruleIndex;
  final String text;
}

class _Work {
  const _Work({
    required this.text,
    required this.conditions,
    required this.trace,
  });

  final String text;
  final int conditions;
  final List<_TraceFrame> trace;
}

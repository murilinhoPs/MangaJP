// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_srs_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardSrsState _$CardSrsStateFromJson(Map<String, dynamic> json) =>
    _CardSrsState(
      easeFactor: (json['easeFactor'] as num).toDouble(),
      intervalDays: (json['intervalDays'] as num).toDouble(),
      repetitions: (json['repetitions'] as num).toInt(),
      dueAt: DateTime.parse(json['dueAt'] as String),
      phase: $enumDecode(_$CardPhaseEnumMap, json['phase']),
      engineId: json['engineId'] as String? ?? 'sm2-jr@1',
    );

Map<String, dynamic> _$CardSrsStateToJson(_CardSrsState instance) =>
    <String, dynamic>{
      'easeFactor': instance.easeFactor,
      'intervalDays': instance.intervalDays,
      'repetitions': instance.repetitions,
      'dueAt': instance.dueAt.toIso8601String(),
      'phase': _$CardPhaseEnumMap[instance.phase]!,
      'engineId': instance.engineId,
    };

const _$CardPhaseEnumMap = {
  CardPhase.neu: 'neu',
  CardPhase.learning: 'learning',
  CardPhase.review: 'review',
  CardPhase.relearning: 'relearning',
};

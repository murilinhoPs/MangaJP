// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_file_port.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupFilePort)
final backupFilePortProvider = BackupFilePortProvider._();

final class BackupFilePortProvider
    extends $FunctionalProvider<BackupFilePort, BackupFilePort, BackupFilePort>
    with $Provider<BackupFilePort> {
  BackupFilePortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupFilePortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupFilePortHash();

  @$internal
  @override
  $ProviderElement<BackupFilePort> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupFilePort create(Ref ref) {
    return backupFilePort(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupFilePort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupFilePort>(value),
    );
  }
}

String _$backupFilePortHash() => r'87ed309017188deaa97e1dac720f409809adee1e';

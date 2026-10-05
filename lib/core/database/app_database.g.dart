// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaData copyWith({String? key, String? value}) =>
      AppMetaData(key: key ?? this.key, value: value ?? this.value);
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CapturedPagesTable extends CapturedPages
    with TableInfo<$CapturedPagesTable, CapturedPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapturedPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sha256, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CapturedPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CapturedPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CapturedPage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CapturedPagesTable createAlias(String alias) {
    return $CapturedPagesTable(attachedDatabase, alias);
  }
}

class CapturedPage extends DataClass implements Insertable<CapturedPage> {
  final String id;
  final String sha256;
  final DateTime createdAt;
  const CapturedPage({
    required this.id,
    required this.sha256,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sha256'] = Variable<String>(sha256);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CapturedPagesCompanion toCompanion(bool nullToAbsent) {
    return CapturedPagesCompanion(
      id: Value(id),
      sha256: Value(sha256),
      createdAt: Value(createdAt),
    );
  }

  factory CapturedPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CapturedPage(
      id: serializer.fromJson<String>(json['id']),
      sha256: serializer.fromJson<String>(json['sha256']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sha256': serializer.toJson<String>(sha256),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CapturedPage copyWith({String? id, String? sha256, DateTime? createdAt}) =>
      CapturedPage(
        id: id ?? this.id,
        sha256: sha256 ?? this.sha256,
        createdAt: createdAt ?? this.createdAt,
      );
  CapturedPage copyWithCompanion(CapturedPagesCompanion data) {
    return CapturedPage(
      id: data.id.present ? data.id.value : this.id,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CapturedPage(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sha256, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CapturedPage &&
          other.id == this.id &&
          other.sha256 == this.sha256 &&
          other.createdAt == this.createdAt);
}

class CapturedPagesCompanion extends UpdateCompanion<CapturedPage> {
  final Value<String> id;
  final Value<String> sha256;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CapturedPagesCompanion({
    this.id = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CapturedPagesCompanion.insert({
    required String id,
    required String sha256,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sha256 = Value(sha256),
       createdAt = Value(createdAt);
  static Insertable<CapturedPage> custom({
    Expression<String>? id,
    Expression<String>? sha256,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sha256 != null) 'sha256': sha256,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CapturedPagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sha256,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CapturedPagesCompanion(
      id: id ?? this.id,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapturedPagesCompanion(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CapturedCropsTable extends CapturedCrops
    with TableInfo<$CapturedCropsTable, CapturedCrop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapturedCropsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id)',
    ),
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineIdMeta = const VerificationMeta(
    'engineId',
  );
  @override
  late final GeneratedColumn<String> engineId = GeneratedColumn<String>(
    'engine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leftMeta = const VerificationMeta('left');
  @override
  late final GeneratedColumn<double> left = GeneratedColumn<double>(
    'left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topMeta = const VerificationMeta('top');
  @override
  late final GeneratedColumn<double> top = GeneratedColumn<double>(
    'top',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    ocrText,
    engineId,
    left,
    top,
    width,
    height,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crops';
  @override
  VerificationContext validateIntegrity(
    Insertable<CapturedCrop> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    } else if (isInserting) {
      context.missing(_ocrTextMeta);
    }
    if (data.containsKey('engine_id')) {
      context.handle(
        _engineIdMeta,
        engineId.isAcceptableOrUnknown(data['engine_id']!, _engineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_engineIdMeta);
    }
    if (data.containsKey('left')) {
      context.handle(
        _leftMeta,
        left.isAcceptableOrUnknown(data['left']!, _leftMeta),
      );
    } else if (isInserting) {
      context.missing(_leftMeta);
    }
    if (data.containsKey('top')) {
      context.handle(
        _topMeta,
        top.isAcceptableOrUnknown(data['top']!, _topMeta),
      );
    } else if (isInserting) {
      context.missing(_topMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CapturedCrop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CapturedCrop(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      )!,
      engineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_id'],
      )!,
      left: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}left'],
      )!,
      top: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}top'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CapturedCropsTable createAlias(String alias) {
    return $CapturedCropsTable(attachedDatabase, alias);
  }
}

class CapturedCrop extends DataClass implements Insertable<CapturedCrop> {
  final String id;
  final String pageId;
  final String ocrText;
  final String engineId;
  final double left;
  final double top;
  final double width;
  final double height;
  final DateTime createdAt;
  const CapturedCrop({
    required this.id,
    required this.pageId,
    required this.ocrText,
    required this.engineId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['ocr_text'] = Variable<String>(ocrText);
    map['engine_id'] = Variable<String>(engineId);
    map['left'] = Variable<double>(left);
    map['top'] = Variable<double>(top);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CapturedCropsCompanion toCompanion(bool nullToAbsent) {
    return CapturedCropsCompanion(
      id: Value(id),
      pageId: Value(pageId),
      ocrText: Value(ocrText),
      engineId: Value(engineId),
      left: Value(left),
      top: Value(top),
      width: Value(width),
      height: Value(height),
      createdAt: Value(createdAt),
    );
  }

  factory CapturedCrop.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CapturedCrop(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      ocrText: serializer.fromJson<String>(json['ocrText']),
      engineId: serializer.fromJson<String>(json['engineId']),
      left: serializer.fromJson<double>(json['left']),
      top: serializer.fromJson<double>(json['top']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'ocrText': serializer.toJson<String>(ocrText),
      'engineId': serializer.toJson<String>(engineId),
      'left': serializer.toJson<double>(left),
      'top': serializer.toJson<double>(top),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CapturedCrop copyWith({
    String? id,
    String? pageId,
    String? ocrText,
    String? engineId,
    double? left,
    double? top,
    double? width,
    double? height,
    DateTime? createdAt,
  }) => CapturedCrop(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    ocrText: ocrText ?? this.ocrText,
    engineId: engineId ?? this.engineId,
    left: left ?? this.left,
    top: top ?? this.top,
    width: width ?? this.width,
    height: height ?? this.height,
    createdAt: createdAt ?? this.createdAt,
  );
  CapturedCrop copyWithCompanion(CapturedCropsCompanion data) {
    return CapturedCrop(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      engineId: data.engineId.present ? data.engineId.value : this.engineId,
      left: data.left.present ? data.left.value : this.left,
      top: data.top.present ? data.top.value : this.top,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CapturedCrop(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('ocrText: $ocrText, ')
          ..write('engineId: $engineId, ')
          ..write('left: $left, ')
          ..write('top: $top, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pageId,
    ocrText,
    engineId,
    left,
    top,
    width,
    height,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CapturedCrop &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.ocrText == this.ocrText &&
          other.engineId == this.engineId &&
          other.left == this.left &&
          other.top == this.top &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt);
}

class CapturedCropsCompanion extends UpdateCompanion<CapturedCrop> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> ocrText;
  final Value<String> engineId;
  final Value<double> left;
  final Value<double> top;
  final Value<double> width;
  final Value<double> height;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CapturedCropsCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.engineId = const Value.absent(),
    this.left = const Value.absent(),
    this.top = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CapturedCropsCompanion.insert({
    required String id,
    required String pageId,
    required String ocrText,
    required String engineId,
    required double left,
    required double top,
    required double width,
    required double height,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       ocrText = Value(ocrText),
       engineId = Value(engineId),
       left = Value(left),
       top = Value(top),
       width = Value(width),
       height = Value(height),
       createdAt = Value(createdAt);
  static Insertable<CapturedCrop> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? ocrText,
    Expression<String>? engineId,
    Expression<double>? left,
    Expression<double>? top,
    Expression<double>? width,
    Expression<double>? height,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (ocrText != null) 'ocr_text': ocrText,
      if (engineId != null) 'engine_id': engineId,
      if (left != null) 'left': left,
      if (top != null) 'top': top,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CapturedCropsCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? ocrText,
    Value<String>? engineId,
    Value<double>? left,
    Value<double>? top,
    Value<double>? width,
    Value<double>? height,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CapturedCropsCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      ocrText: ocrText ?? this.ocrText,
      engineId: engineId ?? this.engineId,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (engineId.present) {
      map['engine_id'] = Variable<String>(engineId.value);
    }
    if (left.present) {
      map['left'] = Variable<double>(left.value);
    }
    if (top.present) {
      map['top'] = Variable<double>(top.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapturedCropsCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('ocrText: $ocrText, ')
          ..write('engineId: $engineId, ')
          ..write('left: $left, ')
          ..write('top: $top, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserWordsTable extends UserWords
    with TableInfo<$UserWordsTable, UserWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, seq, lemma, reading, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    } else if (isInserting) {
      context.missing(_lemmaMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserWordsTable createAlias(String alias) {
    return $UserWordsTable(attachedDatabase, alias);
  }
}

class UserWord extends DataClass implements Insertable<UserWord> {
  final String id;
  final int seq;
  final String lemma;
  final String reading;
  final DateTime createdAt;
  const UserWord({
    required this.id,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['seq'] = Variable<int>(seq);
    map['lemma'] = Variable<String>(lemma);
    map['reading'] = Variable<String>(reading);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserWordsCompanion toCompanion(bool nullToAbsent) {
    return UserWordsCompanion(
      id: Value(id),
      seq: Value(seq),
      lemma: Value(lemma),
      reading: Value(reading),
      createdAt: Value(createdAt),
    );
  }

  factory UserWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWord(
      id: serializer.fromJson<String>(json['id']),
      seq: serializer.fromJson<int>(json['seq']),
      lemma: serializer.fromJson<String>(json['lemma']),
      reading: serializer.fromJson<String>(json['reading']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seq': serializer.toJson<int>(seq),
      'lemma': serializer.toJson<String>(lemma),
      'reading': serializer.toJson<String>(reading),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserWord copyWith({
    String? id,
    int? seq,
    String? lemma,
    String? reading,
    DateTime? createdAt,
  }) => UserWord(
    id: id ?? this.id,
    seq: seq ?? this.seq,
    lemma: lemma ?? this.lemma,
    reading: reading ?? this.reading,
    createdAt: createdAt ?? this.createdAt,
  );
  UserWord copyWithCompanion(UserWordsCompanion data) {
    return UserWord(
      id: data.id.present ? data.id.value : this.id,
      seq: data.seq.present ? data.seq.value : this.seq,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      reading: data.reading.present ? data.reading.value : this.reading,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWord(')
          ..write('id: $id, ')
          ..write('seq: $seq, ')
          ..write('lemma: $lemma, ')
          ..write('reading: $reading, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, seq, lemma, reading, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWord &&
          other.id == this.id &&
          other.seq == this.seq &&
          other.lemma == this.lemma &&
          other.reading == this.reading &&
          other.createdAt == this.createdAt);
}

class UserWordsCompanion extends UpdateCompanion<UserWord> {
  final Value<String> id;
  final Value<int> seq;
  final Value<String> lemma;
  final Value<String> reading;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserWordsCompanion({
    this.id = const Value.absent(),
    this.seq = const Value.absent(),
    this.lemma = const Value.absent(),
    this.reading = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWordsCompanion.insert({
    required String id,
    required int seq,
    required String lemma,
    required String reading,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seq = Value(seq),
       lemma = Value(lemma),
       reading = Value(reading),
       createdAt = Value(createdAt);
  static Insertable<UserWord> custom({
    Expression<String>? id,
    Expression<int>? seq,
    Expression<String>? lemma,
    Expression<String>? reading,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seq != null) 'seq': seq,
      if (lemma != null) 'lemma': lemma,
      if (reading != null) 'reading': reading,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWordsCompanion copyWith({
    Value<String>? id,
    Value<int>? seq,
    Value<String>? lemma,
    Value<String>? reading,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UserWordsCompanion(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      lemma: lemma ?? this.lemma,
      reading: reading ?? this.reading,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordsCompanion(')
          ..write('id: $id, ')
          ..write('seq: $seq, ')
          ..write('lemma: $lemma, ')
          ..write('reading: $reading, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserWordStatesTable extends UserWordStates
    with TableInfo<$UserWordStatesTable, UserWordState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [wordId, state, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWordState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  UserWordState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWordState(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserWordStatesTable createAlias(String alias) {
    return $UserWordStatesTable(attachedDatabase, alias);
  }
}

class UserWordState extends DataClass implements Insertable<UserWordState> {
  final String wordId;
  final String state;
  final DateTime updatedAt;
  const UserWordState({
    required this.wordId,
    required this.state,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['state'] = Variable<String>(state);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserWordStatesCompanion toCompanion(bool nullToAbsent) {
    return UserWordStatesCompanion(
      wordId: Value(wordId),
      state: Value(state),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserWordState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWordState(
      wordId: serializer.fromJson<String>(json['wordId']),
      state: serializer.fromJson<String>(json['state']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'state': serializer.toJson<String>(state),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserWordState copyWith({
    String? wordId,
    String? state,
    DateTime? updatedAt,
  }) => UserWordState(
    wordId: wordId ?? this.wordId,
    state: state ?? this.state,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserWordState copyWithCompanion(UserWordStatesCompanion data) {
    return UserWordState(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      state: data.state.present ? data.state.value : this.state,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWordState(')
          ..write('wordId: $wordId, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, state, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWordState &&
          other.wordId == this.wordId &&
          other.state == this.state &&
          other.updatedAt == this.updatedAt);
}

class UserWordStatesCompanion extends UpdateCompanion<UserWordState> {
  final Value<String> wordId;
  final Value<String> state;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserWordStatesCompanion({
    this.wordId = const Value.absent(),
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWordStatesCompanion.insert({
    required String wordId,
    required String state,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : wordId = Value(wordId),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<UserWordState> custom({
    Expression<String>? wordId,
    Expression<String>? state,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (state != null) 'state': state,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWordStatesCompanion copyWith({
    Value<String>? wordId,
    Value<String>? state,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserWordStatesCompanion(
      wordId: wordId ?? this.wordId,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordStatesCompanion(')
          ..write('wordId: $wordId, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CropWordsTable extends CropWords
    with TableInfo<$CropWordsTable, CropWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CropWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES crops (id)',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cropId, wordId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crop_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<CropWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cropId, wordId};
  @override
  CropWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CropWord(
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CropWordsTable createAlias(String alias) {
    return $CropWordsTable(attachedDatabase, alias);
  }
}

class CropWord extends DataClass implements Insertable<CropWord> {
  final String cropId;
  final String wordId;
  final DateTime createdAt;
  const CropWord({
    required this.cropId,
    required this.wordId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['crop_id'] = Variable<String>(cropId);
    map['word_id'] = Variable<String>(wordId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CropWordsCompanion toCompanion(bool nullToAbsent) {
    return CropWordsCompanion(
      cropId: Value(cropId),
      wordId: Value(wordId),
      createdAt: Value(createdAt),
    );
  }

  factory CropWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CropWord(
      cropId: serializer.fromJson<String>(json['cropId']),
      wordId: serializer.fromJson<String>(json['wordId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cropId': serializer.toJson<String>(cropId),
      'wordId': serializer.toJson<String>(wordId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CropWord copyWith({String? cropId, String? wordId, DateTime? createdAt}) =>
      CropWord(
        cropId: cropId ?? this.cropId,
        wordId: wordId ?? this.wordId,
        createdAt: createdAt ?? this.createdAt,
      );
  CropWord copyWithCompanion(CropWordsCompanion data) {
    return CropWord(
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CropWord(')
          ..write('cropId: $cropId, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cropId, wordId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CropWord &&
          other.cropId == this.cropId &&
          other.wordId == this.wordId &&
          other.createdAt == this.createdAt);
}

class CropWordsCompanion extends UpdateCompanion<CropWord> {
  final Value<String> cropId;
  final Value<String> wordId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CropWordsCompanion({
    this.cropId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CropWordsCompanion.insert({
    required String cropId,
    required String wordId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : cropId = Value(cropId),
       wordId = Value(wordId),
       createdAt = Value(createdAt);
  static Insertable<CropWord> custom({
    Expression<String>? cropId,
    Expression<String>? wordId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cropId != null) 'crop_id': cropId,
      if (wordId != null) 'word_id': wordId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CropWordsCompanion copyWith({
    Value<String>? cropId,
    Value<String>? wordId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CropWordsCompanion(
      cropId: cropId ?? this.cropId,
      wordId: wordId ?? this.wordId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CropWordsCompanion(')
          ..write('cropId: $cropId, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCardsTable extends UserCards
    with TableInfo<$UserCardsTable, UserCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suspendReasonMeta = const VerificationMeta(
    'suspendReason',
  );
  @override
  late final GeneratedColumn<String> suspendReason = GeneratedColumn<String>(
    'suspend_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    kind,
    createdAt,
    suspendReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('suspend_reason')) {
      context.handle(
        _suspendReasonMeta,
        suspendReason.isAcceptableOrUnknown(
          data['suspend_reason']!,
          _suspendReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      suspendReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suspend_reason'],
      ),
    );
  }

  @override
  $UserCardsTable createAlias(String alias) {
    return $UserCardsTable(attachedDatabase, alias);
  }
}

class UserCard extends DataClass implements Insertable<UserCard> {
  final String id;
  final String wordId;
  final String kind;
  final DateTime createdAt;
  final String? suspendReason;
  const UserCard({
    required this.id,
    required this.wordId,
    required this.kind,
    required this.createdAt,
    this.suspendReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['word_id'] = Variable<String>(wordId);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || suspendReason != null) {
      map['suspend_reason'] = Variable<String>(suspendReason);
    }
    return map;
  }

  UserCardsCompanion toCompanion(bool nullToAbsent) {
    return UserCardsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      kind: Value(kind),
      createdAt: Value(createdAt),
      suspendReason: suspendReason == null && nullToAbsent
          ? const Value.absent()
          : Value(suspendReason),
    );
  }

  factory UserCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCard(
      id: serializer.fromJson<String>(json['id']),
      wordId: serializer.fromJson<String>(json['wordId']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      suspendReason: serializer.fromJson<String?>(json['suspendReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wordId': serializer.toJson<String>(wordId),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'suspendReason': serializer.toJson<String?>(suspendReason),
    };
  }

  UserCard copyWith({
    String? id,
    String? wordId,
    String? kind,
    DateTime? createdAt,
    Value<String?> suspendReason = const Value.absent(),
  }) => UserCard(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    suspendReason: suspendReason.present
        ? suspendReason.value
        : this.suspendReason,
  );
  UserCard copyWithCompanion(UserCardsCompanion data) {
    return UserCard(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      suspendReason: data.suspendReason.present
          ? data.suspendReason.value
          : this.suspendReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCard(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('suspendReason: $suspendReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, kind, createdAt, suspendReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCard &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.suspendReason == this.suspendReason);
}

class UserCardsCompanion extends UpdateCompanion<UserCard> {
  final Value<String> id;
  final Value<String> wordId;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  final Value<String?> suspendReason;
  final Value<int> rowid;
  const UserCardsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.suspendReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCardsCompanion.insert({
    required String id,
    required String wordId,
    required String kind,
    required DateTime createdAt,
    this.suspendReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wordId = Value(wordId),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<UserCard> custom({
    Expression<String>? id,
    Expression<String>? wordId,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
    Expression<String>? suspendReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (suspendReason != null) 'suspend_reason': suspendReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? wordId,
    Value<String>? kind,
    Value<DateTime>? createdAt,
    Value<String?>? suspendReason,
    Value<int>? rowid,
  }) {
    return UserCardsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      suspendReason: suspendReason ?? this.suspendReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (suspendReason.present) {
      map['suspend_reason'] = Variable<String>(suspendReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCardsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('suspendReason: $suspendReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCardSrsTable extends UserCardSrs
    with TableInfo<$UserCardSrsTable, CardSrsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCardSrsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id)',
    ),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<double> intervalDays = GeneratedColumn<double>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineIdMeta = const VerificationMeta(
    'engineId',
  );
  @override
  late final GeneratedColumn<String> engineId = GeneratedColumn<String>(
    'engine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    easeFactor,
    intervalDays,
    repetitions,
    dueAt,
    phase,
    engineId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_srs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardSrsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    } else if (isInserting) {
      context.missing(_easeFactorMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repetitionsMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('engine_id')) {
      context.handle(
        _engineIdMeta,
        engineId.isAcceptableOrUnknown(data['engine_id']!, _engineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_engineIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  CardSrsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardSrsRow(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      engineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine_id'],
      )!,
    );
  }

  @override
  $UserCardSrsTable createAlias(String alias) {
    return $UserCardSrsTable(attachedDatabase, alias);
  }
}

class CardSrsRow extends DataClass implements Insertable<CardSrsRow> {
  final String cardId;
  final double easeFactor;
  final double intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final String phase;
  final String engineId;
  const CardSrsRow({
    required this.cardId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
    required this.phase,
    required this.engineId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<double>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['phase'] = Variable<String>(phase);
    map['engine_id'] = Variable<String>(engineId);
    return map;
  }

  UserCardSrsCompanion toCompanion(bool nullToAbsent) {
    return UserCardSrsCompanion(
      cardId: Value(cardId),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      dueAt: Value(dueAt),
      phase: Value(phase),
      engineId: Value(engineId),
    );
  }

  factory CardSrsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardSrsRow(
      cardId: serializer.fromJson<String>(json['cardId']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<double>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      phase: serializer.fromJson<String>(json['phase']),
      engineId: serializer.fromJson<String>(json['engineId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<double>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'phase': serializer.toJson<String>(phase),
      'engineId': serializer.toJson<String>(engineId),
    };
  }

  CardSrsRow copyWith({
    String? cardId,
    double? easeFactor,
    double? intervalDays,
    int? repetitions,
    DateTime? dueAt,
    String? phase,
    String? engineId,
  }) => CardSrsRow(
    cardId: cardId ?? this.cardId,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    dueAt: dueAt ?? this.dueAt,
    phase: phase ?? this.phase,
    engineId: engineId ?? this.engineId,
  );
  CardSrsRow copyWithCompanion(UserCardSrsCompanion data) {
    return CardSrsRow(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      phase: data.phase.present ? data.phase.value : this.phase,
      engineId: data.engineId.present ? data.engineId.value : this.engineId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardSrsRow(')
          ..write('cardId: $cardId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueAt: $dueAt, ')
          ..write('phase: $phase, ')
          ..write('engineId: $engineId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cardId,
    easeFactor,
    intervalDays,
    repetitions,
    dueAt,
    phase,
    engineId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardSrsRow &&
          other.cardId == this.cardId &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.dueAt == this.dueAt &&
          other.phase == this.phase &&
          other.engineId == this.engineId);
}

class UserCardSrsCompanion extends UpdateCompanion<CardSrsRow> {
  final Value<String> cardId;
  final Value<double> easeFactor;
  final Value<double> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime> dueAt;
  final Value<String> phase;
  final Value<String> engineId;
  final Value<int> rowid;
  const UserCardSrsCompanion({
    this.cardId = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.phase = const Value.absent(),
    this.engineId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCardSrsCompanion.insert({
    required String cardId,
    required double easeFactor,
    required double intervalDays,
    required int repetitions,
    required DateTime dueAt,
    required String phase,
    required String engineId,
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       easeFactor = Value(easeFactor),
       intervalDays = Value(intervalDays),
       repetitions = Value(repetitions),
       dueAt = Value(dueAt),
       phase = Value(phase),
       engineId = Value(engineId);
  static Insertable<CardSrsRow> custom({
    Expression<String>? cardId,
    Expression<double>? easeFactor,
    Expression<double>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? dueAt,
    Expression<String>? phase,
    Expression<String>? engineId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (dueAt != null) 'due_at': dueAt,
      if (phase != null) 'phase': phase,
      if (engineId != null) 'engine_id': engineId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCardSrsCompanion copyWith({
    Value<String>? cardId,
    Value<double>? easeFactor,
    Value<double>? intervalDays,
    Value<int>? repetitions,
    Value<DateTime>? dueAt,
    Value<String>? phase,
    Value<String>? engineId,
    Value<int>? rowid,
  }) {
    return UserCardSrsCompanion(
      cardId: cardId ?? this.cardId,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueAt: dueAt ?? this.dueAt,
      phase: phase ?? this.phase,
      engineId: engineId ?? this.engineId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<double>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (engineId.present) {
      map['engine_id'] = Variable<String>(engineId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCardSrsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('dueAt: $dueAt, ')
          ..write('phase: $phase, ')
          ..write('engineId: $engineId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $CapturedPagesTable capturedPages = $CapturedPagesTable(this);
  late final $CapturedCropsTable capturedCrops = $CapturedCropsTable(this);
  late final $UserWordsTable userWords = $UserWordsTable(this);
  late final $UserWordStatesTable userWordStates = $UserWordStatesTable(this);
  late final $CropWordsTable cropWords = $CropWordsTable(this);
  late final $UserCardsTable userCards = $UserCardsTable(this);
  late final $UserCardSrsTable userCardSrs = $UserCardSrsTable(this);
  late final AppMetaDao appMetaDao = AppMetaDao(this as AppDatabase);
  late final PagesDao pagesDao = PagesDao(this as AppDatabase);
  late final WordsDao wordsDao = WordsDao(this as AppDatabase);
  late final CardsDao cardsDao = CardsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMeta,
    capturedPages,
    capturedCrops,
    userWords,
    userWordStates,
    cropWords,
    userCards,
    userCardSrs,
  ];
}

typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, AppMetaData>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;
typedef $$CapturedPagesTableCreateCompanionBuilder =
    CapturedPagesCompanion Function({
      required String id,
      required String sha256,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CapturedPagesTableUpdateCompanionBuilder =
    CapturedPagesCompanion Function({
      Value<String> id,
      Value<String> sha256,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CapturedPagesTableReferences
    extends BaseReferences<_$AppDatabase, $CapturedPagesTable, CapturedPage> {
  $$CapturedPagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CapturedCropsTable, List<CapturedCrop>>
  _capturedCropsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.capturedCrops,
    aliasName: 'pages__id__crops__page_id',
  );

  $$CapturedCropsTableProcessedTableManager get capturedCropsRefs {
    final manager = $$CapturedCropsTableTableManager(
      $_db,
      $_db.capturedCrops,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_capturedCropsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CapturedPagesTableFilterComposer
    extends Composer<_$AppDatabase, $CapturedPagesTable> {
  $$CapturedPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> capturedCropsRefs(
    Expression<bool> Function($$CapturedCropsTableFilterComposer f) f,
  ) {
    final $$CapturedCropsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.capturedCrops,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedCropsTableFilterComposer(
            $db: $db,
            $table: $db.capturedCrops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CapturedPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CapturedPagesTable> {
  $$CapturedPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CapturedPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapturedPagesTable> {
  $$CapturedPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> capturedCropsRefs<T extends Object>(
    Expression<T> Function($$CapturedCropsTableAnnotationComposer a) f,
  ) {
    final $$CapturedCropsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.capturedCrops,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedCropsTableAnnotationComposer(
            $db: $db,
            $table: $db.capturedCrops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CapturedPagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapturedPagesTable,
          CapturedPage,
          $$CapturedPagesTableFilterComposer,
          $$CapturedPagesTableOrderingComposer,
          $$CapturedPagesTableAnnotationComposer,
          $$CapturedPagesTableCreateCompanionBuilder,
          $$CapturedPagesTableUpdateCompanionBuilder,
          (CapturedPage, $$CapturedPagesTableReferences),
          CapturedPage,
          PrefetchHooks Function({bool capturedCropsRefs})
        > {
  $$CapturedPagesTableTableManager(_$AppDatabase db, $CapturedPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapturedPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapturedPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapturedPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapturedPagesCompanion(
                id: id,
                sha256: sha256,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sha256,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CapturedPagesCompanion.insert(
                id: id,
                sha256: sha256,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CapturedPagesTable, CapturedPage>(table),
                  $$CapturedPagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({capturedCropsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (capturedCropsRefs) db.capturedCrops,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (capturedCropsRefs)
                    await $_getPrefetchedData<
                      CapturedPage,
                      $CapturedPagesTable,
                      CapturedCrop
                    >(
                      currentTable: table,
                      referencedTable: $$CapturedPagesTableReferences
                          ._capturedCropsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CapturedPagesTableReferences(
                            db,
                            table,
                            p0,
                          ).capturedCropsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.pageId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CapturedPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapturedPagesTable,
      CapturedPage,
      $$CapturedPagesTableFilterComposer,
      $$CapturedPagesTableOrderingComposer,
      $$CapturedPagesTableAnnotationComposer,
      $$CapturedPagesTableCreateCompanionBuilder,
      $$CapturedPagesTableUpdateCompanionBuilder,
      (CapturedPage, $$CapturedPagesTableReferences),
      CapturedPage,
      PrefetchHooks Function({bool capturedCropsRefs})
    >;
typedef $$CapturedCropsTableCreateCompanionBuilder =
    CapturedCropsCompanion Function({
      required String id,
      required String pageId,
      required String ocrText,
      required String engineId,
      required double left,
      required double top,
      required double width,
      required double height,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CapturedCropsTableUpdateCompanionBuilder =
    CapturedCropsCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<String> ocrText,
      Value<String> engineId,
      Value<double> left,
      Value<double> top,
      Value<double> width,
      Value<double> height,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CapturedCropsTableReferences
    extends BaseReferences<_$AppDatabase, $CapturedCropsTable, CapturedCrop> {
  $$CapturedCropsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CapturedPagesTable _pageIdTable(_$AppDatabase db) =>
      db.capturedPages.createAlias('crops__page_id__pages__id');

  $$CapturedPagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$CapturedPagesTableTableManager(
      $_db,
      $_db.capturedPages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CropWordsTable, List<CropWord>>
  _cropWordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cropWords,
    aliasName: 'crops__id__crop_words__crop_id',
  );

  $$CropWordsTableProcessedTableManager get cropWordsRefs {
    final manager = $$CropWordsTableTableManager(
      $_db,
      $_db.cropWords,
    ).filter((f) => f.cropId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cropWordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CapturedCropsTableFilterComposer
    extends Composer<_$AppDatabase, $CapturedCropsTable> {
  $$CapturedCropsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get left => $composableBuilder(
    column: $table.left,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get top => $composableBuilder(
    column: $table.top,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CapturedPagesTableFilterComposer get pageId {
    final $$CapturedPagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.capturedPages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedPagesTableFilterComposer(
            $db: $db,
            $table: $db.capturedPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cropWordsRefs(
    Expression<bool> Function($$CropWordsTableFilterComposer f) f,
  ) {
    final $$CropWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cropWords,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropWordsTableFilterComposer(
            $db: $db,
            $table: $db.cropWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CapturedCropsTableOrderingComposer
    extends Composer<_$AppDatabase, $CapturedCropsTable> {
  $$CapturedCropsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get left => $composableBuilder(
    column: $table.left,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get top => $composableBuilder(
    column: $table.top,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CapturedPagesTableOrderingComposer get pageId {
    final $$CapturedPagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.capturedPages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedPagesTableOrderingComposer(
            $db: $db,
            $table: $db.capturedPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CapturedCropsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapturedCropsTable> {
  $$CapturedCropsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get engineId =>
      $composableBuilder(column: $table.engineId, builder: (column) => column);

  GeneratedColumn<double> get left =>
      $composableBuilder(column: $table.left, builder: (column) => column);

  GeneratedColumn<double> get top =>
      $composableBuilder(column: $table.top, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CapturedPagesTableAnnotationComposer get pageId {
    final $$CapturedPagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.capturedPages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedPagesTableAnnotationComposer(
            $db: $db,
            $table: $db.capturedPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cropWordsRefs<T extends Object>(
    Expression<T> Function($$CropWordsTableAnnotationComposer a) f,
  ) {
    final $$CropWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cropWords,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cropWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CapturedCropsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapturedCropsTable,
          CapturedCrop,
          $$CapturedCropsTableFilterComposer,
          $$CapturedCropsTableOrderingComposer,
          $$CapturedCropsTableAnnotationComposer,
          $$CapturedCropsTableCreateCompanionBuilder,
          $$CapturedCropsTableUpdateCompanionBuilder,
          (CapturedCrop, $$CapturedCropsTableReferences),
          CapturedCrop,
          PrefetchHooks Function({bool pageId, bool cropWordsRefs})
        > {
  $$CapturedCropsTableTableManager(_$AppDatabase db, $CapturedCropsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapturedCropsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapturedCropsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapturedCropsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> ocrText = const Value.absent(),
                Value<String> engineId = const Value.absent(),
                Value<double> left = const Value.absent(),
                Value<double> top = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapturedCropsCompanion(
                id: id,
                pageId: pageId,
                ocrText: ocrText,
                engineId: engineId,
                left: left,
                top: top,
                width: width,
                height: height,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required String ocrText,
                required String engineId,
                required double left,
                required double top,
                required double width,
                required double height,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CapturedCropsCompanion.insert(
                id: id,
                pageId: pageId,
                ocrText: ocrText,
                engineId: engineId,
                left: left,
                top: top,
                width: width,
                height: height,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CapturedCropsTable, CapturedCrop>(table),
                  $$CapturedCropsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false, cropWordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cropWordsRefs) db.cropWords],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.pageId,
                        referencedTable: $$CapturedCropsTableReferences
                            ._pageIdTable(db),
                        referencedColumn: $$CapturedCropsTableReferences
                            ._pageIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cropWordsRefs)
                    await $_getPrefetchedData<
                      CapturedCrop,
                      $CapturedCropsTable,
                      CropWord
                    >(
                      currentTable: table,
                      referencedTable: $$CapturedCropsTableReferences
                          ._cropWordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CapturedCropsTableReferences(
                            db,
                            table,
                            p0,
                          ).cropWordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cropId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CapturedCropsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapturedCropsTable,
      CapturedCrop,
      $$CapturedCropsTableFilterComposer,
      $$CapturedCropsTableOrderingComposer,
      $$CapturedCropsTableAnnotationComposer,
      $$CapturedCropsTableCreateCompanionBuilder,
      $$CapturedCropsTableUpdateCompanionBuilder,
      (CapturedCrop, $$CapturedCropsTableReferences),
      CapturedCrop,
      PrefetchHooks Function({bool pageId, bool cropWordsRefs})
    >;
typedef $$UserWordsTableCreateCompanionBuilder = UserWordsCompanion Function({
  required String id,
  required int seq,
  required String lemma,
  required String reading,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UserWordsTableUpdateCompanionBuilder = UserWordsCompanion Function({
  Value<String> id,
  Value<int> seq,
  Value<String> lemma,
  Value<String> reading,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$UserWordsTableReferences
    extends BaseReferences<_$AppDatabase, $UserWordsTable, UserWord> {
  $$UserWordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserWordStatesTable, List<UserWordState>>
  _userWordStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userWordStates,
    aliasName: 'words__id__word_states__word_id',
  );

  $$UserWordStatesTableProcessedTableManager get userWordStatesRefs {
    final manager = $$UserWordStatesTableTableManager(
      $_db,
      $_db.userWordStates,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userWordStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CropWordsTable, List<CropWord>>
  _cropWordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cropWords,
    aliasName: 'words__id__crop_words__word_id',
  );

  $$CropWordsTableProcessedTableManager get cropWordsRefs {
    final manager = $$CropWordsTableTableManager(
      $_db,
      $_db.cropWords,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cropWordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserCardsTable, List<UserCard>>
  _userCardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userCards,
    aliasName: 'words__id__cards__word_id',
  );

  $$UserCardsTableProcessedTableManager get userCardsRefs {
    final manager = $$UserCardsTableTableManager(
      $_db,
      $_db.userCards,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserWordsTableFilterComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userWordStatesRefs(
    Expression<bool> Function($$UserWordStatesTableFilterComposer f) f,
  ) {
    final $$UserWordStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userWordStates,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordStatesTableFilterComposer(
            $db: $db,
            $table: $db.userWordStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cropWordsRefs(
    Expression<bool> Function($$CropWordsTableFilterComposer f) f,
  ) {
    final $$CropWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cropWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropWordsTableFilterComposer(
            $db: $db,
            $table: $db.cropWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userCardsRefs(
    Expression<bool> Function($$UserCardsTableFilterComposer f) f,
  ) {
    final $$UserCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userCards,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardsTableFilterComposer(
            $db: $db,
            $table: $db.userCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> userWordStatesRefs<T extends Object>(
    Expression<T> Function($$UserWordStatesTableAnnotationComposer a) f,
  ) {
    final $$UserWordStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userWordStates,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.userWordStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cropWordsRefs<T extends Object>(
    Expression<T> Function($$CropWordsTableAnnotationComposer a) f,
  ) {
    final $$CropWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cropWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cropWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userCardsRefs<T extends Object>(
    Expression<T> Function($$UserCardsTableAnnotationComposer a) f,
  ) {
    final $$UserCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userCards,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.userCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserWordsTable,
          UserWord,
          $$UserWordsTableFilterComposer,
          $$UserWordsTableOrderingComposer,
          $$UserWordsTableAnnotationComposer,
          $$UserWordsTableCreateCompanionBuilder,
          $$UserWordsTableUpdateCompanionBuilder,
          (UserWord, $$UserWordsTableReferences),
          UserWord,
          PrefetchHooks Function({
            bool userWordStatesRefs,
            bool cropWordsRefs,
            bool userCardsRefs,
          })
        > {
  $$UserWordsTableTableManager(_$AppDatabase db, $UserWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> lemma = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserWordsCompanion(
                id: id,
                seq: seq,
                lemma: lemma,
                reading: reading,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int seq,
                required String lemma,
                required String reading,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UserWordsCompanion.insert(
                id: id,
                seq: seq,
                lemma: lemma,
                reading: reading,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserWordsTable, UserWord>(table),
                  $$UserWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                userWordStatesRefs = false,
                cropWordsRefs = false,
                userCardsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (userWordStatesRefs) db.userWordStates,
                    if (cropWordsRefs) db.cropWords,
                    if (userCardsRefs) db.userCards,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (userWordStatesRefs)
                        await $_getPrefetchedData<
                          UserWord,
                          $UserWordsTable,
                          UserWordState
                        >(
                          currentTable: table,
                          referencedTable: $$UserWordsTableReferences
                              ._userWordStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UserWordsTableReferences(
                                db,
                                table,
                                p0,
                              ).userWordStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cropWordsRefs)
                        await $_getPrefetchedData<
                          UserWord,
                          $UserWordsTable,
                          CropWord
                        >(
                          currentTable: table,
                          referencedTable: $$UserWordsTableReferences
                              ._cropWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UserWordsTableReferences(
                                db,
                                table,
                                p0,
                              ).cropWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userCardsRefs)
                        await $_getPrefetchedData<
                          UserWord,
                          $UserWordsTable,
                          UserCard
                        >(
                          currentTable: table,
                          referencedTable: $$UserWordsTableReferences
                              ._userCardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UserWordsTableReferences(
                                db,
                                table,
                                p0,
                              ).userCardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UserWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserWordsTable,
      UserWord,
      $$UserWordsTableFilterComposer,
      $$UserWordsTableOrderingComposer,
      $$UserWordsTableAnnotationComposer,
      $$UserWordsTableCreateCompanionBuilder,
      $$UserWordsTableUpdateCompanionBuilder,
      (UserWord, $$UserWordsTableReferences),
      UserWord,
      PrefetchHooks Function({
        bool userWordStatesRefs,
        bool cropWordsRefs,
        bool userCardsRefs,
      })
    >;
typedef $$UserWordStatesTableCreateCompanionBuilder =
    UserWordStatesCompanion Function({
      required String wordId,
      required String state,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserWordStatesTableUpdateCompanionBuilder =
    UserWordStatesCompanion Function({
      Value<String> wordId,
      Value<String> state,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UserWordStatesTableReferences
    extends BaseReferences<_$AppDatabase, $UserWordStatesTable, UserWordState> {
  $$UserWordStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserWordsTable _wordIdTable(_$AppDatabase db) =>
      db.userWords.createAlias('word_states__word_id__words__id');

  $$UserWordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$UserWordsTableTableManager(
      $_db,
      $_db.userWords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserWordStatesTableFilterComposer
    extends Composer<_$AppDatabase, $UserWordStatesTable> {
  $$UserWordStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UserWordsTableFilterComposer get wordId {
    final $$UserWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableFilterComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserWordStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWordStatesTable> {
  $$UserWordStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserWordsTableOrderingComposer get wordId {
    final $$UserWordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableOrderingComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserWordStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWordStatesTable> {
  $$UserWordStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UserWordsTableAnnotationComposer get wordId {
    final $$UserWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserWordStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserWordStatesTable,
          UserWordState,
          $$UserWordStatesTableFilterComposer,
          $$UserWordStatesTableOrderingComposer,
          $$UserWordStatesTableAnnotationComposer,
          $$UserWordStatesTableCreateCompanionBuilder,
          $$UserWordStatesTableUpdateCompanionBuilder,
          (UserWordState, $$UserWordStatesTableReferences),
          UserWordState,
          PrefetchHooks Function({bool wordId})
        > {
  $$UserWordStatesTableTableManager(
    _$AppDatabase db,
    $UserWordStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> wordId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserWordStatesCompanion(
                wordId: wordId,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordId,
                required String state,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserWordStatesCompanion.insert(
                wordId: wordId,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserWordStatesTable, UserWordState>(table),
                  $$UserWordStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$UserWordStatesTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$UserWordStatesTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserWordStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserWordStatesTable,
      UserWordState,
      $$UserWordStatesTableFilterComposer,
      $$UserWordStatesTableOrderingComposer,
      $$UserWordStatesTableAnnotationComposer,
      $$UserWordStatesTableCreateCompanionBuilder,
      $$UserWordStatesTableUpdateCompanionBuilder,
      (UserWordState, $$UserWordStatesTableReferences),
      UserWordState,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$CropWordsTableCreateCompanionBuilder = CropWordsCompanion Function({
  required String cropId,
  required String wordId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CropWordsTableUpdateCompanionBuilder = CropWordsCompanion Function({
  Value<String> cropId,
  Value<String> wordId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CropWordsTableReferences
    extends BaseReferences<_$AppDatabase, $CropWordsTable, CropWord> {
  $$CropWordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CapturedCropsTable _cropIdTable(_$AppDatabase db) =>
      db.capturedCrops.createAlias('crop_words__crop_id__crops__id');

  $$CapturedCropsTableProcessedTableManager get cropId {
    final $_column = $_itemColumn<String>('crop_id')!;

    final manager = $$CapturedCropsTableTableManager(
      $_db,
      $_db.capturedCrops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cropIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UserWordsTable _wordIdTable(_$AppDatabase db) =>
      db.userWords.createAlias('crop_words__word_id__words__id');

  $$UserWordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$UserWordsTableTableManager(
      $_db,
      $_db.userWords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CropWordsTableFilterComposer
    extends Composer<_$AppDatabase, $CropWordsTable> {
  $$CropWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CapturedCropsTableFilterComposer get cropId {
    final $$CapturedCropsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.capturedCrops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedCropsTableFilterComposer(
            $db: $db,
            $table: $db.capturedCrops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserWordsTableFilterComposer get wordId {
    final $$UserWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableFilterComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CropWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CropWordsTable> {
  $$CropWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CapturedCropsTableOrderingComposer get cropId {
    final $$CapturedCropsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.capturedCrops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedCropsTableOrderingComposer(
            $db: $db,
            $table: $db.capturedCrops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserWordsTableOrderingComposer get wordId {
    final $$UserWordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableOrderingComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CropWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CropWordsTable> {
  $$CropWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CapturedCropsTableAnnotationComposer get cropId {
    final $$CapturedCropsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.capturedCrops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturedCropsTableAnnotationComposer(
            $db: $db,
            $table: $db.capturedCrops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UserWordsTableAnnotationComposer get wordId {
    final $$UserWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CropWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CropWordsTable,
          CropWord,
          $$CropWordsTableFilterComposer,
          $$CropWordsTableOrderingComposer,
          $$CropWordsTableAnnotationComposer,
          $$CropWordsTableCreateCompanionBuilder,
          $$CropWordsTableUpdateCompanionBuilder,
          (CropWord, $$CropWordsTableReferences),
          CropWord,
          PrefetchHooks Function({bool cropId, bool wordId})
        > {
  $$CropWordsTableTableManager(_$AppDatabase db, $CropWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CropWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CropWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CropWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cropId = const Value.absent(),
                Value<String> wordId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CropWordsCompanion(
                cropId: cropId,
                wordId: wordId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cropId,
                required String wordId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CropWordsCompanion.insert(
                cropId: cropId,
                wordId: wordId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CropWordsTable, CropWord>(table),
                  $$CropWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cropId = false, wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cropId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cropId,
                        referencedTable: $$CropWordsTableReferences
                            ._cropIdTable(db),
                        referencedColumn: $$CropWordsTableReferences
                            ._cropIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$CropWordsTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$CropWordsTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CropWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CropWordsTable,
      CropWord,
      $$CropWordsTableFilterComposer,
      $$CropWordsTableOrderingComposer,
      $$CropWordsTableAnnotationComposer,
      $$CropWordsTableCreateCompanionBuilder,
      $$CropWordsTableUpdateCompanionBuilder,
      (CropWord, $$CropWordsTableReferences),
      CropWord,
      PrefetchHooks Function({bool cropId, bool wordId})
    >;
typedef $$UserCardsTableCreateCompanionBuilder = UserCardsCompanion Function({
  required String id,
  required String wordId,
  required String kind,
  required DateTime createdAt,
  Value<String?> suspendReason,
  Value<int> rowid,
});
typedef $$UserCardsTableUpdateCompanionBuilder = UserCardsCompanion Function({
  Value<String> id,
  Value<String> wordId,
  Value<String> kind,
  Value<DateTime> createdAt,
  Value<String?> suspendReason,
  Value<int> rowid,
});

final class $$UserCardsTableReferences
    extends BaseReferences<_$AppDatabase, $UserCardsTable, UserCard> {
  $$UserCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UserWordsTable _wordIdTable(_$AppDatabase db) =>
      db.userWords.createAlias('cards__word_id__words__id');

  $$UserWordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$UserWordsTableTableManager(
      $_db,
      $_db.userWords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$UserCardSrsTable, List<CardSrsRow>>
  _userCardSrsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userCardSrs,
    aliasName: 'cards__id__card_srs__card_id',
  );

  $$UserCardSrsTableProcessedTableManager get userCardSrsRefs {
    final manager = $$UserCardSrsTableTableManager(
      $_db,
      $_db.userCardSrs,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userCardSrsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserCardsTableFilterComposer
    extends Composer<_$AppDatabase, $UserCardsTable> {
  $$UserCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suspendReason => $composableBuilder(
    column: $table.suspendReason,
    builder: (column) => ColumnFilters(column),
  );

  $$UserWordsTableFilterComposer get wordId {
    final $$UserWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableFilterComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> userCardSrsRefs(
    Expression<bool> Function($$UserCardSrsTableFilterComposer f) f,
  ) {
    final $$UserCardSrsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userCardSrs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardSrsTableFilterComposer(
            $db: $db,
            $table: $db.userCardSrs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCardsTable> {
  $$UserCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suspendReason => $composableBuilder(
    column: $table.suspendReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserWordsTableOrderingComposer get wordId {
    final $$UserWordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableOrderingComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCardsTable> {
  $$UserCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get suspendReason => $composableBuilder(
    column: $table.suspendReason,
    builder: (column) => column,
  );

  $$UserWordsTableAnnotationComposer get wordId {
    final $$UserWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.userWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.userWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> userCardSrsRefs<T extends Object>(
    Expression<T> Function($$UserCardSrsTableAnnotationComposer a) f,
  ) {
    final $$UserCardSrsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userCardSrs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardSrsTableAnnotationComposer(
            $db: $db,
            $table: $db.userCardSrs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCardsTable,
          UserCard,
          $$UserCardsTableFilterComposer,
          $$UserCardsTableOrderingComposer,
          $$UserCardsTableAnnotationComposer,
          $$UserCardsTableCreateCompanionBuilder,
          $$UserCardsTableUpdateCompanionBuilder,
          (UserCard, $$UserCardsTableReferences),
          UserCard,
          PrefetchHooks Function({bool wordId, bool userCardSrsRefs})
        > {
  $$UserCardsTableTableManager(_$AppDatabase db, $UserCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wordId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> suspendReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCardsCompanion(
                id: id,
                wordId: wordId,
                kind: kind,
                createdAt: createdAt,
                suspendReason: suspendReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String wordId,
                required String kind,
                required DateTime createdAt,
                Value<String?> suspendReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCardsCompanion.insert(
                id: id,
                wordId: wordId,
                kind: kind,
                createdAt: createdAt,
                suspendReason: suspendReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserCardsTable, UserCard>(table),
                  $$UserCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false, userCardSrsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (userCardSrsRefs) db.userCardSrs],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$UserCardsTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$UserCardsTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userCardSrsRefs)
                    await $_getPrefetchedData<
                      UserCard,
                      $UserCardsTable,
                      CardSrsRow
                    >(
                      currentTable: table,
                      referencedTable: $$UserCardsTableReferences
                          ._userCardSrsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).userCardSrsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cardId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCardsTable,
      UserCard,
      $$UserCardsTableFilterComposer,
      $$UserCardsTableOrderingComposer,
      $$UserCardsTableAnnotationComposer,
      $$UserCardsTableCreateCompanionBuilder,
      $$UserCardsTableUpdateCompanionBuilder,
      (UserCard, $$UserCardsTableReferences),
      UserCard,
      PrefetchHooks Function({bool wordId, bool userCardSrsRefs})
    >;
typedef $$UserCardSrsTableCreateCompanionBuilder =
    UserCardSrsCompanion Function({
      required String cardId,
      required double easeFactor,
      required double intervalDays,
      required int repetitions,
      required DateTime dueAt,
      required String phase,
      required String engineId,
      Value<int> rowid,
    });
typedef $$UserCardSrsTableUpdateCompanionBuilder =
    UserCardSrsCompanion Function({
      Value<String> cardId,
      Value<double> easeFactor,
      Value<double> intervalDays,
      Value<int> repetitions,
      Value<DateTime> dueAt,
      Value<String> phase,
      Value<String> engineId,
      Value<int> rowid,
    });

final class $$UserCardSrsTableReferences
    extends BaseReferences<_$AppDatabase, $UserCardSrsTable, CardSrsRow> {
  $$UserCardSrsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UserCardsTable _cardIdTable(_$AppDatabase db) =>
      db.userCards.createAlias('card_srs__card_id__cards__id');

  $$UserCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$UserCardsTableTableManager(
      $_db,
      $_db.userCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserCardSrsTableFilterComposer
    extends Composer<_$AppDatabase, $UserCardSrsTable> {
  $$UserCardSrsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnFilters(column),
  );

  $$UserCardsTableFilterComposer get cardId {
    final $$UserCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.userCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardsTableFilterComposer(
            $db: $db,
            $table: $db.userCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCardSrsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCardSrsTable> {
  $$UserCardSrsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engineId => $composableBuilder(
    column: $table.engineId,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserCardsTableOrderingComposer get cardId {
    final $$UserCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.userCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardsTableOrderingComposer(
            $db: $db,
            $table: $db.userCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCardSrsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCardSrsTable> {
  $$UserCardSrsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get engineId =>
      $composableBuilder(column: $table.engineId, builder: (column) => column);

  $$UserCardsTableAnnotationComposer get cardId {
    final $$UserCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.userCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.userCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserCardSrsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCardSrsTable,
          CardSrsRow,
          $$UserCardSrsTableFilterComposer,
          $$UserCardSrsTableOrderingComposer,
          $$UserCardSrsTableAnnotationComposer,
          $$UserCardSrsTableCreateCompanionBuilder,
          $$UserCardSrsTableUpdateCompanionBuilder,
          (CardSrsRow, $$UserCardSrsTableReferences),
          CardSrsRow,
          PrefetchHooks Function({bool cardId})
        > {
  $$UserCardSrsTableTableManager(_$AppDatabase db, $UserCardSrsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCardSrsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCardSrsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCardSrsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cardId = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<String> engineId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCardSrsCompanion(
                cardId: cardId,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueAt: dueAt,
                phase: phase,
                engineId: engineId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cardId,
                required double easeFactor,
                required double intervalDays,
                required int repetitions,
                required DateTime dueAt,
                required String phase,
                required String engineId,
                Value<int> rowid = const Value.absent(),
              }) => UserCardSrsCompanion.insert(
                cardId: cardId,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                dueAt: dueAt,
                phase: phase,
                engineId: engineId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserCardSrsTable, CardSrsRow>(table),
                  $$UserCardSrsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cardId,
                        referencedTable: $$UserCardSrsTableReferences
                            ._cardIdTable(db),
                        referencedColumn: $$UserCardSrsTableReferences
                            ._cardIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserCardSrsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCardSrsTable,
      CardSrsRow,
      $$UserCardSrsTableFilterComposer,
      $$UserCardSrsTableOrderingComposer,
      $$UserCardSrsTableAnnotationComposer,
      $$UserCardSrsTableCreateCompanionBuilder,
      $$UserCardSrsTableUpdateCompanionBuilder,
      (CardSrsRow, $$UserCardSrsTableReferences),
      CardSrsRow,
      PrefetchHooks Function({bool cardId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$CapturedPagesTableTableManager get capturedPages =>
      $$CapturedPagesTableTableManager(_db, _db.capturedPages);
  $$CapturedCropsTableTableManager get capturedCrops =>
      $$CapturedCropsTableTableManager(_db, _db.capturedCrops);
  $$UserWordsTableTableManager get userWords =>
      $$UserWordsTableTableManager(_db, _db.userWords);
  $$UserWordStatesTableTableManager get userWordStates =>
      $$UserWordStatesTableTableManager(_db, _db.userWordStates);
  $$CropWordsTableTableManager get cropWords =>
      $$CropWordsTableTableManager(_db, _db.cropWords);
  $$UserCardsTableTableManager get userCards =>
      $$UserCardsTableTableManager(_db, _db.userCards);
  $$UserCardSrsTableTableManager get userCardSrs =>
      $$UserCardSrsTableTableManager(_db, _db.userCardSrs);
}

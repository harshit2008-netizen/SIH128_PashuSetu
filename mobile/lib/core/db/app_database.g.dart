// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OutboxReportsTable extends OutboxReports
    with TableInfo<$OutboxReportsTable, OutboxReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceTriageMeta = const VerificationMeta(
    'deviceTriage',
  );
  @override
  late final GeneratedColumn<String> deviceTriage = GeneratedColumn<String>(
    'device_triage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    clientUuid,
    payload,
    photoPath,
    status,
    attempts,
    lastError,
    deviceTriage,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('device_triage')) {
      context.handle(
        _deviceTriageMeta,
        deviceTriage.isAcceptableOrUnknown(
          data['device_triage']!,
          _deviceTriageMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  OutboxReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxReport(
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      deviceTriage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_triage'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxReportsTable createAlias(String alias) {
    return $OutboxReportsTable(attachedDatabase, alias);
  }
}

class OutboxReport extends DataClass implements Insertable<OutboxReport> {
  final String clientUuid;
  final String payload;
  final String? photoPath;
  final String status;
  final int attempts;
  final String? lastError;
  final String? deviceTriage;
  final DateTime createdAt;
  const OutboxReport({
    required this.clientUuid,
    required this.payload,
    this.photoPath,
    required this.status,
    required this.attempts,
    this.lastError,
    this.deviceTriage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || deviceTriage != null) {
      map['device_triage'] = Variable<String>(deviceTriage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxReportsCompanion toCompanion(bool nullToAbsent) {
    return OutboxReportsCompanion(
      clientUuid: Value(clientUuid),
      payload: Value(payload),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      deviceTriage: deviceTriage == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceTriage),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxReport(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      payload: serializer.fromJson<String>(json['payload']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      deviceTriage: serializer.fromJson<String?>(json['deviceTriage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'payload': serializer.toJson<String>(payload),
      'photoPath': serializer.toJson<String?>(photoPath),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'deviceTriage': serializer.toJson<String?>(deviceTriage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxReport copyWith({
    String? clientUuid,
    String? payload,
    Value<String?> photoPath = const Value.absent(),
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<String?> deviceTriage = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxReport(
    clientUuid: clientUuid ?? this.clientUuid,
    payload: payload ?? this.payload,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    deviceTriage: deviceTriage.present ? deviceTriage.value : this.deviceTriage,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxReport copyWithCompanion(OutboxReportsCompanion data) {
    return OutboxReport(
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      payload: data.payload.present ? data.payload.value : this.payload,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      deviceTriage: data.deviceTriage.present
          ? data.deviceTriage.value
          : this.deviceTriage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxReport(')
          ..write('clientUuid: $clientUuid, ')
          ..write('payload: $payload, ')
          ..write('photoPath: $photoPath, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('deviceTriage: $deviceTriage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientUuid,
    payload,
    photoPath,
    status,
    attempts,
    lastError,
    deviceTriage,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxReport &&
          other.clientUuid == this.clientUuid &&
          other.payload == this.payload &&
          other.photoPath == this.photoPath &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.deviceTriage == this.deviceTriage &&
          other.createdAt == this.createdAt);
}

class OutboxReportsCompanion extends UpdateCompanion<OutboxReport> {
  final Value<String> clientUuid;
  final Value<String> payload;
  final Value<String?> photoPath;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<String?> deviceTriage;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OutboxReportsCompanion({
    this.clientUuid = const Value.absent(),
    this.payload = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.deviceTriage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxReportsCompanion.insert({
    required String clientUuid,
    required String payload,
    this.photoPath = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.deviceTriage = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxReport> custom({
    Expression<String>? clientUuid,
    Expression<String>? payload,
    Expression<String>? photoPath,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? deviceTriage,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (payload != null) 'payload': payload,
      if (photoPath != null) 'photo_path': photoPath,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (deviceTriage != null) 'device_triage': deviceTriage,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxReportsCompanion copyWith({
    Value<String>? clientUuid,
    Value<String>? payload,
    Value<String?>? photoPath,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<String?>? deviceTriage,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OutboxReportsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      payload: payload ?? this.payload,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      deviceTriage: deviceTriage ?? this.deviceTriage,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (deviceTriage.present) {
      map['device_triage'] = Variable<String>(deviceTriage.value);
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
    return (StringBuffer('OutboxReportsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('payload: $payload, ')
          ..write('photoPath: $photoPath, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('deviceTriage: $deviceTriage, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCasesTable extends CachedCases
    with TableInfo<$CachedCasesTable, CachedCase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
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
  List<GeneratedColumn> get $columns => [id, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedCasesTable createAlias(String alias) {
    return $CachedCasesTable(attachedDatabase, alias);
  }
}

class CachedCase extends DataClass implements Insertable<CachedCase> {
  final String id;
  final String json;
  final DateTime updatedAt;
  const CachedCase({
    required this.id,
    required this.json,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedCasesCompanion toCompanion(bool nullToAbsent) {
    return CachedCasesCompanion(
      id: Value(id),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedCase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCase(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedCase copyWith({String? id, String? json, DateTime? updatedAt}) =>
      CachedCase(
        id: id ?? this.id,
        json: json ?? this.json,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedCase copyWithCompanion(CachedCasesCompanion data) {
    return CachedCase(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCase(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCase &&
          other.id == this.id &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class CachedCasesCompanion extends UpdateCompanion<CachedCase> {
  final Value<String> id;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedCasesCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCasesCompanion.insert({
    required String id,
    required String json,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       updatedAt = Value(updatedAt);
  static Insertable<CachedCase> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCasesCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedCasesCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
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
    return (StringBuffer('CachedCasesCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAdvisoriesTable extends CachedAdvisories
    with TableInfo<$CachedAdvisoriesTable, CachedAdvisory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAdvisoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, sentAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_advisories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAdvisory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAdvisory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAdvisory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
    );
  }

  @override
  $CachedAdvisoriesTable createAlias(String alias) {
    return $CachedAdvisoriesTable(attachedDatabase, alias);
  }
}

class CachedAdvisory extends DataClass implements Insertable<CachedAdvisory> {
  final String id;
  final String json;
  final DateTime sentAt;
  const CachedAdvisory({
    required this.id,
    required this.json,
    required this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['sent_at'] = Variable<DateTime>(sentAt);
    return map;
  }

  CachedAdvisoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedAdvisoriesCompanion(
      id: Value(id),
      json: Value(json),
      sentAt: Value(sentAt),
    );
  }

  factory CachedAdvisory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAdvisory(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'sentAt': serializer.toJson<DateTime>(sentAt),
    };
  }

  CachedAdvisory copyWith({String? id, String? json, DateTime? sentAt}) =>
      CachedAdvisory(
        id: id ?? this.id,
        json: json ?? this.json,
        sentAt: sentAt ?? this.sentAt,
      );
  CachedAdvisory copyWithCompanion(CachedAdvisoriesCompanion data) {
    return CachedAdvisory(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAdvisory(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAdvisory &&
          other.id == this.id &&
          other.json == this.json &&
          other.sentAt == this.sentAt);
}

class CachedAdvisoriesCompanion extends UpdateCompanion<CachedAdvisory> {
  final Value<String> id;
  final Value<String> json;
  final Value<DateTime> sentAt;
  final Value<int> rowid;
  const CachedAdvisoriesCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAdvisoriesCompanion.insert({
    required String id,
    required String json,
    required DateTime sentAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       sentAt = Value(sentAt);
  static Insertable<CachedAdvisory> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAdvisoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<DateTime>? sentAt,
    Value<int>? rowid,
  }) {
    return CachedAdvisoriesCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAdvisoriesCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAnimalsTable extends CachedAnimals
    with TableInfo<$CachedAnimalsTable, CachedAnimal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAnimalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_animals';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAnimal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAnimal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAnimal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CachedAnimalsTable createAlias(String alias) {
    return $CachedAnimalsTable(attachedDatabase, alias);
  }
}

class CachedAnimal extends DataClass implements Insertable<CachedAnimal> {
  final String id;
  final String json;
  const CachedAnimal({required this.id, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    return map;
  }

  CachedAnimalsCompanion toCompanion(bool nullToAbsent) {
    return CachedAnimalsCompanion(id: Value(id), json: Value(json));
  }

  factory CachedAnimal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAnimal(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
    };
  }

  CachedAnimal copyWith({String? id, String? json}) =>
      CachedAnimal(id: id ?? this.id, json: json ?? this.json);
  CachedAnimal copyWithCompanion(CachedAnimalsCompanion data) {
    return CachedAnimal(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAnimal(')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAnimal && other.id == this.id && other.json == this.json);
}

class CachedAnimalsCompanion extends UpdateCompanion<CachedAnimal> {
  final Value<String> id;
  final Value<String> json;
  final Value<int> rowid;
  const CachedAnimalsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAnimalsCompanion.insert({
    required String id,
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json);
  static Insertable<CachedAnimal> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAnimalsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return CachedAnimalsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAnimalsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedVaccinationsDueTable extends CachedVaccinationsDue
    with TableInfo<$CachedVaccinationsDueTable, CachedVaccinationsDueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedVaccinationsDueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_vaccinations_due';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedVaccinationsDueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedVaccinationsDueData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVaccinationsDueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CachedVaccinationsDueTable createAlias(String alias) {
    return $CachedVaccinationsDueTable(attachedDatabase, alias);
  }
}

class CachedVaccinationsDueData extends DataClass
    implements Insertable<CachedVaccinationsDueData> {
  final String id;
  final String json;
  const CachedVaccinationsDueData({required this.id, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    return map;
  }

  CachedVaccinationsDueCompanion toCompanion(bool nullToAbsent) {
    return CachedVaccinationsDueCompanion(id: Value(id), json: Value(json));
  }

  factory CachedVaccinationsDueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVaccinationsDueData(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
    };
  }

  CachedVaccinationsDueData copyWith({String? id, String? json}) =>
      CachedVaccinationsDueData(id: id ?? this.id, json: json ?? this.json);
  CachedVaccinationsDueData copyWithCompanion(
    CachedVaccinationsDueCompanion data,
  ) {
    return CachedVaccinationsDueData(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVaccinationsDueData(')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVaccinationsDueData &&
          other.id == this.id &&
          other.json == this.json);
}

class CachedVaccinationsDueCompanion
    extends UpdateCompanion<CachedVaccinationsDueData> {
  final Value<String> id;
  final Value<String> json;
  final Value<int> rowid;
  const CachedVaccinationsDueCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedVaccinationsDueCompanion.insert({
    required String id,
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json);
  static Insertable<CachedVaccinationsDueData> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedVaccinationsDueCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return CachedVaccinationsDueCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVaccinationsDueCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KvSettingsTable extends KvSettings
    with TableInfo<$KvSettingsTable, KvSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'kv_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvSetting> instance, {
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
  KvSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvSetting(
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
  $KvSettingsTable createAlias(String alias) {
    return $KvSettingsTable(attachedDatabase, alias);
  }
}

class KvSetting extends DataClass implements Insertable<KvSetting> {
  final String key;
  final String value;
  const KvSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvSettingsCompanion toCompanion(bool nullToAbsent) {
    return KvSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory KvSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvSetting(
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

  KvSetting copyWith({String? key, String? value}) =>
      KvSetting(key: key ?? this.key, value: value ?? this.value);
  KvSetting copyWithCompanion(KvSettingsCompanion data) {
    return KvSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvSetting(')
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
      (other is KvSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class KvSettingsCompanion extends UpdateCompanion<KvSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvSetting> custom({
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

  KvSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvSettingsCompanion(
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
    return (StringBuffer('KvSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxReportsTable outboxReports = $OutboxReportsTable(this);
  late final $CachedCasesTable cachedCases = $CachedCasesTable(this);
  late final $CachedAdvisoriesTable cachedAdvisories = $CachedAdvisoriesTable(
    this,
  );
  late final $CachedAnimalsTable cachedAnimals = $CachedAnimalsTable(this);
  late final $CachedVaccinationsDueTable cachedVaccinationsDue =
      $CachedVaccinationsDueTable(this);
  late final $KvSettingsTable kvSettings = $KvSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxReports,
    cachedCases,
    cachedAdvisories,
    cachedAnimals,
    cachedVaccinationsDue,
    kvSettings,
  ];
}

typedef $$OutboxReportsTableCreateCompanionBuilder =
    OutboxReportsCompanion Function({
      required String clientUuid,
      required String payload,
      Value<String?> photoPath,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<String?> deviceTriage,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$OutboxReportsTableUpdateCompanionBuilder =
    OutboxReportsCompanion Function({
      Value<String> clientUuid,
      Value<String> payload,
      Value<String?> photoPath,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<String?> deviceTriage,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$OutboxReportsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxReportsTable> {
  $$OutboxReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceTriage => $composableBuilder(
    column: $table.deviceTriage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxReportsTable> {
  $$OutboxReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceTriage => $composableBuilder(
    column: $table.deviceTriage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxReportsTable> {
  $$OutboxReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get deviceTriage => $composableBuilder(
    column: $table.deviceTriage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxReportsTable,
          OutboxReport,
          $$OutboxReportsTableFilterComposer,
          $$OutboxReportsTableOrderingComposer,
          $$OutboxReportsTableAnnotationComposer,
          $$OutboxReportsTableCreateCompanionBuilder,
          $$OutboxReportsTableUpdateCompanionBuilder,
          (
            OutboxReport,
            BaseReferences<_$AppDatabase, $OutboxReportsTable, OutboxReport>,
          ),
          OutboxReport,
          PrefetchHooks Function()
        > {
  $$OutboxReportsTableTableManager(_$AppDatabase db, $OutboxReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientUuid = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> deviceTriage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxReportsCompanion(
                clientUuid: clientUuid,
                payload: payload,
                photoPath: photoPath,
                status: status,
                attempts: attempts,
                lastError: lastError,
                deviceTriage: deviceTriage,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientUuid,
                required String payload,
                Value<String?> photoPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> deviceTriage = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OutboxReportsCompanion.insert(
                clientUuid: clientUuid,
                payload: payload,
                photoPath: photoPath,
                status: status,
                attempts: attempts,
                lastError: lastError,
                deviceTriage: deviceTriage,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxReportsTable, OutboxReport>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxReportsTable,
                    OutboxReport
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxReportsTable,
      OutboxReport,
      $$OutboxReportsTableFilterComposer,
      $$OutboxReportsTableOrderingComposer,
      $$OutboxReportsTableAnnotationComposer,
      $$OutboxReportsTableCreateCompanionBuilder,
      $$OutboxReportsTableUpdateCompanionBuilder,
      (
        OutboxReport,
        BaseReferences<_$AppDatabase, $OutboxReportsTable, OutboxReport>,
      ),
      OutboxReport,
      PrefetchHooks Function()
    >;
typedef $$CachedCasesTableCreateCompanionBuilder =
    CachedCasesCompanion Function({
      required String id,
      required String json,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedCasesTableUpdateCompanionBuilder =
    CachedCasesCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedCasesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCasesTable> {
  $$CachedCasesTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCasesTable> {
  $$CachedCasesTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCasesTable> {
  $$CachedCasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedCasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCasesTable,
          CachedCase,
          $$CachedCasesTableFilterComposer,
          $$CachedCasesTableOrderingComposer,
          $$CachedCasesTableAnnotationComposer,
          $$CachedCasesTableCreateCompanionBuilder,
          $$CachedCasesTableUpdateCompanionBuilder,
          (
            CachedCase,
            BaseReferences<_$AppDatabase, $CachedCasesTable, CachedCase>,
          ),
          CachedCase,
          PrefetchHooks Function()
        > {
  $$CachedCasesTableTableManager(_$AppDatabase db, $CachedCasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCasesCompanion(
                id: id,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCasesCompanion.insert(
                id: id,
                json: json,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedCasesTable, CachedCase>(table),
                  BaseReferences<_$AppDatabase, $CachedCasesTable, CachedCase>(
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

typedef $$CachedCasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCasesTable,
      CachedCase,
      $$CachedCasesTableFilterComposer,
      $$CachedCasesTableOrderingComposer,
      $$CachedCasesTableAnnotationComposer,
      $$CachedCasesTableCreateCompanionBuilder,
      $$CachedCasesTableUpdateCompanionBuilder,
      (
        CachedCase,
        BaseReferences<_$AppDatabase, $CachedCasesTable, CachedCase>,
      ),
      CachedCase,
      PrefetchHooks Function()
    >;
typedef $$CachedAdvisoriesTableCreateCompanionBuilder =
    CachedAdvisoriesCompanion Function({
      required String id,
      required String json,
      required DateTime sentAt,
      Value<int> rowid,
    });
typedef $$CachedAdvisoriesTableUpdateCompanionBuilder =
    CachedAdvisoriesCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<DateTime> sentAt,
      Value<int> rowid,
    });

class $$CachedAdvisoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAdvisoriesTable> {
  $$CachedAdvisoriesTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAdvisoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAdvisoriesTable> {
  $$CachedAdvisoriesTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAdvisoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAdvisoriesTable> {
  $$CachedAdvisoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$CachedAdvisoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAdvisoriesTable,
          CachedAdvisory,
          $$CachedAdvisoriesTableFilterComposer,
          $$CachedAdvisoriesTableOrderingComposer,
          $$CachedAdvisoriesTableAnnotationComposer,
          $$CachedAdvisoriesTableCreateCompanionBuilder,
          $$CachedAdvisoriesTableUpdateCompanionBuilder,
          (
            CachedAdvisory,
            BaseReferences<
              _$AppDatabase,
              $CachedAdvisoriesTable,
              CachedAdvisory
            >,
          ),
          CachedAdvisory,
          PrefetchHooks Function()
        > {
  $$CachedAdvisoriesTableTableManager(
    _$AppDatabase db,
    $CachedAdvisoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAdvisoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAdvisoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAdvisoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAdvisoriesCompanion(
                id: id,
                json: json,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required DateTime sentAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAdvisoriesCompanion.insert(
                id: id,
                json: json,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedAdvisoriesTable, CachedAdvisory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedAdvisoriesTable,
                    CachedAdvisory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAdvisoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAdvisoriesTable,
      CachedAdvisory,
      $$CachedAdvisoriesTableFilterComposer,
      $$CachedAdvisoriesTableOrderingComposer,
      $$CachedAdvisoriesTableAnnotationComposer,
      $$CachedAdvisoriesTableCreateCompanionBuilder,
      $$CachedAdvisoriesTableUpdateCompanionBuilder,
      (
        CachedAdvisory,
        BaseReferences<_$AppDatabase, $CachedAdvisoriesTable, CachedAdvisory>,
      ),
      CachedAdvisory,
      PrefetchHooks Function()
    >;
typedef $$CachedAnimalsTableCreateCompanionBuilder =
    CachedAnimalsCompanion Function({
      required String id,
      required String json,
      Value<int> rowid,
    });
typedef $$CachedAnimalsTableUpdateCompanionBuilder =
    CachedAnimalsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<int> rowid,
    });

class $$CachedAnimalsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAnimalsTable> {
  $$CachedAnimalsTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAnimalsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAnimalsTable> {
  $$CachedAnimalsTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAnimalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAnimalsTable> {
  $$CachedAnimalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CachedAnimalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAnimalsTable,
          CachedAnimal,
          $$CachedAnimalsTableFilterComposer,
          $$CachedAnimalsTableOrderingComposer,
          $$CachedAnimalsTableAnnotationComposer,
          $$CachedAnimalsTableCreateCompanionBuilder,
          $$CachedAnimalsTableUpdateCompanionBuilder,
          (
            CachedAnimal,
            BaseReferences<_$AppDatabase, $CachedAnimalsTable, CachedAnimal>,
          ),
          CachedAnimal,
          PrefetchHooks Function()
        > {
  $$CachedAnimalsTableTableManager(_$AppDatabase db, $CachedAnimalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAnimalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAnimalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAnimalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CachedAnimalsCompanion(id: id, json: json, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) => CachedAnimalsCompanion.insert(id: id, json: json, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedAnimalsTable, CachedAnimal>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedAnimalsTable,
                    CachedAnimal
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAnimalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAnimalsTable,
      CachedAnimal,
      $$CachedAnimalsTableFilterComposer,
      $$CachedAnimalsTableOrderingComposer,
      $$CachedAnimalsTableAnnotationComposer,
      $$CachedAnimalsTableCreateCompanionBuilder,
      $$CachedAnimalsTableUpdateCompanionBuilder,
      (
        CachedAnimal,
        BaseReferences<_$AppDatabase, $CachedAnimalsTable, CachedAnimal>,
      ),
      CachedAnimal,
      PrefetchHooks Function()
    >;
typedef $$CachedVaccinationsDueTableCreateCompanionBuilder =
    CachedVaccinationsDueCompanion Function({
      required String id,
      required String json,
      Value<int> rowid,
    });
typedef $$CachedVaccinationsDueTableUpdateCompanionBuilder =
    CachedVaccinationsDueCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<int> rowid,
    });

class $$CachedVaccinationsDueTableFilterComposer
    extends Composer<_$AppDatabase, $CachedVaccinationsDueTable> {
  $$CachedVaccinationsDueTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedVaccinationsDueTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedVaccinationsDueTable> {
  $$CachedVaccinationsDueTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedVaccinationsDueTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedVaccinationsDueTable> {
  $$CachedVaccinationsDueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CachedVaccinationsDueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedVaccinationsDueTable,
          CachedVaccinationsDueData,
          $$CachedVaccinationsDueTableFilterComposer,
          $$CachedVaccinationsDueTableOrderingComposer,
          $$CachedVaccinationsDueTableAnnotationComposer,
          $$CachedVaccinationsDueTableCreateCompanionBuilder,
          $$CachedVaccinationsDueTableUpdateCompanionBuilder,
          (
            CachedVaccinationsDueData,
            BaseReferences<
              _$AppDatabase,
              $CachedVaccinationsDueTable,
              CachedVaccinationsDueData
            >,
          ),
          CachedVaccinationsDueData,
          PrefetchHooks Function()
        > {
  $$CachedVaccinationsDueTableTableManager(
    _$AppDatabase db,
    $CachedVaccinationsDueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedVaccinationsDueTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedVaccinationsDueTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedVaccinationsDueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVaccinationsDueCompanion(
                id: id,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => CachedVaccinationsDueCompanion.insert(
                id: id,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CachedVaccinationsDueTable,
                    CachedVaccinationsDueData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedVaccinationsDueTable,
                    CachedVaccinationsDueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedVaccinationsDueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedVaccinationsDueTable,
      CachedVaccinationsDueData,
      $$CachedVaccinationsDueTableFilterComposer,
      $$CachedVaccinationsDueTableOrderingComposer,
      $$CachedVaccinationsDueTableAnnotationComposer,
      $$CachedVaccinationsDueTableCreateCompanionBuilder,
      $$CachedVaccinationsDueTableUpdateCompanionBuilder,
      (
        CachedVaccinationsDueData,
        BaseReferences<
          _$AppDatabase,
          $CachedVaccinationsDueTable,
          CachedVaccinationsDueData
        >,
      ),
      CachedVaccinationsDueData,
      PrefetchHooks Function()
    >;
typedef $$KvSettingsTableCreateCompanionBuilder = KvSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvSettingsTableUpdateCompanionBuilder = KvSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $KvSettingsTable> {
  $$KvSettingsTableFilterComposer({
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

class $$KvSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $KvSettingsTable> {
  $$KvSettingsTableOrderingComposer({
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

class $$KvSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvSettingsTable> {
  $$KvSettingsTableAnnotationComposer({
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

class $$KvSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvSettingsTable,
          KvSetting,
          $$KvSettingsTableFilterComposer,
          $$KvSettingsTableOrderingComposer,
          $$KvSettingsTableAnnotationComposer,
          $$KvSettingsTableCreateCompanionBuilder,
          $$KvSettingsTableUpdateCompanionBuilder,
          (
            KvSetting,
            BaseReferences<_$AppDatabase, $KvSettingsTable, KvSetting>,
          ),
          KvSetting,
          PrefetchHooks Function()
        > {
  $$KvSettingsTableTableManager(_$AppDatabase db, $KvSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KvSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KvSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KvSettingsTable, KvSetting>(table),
                  BaseReferences<_$AppDatabase, $KvSettingsTable, KvSetting>(
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

typedef $$KvSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvSettingsTable,
      KvSetting,
      $$KvSettingsTableFilterComposer,
      $$KvSettingsTableOrderingComposer,
      $$KvSettingsTableAnnotationComposer,
      $$KvSettingsTableCreateCompanionBuilder,
      $$KvSettingsTableUpdateCompanionBuilder,
      (KvSetting, BaseReferences<_$AppDatabase, $KvSettingsTable, KvSetting>),
      KvSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxReportsTableTableManager get outboxReports =>
      $$OutboxReportsTableTableManager(_db, _db.outboxReports);
  $$CachedCasesTableTableManager get cachedCases =>
      $$CachedCasesTableTableManager(_db, _db.cachedCases);
  $$CachedAdvisoriesTableTableManager get cachedAdvisories =>
      $$CachedAdvisoriesTableTableManager(_db, _db.cachedAdvisories);
  $$CachedAnimalsTableTableManager get cachedAnimals =>
      $$CachedAnimalsTableTableManager(_db, _db.cachedAnimals);
  $$CachedVaccinationsDueTableTableManager get cachedVaccinationsDue =>
      $$CachedVaccinationsDueTableTableManager(_db, _db.cachedVaccinationsDue);
  $$KvSettingsTableTableManager get kvSettings =>
      $$KvSettingsTableTableManager(_db, _db.kvSettings);
}

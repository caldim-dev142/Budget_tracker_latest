// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTableTable extends AccountsTable
    with TableInfo<$AccountsTableTable, AccountsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentBalancePaiseMeta =
      const VerificationMeta('currentBalancePaise');
  @override
  late final GeneratedColumn<int> currentBalancePaise = GeneratedColumn<int>(
      'current_balance_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, name, type, currentBalancePaise, isActive, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AccountsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('current_balance_paise')) {
      context.handle(
          _currentBalancePaiseMeta,
          currentBalancePaise.isAcceptableOrUnknown(
              data['current_balance_paise']!, _currentBalancePaiseMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      currentBalancePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_balance_paise'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $AccountsTableTable createAlias(String alias) {
    return $AccountsTableTable(attachedDatabase, alias);
  }
}

class AccountsTableData extends DataClass
    implements Insertable<AccountsTableData> {
  final String id;
  final String householdId;
  final String name;
  final String type;
  final int currentBalancePaise;
  final bool isActive;
  final int sortOrder;
  const AccountsTableData(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.type,
      required this.currentBalancePaise,
      required this.isActive,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['current_balance_paise'] = Variable<int>(currentBalancePaise);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AccountsTableCompanion toCompanion(bool nullToAbsent) {
    return AccountsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      type: Value(type),
      currentBalancePaise: Value(currentBalancePaise),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
    );
  }

  factory AccountsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      currentBalancePaise:
          serializer.fromJson<int>(json['currentBalancePaise']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'currentBalancePaise': serializer.toJson<int>(currentBalancePaise),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AccountsTableData copyWith(
          {String? id,
          String? householdId,
          String? name,
          String? type,
          int? currentBalancePaise,
          bool? isActive,
          int? sortOrder}) =>
      AccountsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        type: type ?? this.type,
        currentBalancePaise: currentBalancePaise ?? this.currentBalancePaise,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  AccountsTableData copyWithCompanion(AccountsTableCompanion data) {
    return AccountsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currentBalancePaise: data.currentBalancePaise.present
          ? data.currentBalancePaise.value
          : this.currentBalancePaise,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currentBalancePaise: $currentBalancePaise, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, householdId, name, type, currentBalancePaise, isActive, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.type == this.type &&
          other.currentBalancePaise == this.currentBalancePaise &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder);
}

class AccountsTableCompanion extends UpdateCompanion<AccountsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> type;
  final Value<int> currentBalancePaise;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AccountsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currentBalancePaise = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsTableCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    required String type,
    this.currentBalancePaise = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        type = Value(type);
  static Insertable<AccountsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? currentBalancePaise,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currentBalancePaise != null)
        'current_balance_paise': currentBalancePaise,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<String>? type,
      Value<int>? currentBalancePaise,
      Value<bool>? isActive,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return AccountsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      type: type ?? this.type,
      currentBalancePaise: currentBalancePaise ?? this.currentBalancePaise,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currentBalancePaise.present) {
      map['current_balance_paise'] = Variable<int>(currentBalancePaise.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currentBalancePaise: $currentBalancePaise, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupCodeMeta =
      const VerificationMeta('groupCode');
  @override
  late final GeneratedColumn<String> groupCode = GeneratedColumn<String>(
      'group_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _needOrWantMeta =
      const VerificationMeta('needOrWant');
  @override
  late final GeneratedColumn<String> needOrWant = GeneratedColumn<String>(
      'need_or_want', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeductionMeta =
      const VerificationMeta('isDeduction');
  @override
  late final GeneratedColumn<bool> isDeduction = GeneratedColumn<bool>(
      'is_deduction', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_deduction" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        kind,
        groupCode,
        name,
        needOrWant,
        isDeduction,
        isSystem,
        sortOrder,
        archivedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('group_code')) {
      context.handle(_groupCodeMeta,
          groupCode.isAcceptableOrUnknown(data['group_code']!, _groupCodeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('need_or_want')) {
      context.handle(
          _needOrWantMeta,
          needOrWant.isAcceptableOrUnknown(
              data['need_or_want']!, _needOrWantMeta));
    }
    if (data.containsKey('is_deduction')) {
      context.handle(
          _isDeductionMeta,
          isDeduction.isAcceptableOrUnknown(
              data['is_deduction']!, _isDeductionMeta));
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      groupCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_code']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      needOrWant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}need_or_want']),
      isDeduction: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deduction'])!,
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  final String id;
  final String householdId;
  final String kind;
  final String? groupCode;
  final String name;
  final String? needOrWant;
  final bool isDeduction;
  final bool isSystem;
  final int sortOrder;
  final DateTime? archivedAt;
  const CategoriesTableData(
      {required this.id,
      required this.householdId,
      required this.kind,
      this.groupCode,
      required this.name,
      this.needOrWant,
      required this.isDeduction,
      required this.isSystem,
      required this.sortOrder,
      this.archivedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || groupCode != null) {
      map['group_code'] = Variable<String>(groupCode);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || needOrWant != null) {
      map['need_or_want'] = Variable<String>(needOrWant);
    }
    map['is_deduction'] = Variable<bool>(isDeduction);
    map['is_system'] = Variable<bool>(isSystem);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      kind: Value(kind),
      groupCode: groupCode == null && nullToAbsent
          ? const Value.absent()
          : Value(groupCode),
      name: Value(name),
      needOrWant: needOrWant == null && nullToAbsent
          ? const Value.absent()
          : Value(needOrWant),
      isDeduction: Value(isDeduction),
      isSystem: Value(isSystem),
      sortOrder: Value(sortOrder),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory CategoriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      kind: serializer.fromJson<String>(json['kind']),
      groupCode: serializer.fromJson<String?>(json['groupCode']),
      name: serializer.fromJson<String>(json['name']),
      needOrWant: serializer.fromJson<String?>(json['needOrWant']),
      isDeduction: serializer.fromJson<bool>(json['isDeduction']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'kind': serializer.toJson<String>(kind),
      'groupCode': serializer.toJson<String?>(groupCode),
      'name': serializer.toJson<String>(name),
      'needOrWant': serializer.toJson<String?>(needOrWant),
      'isDeduction': serializer.toJson<bool>(isDeduction),
      'isSystem': serializer.toJson<bool>(isSystem),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  CategoriesTableData copyWith(
          {String? id,
          String? householdId,
          String? kind,
          Value<String?> groupCode = const Value.absent(),
          String? name,
          Value<String?> needOrWant = const Value.absent(),
          bool? isDeduction,
          bool? isSystem,
          int? sortOrder,
          Value<DateTime?> archivedAt = const Value.absent()}) =>
      CategoriesTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        kind: kind ?? this.kind,
        groupCode: groupCode.present ? groupCode.value : this.groupCode,
        name: name ?? this.name,
        needOrWant: needOrWant.present ? needOrWant.value : this.needOrWant,
        isDeduction: isDeduction ?? this.isDeduction,
        isSystem: isSystem ?? this.isSystem,
        sortOrder: sortOrder ?? this.sortOrder,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
      );
  CategoriesTableData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      kind: data.kind.present ? data.kind.value : this.kind,
      groupCode: data.groupCode.present ? data.groupCode.value : this.groupCode,
      name: data.name.present ? data.name.value : this.name,
      needOrWant:
          data.needOrWant.present ? data.needOrWant.value : this.needOrWant,
      isDeduction:
          data.isDeduction.present ? data.isDeduction.value : this.isDeduction,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('kind: $kind, ')
          ..write('groupCode: $groupCode, ')
          ..write('name: $name, ')
          ..write('needOrWant: $needOrWant, ')
          ..write('isDeduction: $isDeduction, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, kind, groupCode, name,
      needOrWant, isDeduction, isSystem, sortOrder, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.kind == this.kind &&
          other.groupCode == this.groupCode &&
          other.name == this.name &&
          other.needOrWant == this.needOrWant &&
          other.isDeduction == this.isDeduction &&
          other.isSystem == this.isSystem &&
          other.sortOrder == this.sortOrder &&
          other.archivedAt == this.archivedAt);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> kind;
  final Value<String?> groupCode;
  final Value<String> name;
  final Value<String?> needOrWant;
  final Value<bool> isDeduction;
  final Value<bool> isSystem;
  final Value<int> sortOrder;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.kind = const Value.absent(),
    this.groupCode = const Value.absent(),
    this.name = const Value.absent(),
    this.needOrWant = const Value.absent(),
    this.isDeduction = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String householdId,
    required String kind,
    this.groupCode = const Value.absent(),
    required String name,
    this.needOrWant = const Value.absent(),
    this.isDeduction = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        kind = Value(kind),
        name = Value(name);
  static Insertable<CategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? kind,
    Expression<String>? groupCode,
    Expression<String>? name,
    Expression<String>? needOrWant,
    Expression<bool>? isDeduction,
    Expression<bool>? isSystem,
    Expression<int>? sortOrder,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (kind != null) 'kind': kind,
      if (groupCode != null) 'group_code': groupCode,
      if (name != null) 'name': name,
      if (needOrWant != null) 'need_or_want': needOrWant,
      if (isDeduction != null) 'is_deduction': isDeduction,
      if (isSystem != null) 'is_system': isSystem,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? kind,
      Value<String?>? groupCode,
      Value<String>? name,
      Value<String?>? needOrWant,
      Value<bool>? isDeduction,
      Value<bool>? isSystem,
      Value<int>? sortOrder,
      Value<DateTime?>? archivedAt,
      Value<int>? rowid}) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      kind: kind ?? this.kind,
      groupCode: groupCode ?? this.groupCode,
      name: name ?? this.name,
      needOrWant: needOrWant ?? this.needOrWant,
      isDeduction: isDeduction ?? this.isDeduction,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (groupCode.present) {
      map['group_code'] = Variable<String>(groupCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (needOrWant.present) {
      map['need_or_want'] = Variable<String>(needOrWant.value);
    }
    if (isDeduction.present) {
      map['is_deduction'] = Variable<bool>(isDeduction.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('kind: $kind, ')
          ..write('groupCode: $groupCode, ')
          ..write('name: $name, ')
          ..write('needOrWant: $needOrWant, ')
          ..write('isDeduction: $isDeduction, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTableTable extends BudgetsTable
    with TableInfo<$BudgetsTableTable, BudgetsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _yearMonthMeta =
      const VerificationMeta('yearMonth');
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
      'year_month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, categoryId, yearMonth, amountPaise];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('year_month')) {
      context.handle(_yearMonthMeta,
          yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta));
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      yearMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}year_month'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
    );
  }

  @override
  $BudgetsTableTable createAlias(String alias) {
    return $BudgetsTableTable(attachedDatabase, alias);
  }
}

class BudgetsTableData extends DataClass
    implements Insertable<BudgetsTableData> {
  final String id;
  final String householdId;
  final String categoryId;
  final String yearMonth;
  final int amountPaise;
  const BudgetsTableData(
      {required this.id,
      required this.householdId,
      required this.categoryId,
      required this.yearMonth,
      required this.amountPaise});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['category_id'] = Variable<String>(categoryId);
    map['year_month'] = Variable<String>(yearMonth);
    map['amount_paise'] = Variable<int>(amountPaise);
    return map;
  }

  BudgetsTableCompanion toCompanion(bool nullToAbsent) {
    return BudgetsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      categoryId: Value(categoryId),
      yearMonth: Value(yearMonth),
      amountPaise: Value(amountPaise),
    );
  }

  factory BudgetsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'categoryId': serializer.toJson<String>(categoryId),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'amountPaise': serializer.toJson<int>(amountPaise),
    };
  }

  BudgetsTableData copyWith(
          {String? id,
          String? householdId,
          String? categoryId,
          String? yearMonth,
          int? amountPaise}) =>
      BudgetsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        categoryId: categoryId ?? this.categoryId,
        yearMonth: yearMonth ?? this.yearMonth,
        amountPaise: amountPaise ?? this.amountPaise,
      );
  BudgetsTableData copyWithCompanion(BudgetsTableCompanion data) {
    return BudgetsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('categoryId: $categoryId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('amountPaise: $amountPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, categoryId, yearMonth, amountPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.categoryId == this.categoryId &&
          other.yearMonth == this.yearMonth &&
          other.amountPaise == this.amountPaise);
}

class BudgetsTableCompanion extends UpdateCompanion<BudgetsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> categoryId;
  final Value<String> yearMonth;
  final Value<int> amountPaise;
  final Value<int> rowid;
  const BudgetsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsTableCompanion.insert({
    required String id,
    required String householdId,
    required String categoryId,
    required String yearMonth,
    this.amountPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        categoryId = Value(categoryId),
        yearMonth = Value(yearMonth);
  static Insertable<BudgetsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? categoryId,
    Expression<String>? yearMonth,
    Expression<int>? amountPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (categoryId != null) 'category_id': categoryId,
      if (yearMonth != null) 'year_month': yearMonth,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? categoryId,
      Value<String>? yearMonth,
      Value<int>? amountPaise,
      Value<int>? rowid}) {
    return BudgetsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      categoryId: categoryId ?? this.categoryId,
      yearMonth: yearMonth ?? this.yearMonth,
      amountPaise: amountPaise ?? this.amountPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('categoryId: $categoryId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntriesTableTable extends EntriesTable
    with TableInfo<$EntriesTableTable, EntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entryDateMeta =
      const VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        categoryId,
        kind,
        accountId,
        cardId,
        entryDate,
        amountPaise,
        note,
        parentId,
        createdBy,
        version,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(Insertable<EntriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id']),
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}entry_date'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $EntriesTableTable createAlias(String alias) {
    return $EntriesTableTable(attachedDatabase, alias);
  }
}

class EntriesTableData extends DataClass
    implements Insertable<EntriesTableData> {
  final String id;
  final String householdId;
  final String categoryId;
  final String kind;
  final String? accountId;
  final String? cardId;
  final DateTime entryDate;
  final int amountPaise;
  final String? note;
  final String? parentId;
  final String createdBy;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const EntriesTableData(
      {required this.id,
      required this.householdId,
      required this.categoryId,
      required this.kind,
      this.accountId,
      this.cardId,
      required this.entryDate,
      required this.amountPaise,
      this.note,
      this.parentId,
      required this.createdBy,
      required this.version,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['category_id'] = Variable<String>(categoryId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<String>(cardId);
    }
    map['entry_date'] = Variable<DateTime>(entryDate);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  EntriesTableCompanion toCompanion(bool nullToAbsent) {
    return EntriesTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      categoryId: Value(categoryId),
      kind: Value(kind),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      cardId:
          cardId == null && nullToAbsent ? const Value.absent() : Value(cardId),
      entryDate: Value(entryDate),
      amountPaise: Value(amountPaise),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdBy: Value(createdBy),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory EntriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      kind: serializer.fromJson<String>(json['kind']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      cardId: serializer.fromJson<String?>(json['cardId']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      note: serializer.fromJson<String?>(json['note']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'categoryId': serializer.toJson<String>(categoryId),
      'kind': serializer.toJson<String>(kind),
      'accountId': serializer.toJson<String?>(accountId),
      'cardId': serializer.toJson<String?>(cardId),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'note': serializer.toJson<String?>(note),
      'parentId': serializer.toJson<String?>(parentId),
      'createdBy': serializer.toJson<String>(createdBy),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  EntriesTableData copyWith(
          {String? id,
          String? householdId,
          String? categoryId,
          String? kind,
          Value<String?> accountId = const Value.absent(),
          Value<String?> cardId = const Value.absent(),
          DateTime? entryDate,
          int? amountPaise,
          Value<String?> note = const Value.absent(),
          Value<String?> parentId = const Value.absent(),
          String? createdBy,
          int? version,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      EntriesTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        categoryId: categoryId ?? this.categoryId,
        kind: kind ?? this.kind,
        accountId: accountId.present ? accountId.value : this.accountId,
        cardId: cardId.present ? cardId.value : this.cardId,
        entryDate: entryDate ?? this.entryDate,
        amountPaise: amountPaise ?? this.amountPaise,
        note: note.present ? note.value : this.note,
        parentId: parentId.present ? parentId.value : this.parentId,
        createdBy: createdBy ?? this.createdBy,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  EntriesTableData copyWithCompanion(EntriesTableCompanion data) {
    return EntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      kind: data.kind.present ? data.kind.value : this.kind,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      note: data.note.present ? data.note.value : this.note,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntriesTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('categoryId: $categoryId, ')
          ..write('kind: $kind, ')
          ..write('accountId: $accountId, ')
          ..write('cardId: $cardId, ')
          ..write('entryDate: $entryDate, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('note: $note, ')
          ..write('parentId: $parentId, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      categoryId,
      kind,
      accountId,
      cardId,
      entryDate,
      amountPaise,
      note,
      parentId,
      createdBy,
      version,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntriesTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.categoryId == this.categoryId &&
          other.kind == this.kind &&
          other.accountId == this.accountId &&
          other.cardId == this.cardId &&
          other.entryDate == this.entryDate &&
          other.amountPaise == this.amountPaise &&
          other.note == this.note &&
          other.parentId == this.parentId &&
          other.createdBy == this.createdBy &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class EntriesTableCompanion extends UpdateCompanion<EntriesTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> categoryId;
  final Value<String> kind;
  final Value<String?> accountId;
  final Value<String?> cardId;
  final Value<DateTime> entryDate;
  final Value<int> amountPaise;
  final Value<String?> note;
  final Value<String?> parentId;
  final Value<String> createdBy;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const EntriesTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.kind = const Value.absent(),
    this.accountId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.note = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesTableCompanion.insert({
    required String id,
    required String householdId,
    required String categoryId,
    required String kind,
    this.accountId = const Value.absent(),
    this.cardId = const Value.absent(),
    required DateTime entryDate,
    required int amountPaise,
    this.note = const Value.absent(),
    this.parentId = const Value.absent(),
    required String createdBy,
    this.version = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        categoryId = Value(categoryId),
        kind = Value(kind),
        entryDate = Value(entryDate),
        amountPaise = Value(amountPaise),
        createdBy = Value(createdBy),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<EntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? categoryId,
    Expression<String>? kind,
    Expression<String>? accountId,
    Expression<String>? cardId,
    Expression<DateTime>? entryDate,
    Expression<int>? amountPaise,
    Expression<String>? note,
    Expression<String>? parentId,
    Expression<String>? createdBy,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (categoryId != null) 'category_id': categoryId,
      if (kind != null) 'kind': kind,
      if (accountId != null) 'account_id': accountId,
      if (cardId != null) 'card_id': cardId,
      if (entryDate != null) 'entry_date': entryDate,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (note != null) 'note': note,
      if (parentId != null) 'parent_id': parentId,
      if (createdBy != null) 'created_by': createdBy,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? categoryId,
      Value<String>? kind,
      Value<String?>? accountId,
      Value<String?>? cardId,
      Value<DateTime>? entryDate,
      Value<int>? amountPaise,
      Value<String?>? note,
      Value<String?>? parentId,
      Value<String>? createdBy,
      Value<int>? version,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return EntriesTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      categoryId: categoryId ?? this.categoryId,
      kind: kind ?? this.kind,
      accountId: accountId ?? this.accountId,
      cardId: cardId ?? this.cardId,
      entryDate: entryDate ?? this.entryDate,
      amountPaise: amountPaise ?? this.amountPaise,
      note: note ?? this.note,
      parentId: parentId ?? this.parentId,
      createdBy: createdBy ?? this.createdBy,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('categoryId: $categoryId, ')
          ..write('kind: $kind, ')
          ..write('accountId: $accountId, ')
          ..write('cardId: $cardId, ')
          ..write('entryDate: $entryDate, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('note: $note, ')
          ..write('parentId: $parentId, ')
          ..write('createdBy: $createdBy, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SinkingFundsTableTable extends SinkingFundsTable
    with TableInfo<$SinkingFundsTableTable, SinkingFundsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SinkingFundsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _openingReservePaiseMeta =
      const VerificationMeta('openingReservePaise');
  @override
  late final GeneratedColumn<int> openingReservePaise = GeneratedColumn<int>(
      'opening_reserve_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, name, openingReservePaise, archivedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sinking_funds';
  @override
  VerificationContext validateIntegrity(
      Insertable<SinkingFundsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('opening_reserve_paise')) {
      context.handle(
          _openingReservePaiseMeta,
          openingReservePaise.isAcceptableOrUnknown(
              data['opening_reserve_paise']!, _openingReservePaiseMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SinkingFundsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SinkingFundsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      openingReservePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}opening_reserve_paise'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
    );
  }

  @override
  $SinkingFundsTableTable createAlias(String alias) {
    return $SinkingFundsTableTable(attachedDatabase, alias);
  }
}

class SinkingFundsTableData extends DataClass
    implements Insertable<SinkingFundsTableData> {
  final String id;
  final String householdId;
  final String name;
  final int openingReservePaise;
  final DateTime? archivedAt;
  const SinkingFundsTableData(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.openingReservePaise,
      this.archivedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['opening_reserve_paise'] = Variable<int>(openingReservePaise);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  SinkingFundsTableCompanion toCompanion(bool nullToAbsent) {
    return SinkingFundsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      openingReservePaise: Value(openingReservePaise),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory SinkingFundsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SinkingFundsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      openingReservePaise:
          serializer.fromJson<int>(json['openingReservePaise']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'openingReservePaise': serializer.toJson<int>(openingReservePaise),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  SinkingFundsTableData copyWith(
          {String? id,
          String? householdId,
          String? name,
          int? openingReservePaise,
          Value<DateTime?> archivedAt = const Value.absent()}) =>
      SinkingFundsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        openingReservePaise: openingReservePaise ?? this.openingReservePaise,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
      );
  SinkingFundsTableData copyWithCompanion(SinkingFundsTableCompanion data) {
    return SinkingFundsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      openingReservePaise: data.openingReservePaise.present
          ? data.openingReservePaise.value
          : this.openingReservePaise,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SinkingFundsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('openingReservePaise: $openingReservePaise, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, name, openingReservePaise, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SinkingFundsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.openingReservePaise == this.openingReservePaise &&
          other.archivedAt == this.archivedAt);
}

class SinkingFundsTableCompanion
    extends UpdateCompanion<SinkingFundsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<int> openingReservePaise;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const SinkingFundsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.openingReservePaise = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SinkingFundsTableCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    this.openingReservePaise = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name);
  static Insertable<SinkingFundsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<int>? openingReservePaise,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (openingReservePaise != null)
        'opening_reserve_paise': openingReservePaise,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SinkingFundsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<int>? openingReservePaise,
      Value<DateTime?>? archivedAt,
      Value<int>? rowid}) {
    return SinkingFundsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      openingReservePaise: openingReservePaise ?? this.openingReservePaise,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (openingReservePaise.present) {
      map['opening_reserve_paise'] = Variable<int>(openingReservePaise.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SinkingFundsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('openingReservePaise: $openingReservePaise, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FundMovementsTableTable extends FundMovementsTable
    with TableInfo<$FundMovementsTableTable, FundMovementsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundMovementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<String> fundId = GeneratedColumn<String>(
      'fund_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sinking_funds (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _movementDateMeta =
      const VerificationMeta('movementDate');
  @override
  late final GeneratedColumn<DateTime> movementDate = GeneratedColumn<DateTime>(
      'movement_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, fundId, type, amountPaise, movementDate, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fund_movements';
  @override
  VerificationContext validateIntegrity(
      Insertable<FundMovementsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fund_id')) {
      context.handle(_fundIdMeta,
          fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta));
    } else if (isInserting) {
      context.missing(_fundIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('movement_date')) {
      context.handle(
          _movementDateMeta,
          movementDate.isAcceptableOrUnknown(
              data['movement_date']!, _movementDateMeta));
    } else if (isInserting) {
      context.missing(_movementDateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FundMovementsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FundMovementsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fundId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fund_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      movementDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}movement_date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $FundMovementsTableTable createAlias(String alias) {
    return $FundMovementsTableTable(attachedDatabase, alias);
  }
}

class FundMovementsTableData extends DataClass
    implements Insertable<FundMovementsTableData> {
  final String id;
  final String fundId;
  final String type;
  final int amountPaise;
  final DateTime movementDate;
  final String? note;
  const FundMovementsTableData(
      {required this.id,
      required this.fundId,
      required this.type,
      required this.amountPaise,
      required this.movementDate,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fund_id'] = Variable<String>(fundId);
    map['type'] = Variable<String>(type);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['movement_date'] = Variable<DateTime>(movementDate);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  FundMovementsTableCompanion toCompanion(bool nullToAbsent) {
    return FundMovementsTableCompanion(
      id: Value(id),
      fundId: Value(fundId),
      type: Value(type),
      amountPaise: Value(amountPaise),
      movementDate: Value(movementDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory FundMovementsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FundMovementsTableData(
      id: serializer.fromJson<String>(json['id']),
      fundId: serializer.fromJson<String>(json['fundId']),
      type: serializer.fromJson<String>(json['type']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      movementDate: serializer.fromJson<DateTime>(json['movementDate']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fundId': serializer.toJson<String>(fundId),
      'type': serializer.toJson<String>(type),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'movementDate': serializer.toJson<DateTime>(movementDate),
      'note': serializer.toJson<String?>(note),
    };
  }

  FundMovementsTableData copyWith(
          {String? id,
          String? fundId,
          String? type,
          int? amountPaise,
          DateTime? movementDate,
          Value<String?> note = const Value.absent()}) =>
      FundMovementsTableData(
        id: id ?? this.id,
        fundId: fundId ?? this.fundId,
        type: type ?? this.type,
        amountPaise: amountPaise ?? this.amountPaise,
        movementDate: movementDate ?? this.movementDate,
        note: note.present ? note.value : this.note,
      );
  FundMovementsTableData copyWithCompanion(FundMovementsTableCompanion data) {
    return FundMovementsTableData(
      id: data.id.present ? data.id.value : this.id,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      type: data.type.present ? data.type.value : this.type,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      movementDate: data.movementDate.present
          ? data.movementDate.value
          : this.movementDate,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FundMovementsTableData(')
          ..write('id: $id, ')
          ..write('fundId: $fundId, ')
          ..write('type: $type, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('movementDate: $movementDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fundId, type, amountPaise, movementDate, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FundMovementsTableData &&
          other.id == this.id &&
          other.fundId == this.fundId &&
          other.type == this.type &&
          other.amountPaise == this.amountPaise &&
          other.movementDate == this.movementDate &&
          other.note == this.note);
}

class FundMovementsTableCompanion
    extends UpdateCompanion<FundMovementsTableData> {
  final Value<String> id;
  final Value<String> fundId;
  final Value<String> type;
  final Value<int> amountPaise;
  final Value<DateTime> movementDate;
  final Value<String?> note;
  final Value<int> rowid;
  const FundMovementsTableCompanion({
    this.id = const Value.absent(),
    this.fundId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.movementDate = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FundMovementsTableCompanion.insert({
    required String id,
    required String fundId,
    required String type,
    required int amountPaise,
    required DateTime movementDate,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fundId = Value(fundId),
        type = Value(type),
        amountPaise = Value(amountPaise),
        movementDate = Value(movementDate);
  static Insertable<FundMovementsTableData> custom({
    Expression<String>? id,
    Expression<String>? fundId,
    Expression<String>? type,
    Expression<int>? amountPaise,
    Expression<DateTime>? movementDate,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fundId != null) 'fund_id': fundId,
      if (type != null) 'type': type,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (movementDate != null) 'movement_date': movementDate,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FundMovementsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? fundId,
      Value<String>? type,
      Value<int>? amountPaise,
      Value<DateTime>? movementDate,
      Value<String?>? note,
      Value<int>? rowid}) {
    return FundMovementsTableCompanion(
      id: id ?? this.id,
      fundId: fundId ?? this.fundId,
      type: type ?? this.type,
      amountPaise: amountPaise ?? this.amountPaise,
      movementDate: movementDate ?? this.movementDate,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<String>(fundId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (movementDate.present) {
      map['movement_date'] = Variable<DateTime>(movementDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundMovementsTableCompanion(')
          ..write('id: $id, ')
          ..write('fundId: $fundId, ')
          ..write('type: $type, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('movementDate: $movementDate, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingGoalsTableTable extends SavingGoalsTable
    with TableInfo<$SavingGoalsTableTable, SavingGoalsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingGoalsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
      'bucket', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetPaiseMeta =
      const VerificationMeta('targetPaise');
  @override
  late final GeneratedColumn<int> targetPaise = GeneratedColumn<int>(
      'target_paise', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _monthlyBudgetPaiseMeta =
      const VerificationMeta('monthlyBudgetPaise');
  @override
  late final GeneratedColumn<int> monthlyBudgetPaise = GeneratedColumn<int>(
      'monthly_budget_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        bucket,
        name,
        targetPaise,
        monthlyBudgetPaise,
        archivedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saving_goals';
  @override
  VerificationContext validateIntegrity(
      Insertable<SavingGoalsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('bucket')) {
      context.handle(_bucketMeta,
          bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta));
    } else if (isInserting) {
      context.missing(_bucketMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_paise')) {
      context.handle(
          _targetPaiseMeta,
          targetPaise.isAcceptableOrUnknown(
              data['target_paise']!, _targetPaiseMeta));
    }
    if (data.containsKey('monthly_budget_paise')) {
      context.handle(
          _monthlyBudgetPaiseMeta,
          monthlyBudgetPaise.isAcceptableOrUnknown(
              data['monthly_budget_paise']!, _monthlyBudgetPaiseMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingGoalsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingGoalsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      bucket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bucket'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      targetPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_paise']),
      monthlyBudgetPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}monthly_budget_paise'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
    );
  }

  @override
  $SavingGoalsTableTable createAlias(String alias) {
    return $SavingGoalsTableTable(attachedDatabase, alias);
  }
}

class SavingGoalsTableData extends DataClass
    implements Insertable<SavingGoalsTableData> {
  final String id;
  final String householdId;
  final String bucket;
  final String name;
  final int? targetPaise;
  final int monthlyBudgetPaise;
  final DateTime? archivedAt;
  const SavingGoalsTableData(
      {required this.id,
      required this.householdId,
      required this.bucket,
      required this.name,
      this.targetPaise,
      required this.monthlyBudgetPaise,
      this.archivedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['bucket'] = Variable<String>(bucket);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || targetPaise != null) {
      map['target_paise'] = Variable<int>(targetPaise);
    }
    map['monthly_budget_paise'] = Variable<int>(monthlyBudgetPaise);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  SavingGoalsTableCompanion toCompanion(bool nullToAbsent) {
    return SavingGoalsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      bucket: Value(bucket),
      name: Value(name),
      targetPaise: targetPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPaise),
      monthlyBudgetPaise: Value(monthlyBudgetPaise),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory SavingGoalsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingGoalsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      bucket: serializer.fromJson<String>(json['bucket']),
      name: serializer.fromJson<String>(json['name']),
      targetPaise: serializer.fromJson<int?>(json['targetPaise']),
      monthlyBudgetPaise: serializer.fromJson<int>(json['monthlyBudgetPaise']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'bucket': serializer.toJson<String>(bucket),
      'name': serializer.toJson<String>(name),
      'targetPaise': serializer.toJson<int?>(targetPaise),
      'monthlyBudgetPaise': serializer.toJson<int>(monthlyBudgetPaise),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  SavingGoalsTableData copyWith(
          {String? id,
          String? householdId,
          String? bucket,
          String? name,
          Value<int?> targetPaise = const Value.absent(),
          int? monthlyBudgetPaise,
          Value<DateTime?> archivedAt = const Value.absent()}) =>
      SavingGoalsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        bucket: bucket ?? this.bucket,
        name: name ?? this.name,
        targetPaise: targetPaise.present ? targetPaise.value : this.targetPaise,
        monthlyBudgetPaise: monthlyBudgetPaise ?? this.monthlyBudgetPaise,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
      );
  SavingGoalsTableData copyWithCompanion(SavingGoalsTableCompanion data) {
    return SavingGoalsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      name: data.name.present ? data.name.value : this.name,
      targetPaise:
          data.targetPaise.present ? data.targetPaise.value : this.targetPaise,
      monthlyBudgetPaise: data.monthlyBudgetPaise.present
          ? data.monthlyBudgetPaise.value
          : this.monthlyBudgetPaise,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingGoalsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('bucket: $bucket, ')
          ..write('name: $name, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('monthlyBudgetPaise: $monthlyBudgetPaise, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, bucket, name, targetPaise,
      monthlyBudgetPaise, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingGoalsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.bucket == this.bucket &&
          other.name == this.name &&
          other.targetPaise == this.targetPaise &&
          other.monthlyBudgetPaise == this.monthlyBudgetPaise &&
          other.archivedAt == this.archivedAt);
}

class SavingGoalsTableCompanion extends UpdateCompanion<SavingGoalsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> bucket;
  final Value<String> name;
  final Value<int?> targetPaise;
  final Value<int> monthlyBudgetPaise;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const SavingGoalsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.bucket = const Value.absent(),
    this.name = const Value.absent(),
    this.targetPaise = const Value.absent(),
    this.monthlyBudgetPaise = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingGoalsTableCompanion.insert({
    required String id,
    required String householdId,
    required String bucket,
    required String name,
    this.targetPaise = const Value.absent(),
    this.monthlyBudgetPaise = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        bucket = Value(bucket),
        name = Value(name);
  static Insertable<SavingGoalsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? bucket,
    Expression<String>? name,
    Expression<int>? targetPaise,
    Expression<int>? monthlyBudgetPaise,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (bucket != null) 'bucket': bucket,
      if (name != null) 'name': name,
      if (targetPaise != null) 'target_paise': targetPaise,
      if (monthlyBudgetPaise != null)
        'monthly_budget_paise': monthlyBudgetPaise,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingGoalsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? bucket,
      Value<String>? name,
      Value<int?>? targetPaise,
      Value<int>? monthlyBudgetPaise,
      Value<DateTime?>? archivedAt,
      Value<int>? rowid}) {
    return SavingGoalsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      bucket: bucket ?? this.bucket,
      name: name ?? this.name,
      targetPaise: targetPaise ?? this.targetPaise,
      monthlyBudgetPaise: monthlyBudgetPaise ?? this.monthlyBudgetPaise,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetPaise.present) {
      map['target_paise'] = Variable<int>(targetPaise.value);
    }
    if (monthlyBudgetPaise.present) {
      map['monthly_budget_paise'] = Variable<int>(monthlyBudgetPaise.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingGoalsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('bucket: $bucket, ')
          ..write('name: $name, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('monthlyBudgetPaise: $monthlyBudgetPaise, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalContributionsTableTable extends GoalContributionsTable
    with TableInfo<$GoalContributionsTableTable, GoalContributionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalContributionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES saving_goals (id)'));
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contributionDateMeta =
      const VerificationMeta('contributionDate');
  @override
  late final GeneratedColumn<DateTime> contributionDate =
      GeneratedColumn<DateTime>('contribution_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, goalId, amountPaise, contributionDate, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_contributions';
  @override
  VerificationContext validateIntegrity(
      Insertable<GoalContributionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('contribution_date')) {
      context.handle(
          _contributionDateMeta,
          contributionDate.isAcceptableOrUnknown(
              data['contribution_date']!, _contributionDateMeta));
    } else if (isInserting) {
      context.missing(_contributionDateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalContributionsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalContributionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_id'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      contributionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}contribution_date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $GoalContributionsTableTable createAlias(String alias) {
    return $GoalContributionsTableTable(attachedDatabase, alias);
  }
}

class GoalContributionsTableData extends DataClass
    implements Insertable<GoalContributionsTableData> {
  final String id;
  final String goalId;
  final int amountPaise;
  final DateTime contributionDate;
  final String? note;
  const GoalContributionsTableData(
      {required this.id,
      required this.goalId,
      required this.amountPaise,
      required this.contributionDate,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['contribution_date'] = Variable<DateTime>(contributionDate);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  GoalContributionsTableCompanion toCompanion(bool nullToAbsent) {
    return GoalContributionsTableCompanion(
      id: Value(id),
      goalId: Value(goalId),
      amountPaise: Value(amountPaise),
      contributionDate: Value(contributionDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory GoalContributionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalContributionsTableData(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      contributionDate: serializer.fromJson<DateTime>(json['contributionDate']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'contributionDate': serializer.toJson<DateTime>(contributionDate),
      'note': serializer.toJson<String?>(note),
    };
  }

  GoalContributionsTableData copyWith(
          {String? id,
          String? goalId,
          int? amountPaise,
          DateTime? contributionDate,
          Value<String?> note = const Value.absent()}) =>
      GoalContributionsTableData(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        amountPaise: amountPaise ?? this.amountPaise,
        contributionDate: contributionDate ?? this.contributionDate,
        note: note.present ? note.value : this.note,
      );
  GoalContributionsTableData copyWithCompanion(
      GoalContributionsTableCompanion data) {
    return GoalContributionsTableData(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      contributionDate: data.contributionDate.present
          ? data.contributionDate.value
          : this.contributionDate,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalContributionsTableData(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('contributionDate: $contributionDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, goalId, amountPaise, contributionDate, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalContributionsTableData &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.amountPaise == this.amountPaise &&
          other.contributionDate == this.contributionDate &&
          other.note == this.note);
}

class GoalContributionsTableCompanion
    extends UpdateCompanion<GoalContributionsTableData> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<int> amountPaise;
  final Value<DateTime> contributionDate;
  final Value<String?> note;
  final Value<int> rowid;
  const GoalContributionsTableCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.contributionDate = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalContributionsTableCompanion.insert({
    required String id,
    required String goalId,
    required int amountPaise,
    required DateTime contributionDate,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        goalId = Value(goalId),
        amountPaise = Value(amountPaise),
        contributionDate = Value(contributionDate);
  static Insertable<GoalContributionsTableData> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<int>? amountPaise,
    Expression<DateTime>? contributionDate,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (contributionDate != null) 'contribution_date': contributionDate,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalContributionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? goalId,
      Value<int>? amountPaise,
      Value<DateTime>? contributionDate,
      Value<String?>? note,
      Value<int>? rowid}) {
    return GoalContributionsTableCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amountPaise: amountPaise ?? this.amountPaise,
      contributionDate: contributionDate ?? this.contributionDate,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (contributionDate.present) {
      map['contribution_date'] = Variable<DateTime>(contributionDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalContributionsTableCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('contributionDate: $contributionDate, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditCardsTableTable extends CreditCardsTable
    with TableInfo<$CreditCardsTableTable, CreditCardsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _previousOutstandingPaiseMeta =
      const VerificationMeta('previousOutstandingPaise');
  @override
  late final GeneratedColumn<int> previousOutstandingPaise =
      GeneratedColumn<int>('previous_outstanding_paise', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, name, previousOutstandingPaise, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_cards';
  @override
  VerificationContext validateIntegrity(
      Insertable<CreditCardsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('previous_outstanding_paise')) {
      context.handle(
          _previousOutstandingPaiseMeta,
          previousOutstandingPaise.isAcceptableOrUnknown(
              data['previous_outstanding_paise']!,
              _previousOutstandingPaiseMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCardsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCardsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      previousOutstandingPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}previous_outstanding_paise'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $CreditCardsTableTable createAlias(String alias) {
    return $CreditCardsTableTable(attachedDatabase, alias);
  }
}

class CreditCardsTableData extends DataClass
    implements Insertable<CreditCardsTableData> {
  final String id;
  final String householdId;
  final String name;
  final int previousOutstandingPaise;
  final bool isActive;
  const CreditCardsTableData(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.previousOutstandingPaise,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['previous_outstanding_paise'] = Variable<int>(previousOutstandingPaise);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CreditCardsTableCompanion toCompanion(bool nullToAbsent) {
    return CreditCardsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      previousOutstandingPaise: Value(previousOutstandingPaise),
      isActive: Value(isActive),
    );
  }

  factory CreditCardsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCardsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      previousOutstandingPaise:
          serializer.fromJson<int>(json['previousOutstandingPaise']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'previousOutstandingPaise':
          serializer.toJson<int>(previousOutstandingPaise),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CreditCardsTableData copyWith(
          {String? id,
          String? householdId,
          String? name,
          int? previousOutstandingPaise,
          bool? isActive}) =>
      CreditCardsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        previousOutstandingPaise:
            previousOutstandingPaise ?? this.previousOutstandingPaise,
        isActive: isActive ?? this.isActive,
      );
  CreditCardsTableData copyWithCompanion(CreditCardsTableCompanion data) {
    return CreditCardsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      previousOutstandingPaise: data.previousOutstandingPaise.present
          ? data.previousOutstandingPaise.value
          : this.previousOutstandingPaise,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('previousOutstandingPaise: $previousOutstandingPaise, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, name, previousOutstandingPaise, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCardsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.previousOutstandingPaise == this.previousOutstandingPaise &&
          other.isActive == this.isActive);
}

class CreditCardsTableCompanion extends UpdateCompanion<CreditCardsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<int> previousOutstandingPaise;
  final Value<bool> isActive;
  final Value<int> rowid;
  const CreditCardsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.previousOutstandingPaise = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditCardsTableCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    this.previousOutstandingPaise = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name);
  static Insertable<CreditCardsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<int>? previousOutstandingPaise,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (previousOutstandingPaise != null)
        'previous_outstanding_paise': previousOutstandingPaise,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditCardsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<int>? previousOutstandingPaise,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return CreditCardsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      previousOutstandingPaise:
          previousOutstandingPaise ?? this.previousOutstandingPaise,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (previousOutstandingPaise.present) {
      map['previous_outstanding_paise'] =
          Variable<int>(previousOutstandingPaise.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('previousOutstandingPaise: $previousOutstandingPaise, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardTransactionsTableTable extends CardTransactionsTable
    with TableInfo<$CardTransactionsTableTable, CardTransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardTransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES credit_cards (id)'));
  static const VerificationMeta _txnDateMeta =
      const VerificationMeta('txnDate');
  @override
  late final GeneratedColumn<DateTime> txnDate = GeneratedColumn<DateTime>(
      'txn_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sNoMeta = const VerificationMeta('sNo');
  @override
  late final GeneratedColumn<int> sNo = GeneratedColumn<int>(
      's_no', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, cardId, txnDate, description, amountPaise, sNo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<CardTransactionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('txn_date')) {
      context.handle(_txnDateMeta,
          txnDate.isAcceptableOrUnknown(data['txn_date']!, _txnDateMeta));
    } else if (isInserting) {
      context.missing(_txnDateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('s_no')) {
      context.handle(
          _sNoMeta, sNo.isAcceptableOrUnknown(data['s_no']!, _sNoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardTransactionsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardTransactionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      txnDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}txn_date'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      sNo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}s_no']),
    );
  }

  @override
  $CardTransactionsTableTable createAlias(String alias) {
    return $CardTransactionsTableTable(attachedDatabase, alias);
  }
}

class CardTransactionsTableData extends DataClass
    implements Insertable<CardTransactionsTableData> {
  final String id;
  final String cardId;
  final DateTime txnDate;
  final String description;
  final int amountPaise;
  final int? sNo;
  const CardTransactionsTableData(
      {required this.id,
      required this.cardId,
      required this.txnDate,
      required this.description,
      required this.amountPaise,
      this.sNo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['txn_date'] = Variable<DateTime>(txnDate);
    map['description'] = Variable<String>(description);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || sNo != null) {
      map['s_no'] = Variable<int>(sNo);
    }
    return map;
  }

  CardTransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return CardTransactionsTableCompanion(
      id: Value(id),
      cardId: Value(cardId),
      txnDate: Value(txnDate),
      description: Value(description),
      amountPaise: Value(amountPaise),
      sNo: sNo == null && nullToAbsent ? const Value.absent() : Value(sNo),
    );
  }

  factory CardTransactionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardTransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      txnDate: serializer.fromJson<DateTime>(json['txnDate']),
      description: serializer.fromJson<String>(json['description']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      sNo: serializer.fromJson<int?>(json['sNo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'txnDate': serializer.toJson<DateTime>(txnDate),
      'description': serializer.toJson<String>(description),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'sNo': serializer.toJson<int?>(sNo),
    };
  }

  CardTransactionsTableData copyWith(
          {String? id,
          String? cardId,
          DateTime? txnDate,
          String? description,
          int? amountPaise,
          Value<int?> sNo = const Value.absent()}) =>
      CardTransactionsTableData(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        txnDate: txnDate ?? this.txnDate,
        description: description ?? this.description,
        amountPaise: amountPaise ?? this.amountPaise,
        sNo: sNo.present ? sNo.value : this.sNo,
      );
  CardTransactionsTableData copyWithCompanion(
      CardTransactionsTableCompanion data) {
    return CardTransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      txnDate: data.txnDate.present ? data.txnDate.value : this.txnDate,
      description:
          data.description.present ? data.description.value : this.description,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      sNo: data.sNo.present ? data.sNo.value : this.sNo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardTransactionsTableData(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('txnDate: $txnDate, ')
          ..write('description: $description, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('sNo: $sNo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cardId, txnDate, description, amountPaise, sNo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardTransactionsTableData &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.txnDate == this.txnDate &&
          other.description == this.description &&
          other.amountPaise == this.amountPaise &&
          other.sNo == this.sNo);
}

class CardTransactionsTableCompanion
    extends UpdateCompanion<CardTransactionsTableData> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<DateTime> txnDate;
  final Value<String> description;
  final Value<int> amountPaise;
  final Value<int?> sNo;
  final Value<int> rowid;
  const CardTransactionsTableCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.txnDate = const Value.absent(),
    this.description = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.sNo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardTransactionsTableCompanion.insert({
    required String id,
    required String cardId,
    required DateTime txnDate,
    required String description,
    required int amountPaise,
    this.sNo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        cardId = Value(cardId),
        txnDate = Value(txnDate),
        description = Value(description),
        amountPaise = Value(amountPaise);
  static Insertable<CardTransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<DateTime>? txnDate,
    Expression<String>? description,
    Expression<int>? amountPaise,
    Expression<int>? sNo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (txnDate != null) 'txn_date': txnDate,
      if (description != null) 'description': description,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (sNo != null) 's_no': sNo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardTransactionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? cardId,
      Value<DateTime>? txnDate,
      Value<String>? description,
      Value<int>? amountPaise,
      Value<int?>? sNo,
      Value<int>? rowid}) {
    return CardTransactionsTableCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      txnDate: txnDate ?? this.txnDate,
      description: description ?? this.description,
      amountPaise: amountPaise ?? this.amountPaise,
      sNo: sNo ?? this.sNo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (txnDate.present) {
      map['txn_date'] = Variable<DateTime>(txnDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (sNo.present) {
      map['s_no'] = Variable<int>(sNo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardTransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('txnDate: $txnDate, ')
          ..write('description: $description, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('sNo: $sNo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceivablesTableTable extends ReceivablesTable
    with TableInfo<$ReceivablesTableTable, ReceivablesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceivablesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personNameMeta =
      const VerificationMeta('personName');
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
      'person_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
      'entry_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, personName, amountPaise, status, dueDate, entryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receivables';
  @override
  VerificationContext validateIntegrity(
      Insertable<ReceivablesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
          _personNameMeta,
          personName.isAcceptableOrUnknown(
              data['person_name']!, _personNameMeta));
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceivablesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivablesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      personName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person_name'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_id']),
    );
  }

  @override
  $ReceivablesTableTable createAlias(String alias) {
    return $ReceivablesTableTable(attachedDatabase, alias);
  }
}

class ReceivablesTableData extends DataClass
    implements Insertable<ReceivablesTableData> {
  final String id;
  final String householdId;
  final String personName;
  final int amountPaise;
  final String status;
  final DateTime? dueDate;

  /// Linked entry ID for transaction sync (Feature 2: borrow/lending sync)
  final String? entryId;
  const ReceivablesTableData(
      {required this.id,
      required this.householdId,
      required this.personName,
      required this.amountPaise,
      required this.status,
      this.dueDate,
      this.entryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['person_name'] = Variable<String>(personName);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<String>(entryId);
    }
    return map;
  }

  ReceivablesTableCompanion toCompanion(bool nullToAbsent) {
    return ReceivablesTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      personName: Value(personName),
      amountPaise: Value(amountPaise),
      status: Value(status),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
    );
  }

  factory ReceivablesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivablesTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      personName: serializer.fromJson<String>(json['personName']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      status: serializer.fromJson<String>(json['status']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      entryId: serializer.fromJson<String?>(json['entryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'personName': serializer.toJson<String>(personName),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'status': serializer.toJson<String>(status),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'entryId': serializer.toJson<String?>(entryId),
    };
  }

  ReceivablesTableData copyWith(
          {String? id,
          String? householdId,
          String? personName,
          int? amountPaise,
          String? status,
          Value<DateTime?> dueDate = const Value.absent(),
          Value<String?> entryId = const Value.absent()}) =>
      ReceivablesTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        personName: personName ?? this.personName,
        amountPaise: amountPaise ?? this.amountPaise,
        status: status ?? this.status,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        entryId: entryId.present ? entryId.value : this.entryId,
      );
  ReceivablesTableData copyWithCompanion(ReceivablesTableCompanion data) {
    return ReceivablesTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      personName:
          data.personName.present ? data.personName.value : this.personName,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      status: data.status.present ? data.status.value : this.status,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivablesTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('personName: $personName, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('entryId: $entryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, householdId, personName, amountPaise, status, dueDate, entryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivablesTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.personName == this.personName &&
          other.amountPaise == this.amountPaise &&
          other.status == this.status &&
          other.dueDate == this.dueDate &&
          other.entryId == this.entryId);
}

class ReceivablesTableCompanion extends UpdateCompanion<ReceivablesTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> personName;
  final Value<int> amountPaise;
  final Value<String> status;
  final Value<DateTime?> dueDate;
  final Value<String?> entryId;
  final Value<int> rowid;
  const ReceivablesTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.personName = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceivablesTableCompanion.insert({
    required String id,
    required String householdId,
    required String personName,
    required int amountPaise,
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        personName = Value(personName),
        amountPaise = Value(amountPaise);
  static Insertable<ReceivablesTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? personName,
    Expression<int>? amountPaise,
    Expression<String>? status,
    Expression<DateTime>? dueDate,
    Expression<String>? entryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (personName != null) 'person_name': personName,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (entryId != null) 'entry_id': entryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceivablesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? personName,
      Value<int>? amountPaise,
      Value<String>? status,
      Value<DateTime?>? dueDate,
      Value<String?>? entryId,
      Value<int>? rowid}) {
    return ReceivablesTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      personName: personName ?? this.personName,
      amountPaise: amountPaise ?? this.amountPaise,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      entryId: entryId ?? this.entryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceivablesTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('personName: $personName, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('entryId: $entryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannedBillsTableTable extends PlannedBillsTable
    with TableInfo<$PlannedBillsTableTable, PlannedBillsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedBillsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
      'is_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _entryIdMeta =
      const VerificationMeta('entryId');
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
      'entry_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, name, amountPaise, dueDate, isPaid, entryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_bills';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlannedBillsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('is_paid')) {
      context.handle(_isPaidMeta,
          isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(_entryIdMeta,
          entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedBillsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedBillsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      isPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_paid'])!,
      entryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_id']),
    );
  }

  @override
  $PlannedBillsTableTable createAlias(String alias) {
    return $PlannedBillsTableTable(attachedDatabase, alias);
  }
}

class PlannedBillsTableData extends DataClass
    implements Insertable<PlannedBillsTableData> {
  final String id;
  final String householdId;
  final String name;
  final int amountPaise;
  final DateTime? dueDate;
  final bool isPaid;

  /// Linked entry ID for transaction sync (Feature 2: borrow/lending sync)
  final String? entryId;
  const PlannedBillsTableData(
      {required this.id,
      required this.householdId,
      required this.name,
      required this.amountPaise,
      this.dueDate,
      required this.isPaid,
      this.entryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_paid'] = Variable<bool>(isPaid);
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<String>(entryId);
    }
    return map;
  }

  PlannedBillsTableCompanion toCompanion(bool nullToAbsent) {
    return PlannedBillsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      amountPaise: Value(amountPaise),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isPaid: Value(isPaid),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
    );
  }

  factory PlannedBillsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedBillsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
      entryId: serializer.fromJson<String?>(json['entryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isPaid': serializer.toJson<bool>(isPaid),
      'entryId': serializer.toJson<String?>(entryId),
    };
  }

  PlannedBillsTableData copyWith(
          {String? id,
          String? householdId,
          String? name,
          int? amountPaise,
          Value<DateTime?> dueDate = const Value.absent(),
          bool? isPaid,
          Value<String?> entryId = const Value.absent()}) =>
      PlannedBillsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        name: name ?? this.name,
        amountPaise: amountPaise ?? this.amountPaise,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        isPaid: isPaid ?? this.isPaid,
        entryId: entryId.present ? entryId.value : this.entryId,
      );
  PlannedBillsTableData copyWithCompanion(PlannedBillsTableCompanion data) {
    return PlannedBillsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedBillsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('dueDate: $dueDate, ')
          ..write('isPaid: $isPaid, ')
          ..write('entryId: $entryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, name, amountPaise, dueDate, isPaid, entryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedBillsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.amountPaise == this.amountPaise &&
          other.dueDate == this.dueDate &&
          other.isPaid == this.isPaid &&
          other.entryId == this.entryId);
}

class PlannedBillsTableCompanion
    extends UpdateCompanion<PlannedBillsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<int> amountPaise;
  final Value<DateTime?> dueDate;
  final Value<bool> isPaid;
  final Value<String?> entryId;
  final Value<int> rowid;
  const PlannedBillsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannedBillsTableCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    required int amountPaise,
    this.dueDate = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        name = Value(name),
        amountPaise = Value(amountPaise);
  static Insertable<PlannedBillsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<int>? amountPaise,
    Expression<DateTime>? dueDate,
    Expression<bool>? isPaid,
    Expression<String>? entryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (dueDate != null) 'due_date': dueDate,
      if (isPaid != null) 'is_paid': isPaid,
      if (entryId != null) 'entry_id': entryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannedBillsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? name,
      Value<int>? amountPaise,
      Value<DateTime?>? dueDate,
      Value<bool>? isPaid,
      Value<String?>? entryId,
      Value<int>? rowid}) {
    return PlannedBillsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      amountPaise: amountPaise ?? this.amountPaise,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      entryId: entryId ?? this.entryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedBillsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('dueDate: $dueDate, ')
          ..write('isPaid: $isPaid, ')
          ..write('entryId: $entryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReserveLinesTableTable extends ReserveLinesTable
    with TableInfo<$ReserveLinesTableTable, ReserveLinesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReserveLinesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMonthMeta =
      const VerificationMeta('yearMonth');
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
      'year_month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, yearMonth, name, amountPaise, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reserve_lines';
  @override
  VerificationContext validateIntegrity(
      Insertable<ReserveLinesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('year_month')) {
      context.handle(_yearMonthMeta,
          yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta));
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReserveLinesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReserveLinesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      yearMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}year_month'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $ReserveLinesTableTable createAlias(String alias) {
    return $ReserveLinesTableTable(attachedDatabase, alias);
  }
}

class ReserveLinesTableData extends DataClass
    implements Insertable<ReserveLinesTableData> {
  final String id;
  final String householdId;
  final String yearMonth;
  final String name;
  final int amountPaise;
  final String source;
  const ReserveLinesTableData(
      {required this.id,
      required this.householdId,
      required this.yearMonth,
      required this.name,
      required this.amountPaise,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['year_month'] = Variable<String>(yearMonth);
    map['name'] = Variable<String>(name);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['source'] = Variable<String>(source);
    return map;
  }

  ReserveLinesTableCompanion toCompanion(bool nullToAbsent) {
    return ReserveLinesTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      yearMonth: Value(yearMonth),
      name: Value(name),
      amountPaise: Value(amountPaise),
      source: Value(source),
    );
  }

  factory ReserveLinesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReserveLinesTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      name: serializer.fromJson<String>(json['name']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'name': serializer.toJson<String>(name),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'source': serializer.toJson<String>(source),
    };
  }

  ReserveLinesTableData copyWith(
          {String? id,
          String? householdId,
          String? yearMonth,
          String? name,
          int? amountPaise,
          String? source}) =>
      ReserveLinesTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        yearMonth: yearMonth ?? this.yearMonth,
        name: name ?? this.name,
        amountPaise: amountPaise ?? this.amountPaise,
        source: source ?? this.source,
      );
  ReserveLinesTableData copyWithCompanion(ReserveLinesTableCompanion data) {
    return ReserveLinesTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      name: data.name.present ? data.name.value : this.name,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReserveLinesTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('name: $name, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, yearMonth, name, amountPaise, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReserveLinesTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.yearMonth == this.yearMonth &&
          other.name == this.name &&
          other.amountPaise == this.amountPaise &&
          other.source == this.source);
}

class ReserveLinesTableCompanion
    extends UpdateCompanion<ReserveLinesTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> yearMonth;
  final Value<String> name;
  final Value<int> amountPaise;
  final Value<String> source;
  final Value<int> rowid;
  const ReserveLinesTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.name = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReserveLinesTableCompanion.insert({
    required String id,
    required String householdId,
    required String yearMonth,
    required String name,
    required int amountPaise,
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        yearMonth = Value(yearMonth),
        name = Value(name),
        amountPaise = Value(amountPaise);
  static Insertable<ReserveLinesTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? yearMonth,
    Expression<String>? name,
    Expression<int>? amountPaise,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (yearMonth != null) 'year_month': yearMonth,
      if (name != null) 'name': name,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReserveLinesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? yearMonth,
      Value<String>? name,
      Value<int>? amountPaise,
      Value<String>? source,
      Value<int>? rowid}) {
    return ReserveLinesTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      yearMonth: yearMonth ?? this.yearMonth,
      name: name ?? this.name,
      amountPaise: amountPaise ?? this.amountPaise,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReserveLinesTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('name: $name, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthSnapshotsTableTable extends MonthSnapshotsTable
    with TableInfo<$MonthSnapshotsTableTable, MonthSnapshotsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthSnapshotsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMonthMeta =
      const VerificationMeta('yearMonth');
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
      'year_month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _openingBalancePaiseMeta =
      const VerificationMeta('openingBalancePaise');
  @override
  late final GeneratedColumn<int> openingBalancePaise = GeneratedColumn<int>(
      'opening_balance_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastMonthReservesPaiseMeta =
      const VerificationMeta('lastMonthReservesPaise');
  @override
  late final GeneratedColumn<int> lastMonthReservesPaise = GeneratedColumn<int>(
      'last_month_reserves_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _incomePaiseMeta =
      const VerificationMeta('incomePaise');
  @override
  late final GeneratedColumn<int> incomePaise = GeneratedColumn<int>(
      'income_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _adjustmentsPaiseMeta =
      const VerificationMeta('adjustmentsPaise');
  @override
  late final GeneratedColumn<int> adjustmentsPaise = GeneratedColumn<int>(
      'adjustments_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _spendingPaiseMeta =
      const VerificationMeta('spendingPaise');
  @override
  late final GeneratedColumn<int> spendingPaise = GeneratedColumn<int>(
      'spending_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _protectionPaiseMeta =
      const VerificationMeta('protectionPaise');
  @override
  late final GeneratedColumn<int> protectionPaise = GeneratedColumn<int>(
      'protection_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _savingPaiseMeta =
      const VerificationMeta('savingPaise');
  @override
  late final GeneratedColumn<int> savingPaise = GeneratedColumn<int>(
      'saving_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reservesPaiseMeta =
      const VerificationMeta('reservesPaise');
  @override
  late final GeneratedColumn<int> reservesPaise = GeneratedColumn<int>(
      'reserves_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _closingBalancePaiseMeta =
      const VerificationMeta('closingBalancePaise');
  @override
  late final GeneratedColumn<int> closingBalancePaise = GeneratedColumn<int>(
      'closing_balance_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _remainingPaiseMeta =
      const VerificationMeta('remainingPaise');
  @override
  late final GeneratedColumn<int> remainingPaise = GeneratedColumn<int>(
      'remaining_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        householdId,
        yearMonth,
        openingBalancePaise,
        lastMonthReservesPaise,
        incomePaise,
        adjustmentsPaise,
        spendingPaise,
        protectionPaise,
        savingPaise,
        reservesPaise,
        closingBalancePaise,
        remainingPaise,
        status,
        closedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'month_snapshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<MonthSnapshotsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('year_month')) {
      context.handle(_yearMonthMeta,
          yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta));
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('opening_balance_paise')) {
      context.handle(
          _openingBalancePaiseMeta,
          openingBalancePaise.isAcceptableOrUnknown(
              data['opening_balance_paise']!, _openingBalancePaiseMeta));
    }
    if (data.containsKey('last_month_reserves_paise')) {
      context.handle(
          _lastMonthReservesPaiseMeta,
          lastMonthReservesPaise.isAcceptableOrUnknown(
              data['last_month_reserves_paise']!, _lastMonthReservesPaiseMeta));
    }
    if (data.containsKey('income_paise')) {
      context.handle(
          _incomePaiseMeta,
          incomePaise.isAcceptableOrUnknown(
              data['income_paise']!, _incomePaiseMeta));
    }
    if (data.containsKey('adjustments_paise')) {
      context.handle(
          _adjustmentsPaiseMeta,
          adjustmentsPaise.isAcceptableOrUnknown(
              data['adjustments_paise']!, _adjustmentsPaiseMeta));
    }
    if (data.containsKey('spending_paise')) {
      context.handle(
          _spendingPaiseMeta,
          spendingPaise.isAcceptableOrUnknown(
              data['spending_paise']!, _spendingPaiseMeta));
    }
    if (data.containsKey('protection_paise')) {
      context.handle(
          _protectionPaiseMeta,
          protectionPaise.isAcceptableOrUnknown(
              data['protection_paise']!, _protectionPaiseMeta));
    }
    if (data.containsKey('saving_paise')) {
      context.handle(
          _savingPaiseMeta,
          savingPaise.isAcceptableOrUnknown(
              data['saving_paise']!, _savingPaiseMeta));
    }
    if (data.containsKey('reserves_paise')) {
      context.handle(
          _reservesPaiseMeta,
          reservesPaise.isAcceptableOrUnknown(
              data['reserves_paise']!, _reservesPaiseMeta));
    }
    if (data.containsKey('closing_balance_paise')) {
      context.handle(
          _closingBalancePaiseMeta,
          closingBalancePaise.isAcceptableOrUnknown(
              data['closing_balance_paise']!, _closingBalancePaiseMeta));
    }
    if (data.containsKey('remaining_paise')) {
      context.handle(
          _remainingPaiseMeta,
          remainingPaise.isAcceptableOrUnknown(
              data['remaining_paise']!, _remainingPaiseMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthSnapshotsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthSnapshotsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      yearMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}year_month'])!,
      openingBalancePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}opening_balance_paise'])!,
      lastMonthReservesPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_month_reserves_paise'])!,
      incomePaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}income_paise'])!,
      adjustmentsPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}adjustments_paise'])!,
      spendingPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}spending_paise'])!,
      protectionPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}protection_paise'])!,
      savingPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saving_paise'])!,
      reservesPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reserves_paise'])!,
      closingBalancePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}closing_balance_paise'])!,
      remainingPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remaining_paise'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at']),
    );
  }

  @override
  $MonthSnapshotsTableTable createAlias(String alias) {
    return $MonthSnapshotsTableTable(attachedDatabase, alias);
  }
}

class MonthSnapshotsTableData extends DataClass
    implements Insertable<MonthSnapshotsTableData> {
  final String id;
  final String householdId;
  final String yearMonth;
  final int openingBalancePaise;
  final int lastMonthReservesPaise;
  final int incomePaise;
  final int adjustmentsPaise;
  final int spendingPaise;
  final int protectionPaise;
  final int savingPaise;
  final int reservesPaise;
  final int closingBalancePaise;
  final int remainingPaise;
  final String status;
  final DateTime? closedAt;
  const MonthSnapshotsTableData(
      {required this.id,
      required this.householdId,
      required this.yearMonth,
      required this.openingBalancePaise,
      required this.lastMonthReservesPaise,
      required this.incomePaise,
      required this.adjustmentsPaise,
      required this.spendingPaise,
      required this.protectionPaise,
      required this.savingPaise,
      required this.reservesPaise,
      required this.closingBalancePaise,
      required this.remainingPaise,
      required this.status,
      this.closedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['year_month'] = Variable<String>(yearMonth);
    map['opening_balance_paise'] = Variable<int>(openingBalancePaise);
    map['last_month_reserves_paise'] = Variable<int>(lastMonthReservesPaise);
    map['income_paise'] = Variable<int>(incomePaise);
    map['adjustments_paise'] = Variable<int>(adjustmentsPaise);
    map['spending_paise'] = Variable<int>(spendingPaise);
    map['protection_paise'] = Variable<int>(protectionPaise);
    map['saving_paise'] = Variable<int>(savingPaise);
    map['reserves_paise'] = Variable<int>(reservesPaise);
    map['closing_balance_paise'] = Variable<int>(closingBalancePaise);
    map['remaining_paise'] = Variable<int>(remainingPaise);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  MonthSnapshotsTableCompanion toCompanion(bool nullToAbsent) {
    return MonthSnapshotsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      yearMonth: Value(yearMonth),
      openingBalancePaise: Value(openingBalancePaise),
      lastMonthReservesPaise: Value(lastMonthReservesPaise),
      incomePaise: Value(incomePaise),
      adjustmentsPaise: Value(adjustmentsPaise),
      spendingPaise: Value(spendingPaise),
      protectionPaise: Value(protectionPaise),
      savingPaise: Value(savingPaise),
      reservesPaise: Value(reservesPaise),
      closingBalancePaise: Value(closingBalancePaise),
      remainingPaise: Value(remainingPaise),
      status: Value(status),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory MonthSnapshotsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthSnapshotsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      openingBalancePaise:
          serializer.fromJson<int>(json['openingBalancePaise']),
      lastMonthReservesPaise:
          serializer.fromJson<int>(json['lastMonthReservesPaise']),
      incomePaise: serializer.fromJson<int>(json['incomePaise']),
      adjustmentsPaise: serializer.fromJson<int>(json['adjustmentsPaise']),
      spendingPaise: serializer.fromJson<int>(json['spendingPaise']),
      protectionPaise: serializer.fromJson<int>(json['protectionPaise']),
      savingPaise: serializer.fromJson<int>(json['savingPaise']),
      reservesPaise: serializer.fromJson<int>(json['reservesPaise']),
      closingBalancePaise:
          serializer.fromJson<int>(json['closingBalancePaise']),
      remainingPaise: serializer.fromJson<int>(json['remainingPaise']),
      status: serializer.fromJson<String>(json['status']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'openingBalancePaise': serializer.toJson<int>(openingBalancePaise),
      'lastMonthReservesPaise': serializer.toJson<int>(lastMonthReservesPaise),
      'incomePaise': serializer.toJson<int>(incomePaise),
      'adjustmentsPaise': serializer.toJson<int>(adjustmentsPaise),
      'spendingPaise': serializer.toJson<int>(spendingPaise),
      'protectionPaise': serializer.toJson<int>(protectionPaise),
      'savingPaise': serializer.toJson<int>(savingPaise),
      'reservesPaise': serializer.toJson<int>(reservesPaise),
      'closingBalancePaise': serializer.toJson<int>(closingBalancePaise),
      'remainingPaise': serializer.toJson<int>(remainingPaise),
      'status': serializer.toJson<String>(status),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  MonthSnapshotsTableData copyWith(
          {String? id,
          String? householdId,
          String? yearMonth,
          int? openingBalancePaise,
          int? lastMonthReservesPaise,
          int? incomePaise,
          int? adjustmentsPaise,
          int? spendingPaise,
          int? protectionPaise,
          int? savingPaise,
          int? reservesPaise,
          int? closingBalancePaise,
          int? remainingPaise,
          String? status,
          Value<DateTime?> closedAt = const Value.absent()}) =>
      MonthSnapshotsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        yearMonth: yearMonth ?? this.yearMonth,
        openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
        lastMonthReservesPaise:
            lastMonthReservesPaise ?? this.lastMonthReservesPaise,
        incomePaise: incomePaise ?? this.incomePaise,
        adjustmentsPaise: adjustmentsPaise ?? this.adjustmentsPaise,
        spendingPaise: spendingPaise ?? this.spendingPaise,
        protectionPaise: protectionPaise ?? this.protectionPaise,
        savingPaise: savingPaise ?? this.savingPaise,
        reservesPaise: reservesPaise ?? this.reservesPaise,
        closingBalancePaise: closingBalancePaise ?? this.closingBalancePaise,
        remainingPaise: remainingPaise ?? this.remainingPaise,
        status: status ?? this.status,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
      );
  MonthSnapshotsTableData copyWithCompanion(MonthSnapshotsTableCompanion data) {
    return MonthSnapshotsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      openingBalancePaise: data.openingBalancePaise.present
          ? data.openingBalancePaise.value
          : this.openingBalancePaise,
      lastMonthReservesPaise: data.lastMonthReservesPaise.present
          ? data.lastMonthReservesPaise.value
          : this.lastMonthReservesPaise,
      incomePaise:
          data.incomePaise.present ? data.incomePaise.value : this.incomePaise,
      adjustmentsPaise: data.adjustmentsPaise.present
          ? data.adjustmentsPaise.value
          : this.adjustmentsPaise,
      spendingPaise: data.spendingPaise.present
          ? data.spendingPaise.value
          : this.spendingPaise,
      protectionPaise: data.protectionPaise.present
          ? data.protectionPaise.value
          : this.protectionPaise,
      savingPaise:
          data.savingPaise.present ? data.savingPaise.value : this.savingPaise,
      reservesPaise: data.reservesPaise.present
          ? data.reservesPaise.value
          : this.reservesPaise,
      closingBalancePaise: data.closingBalancePaise.present
          ? data.closingBalancePaise.value
          : this.closingBalancePaise,
      remainingPaise: data.remainingPaise.present
          ? data.remainingPaise.value
          : this.remainingPaise,
      status: data.status.present ? data.status.value : this.status,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthSnapshotsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('openingBalancePaise: $openingBalancePaise, ')
          ..write('lastMonthReservesPaise: $lastMonthReservesPaise, ')
          ..write('incomePaise: $incomePaise, ')
          ..write('adjustmentsPaise: $adjustmentsPaise, ')
          ..write('spendingPaise: $spendingPaise, ')
          ..write('protectionPaise: $protectionPaise, ')
          ..write('savingPaise: $savingPaise, ')
          ..write('reservesPaise: $reservesPaise, ')
          ..write('closingBalancePaise: $closingBalancePaise, ')
          ..write('remainingPaise: $remainingPaise, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      householdId,
      yearMonth,
      openingBalancePaise,
      lastMonthReservesPaise,
      incomePaise,
      adjustmentsPaise,
      spendingPaise,
      protectionPaise,
      savingPaise,
      reservesPaise,
      closingBalancePaise,
      remainingPaise,
      status,
      closedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthSnapshotsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.yearMonth == this.yearMonth &&
          other.openingBalancePaise == this.openingBalancePaise &&
          other.lastMonthReservesPaise == this.lastMonthReservesPaise &&
          other.incomePaise == this.incomePaise &&
          other.adjustmentsPaise == this.adjustmentsPaise &&
          other.spendingPaise == this.spendingPaise &&
          other.protectionPaise == this.protectionPaise &&
          other.savingPaise == this.savingPaise &&
          other.reservesPaise == this.reservesPaise &&
          other.closingBalancePaise == this.closingBalancePaise &&
          other.remainingPaise == this.remainingPaise &&
          other.status == this.status &&
          other.closedAt == this.closedAt);
}

class MonthSnapshotsTableCompanion
    extends UpdateCompanion<MonthSnapshotsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> yearMonth;
  final Value<int> openingBalancePaise;
  final Value<int> lastMonthReservesPaise;
  final Value<int> incomePaise;
  final Value<int> adjustmentsPaise;
  final Value<int> spendingPaise;
  final Value<int> protectionPaise;
  final Value<int> savingPaise;
  final Value<int> reservesPaise;
  final Value<int> closingBalancePaise;
  final Value<int> remainingPaise;
  final Value<String> status;
  final Value<DateTime?> closedAt;
  final Value<int> rowid;
  const MonthSnapshotsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.openingBalancePaise = const Value.absent(),
    this.lastMonthReservesPaise = const Value.absent(),
    this.incomePaise = const Value.absent(),
    this.adjustmentsPaise = const Value.absent(),
    this.spendingPaise = const Value.absent(),
    this.protectionPaise = const Value.absent(),
    this.savingPaise = const Value.absent(),
    this.reservesPaise = const Value.absent(),
    this.closingBalancePaise = const Value.absent(),
    this.remainingPaise = const Value.absent(),
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthSnapshotsTableCompanion.insert({
    required String id,
    required String householdId,
    required String yearMonth,
    this.openingBalancePaise = const Value.absent(),
    this.lastMonthReservesPaise = const Value.absent(),
    this.incomePaise = const Value.absent(),
    this.adjustmentsPaise = const Value.absent(),
    this.spendingPaise = const Value.absent(),
    this.protectionPaise = const Value.absent(),
    this.savingPaise = const Value.absent(),
    this.reservesPaise = const Value.absent(),
    this.closingBalancePaise = const Value.absent(),
    this.remainingPaise = const Value.absent(),
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        yearMonth = Value(yearMonth);
  static Insertable<MonthSnapshotsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? yearMonth,
    Expression<int>? openingBalancePaise,
    Expression<int>? lastMonthReservesPaise,
    Expression<int>? incomePaise,
    Expression<int>? adjustmentsPaise,
    Expression<int>? spendingPaise,
    Expression<int>? protectionPaise,
    Expression<int>? savingPaise,
    Expression<int>? reservesPaise,
    Expression<int>? closingBalancePaise,
    Expression<int>? remainingPaise,
    Expression<String>? status,
    Expression<DateTime>? closedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (yearMonth != null) 'year_month': yearMonth,
      if (openingBalancePaise != null)
        'opening_balance_paise': openingBalancePaise,
      if (lastMonthReservesPaise != null)
        'last_month_reserves_paise': lastMonthReservesPaise,
      if (incomePaise != null) 'income_paise': incomePaise,
      if (adjustmentsPaise != null) 'adjustments_paise': adjustmentsPaise,
      if (spendingPaise != null) 'spending_paise': spendingPaise,
      if (protectionPaise != null) 'protection_paise': protectionPaise,
      if (savingPaise != null) 'saving_paise': savingPaise,
      if (reservesPaise != null) 'reserves_paise': reservesPaise,
      if (closingBalancePaise != null)
        'closing_balance_paise': closingBalancePaise,
      if (remainingPaise != null) 'remaining_paise': remainingPaise,
      if (status != null) 'status': status,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthSnapshotsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? yearMonth,
      Value<int>? openingBalancePaise,
      Value<int>? lastMonthReservesPaise,
      Value<int>? incomePaise,
      Value<int>? adjustmentsPaise,
      Value<int>? spendingPaise,
      Value<int>? protectionPaise,
      Value<int>? savingPaise,
      Value<int>? reservesPaise,
      Value<int>? closingBalancePaise,
      Value<int>? remainingPaise,
      Value<String>? status,
      Value<DateTime?>? closedAt,
      Value<int>? rowid}) {
    return MonthSnapshotsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      yearMonth: yearMonth ?? this.yearMonth,
      openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
      lastMonthReservesPaise:
          lastMonthReservesPaise ?? this.lastMonthReservesPaise,
      incomePaise: incomePaise ?? this.incomePaise,
      adjustmentsPaise: adjustmentsPaise ?? this.adjustmentsPaise,
      spendingPaise: spendingPaise ?? this.spendingPaise,
      protectionPaise: protectionPaise ?? this.protectionPaise,
      savingPaise: savingPaise ?? this.savingPaise,
      reservesPaise: reservesPaise ?? this.reservesPaise,
      closingBalancePaise: closingBalancePaise ?? this.closingBalancePaise,
      remainingPaise: remainingPaise ?? this.remainingPaise,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (openingBalancePaise.present) {
      map['opening_balance_paise'] = Variable<int>(openingBalancePaise.value);
    }
    if (lastMonthReservesPaise.present) {
      map['last_month_reserves_paise'] =
          Variable<int>(lastMonthReservesPaise.value);
    }
    if (incomePaise.present) {
      map['income_paise'] = Variable<int>(incomePaise.value);
    }
    if (adjustmentsPaise.present) {
      map['adjustments_paise'] = Variable<int>(adjustmentsPaise.value);
    }
    if (spendingPaise.present) {
      map['spending_paise'] = Variable<int>(spendingPaise.value);
    }
    if (protectionPaise.present) {
      map['protection_paise'] = Variable<int>(protectionPaise.value);
    }
    if (savingPaise.present) {
      map['saving_paise'] = Variable<int>(savingPaise.value);
    }
    if (reservesPaise.present) {
      map['reserves_paise'] = Variable<int>(reservesPaise.value);
    }
    if (closingBalancePaise.present) {
      map['closing_balance_paise'] = Variable<int>(closingBalancePaise.value);
    }
    if (remainingPaise.present) {
      map['remaining_paise'] = Variable<int>(remainingPaise.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthSnapshotsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('openingBalancePaise: $openingBalancePaise, ')
          ..write('lastMonthReservesPaise: $lastMonthReservesPaise, ')
          ..write('incomePaise: $incomePaise, ')
          ..write('adjustmentsPaise: $adjustmentsPaise, ')
          ..write('spendingPaise: $spendingPaise, ')
          ..write('protectionPaise: $protectionPaise, ')
          ..write('savingPaise: $savingPaise, ')
          ..write('reservesPaise: $reservesPaise, ')
          ..write('closingBalancePaise: $closingBalancePaise, ')
          ..write('remainingPaise: $remainingPaise, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
      'op', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, op, entity, entityId, payload, createdAt, attempts, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      op: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final String id;
  final String op;
  final String entity;
  final String entityId;
  final String payload;
  final DateTime createdAt;
  final int attempts;
  final DateTime? syncedAt;
  const SyncQueueTableData(
      {required this.id,
      required this.op,
      required this.entity,
      required this.entityId,
      required this.payload,
      required this.createdAt,
      required this.attempts,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['op'] = Variable<String>(op);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      op: Value(op),
      entity: Value(entity),
      entityId: Value(entityId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<String>(json['id']),
      op: serializer.fromJson<String>(json['op']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'op': serializer.toJson<String>(op),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SyncQueueTableData copyWith(
          {String? id,
          String? op,
          String? entity,
          String? entityId,
          String? payload,
          DateTime? createdAt,
          int? attempts,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        op: op ?? this.op,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        attempts: attempts ?? this.attempts,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      op: data.op.present ? data.op.value : this.op,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, op, entity, entityId, payload, createdAt, attempts, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.op == this.op &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.syncedAt == this.syncedAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<String> id;
  final Value<String> op;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.op = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    required String id,
    required String op,
    required String entity,
    required String entityId,
    required String payload,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        op = Value(op),
        entity = Value(entity),
        entityId = Value(entityId),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<String>? id,
    Expression<String>? op,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (op != null) 'op': op,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? op,
      Value<String>? entity,
      Value<String>? entityId,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<int>? attempts,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      op: op ?? this.op,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnualTargetsTableTable extends AnnualTargetsTable
    with TableInfo<$AnnualTargetsTableTable, AnnualTargetsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnualTargetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetPaiseMeta =
      const VerificationMeta('targetPaise');
  @override
  late final GeneratedColumn<int> targetPaise = GeneratedColumn<int>(
      'target_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('income'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, householdId, title, targetPaise, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annual_targets';
  @override
  VerificationContext validateIntegrity(
      Insertable<AnnualTargetsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_paise')) {
      context.handle(
          _targetPaiseMeta,
          targetPaise.isAcceptableOrUnknown(
              data['target_paise']!, _targetPaiseMeta));
    } else if (isInserting) {
      context.missing(_targetPaiseMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnualTargetsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnualTargetsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_paise'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $AnnualTargetsTableTable createAlias(String alias) {
    return $AnnualTargetsTableTable(attachedDatabase, alias);
  }
}

class AnnualTargetsTableData extends DataClass
    implements Insertable<AnnualTargetsTableData> {
  final String id;
  final String householdId;
  final String title;
  final int targetPaise;
  final String type;
  const AnnualTargetsTableData(
      {required this.id,
      required this.householdId,
      required this.title,
      required this.targetPaise,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['title'] = Variable<String>(title);
    map['target_paise'] = Variable<int>(targetPaise);
    map['type'] = Variable<String>(type);
    return map;
  }

  AnnualTargetsTableCompanion toCompanion(bool nullToAbsent) {
    return AnnualTargetsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      title: Value(title),
      targetPaise: Value(targetPaise),
      type: Value(type),
    );
  }

  factory AnnualTargetsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnualTargetsTableData(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      title: serializer.fromJson<String>(json['title']),
      targetPaise: serializer.fromJson<int>(json['targetPaise']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'title': serializer.toJson<String>(title),
      'targetPaise': serializer.toJson<int>(targetPaise),
      'type': serializer.toJson<String>(type),
    };
  }

  AnnualTargetsTableData copyWith(
          {String? id,
          String? householdId,
          String? title,
          int? targetPaise,
          String? type}) =>
      AnnualTargetsTableData(
        id: id ?? this.id,
        householdId: householdId ?? this.householdId,
        title: title ?? this.title,
        targetPaise: targetPaise ?? this.targetPaise,
        type: type ?? this.type,
      );
  AnnualTargetsTableData copyWithCompanion(AnnualTargetsTableCompanion data) {
    return AnnualTargetsTableData(
      id: data.id.present ? data.id.value : this.id,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      title: data.title.present ? data.title.value : this.title,
      targetPaise:
          data.targetPaise.present ? data.targetPaise.value : this.targetPaise,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnualTargetsTableData(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('title: $title, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, householdId, title, targetPaise, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnualTargetsTableData &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.title == this.title &&
          other.targetPaise == this.targetPaise &&
          other.type == this.type);
}

class AnnualTargetsTableCompanion
    extends UpdateCompanion<AnnualTargetsTableData> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> title;
  final Value<int> targetPaise;
  final Value<String> type;
  final Value<int> rowid;
  const AnnualTargetsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetPaise = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnualTargetsTableCompanion.insert({
    required String id,
    required String householdId,
    required String title,
    required int targetPaise,
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        householdId = Value(householdId),
        title = Value(title),
        targetPaise = Value(targetPaise);
  static Insertable<AnnualTargetsTableData> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? title,
    Expression<int>? targetPaise,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (title != null) 'title': title,
      if (targetPaise != null) 'target_paise': targetPaise,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnualTargetsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? householdId,
      Value<String>? title,
      Value<int>? targetPaise,
      Value<String>? type,
      Value<int>? rowid}) {
    return AnnualTargetsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      targetPaise: targetPaise ?? this.targetPaise,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetPaise.present) {
      map['target_paise'] = Variable<int>(targetPaise.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnualTargetsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('title: $title, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authProviderMeta =
      const VerificationMeta('authProvider');
  @override
  late final GeneratedColumn<String> authProvider = GeneratedColumn<String>(
      'auth_provider', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('email'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, email, password, displayName, householdId, authProvider, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<UsersTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('auth_provider')) {
      context.handle(
          _authProviderMeta,
          authProvider.isAcceptableOrUnknown(
              data['auth_provider']!, _authProviderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id'])!,
      authProvider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}auth_provider'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UsersTableData extends DataClass implements Insertable<UsersTableData> {
  final String id;
  final String email;
  final String? password;
  final String displayName;
  final String householdId;
  final String authProvider;
  final DateTime createdAt;
  const UsersTableData(
      {required this.id,
      required this.email,
      this.password,
      required this.displayName,
      required this.householdId,
      required this.authProvider,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    map['display_name'] = Variable<String>(displayName);
    map['household_id'] = Variable<String>(householdId);
    map['auth_provider'] = Variable<String>(authProvider);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      email: Value(email),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      displayName: Value(displayName),
      householdId: Value(householdId),
      authProvider: Value(authProvider),
      createdAt: Value(createdAt),
    );
  }

  factory UsersTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersTableData(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      password: serializer.fromJson<String?>(json['password']),
      displayName: serializer.fromJson<String>(json['displayName']),
      householdId: serializer.fromJson<String>(json['householdId']),
      authProvider: serializer.fromJson<String>(json['authProvider']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'password': serializer.toJson<String?>(password),
      'displayName': serializer.toJson<String>(displayName),
      'householdId': serializer.toJson<String>(householdId),
      'authProvider': serializer.toJson<String>(authProvider),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UsersTableData copyWith(
          {String? id,
          String? email,
          Value<String?> password = const Value.absent(),
          String? displayName,
          String? householdId,
          String? authProvider,
          DateTime? createdAt}) =>
      UsersTableData(
        id: id ?? this.id,
        email: email ?? this.email,
        password: password.present ? password.value : this.password,
        displayName: displayName ?? this.displayName,
        householdId: householdId ?? this.householdId,
        authProvider: authProvider ?? this.authProvider,
        createdAt: createdAt ?? this.createdAt,
      );
  UsersTableData copyWithCompanion(UsersTableCompanion data) {
    return UsersTableData(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      password: data.password.present ? data.password.value : this.password,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      authProvider: data.authProvider.present
          ? data.authProvider.value
          : this.authProvider,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableData(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('displayName: $displayName, ')
          ..write('householdId: $householdId, ')
          ..write('authProvider: $authProvider, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, email, password, displayName, householdId, authProvider, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersTableData &&
          other.id == this.id &&
          other.email == this.email &&
          other.password == this.password &&
          other.displayName == this.displayName &&
          other.householdId == this.householdId &&
          other.authProvider == this.authProvider &&
          other.createdAt == this.createdAt);
}

class UsersTableCompanion extends UpdateCompanion<UsersTableData> {
  final Value<String> id;
  final Value<String> email;
  final Value<String?> password;
  final Value<String> displayName;
  final Value<String> householdId;
  final Value<String> authProvider;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.password = const Value.absent(),
    this.displayName = const Value.absent(),
    this.householdId = const Value.absent(),
    this.authProvider = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String id,
    required String email,
    this.password = const Value.absent(),
    required String displayName,
    required String householdId,
    this.authProvider = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email),
        displayName = Value(displayName),
        householdId = Value(householdId),
        createdAt = Value(createdAt);
  static Insertable<UsersTableData> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? password,
    Expression<String>? displayName,
    Expression<String>? householdId,
    Expression<String>? authProvider,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (displayName != null) 'display_name': displayName,
      if (householdId != null) 'household_id': householdId,
      if (authProvider != null) 'auth_provider': authProvider,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String?>? password,
      Value<String>? displayName,
      Value<String>? householdId,
      Value<String>? authProvider,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return UsersTableCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      householdId: householdId ?? this.householdId,
      authProvider: authProvider ?? this.authProvider,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (authProvider.present) {
      map['auth_provider'] = Variable<String>(authProvider.value);
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
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('password: $password, ')
          ..write('displayName: $displayName, ')
          ..write('householdId: $householdId, ')
          ..write('authProvider: $authProvider, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTableTable accountsTable = $AccountsTableTable(this);
  late final $CategoriesTableTable categoriesTable =
      $CategoriesTableTable(this);
  late final $BudgetsTableTable budgetsTable = $BudgetsTableTable(this);
  late final $EntriesTableTable entriesTable = $EntriesTableTable(this);
  late final $SinkingFundsTableTable sinkingFundsTable =
      $SinkingFundsTableTable(this);
  late final $FundMovementsTableTable fundMovementsTable =
      $FundMovementsTableTable(this);
  late final $SavingGoalsTableTable savingGoalsTable =
      $SavingGoalsTableTable(this);
  late final $GoalContributionsTableTable goalContributionsTable =
      $GoalContributionsTableTable(this);
  late final $CreditCardsTableTable creditCardsTable =
      $CreditCardsTableTable(this);
  late final $CardTransactionsTableTable cardTransactionsTable =
      $CardTransactionsTableTable(this);
  late final $ReceivablesTableTable receivablesTable =
      $ReceivablesTableTable(this);
  late final $PlannedBillsTableTable plannedBillsTable =
      $PlannedBillsTableTable(this);
  late final $ReserveLinesTableTable reserveLinesTable =
      $ReserveLinesTableTable(this);
  late final $MonthSnapshotsTableTable monthSnapshotsTable =
      $MonthSnapshotsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $AnnualTargetsTableTable annualTargetsTable =
      $AnnualTargetsTableTable(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final EntryDao entryDao = EntryDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final SnapshotDao snapshotDao = SnapshotDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final FundDao fundDao = FundDao(this as AppDatabase);
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  late final CardDao cardDao = CardDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final BorrowLendDao borrowLendDao = BorrowLendDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accountsTable,
        categoriesTable,
        budgetsTable,
        entriesTable,
        sinkingFundsTable,
        fundMovementsTable,
        savingGoalsTable,
        goalContributionsTable,
        creditCardsTable,
        cardTransactionsTable,
        receivablesTable,
        plannedBillsTable,
        reserveLinesTable,
        monthSnapshotsTable,
        syncQueueTable,
        annualTargetsTable,
        usersTable
      ];
}

typedef $$AccountsTableTableCreateCompanionBuilder = AccountsTableCompanion
    Function({
  required String id,
  required String householdId,
  required String name,
  required String type,
  Value<int> currentBalancePaise,
  Value<bool> isActive,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$AccountsTableTableUpdateCompanionBuilder = AccountsTableCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<String> type,
  Value<int> currentBalancePaise,
  Value<bool> isActive,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$AccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentBalancePaise => $composableBuilder(
      column: $table.currentBalancePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentBalancePaise => $composableBuilder(
      column: $table.currentBalancePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get currentBalancePaise => $composableBuilder(
      column: $table.currentBalancePaise, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AccountsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTableTable,
    AccountsTableData,
    $$AccountsTableTableFilterComposer,
    $$AccountsTableTableOrderingComposer,
    $$AccountsTableTableAnnotationComposer,
    $$AccountsTableTableCreateCompanionBuilder,
    $$AccountsTableTableUpdateCompanionBuilder,
    (
      AccountsTableData,
      BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>
    ),
    AccountsTableData,
    PrefetchHooks Function()> {
  $$AccountsTableTableTableManager(_$AppDatabase db, $AccountsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> currentBalancePaise = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsTableCompanion(
            id: id,
            householdId: householdId,
            name: name,
            type: type,
            currentBalancePaise: currentBalancePaise,
            isActive: isActive,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            required String type,
            Value<int> currentBalancePaise = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsTableCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            type: type,
            currentBalancePaise: currentBalancePaise,
            isActive: isActive,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTableTable,
    AccountsTableData,
    $$AccountsTableTableFilterComposer,
    $$AccountsTableTableOrderingComposer,
    $$AccountsTableTableAnnotationComposer,
    $$AccountsTableTableCreateCompanionBuilder,
    $$AccountsTableTableUpdateCompanionBuilder,
    (
      AccountsTableData,
      BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>
    ),
    AccountsTableData,
    PrefetchHooks Function()>;
typedef $$CategoriesTableTableCreateCompanionBuilder = CategoriesTableCompanion
    Function({
  required String id,
  required String householdId,
  required String kind,
  Value<String?> groupCode,
  required String name,
  Value<String?> needOrWant,
  Value<bool> isDeduction,
  Value<bool> isSystem,
  Value<int> sortOrder,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableTableUpdateCompanionBuilder = CategoriesTableCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> kind,
  Value<String?> groupCode,
  Value<String> name,
  Value<String?> needOrWant,
  Value<bool> isDeduction,
  Value<bool> isSystem,
  Value<int> sortOrder,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

final class $$CategoriesTableTableReferences extends BaseReferences<
    _$AppDatabase, $CategoriesTableTable, CategoriesTableData> {
  $$CategoriesTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BudgetsTableTable, List<BudgetsTableData>>
      _budgetsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.budgetsTable,
              aliasName: $_aliasNameGenerator(
                  db.categoriesTable.id, db.budgetsTable.categoryId));

  $$BudgetsTableTableProcessedTableManager get budgetsTableRefs {
    final manager = $$BudgetsTableTableTableManager($_db, $_db.budgetsTable)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EntriesTableTable, List<EntriesTableData>>
      _entriesTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.entriesTable,
              aliasName: $_aliasNameGenerator(
                  db.categoriesTable.id, db.entriesTable.categoryId));

  $$EntriesTableTableProcessedTableManager get entriesTableRefs {
    final manager = $$EntriesTableTableTableManager($_db, $_db.entriesTable)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupCode => $composableBuilder(
      column: $table.groupCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get needOrWant => $composableBuilder(
      column: $table.needOrWant, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeduction => $composableBuilder(
      column: $table.isDeduction, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> budgetsTableRefs(
      Expression<bool> Function($$BudgetsTableTableFilterComposer f) f) {
    final $$BudgetsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgetsTable,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableTableFilterComposer(
              $db: $db,
              $table: $db.budgetsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> entriesTableRefs(
      Expression<bool> Function($$EntriesTableTableFilterComposer f) f) {
    final $$EntriesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.entriesTable,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableTableFilterComposer(
              $db: $db,
              $table: $db.entriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupCode => $composableBuilder(
      column: $table.groupCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get needOrWant => $composableBuilder(
      column: $table.needOrWant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeduction => $composableBuilder(
      column: $table.isDeduction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get groupCode =>
      $composableBuilder(column: $table.groupCode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get needOrWant => $composableBuilder(
      column: $table.needOrWant, builder: (column) => column);

  GeneratedColumn<bool> get isDeduction => $composableBuilder(
      column: $table.isDeduction, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  Expression<T> budgetsTableRefs<T extends Object>(
      Expression<T> Function($$BudgetsTableTableAnnotationComposer a) f) {
    final $$BudgetsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgetsTable,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.budgetsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> entriesTableRefs<T extends Object>(
      Expression<T> Function($$EntriesTableTableAnnotationComposer a) f) {
    final $$EntriesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.entriesTable,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EntriesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.entriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    CategoriesTableData,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (CategoriesTableData, $$CategoriesTableTableReferences),
    CategoriesTableData,
    PrefetchHooks Function({bool budgetsTableRefs, bool entriesTableRefs})> {
  $$CategoriesTableTableTableManager(
      _$AppDatabase db, $CategoriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> groupCode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> needOrWant = const Value.absent(),
            Value<bool> isDeduction = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion(
            id: id,
            householdId: householdId,
            kind: kind,
            groupCode: groupCode,
            name: name,
            needOrWant: needOrWant,
            isDeduction: isDeduction,
            isSystem: isSystem,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String kind,
            Value<String?> groupCode = const Value.absent(),
            required String name,
            Value<String?> needOrWant = const Value.absent(),
            Value<bool> isDeduction = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion.insert(
            id: id,
            householdId: householdId,
            kind: kind,
            groupCode: groupCode,
            name: name,
            needOrWant: needOrWant,
            isDeduction: isDeduction,
            isSystem: isSystem,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {budgetsTableRefs = false, entriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (budgetsTableRefs) db.budgetsTable,
                if (entriesTableRefs) db.entriesTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (budgetsTableRefs)
                    await $_getPrefetchedData<CategoriesTableData,
                            $CategoriesTableTable, BudgetsTableData>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableTableReferences
                            ._budgetsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableTableReferences(db, table, p0)
                                .budgetsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (entriesTableRefs)
                    await $_getPrefetchedData<CategoriesTableData,
                            $CategoriesTableTable, EntriesTableData>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableTableReferences
                            ._entriesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableTableReferences(db, table, p0)
                                .entriesTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    CategoriesTableData,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (CategoriesTableData, $$CategoriesTableTableReferences),
    CategoriesTableData,
    PrefetchHooks Function({bool budgetsTableRefs, bool entriesTableRefs})>;
typedef $$BudgetsTableTableCreateCompanionBuilder = BudgetsTableCompanion
    Function({
  required String id,
  required String householdId,
  required String categoryId,
  required String yearMonth,
  Value<int> amountPaise,
  Value<int> rowid,
});
typedef $$BudgetsTableTableUpdateCompanionBuilder = BudgetsTableCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> categoryId,
  Value<String> yearMonth,
  Value<int> amountPaise,
  Value<int> rowid,
});

final class $$BudgetsTableTableReferences extends BaseReferences<_$AppDatabase,
    $BudgetsTableTable, BudgetsTableData> {
  $$BudgetsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTableTable _categoryIdTable(_$AppDatabase db) =>
      db.categoriesTable.createAlias($_aliasNameGenerator(
          db.budgetsTable.categoryId, db.categoriesTable.id));

  $$CategoriesTableTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager =
        $$CategoriesTableTableTableManager($_db, $_db.categoriesTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTableTable> {
  $$BudgetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  $$CategoriesTableTableFilterComposer get categoryId {
    final $$CategoriesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categoriesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableTableFilterComposer(
              $db: $db,
              $table: $db.categoriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTableTable> {
  $$BudgetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableTableOrderingComposer get categoryId {
    final $$CategoriesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categoriesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableTableOrderingComposer(
              $db: $db,
              $table: $db.categoriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTableTable> {
  $$BudgetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  $$CategoriesTableTableAnnotationComposer get categoryId {
    final $$CategoriesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categoriesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.categoriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTableTable,
    BudgetsTableData,
    $$BudgetsTableTableFilterComposer,
    $$BudgetsTableTableOrderingComposer,
    $$BudgetsTableTableAnnotationComposer,
    $$BudgetsTableTableCreateCompanionBuilder,
    $$BudgetsTableTableUpdateCompanionBuilder,
    (BudgetsTableData, $$BudgetsTableTableReferences),
    BudgetsTableData,
    PrefetchHooks Function({bool categoryId})> {
  $$BudgetsTableTableTableManager(_$AppDatabase db, $BudgetsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> yearMonth = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsTableCompanion(
            id: id,
            householdId: householdId,
            categoryId: categoryId,
            yearMonth: yearMonth,
            amountPaise: amountPaise,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String categoryId,
            required String yearMonth,
            Value<int> amountPaise = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsTableCompanion.insert(
            id: id,
            householdId: householdId,
            categoryId: categoryId,
            yearMonth: yearMonth,
            amountPaise: amountPaise,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BudgetsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BudgetsTableTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$BudgetsTableTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BudgetsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTableTable,
    BudgetsTableData,
    $$BudgetsTableTableFilterComposer,
    $$BudgetsTableTableOrderingComposer,
    $$BudgetsTableTableAnnotationComposer,
    $$BudgetsTableTableCreateCompanionBuilder,
    $$BudgetsTableTableUpdateCompanionBuilder,
    (BudgetsTableData, $$BudgetsTableTableReferences),
    BudgetsTableData,
    PrefetchHooks Function({bool categoryId})>;
typedef $$EntriesTableTableCreateCompanionBuilder = EntriesTableCompanion
    Function({
  required String id,
  required String householdId,
  required String categoryId,
  required String kind,
  Value<String?> accountId,
  Value<String?> cardId,
  required DateTime entryDate,
  required int amountPaise,
  Value<String?> note,
  Value<String?> parentId,
  required String createdBy,
  Value<int> version,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$EntriesTableTableUpdateCompanionBuilder = EntriesTableCompanion
    Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> categoryId,
  Value<String> kind,
  Value<String?> accountId,
  Value<String?> cardId,
  Value<DateTime> entryDate,
  Value<int> amountPaise,
  Value<String?> note,
  Value<String?> parentId,
  Value<String> createdBy,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$EntriesTableTableReferences extends BaseReferences<_$AppDatabase,
    $EntriesTableTable, EntriesTableData> {
  $$EntriesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTableTable _categoryIdTable(_$AppDatabase db) =>
      db.categoriesTable.createAlias($_aliasNameGenerator(
          db.entriesTable.categoryId, db.categoriesTable.id));

  $$CategoriesTableTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager =
        $$CategoriesTableTableTableManager($_db, $_db.categoriesTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTableTable> {
  $$EntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardId => $composableBuilder(
      column: $table.cardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableTableFilterComposer get categoryId {
    final $$CategoriesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categoriesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableTableFilterComposer(
              $db: $db,
              $table: $db.categoriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTableTable> {
  $$EntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardId => $composableBuilder(
      column: $table.cardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableTableOrderingComposer get categoryId {
    final $$CategoriesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categoriesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableTableOrderingComposer(
              $db: $db,
              $table: $db.categoriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTableTable> {
  $$EntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CategoriesTableTableAnnotationComposer get categoryId {
    final $$CategoriesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categoriesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.categoriesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EntriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntriesTableTable,
    EntriesTableData,
    $$EntriesTableTableFilterComposer,
    $$EntriesTableTableOrderingComposer,
    $$EntriesTableTableAnnotationComposer,
    $$EntriesTableTableCreateCompanionBuilder,
    $$EntriesTableTableUpdateCompanionBuilder,
    (EntriesTableData, $$EntriesTableTableReferences),
    EntriesTableData,
    PrefetchHooks Function({bool categoryId})> {
  $$EntriesTableTableTableManager(_$AppDatabase db, $EntriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> cardId = const Value.absent(),
            Value<DateTime> entryDate = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> createdBy = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntriesTableCompanion(
            id: id,
            householdId: householdId,
            categoryId: categoryId,
            kind: kind,
            accountId: accountId,
            cardId: cardId,
            entryDate: entryDate,
            amountPaise: amountPaise,
            note: note,
            parentId: parentId,
            createdBy: createdBy,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String categoryId,
            required String kind,
            Value<String?> accountId = const Value.absent(),
            Value<String?> cardId = const Value.absent(),
            required DateTime entryDate,
            required int amountPaise,
            Value<String?> note = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            required String createdBy,
            Value<int> version = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntriesTableCompanion.insert(
            id: id,
            householdId: householdId,
            categoryId: categoryId,
            kind: kind,
            accountId: accountId,
            cardId: cardId,
            entryDate: entryDate,
            amountPaise: amountPaise,
            note: note,
            parentId: parentId,
            createdBy: createdBy,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EntriesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$EntriesTableTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$EntriesTableTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EntriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntriesTableTable,
    EntriesTableData,
    $$EntriesTableTableFilterComposer,
    $$EntriesTableTableOrderingComposer,
    $$EntriesTableTableAnnotationComposer,
    $$EntriesTableTableCreateCompanionBuilder,
    $$EntriesTableTableUpdateCompanionBuilder,
    (EntriesTableData, $$EntriesTableTableReferences),
    EntriesTableData,
    PrefetchHooks Function({bool categoryId})>;
typedef $$SinkingFundsTableTableCreateCompanionBuilder
    = SinkingFundsTableCompanion Function({
  required String id,
  required String householdId,
  required String name,
  Value<int> openingReservePaise,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $$SinkingFundsTableTableUpdateCompanionBuilder
    = SinkingFundsTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<int> openingReservePaise,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

final class $$SinkingFundsTableTableReferences extends BaseReferences<
    _$AppDatabase, $SinkingFundsTableTable, SinkingFundsTableData> {
  $$SinkingFundsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FundMovementsTableTable,
      List<FundMovementsTableData>> _fundMovementsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.fundMovementsTable,
          aliasName: $_aliasNameGenerator(
              db.sinkingFundsTable.id, db.fundMovementsTable.fundId));

  $$FundMovementsTableTableProcessedTableManager get fundMovementsTableRefs {
    final manager =
        $$FundMovementsTableTableTableManager($_db, $_db.fundMovementsTable)
            .filter((f) => f.fundId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_fundMovementsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SinkingFundsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SinkingFundsTableTable> {
  $$SinkingFundsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingReservePaise => $composableBuilder(
      column: $table.openingReservePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> fundMovementsTableRefs(
      Expression<bool> Function($$FundMovementsTableTableFilterComposer f) f) {
    final $$FundMovementsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fundMovementsTable,
        getReferencedColumn: (t) => t.fundId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FundMovementsTableTableFilterComposer(
              $db: $db,
              $table: $db.fundMovementsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SinkingFundsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SinkingFundsTableTable> {
  $$SinkingFundsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingReservePaise => $composableBuilder(
      column: $table.openingReservePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));
}

class $$SinkingFundsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SinkingFundsTableTable> {
  $$SinkingFundsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get openingReservePaise => $composableBuilder(
      column: $table.openingReservePaise, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  Expression<T> fundMovementsTableRefs<T extends Object>(
      Expression<T> Function($$FundMovementsTableTableAnnotationComposer a) f) {
    final $$FundMovementsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.fundMovementsTable,
            getReferencedColumn: (t) => t.fundId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$FundMovementsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.fundMovementsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SinkingFundsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SinkingFundsTableTable,
    SinkingFundsTableData,
    $$SinkingFundsTableTableFilterComposer,
    $$SinkingFundsTableTableOrderingComposer,
    $$SinkingFundsTableTableAnnotationComposer,
    $$SinkingFundsTableTableCreateCompanionBuilder,
    $$SinkingFundsTableTableUpdateCompanionBuilder,
    (SinkingFundsTableData, $$SinkingFundsTableTableReferences),
    SinkingFundsTableData,
    PrefetchHooks Function({bool fundMovementsTableRefs})> {
  $$SinkingFundsTableTableTableManager(
      _$AppDatabase db, $SinkingFundsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SinkingFundsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SinkingFundsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SinkingFundsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> openingReservePaise = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SinkingFundsTableCompanion(
            id: id,
            householdId: householdId,
            name: name,
            openingReservePaise: openingReservePaise,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            Value<int> openingReservePaise = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SinkingFundsTableCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            openingReservePaise: openingReservePaise,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SinkingFundsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fundMovementsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (fundMovementsTableRefs) db.fundMovementsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fundMovementsTableRefs)
                    await $_getPrefetchedData<SinkingFundsTableData,
                            $SinkingFundsTableTable, FundMovementsTableData>(
                        currentTable: table,
                        referencedTable: $$SinkingFundsTableTableReferences
                            ._fundMovementsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SinkingFundsTableTableReferences(db, table, p0)
                                .fundMovementsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.fundId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SinkingFundsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SinkingFundsTableTable,
    SinkingFundsTableData,
    $$SinkingFundsTableTableFilterComposer,
    $$SinkingFundsTableTableOrderingComposer,
    $$SinkingFundsTableTableAnnotationComposer,
    $$SinkingFundsTableTableCreateCompanionBuilder,
    $$SinkingFundsTableTableUpdateCompanionBuilder,
    (SinkingFundsTableData, $$SinkingFundsTableTableReferences),
    SinkingFundsTableData,
    PrefetchHooks Function({bool fundMovementsTableRefs})>;
typedef $$FundMovementsTableTableCreateCompanionBuilder
    = FundMovementsTableCompanion Function({
  required String id,
  required String fundId,
  required String type,
  required int amountPaise,
  required DateTime movementDate,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$FundMovementsTableTableUpdateCompanionBuilder
    = FundMovementsTableCompanion Function({
  Value<String> id,
  Value<String> fundId,
  Value<String> type,
  Value<int> amountPaise,
  Value<DateTime> movementDate,
  Value<String?> note,
  Value<int> rowid,
});

final class $$FundMovementsTableTableReferences extends BaseReferences<
    _$AppDatabase, $FundMovementsTableTable, FundMovementsTableData> {
  $$FundMovementsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SinkingFundsTableTable _fundIdTable(_$AppDatabase db) =>
      db.sinkingFundsTable.createAlias($_aliasNameGenerator(
          db.fundMovementsTable.fundId, db.sinkingFundsTable.id));

  $$SinkingFundsTableTableProcessedTableManager get fundId {
    final $_column = $_itemColumn<String>('fund_id')!;

    final manager =
        $$SinkingFundsTableTableTableManager($_db, $_db.sinkingFundsTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FundMovementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FundMovementsTableTable> {
  $$FundMovementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get movementDate => $composableBuilder(
      column: $table.movementDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$SinkingFundsTableTableFilterComposer get fundId {
    final $$SinkingFundsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fundId,
        referencedTable: $db.sinkingFundsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SinkingFundsTableTableFilterComposer(
              $db: $db,
              $table: $db.sinkingFundsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FundMovementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FundMovementsTableTable> {
  $$FundMovementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get movementDate => $composableBuilder(
      column: $table.movementDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$SinkingFundsTableTableOrderingComposer get fundId {
    final $$SinkingFundsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fundId,
        referencedTable: $db.sinkingFundsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SinkingFundsTableTableOrderingComposer(
              $db: $db,
              $table: $db.sinkingFundsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FundMovementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FundMovementsTableTable> {
  $$FundMovementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get movementDate => $composableBuilder(
      column: $table.movementDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SinkingFundsTableTableAnnotationComposer get fundId {
    final $$SinkingFundsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.fundId,
            referencedTable: $db.sinkingFundsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SinkingFundsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.sinkingFundsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$FundMovementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FundMovementsTableTable,
    FundMovementsTableData,
    $$FundMovementsTableTableFilterComposer,
    $$FundMovementsTableTableOrderingComposer,
    $$FundMovementsTableTableAnnotationComposer,
    $$FundMovementsTableTableCreateCompanionBuilder,
    $$FundMovementsTableTableUpdateCompanionBuilder,
    (FundMovementsTableData, $$FundMovementsTableTableReferences),
    FundMovementsTableData,
    PrefetchHooks Function({bool fundId})> {
  $$FundMovementsTableTableTableManager(
      _$AppDatabase db, $FundMovementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FundMovementsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FundMovementsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FundMovementsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fundId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<DateTime> movementDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FundMovementsTableCompanion(
            id: id,
            fundId: fundId,
            type: type,
            amountPaise: amountPaise,
            movementDate: movementDate,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fundId,
            required String type,
            required int amountPaise,
            required DateTime movementDate,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FundMovementsTableCompanion.insert(
            id: id,
            fundId: fundId,
            type: type,
            amountPaise: amountPaise,
            movementDate: movementDate,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FundMovementsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (fundId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fundId,
                    referencedTable:
                        $$FundMovementsTableTableReferences._fundIdTable(db),
                    referencedColumn:
                        $$FundMovementsTableTableReferences._fundIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FundMovementsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FundMovementsTableTable,
    FundMovementsTableData,
    $$FundMovementsTableTableFilterComposer,
    $$FundMovementsTableTableOrderingComposer,
    $$FundMovementsTableTableAnnotationComposer,
    $$FundMovementsTableTableCreateCompanionBuilder,
    $$FundMovementsTableTableUpdateCompanionBuilder,
    (FundMovementsTableData, $$FundMovementsTableTableReferences),
    FundMovementsTableData,
    PrefetchHooks Function({bool fundId})>;
typedef $$SavingGoalsTableTableCreateCompanionBuilder
    = SavingGoalsTableCompanion Function({
  required String id,
  required String householdId,
  required String bucket,
  required String name,
  Value<int?> targetPaise,
  Value<int> monthlyBudgetPaise,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $$SavingGoalsTableTableUpdateCompanionBuilder
    = SavingGoalsTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> bucket,
  Value<String> name,
  Value<int?> targetPaise,
  Value<int> monthlyBudgetPaise,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

final class $$SavingGoalsTableTableReferences extends BaseReferences<
    _$AppDatabase, $SavingGoalsTableTable, SavingGoalsTableData> {
  $$SavingGoalsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GoalContributionsTableTable,
      List<GoalContributionsTableData>> _goalContributionsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goalContributionsTable,
          aliasName: $_aliasNameGenerator(
              db.savingGoalsTable.id, db.goalContributionsTable.goalId));

  $$GoalContributionsTableTableProcessedTableManager
      get goalContributionsTableRefs {
    final manager = $$GoalContributionsTableTableTableManager(
            $_db, $_db.goalContributionsTable)
        .filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_goalContributionsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SavingGoalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SavingGoalsTableTable> {
  $$SavingGoalsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetPaise => $composableBuilder(
      column: $table.targetPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get monthlyBudgetPaise => $composableBuilder(
      column: $table.monthlyBudgetPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> goalContributionsTableRefs(
      Expression<bool> Function($$GoalContributionsTableTableFilterComposer f)
          f) {
    final $$GoalContributionsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.goalContributionsTable,
            getReferencedColumn: (t) => t.goalId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$GoalContributionsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.goalContributionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SavingGoalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingGoalsTableTable> {
  $$SavingGoalsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetPaise => $composableBuilder(
      column: $table.targetPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get monthlyBudgetPaise => $composableBuilder(
      column: $table.monthlyBudgetPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavingGoalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingGoalsTableTable> {
  $$SavingGoalsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetPaise => $composableBuilder(
      column: $table.targetPaise, builder: (column) => column);

  GeneratedColumn<int> get monthlyBudgetPaise => $composableBuilder(
      column: $table.monthlyBudgetPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  Expression<T> goalContributionsTableRefs<T extends Object>(
      Expression<T> Function($$GoalContributionsTableTableAnnotationComposer a)
          f) {
    final $$GoalContributionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.goalContributionsTable,
            getReferencedColumn: (t) => t.goalId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$GoalContributionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.goalContributionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SavingGoalsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingGoalsTableTable,
    SavingGoalsTableData,
    $$SavingGoalsTableTableFilterComposer,
    $$SavingGoalsTableTableOrderingComposer,
    $$SavingGoalsTableTableAnnotationComposer,
    $$SavingGoalsTableTableCreateCompanionBuilder,
    $$SavingGoalsTableTableUpdateCompanionBuilder,
    (SavingGoalsTableData, $$SavingGoalsTableTableReferences),
    SavingGoalsTableData,
    PrefetchHooks Function({bool goalContributionsTableRefs})> {
  $$SavingGoalsTableTableTableManager(
      _$AppDatabase db, $SavingGoalsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingGoalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingGoalsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingGoalsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> bucket = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> targetPaise = const Value.absent(),
            Value<int> monthlyBudgetPaise = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingGoalsTableCompanion(
            id: id,
            householdId: householdId,
            bucket: bucket,
            name: name,
            targetPaise: targetPaise,
            monthlyBudgetPaise: monthlyBudgetPaise,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String bucket,
            required String name,
            Value<int?> targetPaise = const Value.absent(),
            Value<int> monthlyBudgetPaise = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavingGoalsTableCompanion.insert(
            id: id,
            householdId: householdId,
            bucket: bucket,
            name: name,
            targetPaise: targetPaise,
            monthlyBudgetPaise: monthlyBudgetPaise,
            archivedAt: archivedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SavingGoalsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({goalContributionsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (goalContributionsTableRefs) db.goalContributionsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (goalContributionsTableRefs)
                    await $_getPrefetchedData<SavingGoalsTableData,
                            $SavingGoalsTableTable, GoalContributionsTableData>(
                        currentTable: table,
                        referencedTable: $$SavingGoalsTableTableReferences
                            ._goalContributionsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SavingGoalsTableTableReferences(db, table, p0)
                                .goalContributionsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.goalId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SavingGoalsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavingGoalsTableTable,
    SavingGoalsTableData,
    $$SavingGoalsTableTableFilterComposer,
    $$SavingGoalsTableTableOrderingComposer,
    $$SavingGoalsTableTableAnnotationComposer,
    $$SavingGoalsTableTableCreateCompanionBuilder,
    $$SavingGoalsTableTableUpdateCompanionBuilder,
    (SavingGoalsTableData, $$SavingGoalsTableTableReferences),
    SavingGoalsTableData,
    PrefetchHooks Function({bool goalContributionsTableRefs})>;
typedef $$GoalContributionsTableTableCreateCompanionBuilder
    = GoalContributionsTableCompanion Function({
  required String id,
  required String goalId,
  required int amountPaise,
  required DateTime contributionDate,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$GoalContributionsTableTableUpdateCompanionBuilder
    = GoalContributionsTableCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<int> amountPaise,
  Value<DateTime> contributionDate,
  Value<String?> note,
  Value<int> rowid,
});

final class $$GoalContributionsTableTableReferences extends BaseReferences<
    _$AppDatabase, $GoalContributionsTableTable, GoalContributionsTableData> {
  $$GoalContributionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SavingGoalsTableTable _goalIdTable(_$AppDatabase db) =>
      db.savingGoalsTable.createAlias($_aliasNameGenerator(
          db.goalContributionsTable.goalId, db.savingGoalsTable.id));

  $$SavingGoalsTableTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager =
        $$SavingGoalsTableTableTableManager($_db, $_db.savingGoalsTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalContributionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GoalContributionsTableTable> {
  $$GoalContributionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get contributionDate => $composableBuilder(
      column: $table.contributionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$SavingGoalsTableTableFilterComposer get goalId {
    final $$SavingGoalsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.savingGoalsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavingGoalsTableTableFilterComposer(
              $db: $db,
              $table: $db.savingGoalsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalContributionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalContributionsTableTable> {
  $$GoalContributionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get contributionDate => $composableBuilder(
      column: $table.contributionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$SavingGoalsTableTableOrderingComposer get goalId {
    final $$SavingGoalsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.savingGoalsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavingGoalsTableTableOrderingComposer(
              $db: $db,
              $table: $db.savingGoalsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalContributionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalContributionsTableTable> {
  $$GoalContributionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get contributionDate => $composableBuilder(
      column: $table.contributionDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SavingGoalsTableTableAnnotationComposer get goalId {
    final $$SavingGoalsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.savingGoalsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavingGoalsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.savingGoalsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalContributionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalContributionsTableTable,
    GoalContributionsTableData,
    $$GoalContributionsTableTableFilterComposer,
    $$GoalContributionsTableTableOrderingComposer,
    $$GoalContributionsTableTableAnnotationComposer,
    $$GoalContributionsTableTableCreateCompanionBuilder,
    $$GoalContributionsTableTableUpdateCompanionBuilder,
    (GoalContributionsTableData, $$GoalContributionsTableTableReferences),
    GoalContributionsTableData,
    PrefetchHooks Function({bool goalId})> {
  $$GoalContributionsTableTableTableManager(
      _$AppDatabase db, $GoalContributionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalContributionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalContributionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalContributionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> goalId = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<DateTime> contributionDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalContributionsTableCompanion(
            id: id,
            goalId: goalId,
            amountPaise: amountPaise,
            contributionDate: contributionDate,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String goalId,
            required int amountPaise,
            required DateTime contributionDate,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalContributionsTableCompanion.insert(
            id: id,
            goalId: goalId,
            amountPaise: amountPaise,
            contributionDate: contributionDate,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GoalContributionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (goalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.goalId,
                    referencedTable: $$GoalContributionsTableTableReferences
                        ._goalIdTable(db),
                    referencedColumn: $$GoalContributionsTableTableReferences
                        ._goalIdTable(db)
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
        ));
}

typedef $$GoalContributionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $GoalContributionsTableTable,
        GoalContributionsTableData,
        $$GoalContributionsTableTableFilterComposer,
        $$GoalContributionsTableTableOrderingComposer,
        $$GoalContributionsTableTableAnnotationComposer,
        $$GoalContributionsTableTableCreateCompanionBuilder,
        $$GoalContributionsTableTableUpdateCompanionBuilder,
        (GoalContributionsTableData, $$GoalContributionsTableTableReferences),
        GoalContributionsTableData,
        PrefetchHooks Function({bool goalId})>;
typedef $$CreditCardsTableTableCreateCompanionBuilder
    = CreditCardsTableCompanion Function({
  required String id,
  required String householdId,
  required String name,
  Value<int> previousOutstandingPaise,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$CreditCardsTableTableUpdateCompanionBuilder
    = CreditCardsTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<int> previousOutstandingPaise,
  Value<bool> isActive,
  Value<int> rowid,
});

final class $$CreditCardsTableTableReferences extends BaseReferences<
    _$AppDatabase, $CreditCardsTableTable, CreditCardsTableData> {
  $$CreditCardsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CardTransactionsTableTable,
      List<CardTransactionsTableData>> _cardTransactionsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.cardTransactionsTable,
          aliasName: $_aliasNameGenerator(
              db.creditCardsTable.id, db.cardTransactionsTable.cardId));

  $$CardTransactionsTableTableProcessedTableManager
      get cardTransactionsTableRefs {
    final manager = $$CardTransactionsTableTableTableManager(
            $_db, $_db.cardTransactionsTable)
        .filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_cardTransactionsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CreditCardsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardsTableTable> {
  $$CreditCardsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get previousOutstandingPaise => $composableBuilder(
      column: $table.previousOutstandingPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  Expression<bool> cardTransactionsTableRefs(
      Expression<bool> Function($$CardTransactionsTableTableFilterComposer f)
          f) {
    final $$CardTransactionsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.cardTransactionsTable,
            getReferencedColumn: (t) => t.cardId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CardTransactionsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.cardTransactionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CreditCardsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardsTableTable> {
  $$CreditCardsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get previousOutstandingPaise => $composableBuilder(
      column: $table.previousOutstandingPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$CreditCardsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardsTableTable> {
  $$CreditCardsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get previousOutstandingPaise => $composableBuilder(
      column: $table.previousOutstandingPaise, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> cardTransactionsTableRefs<T extends Object>(
      Expression<T> Function($$CardTransactionsTableTableAnnotationComposer a)
          f) {
    final $$CardTransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.cardTransactionsTable,
            getReferencedColumn: (t) => t.cardId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CardTransactionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.cardTransactionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CreditCardsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CreditCardsTableTable,
    CreditCardsTableData,
    $$CreditCardsTableTableFilterComposer,
    $$CreditCardsTableTableOrderingComposer,
    $$CreditCardsTableTableAnnotationComposer,
    $$CreditCardsTableTableCreateCompanionBuilder,
    $$CreditCardsTableTableUpdateCompanionBuilder,
    (CreditCardsTableData, $$CreditCardsTableTableReferences),
    CreditCardsTableData,
    PrefetchHooks Function({bool cardTransactionsTableRefs})> {
  $$CreditCardsTableTableTableManager(
      _$AppDatabase db, $CreditCardsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditCardsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditCardsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> previousOutstandingPaise = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CreditCardsTableCompanion(
            id: id,
            householdId: householdId,
            name: name,
            previousOutstandingPaise: previousOutstandingPaise,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            Value<int> previousOutstandingPaise = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CreditCardsTableCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            previousOutstandingPaise: previousOutstandingPaise,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CreditCardsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardTransactionsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cardTransactionsTableRefs) db.cardTransactionsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardTransactionsTableRefs)
                    await $_getPrefetchedData<CreditCardsTableData,
                            $CreditCardsTableTable, CardTransactionsTableData>(
                        currentTable: table,
                        referencedTable: $$CreditCardsTableTableReferences
                            ._cardTransactionsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CreditCardsTableTableReferences(db, table, p0)
                                .cardTransactionsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CreditCardsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CreditCardsTableTable,
    CreditCardsTableData,
    $$CreditCardsTableTableFilterComposer,
    $$CreditCardsTableTableOrderingComposer,
    $$CreditCardsTableTableAnnotationComposer,
    $$CreditCardsTableTableCreateCompanionBuilder,
    $$CreditCardsTableTableUpdateCompanionBuilder,
    (CreditCardsTableData, $$CreditCardsTableTableReferences),
    CreditCardsTableData,
    PrefetchHooks Function({bool cardTransactionsTableRefs})>;
typedef $$CardTransactionsTableTableCreateCompanionBuilder
    = CardTransactionsTableCompanion Function({
  required String id,
  required String cardId,
  required DateTime txnDate,
  required String description,
  required int amountPaise,
  Value<int?> sNo,
  Value<int> rowid,
});
typedef $$CardTransactionsTableTableUpdateCompanionBuilder
    = CardTransactionsTableCompanion Function({
  Value<String> id,
  Value<String> cardId,
  Value<DateTime> txnDate,
  Value<String> description,
  Value<int> amountPaise,
  Value<int?> sNo,
  Value<int> rowid,
});

final class $$CardTransactionsTableTableReferences extends BaseReferences<
    _$AppDatabase, $CardTransactionsTableTable, CardTransactionsTableData> {
  $$CardTransactionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CreditCardsTableTable _cardIdTable(_$AppDatabase db) =>
      db.creditCardsTable.createAlias($_aliasNameGenerator(
          db.cardTransactionsTable.cardId, db.creditCardsTable.id));

  $$CreditCardsTableTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager =
        $$CreditCardsTableTableTableManager($_db, $_db.creditCardsTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CardTransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CardTransactionsTableTable> {
  $$CardTransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get txnDate => $composableBuilder(
      column: $table.txnDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sNo => $composableBuilder(
      column: $table.sNo, builder: (column) => ColumnFilters(column));

  $$CreditCardsTableTableFilterComposer get cardId {
    final $$CreditCardsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.creditCardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CreditCardsTableTableFilterComposer(
              $db: $db,
              $table: $db.creditCardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardTransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CardTransactionsTableTable> {
  $$CardTransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get txnDate => $composableBuilder(
      column: $table.txnDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sNo => $composableBuilder(
      column: $table.sNo, builder: (column) => ColumnOrderings(column));

  $$CreditCardsTableTableOrderingComposer get cardId {
    final $$CreditCardsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.creditCardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CreditCardsTableTableOrderingComposer(
              $db: $db,
              $table: $db.creditCardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardTransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardTransactionsTableTable> {
  $$CardTransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get txnDate =>
      $composableBuilder(column: $table.txnDate, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<int> get sNo =>
      $composableBuilder(column: $table.sNo, builder: (column) => column);

  $$CreditCardsTableTableAnnotationComposer get cardId {
    final $$CreditCardsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.creditCardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CreditCardsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.creditCardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardTransactionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardTransactionsTableTable,
    CardTransactionsTableData,
    $$CardTransactionsTableTableFilterComposer,
    $$CardTransactionsTableTableOrderingComposer,
    $$CardTransactionsTableTableAnnotationComposer,
    $$CardTransactionsTableTableCreateCompanionBuilder,
    $$CardTransactionsTableTableUpdateCompanionBuilder,
    (CardTransactionsTableData, $$CardTransactionsTableTableReferences),
    CardTransactionsTableData,
    PrefetchHooks Function({bool cardId})> {
  $$CardTransactionsTableTableTableManager(
      _$AppDatabase db, $CardTransactionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardTransactionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CardTransactionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardTransactionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<DateTime> txnDate = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<int?> sNo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardTransactionsTableCompanion(
            id: id,
            cardId: cardId,
            txnDate: txnDate,
            description: description,
            amountPaise: amountPaise,
            sNo: sNo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String cardId,
            required DateTime txnDate,
            required String description,
            required int amountPaise,
            Value<int?> sNo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardTransactionsTableCompanion.insert(
            id: id,
            cardId: cardId,
            txnDate: txnDate,
            description: description,
            amountPaise: amountPaise,
            sNo: sNo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CardTransactionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (cardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardId,
                    referencedTable:
                        $$CardTransactionsTableTableReferences._cardIdTable(db),
                    referencedColumn: $$CardTransactionsTableTableReferences
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
        ));
}

typedef $$CardTransactionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CardTransactionsTableTable,
        CardTransactionsTableData,
        $$CardTransactionsTableTableFilterComposer,
        $$CardTransactionsTableTableOrderingComposer,
        $$CardTransactionsTableTableAnnotationComposer,
        $$CardTransactionsTableTableCreateCompanionBuilder,
        $$CardTransactionsTableTableUpdateCompanionBuilder,
        (CardTransactionsTableData, $$CardTransactionsTableTableReferences),
        CardTransactionsTableData,
        PrefetchHooks Function({bool cardId})>;
typedef $$ReceivablesTableTableCreateCompanionBuilder
    = ReceivablesTableCompanion Function({
  required String id,
  required String householdId,
  required String personName,
  required int amountPaise,
  Value<String> status,
  Value<DateTime?> dueDate,
  Value<String?> entryId,
  Value<int> rowid,
});
typedef $$ReceivablesTableTableUpdateCompanionBuilder
    = ReceivablesTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> personName,
  Value<int> amountPaise,
  Value<String> status,
  Value<DateTime?> dueDate,
  Value<String?> entryId,
  Value<int> rowid,
});

class $$ReceivablesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReceivablesTableTable> {
  $$ReceivablesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnFilters(column));
}

class $$ReceivablesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceivablesTableTable> {
  $$ReceivablesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnOrderings(column));
}

class $$ReceivablesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceivablesTableTable> {
  $$ReceivablesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
      column: $table.personName, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);
}

class $$ReceivablesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReceivablesTableTable,
    ReceivablesTableData,
    $$ReceivablesTableTableFilterComposer,
    $$ReceivablesTableTableOrderingComposer,
    $$ReceivablesTableTableAnnotationComposer,
    $$ReceivablesTableTableCreateCompanionBuilder,
    $$ReceivablesTableTableUpdateCompanionBuilder,
    (
      ReceivablesTableData,
      BaseReferences<_$AppDatabase, $ReceivablesTableTable,
          ReceivablesTableData>
    ),
    ReceivablesTableData,
    PrefetchHooks Function()> {
  $$ReceivablesTableTableTableManager(
      _$AppDatabase db, $ReceivablesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceivablesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceivablesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceivablesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> personName = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String?> entryId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceivablesTableCompanion(
            id: id,
            householdId: householdId,
            personName: personName,
            amountPaise: amountPaise,
            status: status,
            dueDate: dueDate,
            entryId: entryId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String personName,
            required int amountPaise,
            Value<String> status = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String?> entryId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceivablesTableCompanion.insert(
            id: id,
            householdId: householdId,
            personName: personName,
            amountPaise: amountPaise,
            status: status,
            dueDate: dueDate,
            entryId: entryId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReceivablesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReceivablesTableTable,
    ReceivablesTableData,
    $$ReceivablesTableTableFilterComposer,
    $$ReceivablesTableTableOrderingComposer,
    $$ReceivablesTableTableAnnotationComposer,
    $$ReceivablesTableTableCreateCompanionBuilder,
    $$ReceivablesTableTableUpdateCompanionBuilder,
    (
      ReceivablesTableData,
      BaseReferences<_$AppDatabase, $ReceivablesTableTable,
          ReceivablesTableData>
    ),
    ReceivablesTableData,
    PrefetchHooks Function()>;
typedef $$PlannedBillsTableTableCreateCompanionBuilder
    = PlannedBillsTableCompanion Function({
  required String id,
  required String householdId,
  required String name,
  required int amountPaise,
  Value<DateTime?> dueDate,
  Value<bool> isPaid,
  Value<String?> entryId,
  Value<int> rowid,
});
typedef $$PlannedBillsTableTableUpdateCompanionBuilder
    = PlannedBillsTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> name,
  Value<int> amountPaise,
  Value<DateTime?> dueDate,
  Value<bool> isPaid,
  Value<String?> entryId,
  Value<int> rowid,
});

class $$PlannedBillsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedBillsTableTable> {
  $$PlannedBillsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPaid => $composableBuilder(
      column: $table.isPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnFilters(column));
}

class $$PlannedBillsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedBillsTableTable> {
  $$PlannedBillsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPaid => $composableBuilder(
      column: $table.isPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryId => $composableBuilder(
      column: $table.entryId, builder: (column) => ColumnOrderings(column));
}

class $$PlannedBillsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedBillsTableTable> {
  $$PlannedBillsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);
}

class $$PlannedBillsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlannedBillsTableTable,
    PlannedBillsTableData,
    $$PlannedBillsTableTableFilterComposer,
    $$PlannedBillsTableTableOrderingComposer,
    $$PlannedBillsTableTableAnnotationComposer,
    $$PlannedBillsTableTableCreateCompanionBuilder,
    $$PlannedBillsTableTableUpdateCompanionBuilder,
    (
      PlannedBillsTableData,
      BaseReferences<_$AppDatabase, $PlannedBillsTableTable,
          PlannedBillsTableData>
    ),
    PlannedBillsTableData,
    PrefetchHooks Function()> {
  $$PlannedBillsTableTableTableManager(
      _$AppDatabase db, $PlannedBillsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedBillsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedBillsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedBillsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<String?> entryId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlannedBillsTableCompanion(
            id: id,
            householdId: householdId,
            name: name,
            amountPaise: amountPaise,
            dueDate: dueDate,
            isPaid: isPaid,
            entryId: entryId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String name,
            required int amountPaise,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<String?> entryId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlannedBillsTableCompanion.insert(
            id: id,
            householdId: householdId,
            name: name,
            amountPaise: amountPaise,
            dueDate: dueDate,
            isPaid: isPaid,
            entryId: entryId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlannedBillsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlannedBillsTableTable,
    PlannedBillsTableData,
    $$PlannedBillsTableTableFilterComposer,
    $$PlannedBillsTableTableOrderingComposer,
    $$PlannedBillsTableTableAnnotationComposer,
    $$PlannedBillsTableTableCreateCompanionBuilder,
    $$PlannedBillsTableTableUpdateCompanionBuilder,
    (
      PlannedBillsTableData,
      BaseReferences<_$AppDatabase, $PlannedBillsTableTable,
          PlannedBillsTableData>
    ),
    PlannedBillsTableData,
    PrefetchHooks Function()>;
typedef $$ReserveLinesTableTableCreateCompanionBuilder
    = ReserveLinesTableCompanion Function({
  required String id,
  required String householdId,
  required String yearMonth,
  required String name,
  required int amountPaise,
  Value<String> source,
  Value<int> rowid,
});
typedef $$ReserveLinesTableTableUpdateCompanionBuilder
    = ReserveLinesTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> yearMonth,
  Value<String> name,
  Value<int> amountPaise,
  Value<String> source,
  Value<int> rowid,
});

class $$ReserveLinesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReserveLinesTableTable> {
  $$ReserveLinesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$ReserveLinesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReserveLinesTableTable> {
  $$ReserveLinesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$ReserveLinesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReserveLinesTableTable> {
  $$ReserveLinesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$ReserveLinesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReserveLinesTableTable,
    ReserveLinesTableData,
    $$ReserveLinesTableTableFilterComposer,
    $$ReserveLinesTableTableOrderingComposer,
    $$ReserveLinesTableTableAnnotationComposer,
    $$ReserveLinesTableTableCreateCompanionBuilder,
    $$ReserveLinesTableTableUpdateCompanionBuilder,
    (
      ReserveLinesTableData,
      BaseReferences<_$AppDatabase, $ReserveLinesTableTable,
          ReserveLinesTableData>
    ),
    ReserveLinesTableData,
    PrefetchHooks Function()> {
  $$ReserveLinesTableTableTableManager(
      _$AppDatabase db, $ReserveLinesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReserveLinesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReserveLinesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReserveLinesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> yearMonth = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReserveLinesTableCompanion(
            id: id,
            householdId: householdId,
            yearMonth: yearMonth,
            name: name,
            amountPaise: amountPaise,
            source: source,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String yearMonth,
            required String name,
            required int amountPaise,
            Value<String> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReserveLinesTableCompanion.insert(
            id: id,
            householdId: householdId,
            yearMonth: yearMonth,
            name: name,
            amountPaise: amountPaise,
            source: source,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReserveLinesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReserveLinesTableTable,
    ReserveLinesTableData,
    $$ReserveLinesTableTableFilterComposer,
    $$ReserveLinesTableTableOrderingComposer,
    $$ReserveLinesTableTableAnnotationComposer,
    $$ReserveLinesTableTableCreateCompanionBuilder,
    $$ReserveLinesTableTableUpdateCompanionBuilder,
    (
      ReserveLinesTableData,
      BaseReferences<_$AppDatabase, $ReserveLinesTableTable,
          ReserveLinesTableData>
    ),
    ReserveLinesTableData,
    PrefetchHooks Function()>;
typedef $$MonthSnapshotsTableTableCreateCompanionBuilder
    = MonthSnapshotsTableCompanion Function({
  required String id,
  required String householdId,
  required String yearMonth,
  Value<int> openingBalancePaise,
  Value<int> lastMonthReservesPaise,
  Value<int> incomePaise,
  Value<int> adjustmentsPaise,
  Value<int> spendingPaise,
  Value<int> protectionPaise,
  Value<int> savingPaise,
  Value<int> reservesPaise,
  Value<int> closingBalancePaise,
  Value<int> remainingPaise,
  Value<String> status,
  Value<DateTime?> closedAt,
  Value<int> rowid,
});
typedef $$MonthSnapshotsTableTableUpdateCompanionBuilder
    = MonthSnapshotsTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> yearMonth,
  Value<int> openingBalancePaise,
  Value<int> lastMonthReservesPaise,
  Value<int> incomePaise,
  Value<int> adjustmentsPaise,
  Value<int> spendingPaise,
  Value<int> protectionPaise,
  Value<int> savingPaise,
  Value<int> reservesPaise,
  Value<int> closingBalancePaise,
  Value<int> remainingPaise,
  Value<String> status,
  Value<DateTime?> closedAt,
  Value<int> rowid,
});

class $$MonthSnapshotsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MonthSnapshotsTableTable> {
  $$MonthSnapshotsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingBalancePaise => $composableBuilder(
      column: $table.openingBalancePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastMonthReservesPaise => $composableBuilder(
      column: $table.lastMonthReservesPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incomePaise => $composableBuilder(
      column: $table.incomePaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get adjustmentsPaise => $composableBuilder(
      column: $table.adjustmentsPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get spendingPaise => $composableBuilder(
      column: $table.spendingPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get protectionPaise => $composableBuilder(
      column: $table.protectionPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get savingPaise => $composableBuilder(
      column: $table.savingPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reservesPaise => $composableBuilder(
      column: $table.reservesPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get closingBalancePaise => $composableBuilder(
      column: $table.closingBalancePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remainingPaise => $composableBuilder(
      column: $table.remainingPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));
}

class $$MonthSnapshotsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthSnapshotsTableTable> {
  $$MonthSnapshotsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingBalancePaise => $composableBuilder(
      column: $table.openingBalancePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastMonthReservesPaise => $composableBuilder(
      column: $table.lastMonthReservesPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incomePaise => $composableBuilder(
      column: $table.incomePaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get adjustmentsPaise => $composableBuilder(
      column: $table.adjustmentsPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spendingPaise => $composableBuilder(
      column: $table.spendingPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get protectionPaise => $composableBuilder(
      column: $table.protectionPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get savingPaise => $composableBuilder(
      column: $table.savingPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reservesPaise => $composableBuilder(
      column: $table.reservesPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get closingBalancePaise => $composableBuilder(
      column: $table.closingBalancePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remainingPaise => $composableBuilder(
      column: $table.remainingPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));
}

class $$MonthSnapshotsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthSnapshotsTableTable> {
  $$MonthSnapshotsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get openingBalancePaise => $composableBuilder(
      column: $table.openingBalancePaise, builder: (column) => column);

  GeneratedColumn<int> get lastMonthReservesPaise => $composableBuilder(
      column: $table.lastMonthReservesPaise, builder: (column) => column);

  GeneratedColumn<int> get incomePaise => $composableBuilder(
      column: $table.incomePaise, builder: (column) => column);

  GeneratedColumn<int> get adjustmentsPaise => $composableBuilder(
      column: $table.adjustmentsPaise, builder: (column) => column);

  GeneratedColumn<int> get spendingPaise => $composableBuilder(
      column: $table.spendingPaise, builder: (column) => column);

  GeneratedColumn<int> get protectionPaise => $composableBuilder(
      column: $table.protectionPaise, builder: (column) => column);

  GeneratedColumn<int> get savingPaise => $composableBuilder(
      column: $table.savingPaise, builder: (column) => column);

  GeneratedColumn<int> get reservesPaise => $composableBuilder(
      column: $table.reservesPaise, builder: (column) => column);

  GeneratedColumn<int> get closingBalancePaise => $composableBuilder(
      column: $table.closingBalancePaise, builder: (column) => column);

  GeneratedColumn<int> get remainingPaise => $composableBuilder(
      column: $table.remainingPaise, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);
}

class $$MonthSnapshotsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MonthSnapshotsTableTable,
    MonthSnapshotsTableData,
    $$MonthSnapshotsTableTableFilterComposer,
    $$MonthSnapshotsTableTableOrderingComposer,
    $$MonthSnapshotsTableTableAnnotationComposer,
    $$MonthSnapshotsTableTableCreateCompanionBuilder,
    $$MonthSnapshotsTableTableUpdateCompanionBuilder,
    (
      MonthSnapshotsTableData,
      BaseReferences<_$AppDatabase, $MonthSnapshotsTableTable,
          MonthSnapshotsTableData>
    ),
    MonthSnapshotsTableData,
    PrefetchHooks Function()> {
  $$MonthSnapshotsTableTableTableManager(
      _$AppDatabase db, $MonthSnapshotsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthSnapshotsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthSnapshotsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthSnapshotsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> yearMonth = const Value.absent(),
            Value<int> openingBalancePaise = const Value.absent(),
            Value<int> lastMonthReservesPaise = const Value.absent(),
            Value<int> incomePaise = const Value.absent(),
            Value<int> adjustmentsPaise = const Value.absent(),
            Value<int> spendingPaise = const Value.absent(),
            Value<int> protectionPaise = const Value.absent(),
            Value<int> savingPaise = const Value.absent(),
            Value<int> reservesPaise = const Value.absent(),
            Value<int> closingBalancePaise = const Value.absent(),
            Value<int> remainingPaise = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MonthSnapshotsTableCompanion(
            id: id,
            householdId: householdId,
            yearMonth: yearMonth,
            openingBalancePaise: openingBalancePaise,
            lastMonthReservesPaise: lastMonthReservesPaise,
            incomePaise: incomePaise,
            adjustmentsPaise: adjustmentsPaise,
            spendingPaise: spendingPaise,
            protectionPaise: protectionPaise,
            savingPaise: savingPaise,
            reservesPaise: reservesPaise,
            closingBalancePaise: closingBalancePaise,
            remainingPaise: remainingPaise,
            status: status,
            closedAt: closedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String yearMonth,
            Value<int> openingBalancePaise = const Value.absent(),
            Value<int> lastMonthReservesPaise = const Value.absent(),
            Value<int> incomePaise = const Value.absent(),
            Value<int> adjustmentsPaise = const Value.absent(),
            Value<int> spendingPaise = const Value.absent(),
            Value<int> protectionPaise = const Value.absent(),
            Value<int> savingPaise = const Value.absent(),
            Value<int> reservesPaise = const Value.absent(),
            Value<int> closingBalancePaise = const Value.absent(),
            Value<int> remainingPaise = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MonthSnapshotsTableCompanion.insert(
            id: id,
            householdId: householdId,
            yearMonth: yearMonth,
            openingBalancePaise: openingBalancePaise,
            lastMonthReservesPaise: lastMonthReservesPaise,
            incomePaise: incomePaise,
            adjustmentsPaise: adjustmentsPaise,
            spendingPaise: spendingPaise,
            protectionPaise: protectionPaise,
            savingPaise: savingPaise,
            reservesPaise: reservesPaise,
            closingBalancePaise: closingBalancePaise,
            remainingPaise: remainingPaise,
            status: status,
            closedAt: closedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MonthSnapshotsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MonthSnapshotsTableTable,
    MonthSnapshotsTableData,
    $$MonthSnapshotsTableTableFilterComposer,
    $$MonthSnapshotsTableTableOrderingComposer,
    $$MonthSnapshotsTableTableAnnotationComposer,
    $$MonthSnapshotsTableTableCreateCompanionBuilder,
    $$MonthSnapshotsTableTableUpdateCompanionBuilder,
    (
      MonthSnapshotsTableData,
      BaseReferences<_$AppDatabase, $MonthSnapshotsTableTable,
          MonthSnapshotsTableData>
    ),
    MonthSnapshotsTableData,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  required String id,
  required String op,
  required String entity,
  required String entityId,
  required String payload,
  required DateTime createdAt,
  Value<int> attempts,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<String> id,
  Value<String> op,
  Value<String> entity,
  Value<String> entityId,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> attempts,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$AppDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> op = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            op: op,
            entity: entity,
            entityId: entityId,
            payload: payload,
            createdAt: createdAt,
            attempts: attempts,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String op,
            required String entity,
            required String entityId,
            required String payload,
            required DateTime createdAt,
            Value<int> attempts = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            op: op,
            entity: entity,
            entityId: entityId,
            payload: payload,
            createdAt: createdAt,
            attempts: attempts,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;
typedef $$AnnualTargetsTableTableCreateCompanionBuilder
    = AnnualTargetsTableCompanion Function({
  required String id,
  required String householdId,
  required String title,
  required int targetPaise,
  Value<String> type,
  Value<int> rowid,
});
typedef $$AnnualTargetsTableTableUpdateCompanionBuilder
    = AnnualTargetsTableCompanion Function({
  Value<String> id,
  Value<String> householdId,
  Value<String> title,
  Value<int> targetPaise,
  Value<String> type,
  Value<int> rowid,
});

class $$AnnualTargetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AnnualTargetsTableTable> {
  $$AnnualTargetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetPaise => $composableBuilder(
      column: $table.targetPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));
}

class $$AnnualTargetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnualTargetsTableTable> {
  $$AnnualTargetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetPaise => $composableBuilder(
      column: $table.targetPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));
}

class $$AnnualTargetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnualTargetsTableTable> {
  $$AnnualTargetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetPaise => $composableBuilder(
      column: $table.targetPaise, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$AnnualTargetsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnnualTargetsTableTable,
    AnnualTargetsTableData,
    $$AnnualTargetsTableTableFilterComposer,
    $$AnnualTargetsTableTableOrderingComposer,
    $$AnnualTargetsTableTableAnnotationComposer,
    $$AnnualTargetsTableTableCreateCompanionBuilder,
    $$AnnualTargetsTableTableUpdateCompanionBuilder,
    (
      AnnualTargetsTableData,
      BaseReferences<_$AppDatabase, $AnnualTargetsTableTable,
          AnnualTargetsTableData>
    ),
    AnnualTargetsTableData,
    PrefetchHooks Function()> {
  $$AnnualTargetsTableTableTableManager(
      _$AppDatabase db, $AnnualTargetsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnualTargetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnualTargetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnualTargetsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> targetPaise = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnnualTargetsTableCompanion(
            id: id,
            householdId: householdId,
            title: title,
            targetPaise: targetPaise,
            type: type,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String householdId,
            required String title,
            required int targetPaise,
            Value<String> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnnualTargetsTableCompanion.insert(
            id: id,
            householdId: householdId,
            title: title,
            targetPaise: targetPaise,
            type: type,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnnualTargetsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnnualTargetsTableTable,
    AnnualTargetsTableData,
    $$AnnualTargetsTableTableFilterComposer,
    $$AnnualTargetsTableTableOrderingComposer,
    $$AnnualTargetsTableTableAnnotationComposer,
    $$AnnualTargetsTableTableCreateCompanionBuilder,
    $$AnnualTargetsTableTableUpdateCompanionBuilder,
    (
      AnnualTargetsTableData,
      BaseReferences<_$AppDatabase, $AnnualTargetsTableTable,
          AnnualTargetsTableData>
    ),
    AnnualTargetsTableData,
    PrefetchHooks Function()>;
typedef $$UsersTableTableCreateCompanionBuilder = UsersTableCompanion Function({
  required String id,
  required String email,
  Value<String?> password,
  required String displayName,
  required String householdId,
  Value<String> authProvider,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UsersTableTableUpdateCompanionBuilder = UsersTableCompanion Function({
  Value<String> id,
  Value<String> email,
  Value<String?> password,
  Value<String> displayName,
  Value<String> householdId,
  Value<String> authProvider,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authProvider => $composableBuilder(
      column: $table.authProvider, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authProvider => $composableBuilder(
      column: $table.authProvider,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get authProvider => $composableBuilder(
      column: $table.authProvider, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTableTable,
    UsersTableData,
    $$UsersTableTableFilterComposer,
    $$UsersTableTableOrderingComposer,
    $$UsersTableTableAnnotationComposer,
    $$UsersTableTableCreateCompanionBuilder,
    $$UsersTableTableUpdateCompanionBuilder,
    (
      UsersTableData,
      BaseReferences<_$AppDatabase, $UsersTableTable, UsersTableData>
    ),
    UsersTableData,
    PrefetchHooks Function()> {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> householdId = const Value.absent(),
            Value<String> authProvider = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersTableCompanion(
            id: id,
            email: email,
            password: password,
            displayName: displayName,
            householdId: householdId,
            authProvider: authProvider,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String email,
            Value<String?> password = const Value.absent(),
            required String displayName,
            required String householdId,
            Value<String> authProvider = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersTableCompanion.insert(
            id: id,
            email: email,
            password: password,
            displayName: displayName,
            householdId: householdId,
            authProvider: authProvider,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTableTable,
    UsersTableData,
    $$UsersTableTableFilterComposer,
    $$UsersTableTableOrderingComposer,
    $$UsersTableTableAnnotationComposer,
    $$UsersTableTableCreateCompanionBuilder,
    $$UsersTableTableUpdateCompanionBuilder,
    (
      UsersTableData,
      BaseReferences<_$AppDatabase, $UsersTableTable, UsersTableData>
    ),
    UsersTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableTableManager get accountsTable =>
      $$AccountsTableTableTableManager(_db, _db.accountsTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$BudgetsTableTableTableManager get budgetsTable =>
      $$BudgetsTableTableTableManager(_db, _db.budgetsTable);
  $$EntriesTableTableTableManager get entriesTable =>
      $$EntriesTableTableTableManager(_db, _db.entriesTable);
  $$SinkingFundsTableTableTableManager get sinkingFundsTable =>
      $$SinkingFundsTableTableTableManager(_db, _db.sinkingFundsTable);
  $$FundMovementsTableTableTableManager get fundMovementsTable =>
      $$FundMovementsTableTableTableManager(_db, _db.fundMovementsTable);
  $$SavingGoalsTableTableTableManager get savingGoalsTable =>
      $$SavingGoalsTableTableTableManager(_db, _db.savingGoalsTable);
  $$GoalContributionsTableTableTableManager get goalContributionsTable =>
      $$GoalContributionsTableTableTableManager(
          _db, _db.goalContributionsTable);
  $$CreditCardsTableTableTableManager get creditCardsTable =>
      $$CreditCardsTableTableTableManager(_db, _db.creditCardsTable);
  $$CardTransactionsTableTableTableManager get cardTransactionsTable =>
      $$CardTransactionsTableTableTableManager(_db, _db.cardTransactionsTable);
  $$ReceivablesTableTableTableManager get receivablesTable =>
      $$ReceivablesTableTableTableManager(_db, _db.receivablesTable);
  $$PlannedBillsTableTableTableManager get plannedBillsTable =>
      $$PlannedBillsTableTableTableManager(_db, _db.plannedBillsTable);
  $$ReserveLinesTableTableTableManager get reserveLinesTable =>
      $$ReserveLinesTableTableTableManager(_db, _db.reserveLinesTable);
  $$MonthSnapshotsTableTableTableManager get monthSnapshotsTable =>
      $$MonthSnapshotsTableTableTableManager(_db, _db.monthSnapshotsTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$AnnualTargetsTableTableTableManager get annualTargetsTable =>
      $$AnnualTargetsTableTableTableManager(_db, _db.annualTargetsTable);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
}

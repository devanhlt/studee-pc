// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalRelativePathMeta =
      const VerificationMeta('originalRelativePath');
  @override
  late final GeneratedColumn<String> originalRelativePath =
      GeneratedColumn<String>(
        'original_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _contentSha256Meta = const VerificationMeta(
    'contentSha256',
  );
  @override
  late final GeneratedColumn<String> contentSha256 = GeneratedColumn<String>(
    'content_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    originalRelativePath,
    contentSha256,
    pageCount,
    processingStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_relative_path')) {
      context.handle(
        _originalRelativePathMeta,
        originalRelativePath.isAcceptableOrUnknown(
          data['original_relative_path']!,
          _originalRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('content_sha256')) {
      context.handle(
        _contentSha256Meta,
        contentSha256.isAcceptableOrUnknown(
          data['content_sha256']!,
          _contentSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentSha256Meta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processingStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_relative_path'],
      ),
      contentSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_sha256'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final String id;
  final String type;
  final String title;
  final String? originalRelativePath;
  final String contentSha256;
  final int? pageCount;
  final String processingStatus;
  final int createdAt;
  final int updatedAt;
  const SourceRow({
    required this.id,
    required this.type,
    required this.title,
    this.originalRelativePath,
    required this.contentSha256,
    this.pageCount,
    required this.processingStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalRelativePath != null) {
      map['original_relative_path'] = Variable<String>(originalRelativePath);
    }
    map['content_sha256'] = Variable<String>(contentSha256);
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['processing_status'] = Variable<String>(processingStatus);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      originalRelativePath: originalRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalRelativePath),
      contentSha256: Value(contentSha256),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      processingStatus: Value(processingStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      originalRelativePath: serializer.fromJson<String?>(
        json['originalRelativePath'],
      ),
      contentSha256: serializer.fromJson<String>(json['contentSha256']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'originalRelativePath': serializer.toJson<String?>(originalRelativePath),
      'contentSha256': serializer.toJson<String>(contentSha256),
      'pageCount': serializer.toJson<int?>(pageCount),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SourceRow copyWith({
    String? id,
    String? type,
    String? title,
    Value<String?> originalRelativePath = const Value.absent(),
    String? contentSha256,
    Value<int?> pageCount = const Value.absent(),
    String? processingStatus,
    int? createdAt,
    int? updatedAt,
  }) => SourceRow(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    originalRelativePath: originalRelativePath.present
        ? originalRelativePath.value
        : this.originalRelativePath,
    contentSha256: contentSha256 ?? this.contentSha256,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    processingStatus: processingStatus ?? this.processingStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      originalRelativePath: data.originalRelativePath.present
          ? data.originalRelativePath.value
          : this.originalRelativePath,
      contentSha256: data.contentSha256.present
          ? data.contentSha256.value
          : this.contentSha256,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('originalRelativePath: $originalRelativePath, ')
          ..write('contentSha256: $contentSha256, ')
          ..write('pageCount: $pageCount, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    originalRelativePath,
    contentSha256,
    pageCount,
    processingStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.originalRelativePath == this.originalRelativePath &&
          other.contentSha256 == this.contentSha256 &&
          other.pageCount == this.pageCount &&
          other.processingStatus == this.processingStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> originalRelativePath;
  final Value<String> contentSha256;
  final Value<int?> pageCount;
  final Value<String> processingStatus;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.originalRelativePath = const Value.absent(),
    this.contentSha256 = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String type,
    required String title,
    this.originalRelativePath = const Value.absent(),
    required String contentSha256,
    this.pageCount = const Value.absent(),
    required String processingStatus,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       contentSha256 = Value(contentSha256),
       processingStatus = Value(processingStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SourceRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? originalRelativePath,
    Expression<String>? contentSha256,
    Expression<int>? pageCount,
    Expression<String>? processingStatus,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (originalRelativePath != null)
        'original_relative_path': originalRelativePath,
      if (contentSha256 != null) 'content_sha256': contentSha256,
      if (pageCount != null) 'page_count': pageCount,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? originalRelativePath,
    Value<String>? contentSha256,
    Value<int?>? pageCount,
    Value<String>? processingStatus,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      originalRelativePath: originalRelativePath ?? this.originalRelativePath,
      contentSha256: contentSha256 ?? this.contentSha256,
      pageCount: pageCount ?? this.pageCount,
      processingStatus: processingStatus ?? this.processingStatus,
      createdAt: createdAt ?? this.createdAt,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalRelativePath.present) {
      map['original_relative_path'] = Variable<String>(
        originalRelativePath.value,
      );
    }
    if (contentSha256.present) {
      map['content_sha256'] = Variable<String>(contentSha256.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('originalRelativePath: $originalRelativePath, ')
          ..write('contentSha256: $contentSha256, ')
          ..write('pageCount: $pageCount, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcePagesTable extends SourcePages
    with TableInfo<$SourcePagesTable, SourcePageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcePagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageRelativePathMeta = const VerificationMeta(
    'imageRelativePath',
  );
  @override
  late final GeneratedColumn<String> imageRelativePath =
      GeneratedColumn<String>(
        'image_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _textLayerMeta = const VerificationMeta(
    'textLayer',
  );
  @override
  late final GeneratedColumn<String> textLayer = GeneratedColumn<String>(
    'text_layer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawOcrRelativePathMeta =
      const VerificationMeta('rawOcrRelativePath');
  @override
  late final GeneratedColumn<String> rawOcrRelativePath =
      GeneratedColumn<String>(
        'raw_ocr_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _normalizedTextMeta = const VerificationMeta(
    'normalizedText',
  );
  @override
  late final GeneratedColumn<String> normalizedText = GeneratedColumn<String>(
    'normalized_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrEngineMeta = const VerificationMeta(
    'ocrEngine',
  );
  @override
  late final GeneratedColumn<String> ocrEngine = GeneratedColumn<String>(
    'ocr_engine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrModelVersionMeta = const VerificationMeta(
    'ocrModelVersion',
  );
  @override
  late final GeneratedColumn<String> ocrModelVersion = GeneratedColumn<String>(
    'ocr_model_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrConfidenceMeta = const VerificationMeta(
    'ocrConfidence',
  );
  @override
  late final GeneratedColumn<double> ocrConfidence = GeneratedColumn<double>(
    'ocr_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    pageNumber,
    imageRelativePath,
    textLayer,
    rawOcrRelativePath,
    normalizedText,
    ocrEngine,
    ocrModelVersion,
    ocrConfidence,
    processingStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourcePageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('image_relative_path')) {
      context.handle(
        _imageRelativePathMeta,
        imageRelativePath.isAcceptableOrUnknown(
          data['image_relative_path']!,
          _imageRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('text_layer')) {
      context.handle(
        _textLayerMeta,
        textLayer.isAcceptableOrUnknown(data['text_layer']!, _textLayerMeta),
      );
    }
    if (data.containsKey('raw_ocr_relative_path')) {
      context.handle(
        _rawOcrRelativePathMeta,
        rawOcrRelativePath.isAcceptableOrUnknown(
          data['raw_ocr_relative_path']!,
          _rawOcrRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('normalized_text')) {
      context.handle(
        _normalizedTextMeta,
        normalizedText.isAcceptableOrUnknown(
          data['normalized_text']!,
          _normalizedTextMeta,
        ),
      );
    }
    if (data.containsKey('ocr_engine')) {
      context.handle(
        _ocrEngineMeta,
        ocrEngine.isAcceptableOrUnknown(data['ocr_engine']!, _ocrEngineMeta),
      );
    }
    if (data.containsKey('ocr_model_version')) {
      context.handle(
        _ocrModelVersionMeta,
        ocrModelVersion.isAcceptableOrUnknown(
          data['ocr_model_version']!,
          _ocrModelVersionMeta,
        ),
      );
    }
    if (data.containsKey('ocr_confidence')) {
      context.handle(
        _ocrConfidenceMeta,
        ocrConfidence.isAcceptableOrUnknown(
          data['ocr_confidence']!,
          _ocrConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processingStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, pageNumber},
  ];
  @override
  SourcePageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourcePageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      imageRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_relative_path'],
      ),
      textLayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_layer'],
      ),
      rawOcrRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_ocr_relative_path'],
      ),
      normalizedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_text'],
      ),
      ocrEngine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_engine'],
      ),
      ocrModelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_model_version'],
      ),
      ocrConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ocr_confidence'],
      ),
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
    );
  }

  @override
  $SourcePagesTable createAlias(String alias) {
    return $SourcePagesTable(attachedDatabase, alias);
  }
}

class SourcePageRow extends DataClass implements Insertable<SourcePageRow> {
  final String id;
  final String sourceId;
  final int pageNumber;
  final String? imageRelativePath;
  final String? textLayer;
  final String? rawOcrRelativePath;
  final String? normalizedText;
  final String? ocrEngine;
  final String? ocrModelVersion;
  final double? ocrConfidence;
  final String processingStatus;
  const SourcePageRow({
    required this.id,
    required this.sourceId,
    required this.pageNumber,
    this.imageRelativePath,
    this.textLayer,
    this.rawOcrRelativePath,
    this.normalizedText,
    this.ocrEngine,
    this.ocrModelVersion,
    this.ocrConfidence,
    required this.processingStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['page_number'] = Variable<int>(pageNumber);
    if (!nullToAbsent || imageRelativePath != null) {
      map['image_relative_path'] = Variable<String>(imageRelativePath);
    }
    if (!nullToAbsent || textLayer != null) {
      map['text_layer'] = Variable<String>(textLayer);
    }
    if (!nullToAbsent || rawOcrRelativePath != null) {
      map['raw_ocr_relative_path'] = Variable<String>(rawOcrRelativePath);
    }
    if (!nullToAbsent || normalizedText != null) {
      map['normalized_text'] = Variable<String>(normalizedText);
    }
    if (!nullToAbsent || ocrEngine != null) {
      map['ocr_engine'] = Variable<String>(ocrEngine);
    }
    if (!nullToAbsent || ocrModelVersion != null) {
      map['ocr_model_version'] = Variable<String>(ocrModelVersion);
    }
    if (!nullToAbsent || ocrConfidence != null) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence);
    }
    map['processing_status'] = Variable<String>(processingStatus);
    return map;
  }

  SourcePagesCompanion toCompanion(bool nullToAbsent) {
    return SourcePagesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      pageNumber: Value(pageNumber),
      imageRelativePath: imageRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageRelativePath),
      textLayer: textLayer == null && nullToAbsent
          ? const Value.absent()
          : Value(textLayer),
      rawOcrRelativePath: rawOcrRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(rawOcrRelativePath),
      normalizedText: normalizedText == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedText),
      ocrEngine: ocrEngine == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrEngine),
      ocrModelVersion: ocrModelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrModelVersion),
      ocrConfidence: ocrConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrConfidence),
      processingStatus: Value(processingStatus),
    );
  }

  factory SourcePageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourcePageRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      imageRelativePath: serializer.fromJson<String?>(
        json['imageRelativePath'],
      ),
      textLayer: serializer.fromJson<String?>(json['textLayer']),
      rawOcrRelativePath: serializer.fromJson<String?>(
        json['rawOcrRelativePath'],
      ),
      normalizedText: serializer.fromJson<String?>(json['normalizedText']),
      ocrEngine: serializer.fromJson<String?>(json['ocrEngine']),
      ocrModelVersion: serializer.fromJson<String?>(json['ocrModelVersion']),
      ocrConfidence: serializer.fromJson<double?>(json['ocrConfidence']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'imageRelativePath': serializer.toJson<String?>(imageRelativePath),
      'textLayer': serializer.toJson<String?>(textLayer),
      'rawOcrRelativePath': serializer.toJson<String?>(rawOcrRelativePath),
      'normalizedText': serializer.toJson<String?>(normalizedText),
      'ocrEngine': serializer.toJson<String?>(ocrEngine),
      'ocrModelVersion': serializer.toJson<String?>(ocrModelVersion),
      'ocrConfidence': serializer.toJson<double?>(ocrConfidence),
      'processingStatus': serializer.toJson<String>(processingStatus),
    };
  }

  SourcePageRow copyWith({
    String? id,
    String? sourceId,
    int? pageNumber,
    Value<String?> imageRelativePath = const Value.absent(),
    Value<String?> textLayer = const Value.absent(),
    Value<String?> rawOcrRelativePath = const Value.absent(),
    Value<String?> normalizedText = const Value.absent(),
    Value<String?> ocrEngine = const Value.absent(),
    Value<String?> ocrModelVersion = const Value.absent(),
    Value<double?> ocrConfidence = const Value.absent(),
    String? processingStatus,
  }) => SourcePageRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    pageNumber: pageNumber ?? this.pageNumber,
    imageRelativePath: imageRelativePath.present
        ? imageRelativePath.value
        : this.imageRelativePath,
    textLayer: textLayer.present ? textLayer.value : this.textLayer,
    rawOcrRelativePath: rawOcrRelativePath.present
        ? rawOcrRelativePath.value
        : this.rawOcrRelativePath,
    normalizedText: normalizedText.present
        ? normalizedText.value
        : this.normalizedText,
    ocrEngine: ocrEngine.present ? ocrEngine.value : this.ocrEngine,
    ocrModelVersion: ocrModelVersion.present
        ? ocrModelVersion.value
        : this.ocrModelVersion,
    ocrConfidence: ocrConfidence.present
        ? ocrConfidence.value
        : this.ocrConfidence,
    processingStatus: processingStatus ?? this.processingStatus,
  );
  SourcePageRow copyWithCompanion(SourcePagesCompanion data) {
    return SourcePageRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      imageRelativePath: data.imageRelativePath.present
          ? data.imageRelativePath.value
          : this.imageRelativePath,
      textLayer: data.textLayer.present ? data.textLayer.value : this.textLayer,
      rawOcrRelativePath: data.rawOcrRelativePath.present
          ? data.rawOcrRelativePath.value
          : this.rawOcrRelativePath,
      normalizedText: data.normalizedText.present
          ? data.normalizedText.value
          : this.normalizedText,
      ocrEngine: data.ocrEngine.present ? data.ocrEngine.value : this.ocrEngine,
      ocrModelVersion: data.ocrModelVersion.present
          ? data.ocrModelVersion.value
          : this.ocrModelVersion,
      ocrConfidence: data.ocrConfidence.present
          ? data.ocrConfidence.value
          : this.ocrConfidence,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourcePageRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('imageRelativePath: $imageRelativePath, ')
          ..write('textLayer: $textLayer, ')
          ..write('rawOcrRelativePath: $rawOcrRelativePath, ')
          ..write('normalizedText: $normalizedText, ')
          ..write('ocrEngine: $ocrEngine, ')
          ..write('ocrModelVersion: $ocrModelVersion, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('processingStatus: $processingStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    pageNumber,
    imageRelativePath,
    textLayer,
    rawOcrRelativePath,
    normalizedText,
    ocrEngine,
    ocrModelVersion,
    ocrConfidence,
    processingStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourcePageRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.pageNumber == this.pageNumber &&
          other.imageRelativePath == this.imageRelativePath &&
          other.textLayer == this.textLayer &&
          other.rawOcrRelativePath == this.rawOcrRelativePath &&
          other.normalizedText == this.normalizedText &&
          other.ocrEngine == this.ocrEngine &&
          other.ocrModelVersion == this.ocrModelVersion &&
          other.ocrConfidence == this.ocrConfidence &&
          other.processingStatus == this.processingStatus);
}

class SourcePagesCompanion extends UpdateCompanion<SourcePageRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<int> pageNumber;
  final Value<String?> imageRelativePath;
  final Value<String?> textLayer;
  final Value<String?> rawOcrRelativePath;
  final Value<String?> normalizedText;
  final Value<String?> ocrEngine;
  final Value<String?> ocrModelVersion;
  final Value<double?> ocrConfidence;
  final Value<String> processingStatus;
  final Value<int> rowid;
  const SourcePagesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.imageRelativePath = const Value.absent(),
    this.textLayer = const Value.absent(),
    this.rawOcrRelativePath = const Value.absent(),
    this.normalizedText = const Value.absent(),
    this.ocrEngine = const Value.absent(),
    this.ocrModelVersion = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcePagesCompanion.insert({
    required String id,
    required String sourceId,
    required int pageNumber,
    this.imageRelativePath = const Value.absent(),
    this.textLayer = const Value.absent(),
    this.rawOcrRelativePath = const Value.absent(),
    this.normalizedText = const Value.absent(),
    this.ocrEngine = const Value.absent(),
    this.ocrModelVersion = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    required String processingStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       pageNumber = Value(pageNumber),
       processingStatus = Value(processingStatus);
  static Insertable<SourcePageRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<int>? pageNumber,
    Expression<String>? imageRelativePath,
    Expression<String>? textLayer,
    Expression<String>? rawOcrRelativePath,
    Expression<String>? normalizedText,
    Expression<String>? ocrEngine,
    Expression<String>? ocrModelVersion,
    Expression<double>? ocrConfidence,
    Expression<String>? processingStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (imageRelativePath != null) 'image_relative_path': imageRelativePath,
      if (textLayer != null) 'text_layer': textLayer,
      if (rawOcrRelativePath != null)
        'raw_ocr_relative_path': rawOcrRelativePath,
      if (normalizedText != null) 'normalized_text': normalizedText,
      if (ocrEngine != null) 'ocr_engine': ocrEngine,
      if (ocrModelVersion != null) 'ocr_model_version': ocrModelVersion,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcePagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<int>? pageNumber,
    Value<String?>? imageRelativePath,
    Value<String?>? textLayer,
    Value<String?>? rawOcrRelativePath,
    Value<String?>? normalizedText,
    Value<String?>? ocrEngine,
    Value<String?>? ocrModelVersion,
    Value<double?>? ocrConfidence,
    Value<String>? processingStatus,
    Value<int>? rowid,
  }) {
    return SourcePagesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageRelativePath: imageRelativePath ?? this.imageRelativePath,
      textLayer: textLayer ?? this.textLayer,
      rawOcrRelativePath: rawOcrRelativePath ?? this.rawOcrRelativePath,
      normalizedText: normalizedText ?? this.normalizedText,
      ocrEngine: ocrEngine ?? this.ocrEngine,
      ocrModelVersion: ocrModelVersion ?? this.ocrModelVersion,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      processingStatus: processingStatus ?? this.processingStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (imageRelativePath.present) {
      map['image_relative_path'] = Variable<String>(imageRelativePath.value);
    }
    if (textLayer.present) {
      map['text_layer'] = Variable<String>(textLayer.value);
    }
    if (rawOcrRelativePath.present) {
      map['raw_ocr_relative_path'] = Variable<String>(rawOcrRelativePath.value);
    }
    if (normalizedText.present) {
      map['normalized_text'] = Variable<String>(normalizedText.value);
    }
    if (ocrEngine.present) {
      map['ocr_engine'] = Variable<String>(ocrEngine.value);
    }
    if (ocrModelVersion.present) {
      map['ocr_model_version'] = Variable<String>(ocrModelVersion.value);
    }
    if (ocrConfidence.present) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcePagesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('imageRelativePath: $imageRelativePath, ')
          ..write('textLayer: $textLayer, ')
          ..write('rawOcrRelativePath: $rawOcrRelativePath, ')
          ..write('normalizedText: $normalizedText, ')
          ..write('ocrEngine: $ocrEngine, ')
          ..write('ocrModelVersion: $ocrModelVersion, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeUnitsTable extends KnowledgeUnits
    with TableInfo<$KnowledgeUnitsTable, KnowledgeUnitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeUnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourcePageIdMeta = const VerificationMeta(
    'sourcePageId',
  );
  @override
  late final GeneratedColumn<String> sourcePageId = GeneratedColumn<String>(
    'source_page_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedContentMeta = const VerificationMeta(
    'normalizedContent',
  );
  @override
  late final GeneratedColumn<String> normalizedContent =
      GeneratedColumn<String>(
        'normalized_content',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bboxJsonMeta = const VerificationMeta(
    'bboxJson',
  );
  @override
  late final GeneratedColumn<String> bboxJson = GeneratedColumn<String>(
    'bbox_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verificationStatusMeta =
      const VerificationMeta('verificationStatus');
  @override
  late final GeneratedColumn<String> verificationStatus =
      GeneratedColumn<String>(
        'verification_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourcePriorityMeta = const VerificationMeta(
    'sourcePriority',
  );
  @override
  late final GeneratedColumn<int> sourcePriority = GeneratedColumn<int>(
    'source_priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    sourcePageId,
    type,
    content,
    normalizedContent,
    bboxJson,
    verificationStatus,
    sourcePriority,
    contentHash,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_units';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnowledgeUnitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('source_page_id')) {
      context.handle(
        _sourcePageIdMeta,
        sourcePageId.isAcceptableOrUnknown(
          data['source_page_id']!,
          _sourcePageIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('normalized_content')) {
      context.handle(
        _normalizedContentMeta,
        normalizedContent.isAcceptableOrUnknown(
          data['normalized_content']!,
          _normalizedContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedContentMeta);
    }
    if (data.containsKey('bbox_json')) {
      context.handle(
        _bboxJsonMeta,
        bboxJson.isAcceptableOrUnknown(data['bbox_json']!, _bboxJsonMeta),
      );
    }
    if (data.containsKey('verification_status')) {
      context.handle(
        _verificationStatusMeta,
        verificationStatus.isAcceptableOrUnknown(
          data['verification_status']!,
          _verificationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_verificationStatusMeta);
    }
    if (data.containsKey('source_priority')) {
      context.handle(
        _sourcePriorityMeta,
        sourcePriority.isAcceptableOrUnknown(
          data['source_priority']!,
          _sourcePriorityMeta,
        ),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  KnowledgeUnitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeUnitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sourcePageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_page_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      normalizedContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_content'],
      )!,
      bboxJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bbox_json'],
      ),
      verificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_status'],
      )!,
      sourcePriority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_priority'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $KnowledgeUnitsTable createAlias(String alias) {
    return $KnowledgeUnitsTable(attachedDatabase, alias);
  }
}

class KnowledgeUnitRow extends DataClass
    implements Insertable<KnowledgeUnitRow> {
  final String id;
  final String sourceId;
  final String? sourcePageId;
  final String type;
  final String content;
  final String normalizedContent;
  final String? bboxJson;
  final String verificationStatus;
  final int sourcePriority;
  final String contentHash;
  final int createdAt;
  final int updatedAt;
  const KnowledgeUnitRow({
    required this.id,
    required this.sourceId,
    this.sourcePageId,
    required this.type,
    required this.content,
    required this.normalizedContent,
    this.bboxJson,
    required this.verificationStatus,
    required this.sourcePriority,
    required this.contentHash,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || sourcePageId != null) {
      map['source_page_id'] = Variable<String>(sourcePageId);
    }
    map['type'] = Variable<String>(type);
    map['content'] = Variable<String>(content);
    map['normalized_content'] = Variable<String>(normalizedContent);
    if (!nullToAbsent || bboxJson != null) {
      map['bbox_json'] = Variable<String>(bboxJson);
    }
    map['verification_status'] = Variable<String>(verificationStatus);
    map['source_priority'] = Variable<int>(sourcePriority);
    map['content_hash'] = Variable<String>(contentHash);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  KnowledgeUnitsCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeUnitsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      sourcePageId: sourcePageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePageId),
      type: Value(type),
      content: Value(content),
      normalizedContent: Value(normalizedContent),
      bboxJson: bboxJson == null && nullToAbsent
          ? const Value.absent()
          : Value(bboxJson),
      verificationStatus: Value(verificationStatus),
      sourcePriority: Value(sourcePriority),
      contentHash: Value(contentHash),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory KnowledgeUnitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeUnitRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourcePageId: serializer.fromJson<String?>(json['sourcePageId']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String>(json['content']),
      normalizedContent: serializer.fromJson<String>(json['normalizedContent']),
      bboxJson: serializer.fromJson<String?>(json['bboxJson']),
      verificationStatus: serializer.fromJson<String>(
        json['verificationStatus'],
      ),
      sourcePriority: serializer.fromJson<int>(json['sourcePriority']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourcePageId': serializer.toJson<String?>(sourcePageId),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String>(content),
      'normalizedContent': serializer.toJson<String>(normalizedContent),
      'bboxJson': serializer.toJson<String?>(bboxJson),
      'verificationStatus': serializer.toJson<String>(verificationStatus),
      'sourcePriority': serializer.toJson<int>(sourcePriority),
      'contentHash': serializer.toJson<String>(contentHash),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  KnowledgeUnitRow copyWith({
    String? id,
    String? sourceId,
    Value<String?> sourcePageId = const Value.absent(),
    String? type,
    String? content,
    String? normalizedContent,
    Value<String?> bboxJson = const Value.absent(),
    String? verificationStatus,
    int? sourcePriority,
    String? contentHash,
    int? createdAt,
    int? updatedAt,
  }) => KnowledgeUnitRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    sourcePageId: sourcePageId.present ? sourcePageId.value : this.sourcePageId,
    type: type ?? this.type,
    content: content ?? this.content,
    normalizedContent: normalizedContent ?? this.normalizedContent,
    bboxJson: bboxJson.present ? bboxJson.value : this.bboxJson,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    sourcePriority: sourcePriority ?? this.sourcePriority,
    contentHash: contentHash ?? this.contentHash,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  KnowledgeUnitRow copyWithCompanion(KnowledgeUnitsCompanion data) {
    return KnowledgeUnitRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourcePageId: data.sourcePageId.present
          ? data.sourcePageId.value
          : this.sourcePageId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      normalizedContent: data.normalizedContent.present
          ? data.normalizedContent.value
          : this.normalizedContent,
      bboxJson: data.bboxJson.present ? data.bboxJson.value : this.bboxJson,
      verificationStatus: data.verificationStatus.present
          ? data.verificationStatus.value
          : this.verificationStatus,
      sourcePriority: data.sourcePriority.present
          ? data.sourcePriority.value
          : this.sourcePriority,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeUnitRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePageId: $sourcePageId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('normalizedContent: $normalizedContent, ')
          ..write('bboxJson: $bboxJson, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('sourcePriority: $sourcePriority, ')
          ..write('contentHash: $contentHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    sourcePageId,
    type,
    content,
    normalizedContent,
    bboxJson,
    verificationStatus,
    sourcePriority,
    contentHash,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeUnitRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.sourcePageId == this.sourcePageId &&
          other.type == this.type &&
          other.content == this.content &&
          other.normalizedContent == this.normalizedContent &&
          other.bboxJson == this.bboxJson &&
          other.verificationStatus == this.verificationStatus &&
          other.sourcePriority == this.sourcePriority &&
          other.contentHash == this.contentHash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class KnowledgeUnitsCompanion extends UpdateCompanion<KnowledgeUnitRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String?> sourcePageId;
  final Value<String> type;
  final Value<String> content;
  final Value<String> normalizedContent;
  final Value<String?> bboxJson;
  final Value<String> verificationStatus;
  final Value<int> sourcePriority;
  final Value<String> contentHash;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const KnowledgeUnitsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourcePageId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.normalizedContent = const Value.absent(),
    this.bboxJson = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.sourcePriority = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnowledgeUnitsCompanion.insert({
    required String id,
    required String sourceId,
    this.sourcePageId = const Value.absent(),
    required String type,
    required String content,
    required String normalizedContent,
    this.bboxJson = const Value.absent(),
    required String verificationStatus,
    this.sourcePriority = const Value.absent(),
    required String contentHash,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       type = Value(type),
       content = Value(content),
       normalizedContent = Value(normalizedContent),
       verificationStatus = Value(verificationStatus),
       contentHash = Value(contentHash),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<KnowledgeUnitRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? sourcePageId,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? normalizedContent,
    Expression<String>? bboxJson,
    Expression<String>? verificationStatus,
    Expression<int>? sourcePriority,
    Expression<String>? contentHash,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (sourcePageId != null) 'source_page_id': sourcePageId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (normalizedContent != null) 'normalized_content': normalizedContent,
      if (bboxJson != null) 'bbox_json': bboxJson,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (sourcePriority != null) 'source_priority': sourcePriority,
      if (contentHash != null) 'content_hash': contentHash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnowledgeUnitsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String?>? sourcePageId,
    Value<String>? type,
    Value<String>? content,
    Value<String>? normalizedContent,
    Value<String?>? bboxJson,
    Value<String>? verificationStatus,
    Value<int>? sourcePriority,
    Value<String>? contentHash,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return KnowledgeUnitsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourcePageId: sourcePageId ?? this.sourcePageId,
      type: type ?? this.type,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      bboxJson: bboxJson ?? this.bboxJson,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      sourcePriority: sourcePriority ?? this.sourcePriority,
      contentHash: contentHash ?? this.contentHash,
      createdAt: createdAt ?? this.createdAt,
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
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourcePageId.present) {
      map['source_page_id'] = Variable<String>(sourcePageId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (normalizedContent.present) {
      map['normalized_content'] = Variable<String>(normalizedContent.value);
    }
    if (bboxJson.present) {
      map['bbox_json'] = Variable<String>(bboxJson.value);
    }
    if (verificationStatus.present) {
      map['verification_status'] = Variable<String>(verificationStatus.value);
    }
    if (sourcePriority.present) {
      map['source_priority'] = Variable<int>(sourcePriority.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeUnitsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePageId: $sourcePageId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('normalizedContent: $normalizedContent, ')
          ..write('bboxJson: $bboxJson, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('sourcePriority: $sourcePriority, ')
          ..write('contentHash: $contentHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, QuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _knowledgeUnitIdMeta = const VerificationMeta(
    'knowledgeUnitId',
  );
  @override
  late final GeneratedColumn<String> knowledgeUnitId = GeneratedColumn<String>(
    'knowledge_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES knowledge_units (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _questionNumberMeta = const VerificationMeta(
    'questionNumber',
  );
  @override
  late final GeneratedColumn<String> questionNumber = GeneratedColumn<String>(
    'question_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _questionTypeMeta = const VerificationMeta(
    'questionType',
  );
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
    'question_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedContentMeta = const VerificationMeta(
    'normalizedContent',
  );
  @override
  late final GeneratedColumn<String> normalizedContent =
      GeneratedColumn<String>(
        'normalized_content',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _questionFingerprintMeta =
      const VerificationMeta('questionFingerprint');
  @override
  late final GeneratedColumn<String> questionFingerprint =
      GeneratedColumn<String>(
        'question_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _answerLabelMeta = const VerificationMeta(
    'answerLabel',
  );
  @override
  late final GeneratedColumn<String> answerLabel = GeneratedColumn<String>(
    'answer_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerContentMeta = const VerificationMeta(
    'answerContent',
  );
  @override
  late final GeneratedColumn<String> answerContent = GeneratedColumn<String>(
    'answer_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verificationStatusMeta =
      const VerificationMeta('verificationStatus');
  @override
  late final GeneratedColumn<String> verificationStatus =
      GeneratedColumn<String>(
        'verification_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    knowledgeUnitId,
    questionNumber,
    questionType,
    content,
    normalizedContent,
    questionFingerprint,
    answerLabel,
    answerContent,
    explanation,
    verificationStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('knowledge_unit_id')) {
      context.handle(
        _knowledgeUnitIdMeta,
        knowledgeUnitId.isAcceptableOrUnknown(
          data['knowledge_unit_id']!,
          _knowledgeUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_knowledgeUnitIdMeta);
    }
    if (data.containsKey('question_number')) {
      context.handle(
        _questionNumberMeta,
        questionNumber.isAcceptableOrUnknown(
          data['question_number']!,
          _questionNumberMeta,
        ),
      );
    }
    if (data.containsKey('question_type')) {
      context.handle(
        _questionTypeMeta,
        questionType.isAcceptableOrUnknown(
          data['question_type']!,
          _questionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('normalized_content')) {
      context.handle(
        _normalizedContentMeta,
        normalizedContent.isAcceptableOrUnknown(
          data['normalized_content']!,
          _normalizedContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedContentMeta);
    }
    if (data.containsKey('question_fingerprint')) {
      context.handle(
        _questionFingerprintMeta,
        questionFingerprint.isAcceptableOrUnknown(
          data['question_fingerprint']!,
          _questionFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionFingerprintMeta);
    }
    if (data.containsKey('answer_label')) {
      context.handle(
        _answerLabelMeta,
        answerLabel.isAcceptableOrUnknown(
          data['answer_label']!,
          _answerLabelMeta,
        ),
      );
    }
    if (data.containsKey('answer_content')) {
      context.handle(
        _answerContentMeta,
        answerContent.isAcceptableOrUnknown(
          data['answer_content']!,
          _answerContentMeta,
        ),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('verification_status')) {
      context.handle(
        _verificationStatusMeta,
        verificationStatus.isAcceptableOrUnknown(
          data['verification_status']!,
          _verificationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_verificationStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  QuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      knowledgeUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knowledge_unit_id'],
      )!,
      questionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_number'],
      ),
      questionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      normalizedContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_content'],
      )!,
      questionFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_fingerprint'],
      )!,
      answerLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_label'],
      ),
      answerContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_content'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      verificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class QuestionRow extends DataClass implements Insertable<QuestionRow> {
  final String id;
  final String knowledgeUnitId;
  final String? questionNumber;
  final String questionType;
  final String content;
  final String normalizedContent;
  final String questionFingerprint;
  final String? answerLabel;
  final String? answerContent;
  final String? explanation;
  final String verificationStatus;
  final int createdAt;
  final int updatedAt;
  const QuestionRow({
    required this.id,
    required this.knowledgeUnitId,
    this.questionNumber,
    required this.questionType,
    required this.content,
    required this.normalizedContent,
    required this.questionFingerprint,
    this.answerLabel,
    this.answerContent,
    this.explanation,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['knowledge_unit_id'] = Variable<String>(knowledgeUnitId);
    if (!nullToAbsent || questionNumber != null) {
      map['question_number'] = Variable<String>(questionNumber);
    }
    map['question_type'] = Variable<String>(questionType);
    map['content'] = Variable<String>(content);
    map['normalized_content'] = Variable<String>(normalizedContent);
    map['question_fingerprint'] = Variable<String>(questionFingerprint);
    if (!nullToAbsent || answerLabel != null) {
      map['answer_label'] = Variable<String>(answerLabel);
    }
    if (!nullToAbsent || answerContent != null) {
      map['answer_content'] = Variable<String>(answerContent);
    }
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    map['verification_status'] = Variable<String>(verificationStatus);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      knowledgeUnitId: Value(knowledgeUnitId),
      questionNumber: questionNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(questionNumber),
      questionType: Value(questionType),
      content: Value(content),
      normalizedContent: Value(normalizedContent),
      questionFingerprint: Value(questionFingerprint),
      answerLabel: answerLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(answerLabel),
      answerContent: answerContent == null && nullToAbsent
          ? const Value.absent()
          : Value(answerContent),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      verificationStatus: Value(verificationStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRow(
      id: serializer.fromJson<String>(json['id']),
      knowledgeUnitId: serializer.fromJson<String>(json['knowledgeUnitId']),
      questionNumber: serializer.fromJson<String?>(json['questionNumber']),
      questionType: serializer.fromJson<String>(json['questionType']),
      content: serializer.fromJson<String>(json['content']),
      normalizedContent: serializer.fromJson<String>(json['normalizedContent']),
      questionFingerprint: serializer.fromJson<String>(
        json['questionFingerprint'],
      ),
      answerLabel: serializer.fromJson<String?>(json['answerLabel']),
      answerContent: serializer.fromJson<String?>(json['answerContent']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      verificationStatus: serializer.fromJson<String>(
        json['verificationStatus'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'knowledgeUnitId': serializer.toJson<String>(knowledgeUnitId),
      'questionNumber': serializer.toJson<String?>(questionNumber),
      'questionType': serializer.toJson<String>(questionType),
      'content': serializer.toJson<String>(content),
      'normalizedContent': serializer.toJson<String>(normalizedContent),
      'questionFingerprint': serializer.toJson<String>(questionFingerprint),
      'answerLabel': serializer.toJson<String?>(answerLabel),
      'answerContent': serializer.toJson<String?>(answerContent),
      'explanation': serializer.toJson<String?>(explanation),
      'verificationStatus': serializer.toJson<String>(verificationStatus),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  QuestionRow copyWith({
    String? id,
    String? knowledgeUnitId,
    Value<String?> questionNumber = const Value.absent(),
    String? questionType,
    String? content,
    String? normalizedContent,
    String? questionFingerprint,
    Value<String?> answerLabel = const Value.absent(),
    Value<String?> answerContent = const Value.absent(),
    Value<String?> explanation = const Value.absent(),
    String? verificationStatus,
    int? createdAt,
    int? updatedAt,
  }) => QuestionRow(
    id: id ?? this.id,
    knowledgeUnitId: knowledgeUnitId ?? this.knowledgeUnitId,
    questionNumber: questionNumber.present
        ? questionNumber.value
        : this.questionNumber,
    questionType: questionType ?? this.questionType,
    content: content ?? this.content,
    normalizedContent: normalizedContent ?? this.normalizedContent,
    questionFingerprint: questionFingerprint ?? this.questionFingerprint,
    answerLabel: answerLabel.present ? answerLabel.value : this.answerLabel,
    answerContent: answerContent.present
        ? answerContent.value
        : this.answerContent,
    explanation: explanation.present ? explanation.value : this.explanation,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuestionRow copyWithCompanion(QuestionsCompanion data) {
    return QuestionRow(
      id: data.id.present ? data.id.value : this.id,
      knowledgeUnitId: data.knowledgeUnitId.present
          ? data.knowledgeUnitId.value
          : this.knowledgeUnitId,
      questionNumber: data.questionNumber.present
          ? data.questionNumber.value
          : this.questionNumber,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      content: data.content.present ? data.content.value : this.content,
      normalizedContent: data.normalizedContent.present
          ? data.normalizedContent.value
          : this.normalizedContent,
      questionFingerprint: data.questionFingerprint.present
          ? data.questionFingerprint.value
          : this.questionFingerprint,
      answerLabel: data.answerLabel.present
          ? data.answerLabel.value
          : this.answerLabel,
      answerContent: data.answerContent.present
          ? data.answerContent.value
          : this.answerContent,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      verificationStatus: data.verificationStatus.present
          ? data.verificationStatus.value
          : this.verificationStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRow(')
          ..write('id: $id, ')
          ..write('knowledgeUnitId: $knowledgeUnitId, ')
          ..write('questionNumber: $questionNumber, ')
          ..write('questionType: $questionType, ')
          ..write('content: $content, ')
          ..write('normalizedContent: $normalizedContent, ')
          ..write('questionFingerprint: $questionFingerprint, ')
          ..write('answerLabel: $answerLabel, ')
          ..write('answerContent: $answerContent, ')
          ..write('explanation: $explanation, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    knowledgeUnitId,
    questionNumber,
    questionType,
    content,
    normalizedContent,
    questionFingerprint,
    answerLabel,
    answerContent,
    explanation,
    verificationStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRow &&
          other.id == this.id &&
          other.knowledgeUnitId == this.knowledgeUnitId &&
          other.questionNumber == this.questionNumber &&
          other.questionType == this.questionType &&
          other.content == this.content &&
          other.normalizedContent == this.normalizedContent &&
          other.questionFingerprint == this.questionFingerprint &&
          other.answerLabel == this.answerLabel &&
          other.answerContent == this.answerContent &&
          other.explanation == this.explanation &&
          other.verificationStatus == this.verificationStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuestionsCompanion extends UpdateCompanion<QuestionRow> {
  final Value<String> id;
  final Value<String> knowledgeUnitId;
  final Value<String?> questionNumber;
  final Value<String> questionType;
  final Value<String> content;
  final Value<String> normalizedContent;
  final Value<String> questionFingerprint;
  final Value<String?> answerLabel;
  final Value<String?> answerContent;
  final Value<String?> explanation;
  final Value<String> verificationStatus;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.knowledgeUnitId = const Value.absent(),
    this.questionNumber = const Value.absent(),
    this.questionType = const Value.absent(),
    this.content = const Value.absent(),
    this.normalizedContent = const Value.absent(),
    this.questionFingerprint = const Value.absent(),
    this.answerLabel = const Value.absent(),
    this.answerContent = const Value.absent(),
    this.explanation = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionsCompanion.insert({
    required String id,
    required String knowledgeUnitId,
    this.questionNumber = const Value.absent(),
    required String questionType,
    required String content,
    required String normalizedContent,
    required String questionFingerprint,
    this.answerLabel = const Value.absent(),
    this.answerContent = const Value.absent(),
    this.explanation = const Value.absent(),
    required String verificationStatus,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       knowledgeUnitId = Value(knowledgeUnitId),
       questionType = Value(questionType),
       content = Value(content),
       normalizedContent = Value(normalizedContent),
       questionFingerprint = Value(questionFingerprint),
       verificationStatus = Value(verificationStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuestionRow> custom({
    Expression<String>? id,
    Expression<String>? knowledgeUnitId,
    Expression<String>? questionNumber,
    Expression<String>? questionType,
    Expression<String>? content,
    Expression<String>? normalizedContent,
    Expression<String>? questionFingerprint,
    Expression<String>? answerLabel,
    Expression<String>? answerContent,
    Expression<String>? explanation,
    Expression<String>? verificationStatus,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (knowledgeUnitId != null) 'knowledge_unit_id': knowledgeUnitId,
      if (questionNumber != null) 'question_number': questionNumber,
      if (questionType != null) 'question_type': questionType,
      if (content != null) 'content': content,
      if (normalizedContent != null) 'normalized_content': normalizedContent,
      if (questionFingerprint != null)
        'question_fingerprint': questionFingerprint,
      if (answerLabel != null) 'answer_label': answerLabel,
      if (answerContent != null) 'answer_content': answerContent,
      if (explanation != null) 'explanation': explanation,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? knowledgeUnitId,
    Value<String?>? questionNumber,
    Value<String>? questionType,
    Value<String>? content,
    Value<String>? normalizedContent,
    Value<String>? questionFingerprint,
    Value<String?>? answerLabel,
    Value<String?>? answerContent,
    Value<String?>? explanation,
    Value<String>? verificationStatus,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      knowledgeUnitId: knowledgeUnitId ?? this.knowledgeUnitId,
      questionNumber: questionNumber ?? this.questionNumber,
      questionType: questionType ?? this.questionType,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      questionFingerprint: questionFingerprint ?? this.questionFingerprint,
      answerLabel: answerLabel ?? this.answerLabel,
      answerContent: answerContent ?? this.answerContent,
      explanation: explanation ?? this.explanation,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
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
    if (knowledgeUnitId.present) {
      map['knowledge_unit_id'] = Variable<String>(knowledgeUnitId.value);
    }
    if (questionNumber.present) {
      map['question_number'] = Variable<String>(questionNumber.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (normalizedContent.present) {
      map['normalized_content'] = Variable<String>(normalizedContent.value);
    }
    if (questionFingerprint.present) {
      map['question_fingerprint'] = Variable<String>(questionFingerprint.value);
    }
    if (answerLabel.present) {
      map['answer_label'] = Variable<String>(answerLabel.value);
    }
    if (answerContent.present) {
      map['answer_content'] = Variable<String>(answerContent.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (verificationStatus.present) {
      map['verification_status'] = Variable<String>(verificationStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('knowledgeUnitId: $knowledgeUnitId, ')
          ..write('questionNumber: $questionNumber, ')
          ..write('questionType: $questionType, ')
          ..write('content: $content, ')
          ..write('normalizedContent: $normalizedContent, ')
          ..write('questionFingerprint: $questionFingerprint, ')
          ..write('answerLabel: $answerLabel, ')
          ..write('answerContent: $answerContent, ')
          ..write('explanation: $explanation, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionChoicesTable extends QuestionChoices
    with TableInfo<$QuestionChoicesTable, QuestionChoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionChoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES questions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedContentMeta = const VerificationMeta(
    'normalizedContent',
  );
  @override
  late final GeneratedColumn<String> normalizedContent =
      GeneratedColumn<String>(
        'normalized_content',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionId,
    label,
    content,
    normalizedContent,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_choices';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionChoiceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('normalized_content')) {
      context.handle(
        _normalizedContentMeta,
        normalizedContent.isAcceptableOrUnknown(
          data['normalized_content']!,
          _normalizedContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedContentMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {questionId, label},
  ];
  @override
  QuestionChoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionChoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      normalizedContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_content'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $QuestionChoicesTable createAlias(String alias) {
    return $QuestionChoicesTable(attachedDatabase, alias);
  }
}

class QuestionChoiceRow extends DataClass
    implements Insertable<QuestionChoiceRow> {
  final String id;
  final String questionId;
  final String label;
  final String content;
  final String normalizedContent;
  final int sortOrder;
  const QuestionChoiceRow({
    required this.id,
    required this.questionId,
    required this.label,
    required this.content,
    required this.normalizedContent,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_id'] = Variable<String>(questionId);
    map['label'] = Variable<String>(label);
    map['content'] = Variable<String>(content);
    map['normalized_content'] = Variable<String>(normalizedContent);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QuestionChoicesCompanion toCompanion(bool nullToAbsent) {
    return QuestionChoicesCompanion(
      id: Value(id),
      questionId: Value(questionId),
      label: Value(label),
      content: Value(content),
      normalizedContent: Value(normalizedContent),
      sortOrder: Value(sortOrder),
    );
  }

  factory QuestionChoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionChoiceRow(
      id: serializer.fromJson<String>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      label: serializer.fromJson<String>(json['label']),
      content: serializer.fromJson<String>(json['content']),
      normalizedContent: serializer.fromJson<String>(json['normalizedContent']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionId': serializer.toJson<String>(questionId),
      'label': serializer.toJson<String>(label),
      'content': serializer.toJson<String>(content),
      'normalizedContent': serializer.toJson<String>(normalizedContent),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  QuestionChoiceRow copyWith({
    String? id,
    String? questionId,
    String? label,
    String? content,
    String? normalizedContent,
    int? sortOrder,
  }) => QuestionChoiceRow(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    label: label ?? this.label,
    content: content ?? this.content,
    normalizedContent: normalizedContent ?? this.normalizedContent,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  QuestionChoiceRow copyWithCompanion(QuestionChoicesCompanion data) {
    return QuestionChoiceRow(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      label: data.label.present ? data.label.value : this.label,
      content: data.content.present ? data.content.value : this.content,
      normalizedContent: data.normalizedContent.present
          ? data.normalizedContent.value
          : this.normalizedContent,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionChoiceRow(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('label: $label, ')
          ..write('content: $content, ')
          ..write('normalizedContent: $normalizedContent, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questionId, label, content, normalizedContent, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionChoiceRow &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.label == this.label &&
          other.content == this.content &&
          other.normalizedContent == this.normalizedContent &&
          other.sortOrder == this.sortOrder);
}

class QuestionChoicesCompanion extends UpdateCompanion<QuestionChoiceRow> {
  final Value<String> id;
  final Value<String> questionId;
  final Value<String> label;
  final Value<String> content;
  final Value<String> normalizedContent;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QuestionChoicesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.label = const Value.absent(),
    this.content = const Value.absent(),
    this.normalizedContent = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionChoicesCompanion.insert({
    required String id,
    required String questionId,
    required String label,
    required String content,
    required String normalizedContent,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       questionId = Value(questionId),
       label = Value(label),
       content = Value(content),
       normalizedContent = Value(normalizedContent),
       sortOrder = Value(sortOrder);
  static Insertable<QuestionChoiceRow> custom({
    Expression<String>? id,
    Expression<String>? questionId,
    Expression<String>? label,
    Expression<String>? content,
    Expression<String>? normalizedContent,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (label != null) 'label': label,
      if (content != null) 'content': content,
      if (normalizedContent != null) 'normalized_content': normalizedContent,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionChoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? questionId,
    Value<String>? label,
    Value<String>? content,
    Value<String>? normalizedContent,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return QuestionChoicesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      label: label ?? this.label,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
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
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (normalizedContent.present) {
      map['normalized_content'] = Variable<String>(normalizedContent.value);
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
    return (StringBuffer('QuestionChoicesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('label: $label, ')
          ..write('content: $content, ')
          ..write('normalizedContent: $normalizedContent, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeRelationsTable extends KnowledgeRelations
    with TableInfo<$KnowledgeRelationsTable, KnowledgeRelationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromUnitIdMeta = const VerificationMeta(
    'fromUnitId',
  );
  @override
  late final GeneratedColumn<String> fromUnitId = GeneratedColumn<String>(
    'from_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES knowledge_units (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _toUnitIdMeta = const VerificationMeta(
    'toUnitId',
  );
  @override
  late final GeneratedColumn<String> toUnitId = GeneratedColumn<String>(
    'to_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES knowledge_units (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _relationTypeMeta = const VerificationMeta(
    'relationType',
  );
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
    'relation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromUnitId,
    toUnitId,
    relationType,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_relations';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnowledgeRelationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_unit_id')) {
      context.handle(
        _fromUnitIdMeta,
        fromUnitId.isAcceptableOrUnknown(
          data['from_unit_id']!,
          _fromUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromUnitIdMeta);
    }
    if (data.containsKey('to_unit_id')) {
      context.handle(
        _toUnitIdMeta,
        toUnitId.isAcceptableOrUnknown(data['to_unit_id']!, _toUnitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toUnitIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
        _relationTypeMeta,
        relationType.isAcceptableOrUnknown(
          data['relation_type']!,
          _relationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnowledgeRelationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeRelationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fromUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_unit_id'],
      )!,
      toUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_unit_id'],
      )!,
      relationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $KnowledgeRelationsTable createAlias(String alias) {
    return $KnowledgeRelationsTable(attachedDatabase, alias);
  }
}

class KnowledgeRelationRow extends DataClass
    implements Insertable<KnowledgeRelationRow> {
  final String id;
  final String fromUnitId;
  final String toUnitId;
  final String relationType;
  final String? note;
  final int createdAt;
  const KnowledgeRelationRow({
    required this.id,
    required this.fromUnitId,
    required this.toUnitId,
    required this.relationType,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_unit_id'] = Variable<String>(fromUnitId);
    map['to_unit_id'] = Variable<String>(toUnitId);
    map['relation_type'] = Variable<String>(relationType);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  KnowledgeRelationsCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeRelationsCompanion(
      id: Value(id),
      fromUnitId: Value(fromUnitId),
      toUnitId: Value(toUnitId),
      relationType: Value(relationType),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory KnowledgeRelationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeRelationRow(
      id: serializer.fromJson<String>(json['id']),
      fromUnitId: serializer.fromJson<String>(json['fromUnitId']),
      toUnitId: serializer.fromJson<String>(json['toUnitId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromUnitId': serializer.toJson<String>(fromUnitId),
      'toUnitId': serializer.toJson<String>(toUnitId),
      'relationType': serializer.toJson<String>(relationType),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  KnowledgeRelationRow copyWith({
    String? id,
    String? fromUnitId,
    String? toUnitId,
    String? relationType,
    Value<String?> note = const Value.absent(),
    int? createdAt,
  }) => KnowledgeRelationRow(
    id: id ?? this.id,
    fromUnitId: fromUnitId ?? this.fromUnitId,
    toUnitId: toUnitId ?? this.toUnitId,
    relationType: relationType ?? this.relationType,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  KnowledgeRelationRow copyWithCompanion(KnowledgeRelationsCompanion data) {
    return KnowledgeRelationRow(
      id: data.id.present ? data.id.value : this.id,
      fromUnitId: data.fromUnitId.present
          ? data.fromUnitId.value
          : this.fromUnitId,
      toUnitId: data.toUnitId.present ? data.toUnitId.value : this.toUnitId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeRelationRow(')
          ..write('id: $id, ')
          ..write('fromUnitId: $fromUnitId, ')
          ..write('toUnitId: $toUnitId, ')
          ..write('relationType: $relationType, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fromUnitId, toUnitId, relationType, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeRelationRow &&
          other.id == this.id &&
          other.fromUnitId == this.fromUnitId &&
          other.toUnitId == this.toUnitId &&
          other.relationType == this.relationType &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class KnowledgeRelationsCompanion
    extends UpdateCompanion<KnowledgeRelationRow> {
  final Value<String> id;
  final Value<String> fromUnitId;
  final Value<String> toUnitId;
  final Value<String> relationType;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> rowid;
  const KnowledgeRelationsCompanion({
    this.id = const Value.absent(),
    this.fromUnitId = const Value.absent(),
    this.toUnitId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnowledgeRelationsCompanion.insert({
    required String id,
    required String fromUnitId,
    required String toUnitId,
    required String relationType,
    this.note = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fromUnitId = Value(fromUnitId),
       toUnitId = Value(toUnitId),
       relationType = Value(relationType),
       createdAt = Value(createdAt);
  static Insertable<KnowledgeRelationRow> custom({
    Expression<String>? id,
    Expression<String>? fromUnitId,
    Expression<String>? toUnitId,
    Expression<String>? relationType,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromUnitId != null) 'from_unit_id': fromUnitId,
      if (toUnitId != null) 'to_unit_id': toUnitId,
      if (relationType != null) 'relation_type': relationType,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnowledgeRelationsCompanion copyWith({
    Value<String>? id,
    Value<String>? fromUnitId,
    Value<String>? toUnitId,
    Value<String>? relationType,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return KnowledgeRelationsCompanion(
      id: id ?? this.id,
      fromUnitId: fromUnitId ?? this.fromUnitId,
      toUnitId: toUnitId ?? this.toUnitId,
      relationType: relationType ?? this.relationType,
      note: note ?? this.note,
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
    if (fromUnitId.present) {
      map['from_unit_id'] = Variable<String>(fromUnitId.value);
    }
    if (toUnitId.present) {
      map['to_unit_id'] = Variable<String>(toUnitId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeRelationsCompanion(')
          ..write('id: $id, ')
          ..write('fromUnitId: $fromUnitId, ')
          ..write('toUnitId: $toUnitId, ')
          ..write('relationType: $relationType, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OcrRunsTable extends OcrRuns with TableInfo<$OcrRunsTable, OcrRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcrRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourcePageIdMeta = const VerificationMeta(
    'sourcePageId',
  );
  @override
  late final GeneratedColumn<String> sourcePageId = GeneratedColumn<String>(
    'source_page_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
    'engine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    sourcePageId,
    engine,
    modelVersion,
    status,
    confidence,
    errorMessage,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocr_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OcrRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('source_page_id')) {
      context.handle(
        _sourcePageIdMeta,
        sourcePageId.isAcceptableOrUnknown(
          data['source_page_id']!,
          _sourcePageIdMeta,
        ),
      );
    }
    if (data.containsKey('engine')) {
      context.handle(
        _engineMeta,
        engine.isAcceptableOrUnknown(data['engine']!, _engineMeta),
      );
    } else if (isInserting) {
      context.missing(_engineMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OcrRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcrRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sourcePageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_page_id'],
      ),
      engine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $OcrRunsTable createAlias(String alias) {
    return $OcrRunsTable(attachedDatabase, alias);
  }
}

class OcrRunRow extends DataClass implements Insertable<OcrRunRow> {
  final String id;
  final String sourceId;
  final String? sourcePageId;
  final String engine;
  final String modelVersion;
  final String status;
  final double? confidence;
  final String? errorMessage;
  final int startedAt;
  final int? finishedAt;
  const OcrRunRow({
    required this.id,
    required this.sourceId,
    this.sourcePageId,
    required this.engine,
    required this.modelVersion,
    required this.status,
    this.confidence,
    this.errorMessage,
    required this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || sourcePageId != null) {
      map['source_page_id'] = Variable<String>(sourcePageId);
    }
    map['engine'] = Variable<String>(engine);
    map['model_version'] = Variable<String>(modelVersion);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    return map;
  }

  OcrRunsCompanion toCompanion(bool nullToAbsent) {
    return OcrRunsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      sourcePageId: sourcePageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePageId),
      engine: Value(engine),
      modelVersion: Value(modelVersion),
      status: Value(status),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory OcrRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcrRunRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourcePageId: serializer.fromJson<String?>(json['sourcePageId']),
      engine: serializer.fromJson<String>(json['engine']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      status: serializer.fromJson<String>(json['status']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourcePageId': serializer.toJson<String?>(sourcePageId),
      'engine': serializer.toJson<String>(engine),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'status': serializer.toJson<String>(status),
      'confidence': serializer.toJson<double?>(confidence),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
    };
  }

  OcrRunRow copyWith({
    String? id,
    String? sourceId,
    Value<String?> sourcePageId = const Value.absent(),
    String? engine,
    String? modelVersion,
    String? status,
    Value<double?> confidence = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
  }) => OcrRunRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    sourcePageId: sourcePageId.present ? sourcePageId.value : this.sourcePageId,
    engine: engine ?? this.engine,
    modelVersion: modelVersion ?? this.modelVersion,
    status: status ?? this.status,
    confidence: confidence.present ? confidence.value : this.confidence,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  OcrRunRow copyWithCompanion(OcrRunsCompanion data) {
    return OcrRunRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourcePageId: data.sourcePageId.present
          ? data.sourcePageId.value
          : this.sourcePageId,
      engine: data.engine.present ? data.engine.value : this.engine,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      status: data.status.present ? data.status.value : this.status,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcrRunRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePageId: $sourcePageId, ')
          ..write('engine: $engine, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('status: $status, ')
          ..write('confidence: $confidence, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    sourcePageId,
    engine,
    modelVersion,
    status,
    confidence,
    errorMessage,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcrRunRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.sourcePageId == this.sourcePageId &&
          other.engine == this.engine &&
          other.modelVersion == this.modelVersion &&
          other.status == this.status &&
          other.confidence == this.confidence &&
          other.errorMessage == this.errorMessage &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class OcrRunsCompanion extends UpdateCompanion<OcrRunRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String?> sourcePageId;
  final Value<String> engine;
  final Value<String> modelVersion;
  final Value<String> status;
  final Value<double?> confidence;
  final Value<String?> errorMessage;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<int> rowid;
  const OcrRunsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourcePageId = const Value.absent(),
    this.engine = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.confidence = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OcrRunsCompanion.insert({
    required String id,
    required String sourceId,
    this.sourcePageId = const Value.absent(),
    required String engine,
    required String modelVersion,
    required String status,
    this.confidence = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required int startedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       engine = Value(engine),
       modelVersion = Value(modelVersion),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<OcrRunRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? sourcePageId,
    Expression<String>? engine,
    Expression<String>? modelVersion,
    Expression<String>? status,
    Expression<double>? confidence,
    Expression<String>? errorMessage,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (sourcePageId != null) 'source_page_id': sourcePageId,
      if (engine != null) 'engine': engine,
      if (modelVersion != null) 'model_version': modelVersion,
      if (status != null) 'status': status,
      if (confidence != null) 'confidence': confidence,
      if (errorMessage != null) 'error_message': errorMessage,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OcrRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String?>? sourcePageId,
    Value<String>? engine,
    Value<String>? modelVersion,
    Value<String>? status,
    Value<double?>? confidence,
    Value<String?>? errorMessage,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<int>? rowid,
  }) {
    return OcrRunsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourcePageId: sourcePageId ?? this.sourcePageId,
      engine: engine ?? this.engine,
      modelVersion: modelVersion ?? this.modelVersion,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourcePageId.present) {
      map['source_page_id'] = Variable<String>(sourcePageId.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcrRunsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePageId: $sourcePageId, ')
          ..write('engine: $engine, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('status: $status, ')
          ..write('confidence: $confidence, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngestionJobsTable extends IngestionJobs
    with TableInfo<$IngestionJobsTable, IngestionJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngestionJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftJsonMeta = const VerificationMeta(
    'draftJson',
  );
  @override
  late final GeneratedColumn<String> draftJson = GeneratedColumn<String>(
    'draft_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    status,
    currentPage,
    totalPages,
    errorMessage,
    draftJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingestion_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngestionJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('draft_json')) {
      context.handle(
        _draftJsonMeta,
        draftJson.isAcceptableOrUnknown(data['draft_json']!, _draftJsonMeta),
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
  IngestionJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngestionJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
      ),
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      draftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IngestionJobsTable createAlias(String alias) {
    return $IngestionJobsTable(attachedDatabase, alias);
  }
}

class IngestionJobRow extends DataClass implements Insertable<IngestionJobRow> {
  final String id;
  final String? sourceId;
  final String status;
  final int? currentPage;
  final int? totalPages;
  final String? errorMessage;
  final String? draftJson;
  final int createdAt;
  final int updatedAt;
  const IngestionJobRow({
    required this.id,
    this.sourceId,
    required this.status,
    this.currentPage,
    this.totalPages,
    this.errorMessage,
    this.draftJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || currentPage != null) {
      map['current_page'] = Variable<int>(currentPage);
    }
    if (!nullToAbsent || totalPages != null) {
      map['total_pages'] = Variable<int>(totalPages);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || draftJson != null) {
      map['draft_json'] = Variable<String>(draftJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  IngestionJobsCompanion toCompanion(bool nullToAbsent) {
    return IngestionJobsCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      status: Value(status),
      currentPage: currentPage == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPage),
      totalPages: totalPages == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPages),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      draftJson: draftJson == null && nullToAbsent
          ? const Value.absent()
          : Value(draftJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IngestionJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngestionJobRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      status: serializer.fromJson<String>(json['status']),
      currentPage: serializer.fromJson<int?>(json['currentPage']),
      totalPages: serializer.fromJson<int?>(json['totalPages']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      draftJson: serializer.fromJson<String?>(json['draftJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'status': serializer.toJson<String>(status),
      'currentPage': serializer.toJson<int?>(currentPage),
      'totalPages': serializer.toJson<int?>(totalPages),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'draftJson': serializer.toJson<String?>(draftJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  IngestionJobRow copyWith({
    String? id,
    Value<String?> sourceId = const Value.absent(),
    String? status,
    Value<int?> currentPage = const Value.absent(),
    Value<int?> totalPages = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    Value<String?> draftJson = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => IngestionJobRow(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    status: status ?? this.status,
    currentPage: currentPage.present ? currentPage.value : this.currentPage,
    totalPages: totalPages.present ? totalPages.value : this.totalPages,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    draftJson: draftJson.present ? draftJson.value : this.draftJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IngestionJobRow copyWithCompanion(IngestionJobsCompanion data) {
    return IngestionJobRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      status: data.status.present ? data.status.value : this.status,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      draftJson: data.draftJson.present ? data.draftJson.value : this.draftJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngestionJobRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('status: $status, ')
          ..write('currentPage: $currentPage, ')
          ..write('totalPages: $totalPages, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('draftJson: $draftJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    status,
    currentPage,
    totalPages,
    errorMessage,
    draftJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngestionJobRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.status == this.status &&
          other.currentPage == this.currentPage &&
          other.totalPages == this.totalPages &&
          other.errorMessage == this.errorMessage &&
          other.draftJson == this.draftJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IngestionJobsCompanion extends UpdateCompanion<IngestionJobRow> {
  final Value<String> id;
  final Value<String?> sourceId;
  final Value<String> status;
  final Value<int?> currentPage;
  final Value<int?> totalPages;
  final Value<String?> errorMessage;
  final Value<String?> draftJson;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const IngestionJobsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.status = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.draftJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngestionJobsCompanion.insert({
    required String id,
    this.sourceId = const Value.absent(),
    required String status,
    this.currentPage = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.draftJson = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<IngestionJobRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? status,
    Expression<int>? currentPage,
    Expression<int>? totalPages,
    Expression<String>? errorMessage,
    Expression<String>? draftJson,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (status != null) 'status': status,
      if (currentPage != null) 'current_page': currentPage,
      if (totalPages != null) 'total_pages': totalPages,
      if (errorMessage != null) 'error_message': errorMessage,
      if (draftJson != null) 'draft_json': draftJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngestionJobsCompanion copyWith({
    Value<String>? id,
    Value<String?>? sourceId,
    Value<String>? status,
    Value<int?>? currentPage,
    Value<int?>? totalPages,
    Value<String?>? errorMessage,
    Value<String?>? draftJson,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return IngestionJobsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: errorMessage ?? this.errorMessage,
      draftJson: draftJson ?? this.draftJson,
      createdAt: createdAt ?? this.createdAt,
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
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (draftJson.present) {
      map['draft_json'] = Variable<String>(draftJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngestionJobsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('status: $status, ')
          ..write('currentPage: $currentPage, ')
          ..write('totalPages: $totalPages, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('draftJson: $draftJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SolveSessionsTable extends SolveSessions
    with TableInfo<$SolveSessionsTable, SolveSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolveSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputTypeMeta = const VerificationMeta(
    'inputType',
  );
  @override
  late final GeneratedColumn<String> inputType = GeneratedColumn<String>(
    'input_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawInputTextMeta = const VerificationMeta(
    'rawInputText',
  );
  @override
  late final GeneratedColumn<String> rawInputText = GeneratedColumn<String>(
    'raw_input_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parsedQuestionJsonMeta =
      const VerificationMeta('parsedQuestionJson');
  @override
  late final GeneratedColumn<String> parsedQuestionJson =
      GeneratedColumn<String>(
        'parsed_question_json',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inputType,
    rawInputText,
    parsedQuestionJson,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solve_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolveSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('input_type')) {
      context.handle(
        _inputTypeMeta,
        inputType.isAcceptableOrUnknown(data['input_type']!, _inputTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_inputTypeMeta);
    }
    if (data.containsKey('raw_input_text')) {
      context.handle(
        _rawInputTextMeta,
        rawInputText.isAcceptableOrUnknown(
          data['raw_input_text']!,
          _rawInputTextMeta,
        ),
      );
    }
    if (data.containsKey('parsed_question_json')) {
      context.handle(
        _parsedQuestionJsonMeta,
        parsedQuestionJson.isAcceptableOrUnknown(
          data['parsed_question_json']!,
          _parsedQuestionJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  SolveSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolveSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inputType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_type'],
      )!,
      rawInputText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_input_text'],
      ),
      parsedQuestionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_question_json'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SolveSessionsTable createAlias(String alias) {
    return $SolveSessionsTable(attachedDatabase, alias);
  }
}

class SolveSessionRow extends DataClass implements Insertable<SolveSessionRow> {
  final String id;
  final String inputType;
  final String? rawInputText;
  final String? parsedQuestionJson;
  final String status;
  final int createdAt;
  final int updatedAt;
  const SolveSessionRow({
    required this.id,
    required this.inputType,
    this.rawInputText,
    this.parsedQuestionJson,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['input_type'] = Variable<String>(inputType);
    if (!nullToAbsent || rawInputText != null) {
      map['raw_input_text'] = Variable<String>(rawInputText);
    }
    if (!nullToAbsent || parsedQuestionJson != null) {
      map['parsed_question_json'] = Variable<String>(parsedQuestionJson);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SolveSessionsCompanion toCompanion(bool nullToAbsent) {
    return SolveSessionsCompanion(
      id: Value(id),
      inputType: Value(inputType),
      rawInputText: rawInputText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawInputText),
      parsedQuestionJson: parsedQuestionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedQuestionJson),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SolveSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolveSessionRow(
      id: serializer.fromJson<String>(json['id']),
      inputType: serializer.fromJson<String>(json['inputType']),
      rawInputText: serializer.fromJson<String?>(json['rawInputText']),
      parsedQuestionJson: serializer.fromJson<String?>(
        json['parsedQuestionJson'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inputType': serializer.toJson<String>(inputType),
      'rawInputText': serializer.toJson<String?>(rawInputText),
      'parsedQuestionJson': serializer.toJson<String?>(parsedQuestionJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SolveSessionRow copyWith({
    String? id,
    String? inputType,
    Value<String?> rawInputText = const Value.absent(),
    Value<String?> parsedQuestionJson = const Value.absent(),
    String? status,
    int? createdAt,
    int? updatedAt,
  }) => SolveSessionRow(
    id: id ?? this.id,
    inputType: inputType ?? this.inputType,
    rawInputText: rawInputText.present ? rawInputText.value : this.rawInputText,
    parsedQuestionJson: parsedQuestionJson.present
        ? parsedQuestionJson.value
        : this.parsedQuestionJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SolveSessionRow copyWithCompanion(SolveSessionsCompanion data) {
    return SolveSessionRow(
      id: data.id.present ? data.id.value : this.id,
      inputType: data.inputType.present ? data.inputType.value : this.inputType,
      rawInputText: data.rawInputText.present
          ? data.rawInputText.value
          : this.rawInputText,
      parsedQuestionJson: data.parsedQuestionJson.present
          ? data.parsedQuestionJson.value
          : this.parsedQuestionJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolveSessionRow(')
          ..write('id: $id, ')
          ..write('inputType: $inputType, ')
          ..write('rawInputText: $rawInputText, ')
          ..write('parsedQuestionJson: $parsedQuestionJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inputType,
    rawInputText,
    parsedQuestionJson,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolveSessionRow &&
          other.id == this.id &&
          other.inputType == this.inputType &&
          other.rawInputText == this.rawInputText &&
          other.parsedQuestionJson == this.parsedQuestionJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SolveSessionsCompanion extends UpdateCompanion<SolveSessionRow> {
  final Value<String> id;
  final Value<String> inputType;
  final Value<String?> rawInputText;
  final Value<String?> parsedQuestionJson;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SolveSessionsCompanion({
    this.id = const Value.absent(),
    this.inputType = const Value.absent(),
    this.rawInputText = const Value.absent(),
    this.parsedQuestionJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SolveSessionsCompanion.insert({
    required String id,
    required String inputType,
    this.rawInputText = const Value.absent(),
    this.parsedQuestionJson = const Value.absent(),
    required String status,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inputType = Value(inputType),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SolveSessionRow> custom({
    Expression<String>? id,
    Expression<String>? inputType,
    Expression<String>? rawInputText,
    Expression<String>? parsedQuestionJson,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inputType != null) 'input_type': inputType,
      if (rawInputText != null) 'raw_input_text': rawInputText,
      if (parsedQuestionJson != null)
        'parsed_question_json': parsedQuestionJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SolveSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? inputType,
    Value<String?>? rawInputText,
    Value<String?>? parsedQuestionJson,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SolveSessionsCompanion(
      id: id ?? this.id,
      inputType: inputType ?? this.inputType,
      rawInputText: rawInputText ?? this.rawInputText,
      parsedQuestionJson: parsedQuestionJson ?? this.parsedQuestionJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
    if (inputType.present) {
      map['input_type'] = Variable<String>(inputType.value);
    }
    if (rawInputText.present) {
      map['raw_input_text'] = Variable<String>(rawInputText.value);
    }
    if (parsedQuestionJson.present) {
      map['parsed_question_json'] = Variable<String>(parsedQuestionJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolveSessionsCompanion(')
          ..write('id: $id, ')
          ..write('inputType: $inputType, ')
          ..write('rawInputText: $rawInputText, ')
          ..write('parsedQuestionJson: $parsedQuestionJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SolveResultsTable extends SolveResults
    with TableInfo<$SolveResultsTable, SolveResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolveResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES solve_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _questionTypeMeta = const VerificationMeta(
    'questionType',
  );
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
    'question_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalAnswerLabelMeta = const VerificationMeta(
    'finalAnswerLabel',
  );
  @override
  late final GeneratedColumn<String> finalAnswerLabel = GeneratedColumn<String>(
    'final_answer_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalAnswerContentMeta =
      const VerificationMeta('finalAnswerContent');
  @override
  late final GeneratedColumn<String> finalAnswerContent =
      GeneratedColumn<String>(
        'final_answer_content',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _shortAnswerMeta = const VerificationMeta(
    'shortAnswer',
  );
  @override
  late final GeneratedColumn<String> shortAnswer = GeneratedColumn<String>(
    'short_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMarkdownMeta =
      const VerificationMeta('explanationMarkdown');
  @override
  late final GeneratedColumn<String> explanationMarkdown =
      GeneratedColumn<String>(
        'explanation_markdown',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _confidenceLevelMeta = const VerificationMeta(
    'confidenceLevel',
  );
  @override
  late final GeneratedColumn<String> confidenceLevel = GeneratedColumn<String>(
    'confidence_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelKnowledgeUsedMeta =
      const VerificationMeta('modelKnowledgeUsed');
  @override
  late final GeneratedColumn<int> modelKnowledgeUsed = GeneratedColumn<int>(
    'model_knowledge_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missingInformationMeta =
      const VerificationMeta('missingInformation');
  @override
  late final GeneratedColumn<int> missingInformation = GeneratedColumn<int>(
    'missing_information',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _warningsJsonMeta = const VerificationMeta(
    'warningsJson',
  );
  @override
  late final GeneratedColumn<String> warningsJson = GeneratedColumn<String>(
    'warnings_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<String> promptVersion = GeneratedColumn<String>(
    'prompt_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawResponseJsonMeta = const VerificationMeta(
    'rawResponseJson',
  );
  @override
  late final GeneratedColumn<String> rawResponseJson = GeneratedColumn<String>(
    'raw_response_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    questionType,
    finalAnswerLabel,
    finalAnswerContent,
    shortAnswer,
    explanationMarkdown,
    confidenceLevel,
    modelKnowledgeUsed,
    missingInformation,
    warningsJson,
    promptVersion,
    rawResponseJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solve_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolveResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('question_type')) {
      context.handle(
        _questionTypeMeta,
        questionType.isAcceptableOrUnknown(
          data['question_type']!,
          _questionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTypeMeta);
    }
    if (data.containsKey('final_answer_label')) {
      context.handle(
        _finalAnswerLabelMeta,
        finalAnswerLabel.isAcceptableOrUnknown(
          data['final_answer_label']!,
          _finalAnswerLabelMeta,
        ),
      );
    }
    if (data.containsKey('final_answer_content')) {
      context.handle(
        _finalAnswerContentMeta,
        finalAnswerContent.isAcceptableOrUnknown(
          data['final_answer_content']!,
          _finalAnswerContentMeta,
        ),
      );
    }
    if (data.containsKey('short_answer')) {
      context.handle(
        _shortAnswerMeta,
        shortAnswer.isAcceptableOrUnknown(
          data['short_answer']!,
          _shortAnswerMeta,
        ),
      );
    }
    if (data.containsKey('explanation_markdown')) {
      context.handle(
        _explanationMarkdownMeta,
        explanationMarkdown.isAcceptableOrUnknown(
          data['explanation_markdown']!,
          _explanationMarkdownMeta,
        ),
      );
    }
    if (data.containsKey('confidence_level')) {
      context.handle(
        _confidenceLevelMeta,
        confidenceLevel.isAcceptableOrUnknown(
          data['confidence_level']!,
          _confidenceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confidenceLevelMeta);
    }
    if (data.containsKey('model_knowledge_used')) {
      context.handle(
        _modelKnowledgeUsedMeta,
        modelKnowledgeUsed.isAcceptableOrUnknown(
          data['model_knowledge_used']!,
          _modelKnowledgeUsedMeta,
        ),
      );
    }
    if (data.containsKey('missing_information')) {
      context.handle(
        _missingInformationMeta,
        missingInformation.isAcceptableOrUnknown(
          data['missing_information']!,
          _missingInformationMeta,
        ),
      );
    }
    if (data.containsKey('warnings_json')) {
      context.handle(
        _warningsJsonMeta,
        warningsJson.isAcceptableOrUnknown(
          data['warnings_json']!,
          _warningsJsonMeta,
        ),
      );
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    }
    if (data.containsKey('raw_response_json')) {
      context.handle(
        _rawResponseJsonMeta,
        rawResponseJson.isAcceptableOrUnknown(
          data['raw_response_json']!,
          _rawResponseJsonMeta,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolveResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolveResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      questionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_type'],
      )!,
      finalAnswerLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_answer_label'],
      ),
      finalAnswerContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_answer_content'],
      ),
      shortAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_answer'],
      ),
      explanationMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_markdown'],
      ),
      confidenceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence_level'],
      )!,
      modelKnowledgeUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}model_knowledge_used'],
      )!,
      missingInformation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}missing_information'],
      )!,
      warningsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings_json'],
      ),
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_version'],
      ),
      rawResponseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_response_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SolveResultsTable createAlias(String alias) {
    return $SolveResultsTable(attachedDatabase, alias);
  }
}

class SolveResultRow extends DataClass implements Insertable<SolveResultRow> {
  final String id;
  final String sessionId;
  final String questionType;
  final String? finalAnswerLabel;
  final String? finalAnswerContent;
  final String? shortAnswer;
  final String? explanationMarkdown;
  final String confidenceLevel;
  final int modelKnowledgeUsed;
  final int missingInformation;
  final String? warningsJson;
  final String? promptVersion;
  final String? rawResponseJson;
  final int createdAt;
  const SolveResultRow({
    required this.id,
    required this.sessionId,
    required this.questionType,
    this.finalAnswerLabel,
    this.finalAnswerContent,
    this.shortAnswer,
    this.explanationMarkdown,
    required this.confidenceLevel,
    required this.modelKnowledgeUsed,
    required this.missingInformation,
    this.warningsJson,
    this.promptVersion,
    this.rawResponseJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['question_type'] = Variable<String>(questionType);
    if (!nullToAbsent || finalAnswerLabel != null) {
      map['final_answer_label'] = Variable<String>(finalAnswerLabel);
    }
    if (!nullToAbsent || finalAnswerContent != null) {
      map['final_answer_content'] = Variable<String>(finalAnswerContent);
    }
    if (!nullToAbsent || shortAnswer != null) {
      map['short_answer'] = Variable<String>(shortAnswer);
    }
    if (!nullToAbsent || explanationMarkdown != null) {
      map['explanation_markdown'] = Variable<String>(explanationMarkdown);
    }
    map['confidence_level'] = Variable<String>(confidenceLevel);
    map['model_knowledge_used'] = Variable<int>(modelKnowledgeUsed);
    map['missing_information'] = Variable<int>(missingInformation);
    if (!nullToAbsent || warningsJson != null) {
      map['warnings_json'] = Variable<String>(warningsJson);
    }
    if (!nullToAbsent || promptVersion != null) {
      map['prompt_version'] = Variable<String>(promptVersion);
    }
    if (!nullToAbsent || rawResponseJson != null) {
      map['raw_response_json'] = Variable<String>(rawResponseJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SolveResultsCompanion toCompanion(bool nullToAbsent) {
    return SolveResultsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      questionType: Value(questionType),
      finalAnswerLabel: finalAnswerLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(finalAnswerLabel),
      finalAnswerContent: finalAnswerContent == null && nullToAbsent
          ? const Value.absent()
          : Value(finalAnswerContent),
      shortAnswer: shortAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(shortAnswer),
      explanationMarkdown: explanationMarkdown == null && nullToAbsent
          ? const Value.absent()
          : Value(explanationMarkdown),
      confidenceLevel: Value(confidenceLevel),
      modelKnowledgeUsed: Value(modelKnowledgeUsed),
      missingInformation: Value(missingInformation),
      warningsJson: warningsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(warningsJson),
      promptVersion: promptVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(promptVersion),
      rawResponseJson: rawResponseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawResponseJson),
      createdAt: Value(createdAt),
    );
  }

  factory SolveResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolveResultRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      questionType: serializer.fromJson<String>(json['questionType']),
      finalAnswerLabel: serializer.fromJson<String?>(json['finalAnswerLabel']),
      finalAnswerContent: serializer.fromJson<String?>(
        json['finalAnswerContent'],
      ),
      shortAnswer: serializer.fromJson<String?>(json['shortAnswer']),
      explanationMarkdown: serializer.fromJson<String?>(
        json['explanationMarkdown'],
      ),
      confidenceLevel: serializer.fromJson<String>(json['confidenceLevel']),
      modelKnowledgeUsed: serializer.fromJson<int>(json['modelKnowledgeUsed']),
      missingInformation: serializer.fromJson<int>(json['missingInformation']),
      warningsJson: serializer.fromJson<String?>(json['warningsJson']),
      promptVersion: serializer.fromJson<String?>(json['promptVersion']),
      rawResponseJson: serializer.fromJson<String?>(json['rawResponseJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'questionType': serializer.toJson<String>(questionType),
      'finalAnswerLabel': serializer.toJson<String?>(finalAnswerLabel),
      'finalAnswerContent': serializer.toJson<String?>(finalAnswerContent),
      'shortAnswer': serializer.toJson<String?>(shortAnswer),
      'explanationMarkdown': serializer.toJson<String?>(explanationMarkdown),
      'confidenceLevel': serializer.toJson<String>(confidenceLevel),
      'modelKnowledgeUsed': serializer.toJson<int>(modelKnowledgeUsed),
      'missingInformation': serializer.toJson<int>(missingInformation),
      'warningsJson': serializer.toJson<String?>(warningsJson),
      'promptVersion': serializer.toJson<String?>(promptVersion),
      'rawResponseJson': serializer.toJson<String?>(rawResponseJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SolveResultRow copyWith({
    String? id,
    String? sessionId,
    String? questionType,
    Value<String?> finalAnswerLabel = const Value.absent(),
    Value<String?> finalAnswerContent = const Value.absent(),
    Value<String?> shortAnswer = const Value.absent(),
    Value<String?> explanationMarkdown = const Value.absent(),
    String? confidenceLevel,
    int? modelKnowledgeUsed,
    int? missingInformation,
    Value<String?> warningsJson = const Value.absent(),
    Value<String?> promptVersion = const Value.absent(),
    Value<String?> rawResponseJson = const Value.absent(),
    int? createdAt,
  }) => SolveResultRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    questionType: questionType ?? this.questionType,
    finalAnswerLabel: finalAnswerLabel.present
        ? finalAnswerLabel.value
        : this.finalAnswerLabel,
    finalAnswerContent: finalAnswerContent.present
        ? finalAnswerContent.value
        : this.finalAnswerContent,
    shortAnswer: shortAnswer.present ? shortAnswer.value : this.shortAnswer,
    explanationMarkdown: explanationMarkdown.present
        ? explanationMarkdown.value
        : this.explanationMarkdown,
    confidenceLevel: confidenceLevel ?? this.confidenceLevel,
    modelKnowledgeUsed: modelKnowledgeUsed ?? this.modelKnowledgeUsed,
    missingInformation: missingInformation ?? this.missingInformation,
    warningsJson: warningsJson.present ? warningsJson.value : this.warningsJson,
    promptVersion: promptVersion.present
        ? promptVersion.value
        : this.promptVersion,
    rawResponseJson: rawResponseJson.present
        ? rawResponseJson.value
        : this.rawResponseJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SolveResultRow copyWithCompanion(SolveResultsCompanion data) {
    return SolveResultRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      finalAnswerLabel: data.finalAnswerLabel.present
          ? data.finalAnswerLabel.value
          : this.finalAnswerLabel,
      finalAnswerContent: data.finalAnswerContent.present
          ? data.finalAnswerContent.value
          : this.finalAnswerContent,
      shortAnswer: data.shortAnswer.present
          ? data.shortAnswer.value
          : this.shortAnswer,
      explanationMarkdown: data.explanationMarkdown.present
          ? data.explanationMarkdown.value
          : this.explanationMarkdown,
      confidenceLevel: data.confidenceLevel.present
          ? data.confidenceLevel.value
          : this.confidenceLevel,
      modelKnowledgeUsed: data.modelKnowledgeUsed.present
          ? data.modelKnowledgeUsed.value
          : this.modelKnowledgeUsed,
      missingInformation: data.missingInformation.present
          ? data.missingInformation.value
          : this.missingInformation,
      warningsJson: data.warningsJson.present
          ? data.warningsJson.value
          : this.warningsJson,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      rawResponseJson: data.rawResponseJson.present
          ? data.rawResponseJson.value
          : this.rawResponseJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolveResultRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('questionType: $questionType, ')
          ..write('finalAnswerLabel: $finalAnswerLabel, ')
          ..write('finalAnswerContent: $finalAnswerContent, ')
          ..write('shortAnswer: $shortAnswer, ')
          ..write('explanationMarkdown: $explanationMarkdown, ')
          ..write('confidenceLevel: $confidenceLevel, ')
          ..write('modelKnowledgeUsed: $modelKnowledgeUsed, ')
          ..write('missingInformation: $missingInformation, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('rawResponseJson: $rawResponseJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    questionType,
    finalAnswerLabel,
    finalAnswerContent,
    shortAnswer,
    explanationMarkdown,
    confidenceLevel,
    modelKnowledgeUsed,
    missingInformation,
    warningsJson,
    promptVersion,
    rawResponseJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolveResultRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.questionType == this.questionType &&
          other.finalAnswerLabel == this.finalAnswerLabel &&
          other.finalAnswerContent == this.finalAnswerContent &&
          other.shortAnswer == this.shortAnswer &&
          other.explanationMarkdown == this.explanationMarkdown &&
          other.confidenceLevel == this.confidenceLevel &&
          other.modelKnowledgeUsed == this.modelKnowledgeUsed &&
          other.missingInformation == this.missingInformation &&
          other.warningsJson == this.warningsJson &&
          other.promptVersion == this.promptVersion &&
          other.rawResponseJson == this.rawResponseJson &&
          other.createdAt == this.createdAt);
}

class SolveResultsCompanion extends UpdateCompanion<SolveResultRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> questionType;
  final Value<String?> finalAnswerLabel;
  final Value<String?> finalAnswerContent;
  final Value<String?> shortAnswer;
  final Value<String?> explanationMarkdown;
  final Value<String> confidenceLevel;
  final Value<int> modelKnowledgeUsed;
  final Value<int> missingInformation;
  final Value<String?> warningsJson;
  final Value<String?> promptVersion;
  final Value<String?> rawResponseJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SolveResultsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.questionType = const Value.absent(),
    this.finalAnswerLabel = const Value.absent(),
    this.finalAnswerContent = const Value.absent(),
    this.shortAnswer = const Value.absent(),
    this.explanationMarkdown = const Value.absent(),
    this.confidenceLevel = const Value.absent(),
    this.modelKnowledgeUsed = const Value.absent(),
    this.missingInformation = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.rawResponseJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SolveResultsCompanion.insert({
    required String id,
    required String sessionId,
    required String questionType,
    this.finalAnswerLabel = const Value.absent(),
    this.finalAnswerContent = const Value.absent(),
    this.shortAnswer = const Value.absent(),
    this.explanationMarkdown = const Value.absent(),
    required String confidenceLevel,
    this.modelKnowledgeUsed = const Value.absent(),
    this.missingInformation = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.rawResponseJson = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       questionType = Value(questionType),
       confidenceLevel = Value(confidenceLevel),
       createdAt = Value(createdAt);
  static Insertable<SolveResultRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? questionType,
    Expression<String>? finalAnswerLabel,
    Expression<String>? finalAnswerContent,
    Expression<String>? shortAnswer,
    Expression<String>? explanationMarkdown,
    Expression<String>? confidenceLevel,
    Expression<int>? modelKnowledgeUsed,
    Expression<int>? missingInformation,
    Expression<String>? warningsJson,
    Expression<String>? promptVersion,
    Expression<String>? rawResponseJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (questionType != null) 'question_type': questionType,
      if (finalAnswerLabel != null) 'final_answer_label': finalAnswerLabel,
      if (finalAnswerContent != null)
        'final_answer_content': finalAnswerContent,
      if (shortAnswer != null) 'short_answer': shortAnswer,
      if (explanationMarkdown != null)
        'explanation_markdown': explanationMarkdown,
      if (confidenceLevel != null) 'confidence_level': confidenceLevel,
      if (modelKnowledgeUsed != null)
        'model_knowledge_used': modelKnowledgeUsed,
      if (missingInformation != null) 'missing_information': missingInformation,
      if (warningsJson != null) 'warnings_json': warningsJson,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (rawResponseJson != null) 'raw_response_json': rawResponseJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SolveResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? questionType,
    Value<String?>? finalAnswerLabel,
    Value<String?>? finalAnswerContent,
    Value<String?>? shortAnswer,
    Value<String?>? explanationMarkdown,
    Value<String>? confidenceLevel,
    Value<int>? modelKnowledgeUsed,
    Value<int>? missingInformation,
    Value<String?>? warningsJson,
    Value<String?>? promptVersion,
    Value<String?>? rawResponseJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SolveResultsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      questionType: questionType ?? this.questionType,
      finalAnswerLabel: finalAnswerLabel ?? this.finalAnswerLabel,
      finalAnswerContent: finalAnswerContent ?? this.finalAnswerContent,
      shortAnswer: shortAnswer ?? this.shortAnswer,
      explanationMarkdown: explanationMarkdown ?? this.explanationMarkdown,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      modelKnowledgeUsed: modelKnowledgeUsed ?? this.modelKnowledgeUsed,
      missingInformation: missingInformation ?? this.missingInformation,
      warningsJson: warningsJson ?? this.warningsJson,
      promptVersion: promptVersion ?? this.promptVersion,
      rawResponseJson: rawResponseJson ?? this.rawResponseJson,
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
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (finalAnswerLabel.present) {
      map['final_answer_label'] = Variable<String>(finalAnswerLabel.value);
    }
    if (finalAnswerContent.present) {
      map['final_answer_content'] = Variable<String>(finalAnswerContent.value);
    }
    if (shortAnswer.present) {
      map['short_answer'] = Variable<String>(shortAnswer.value);
    }
    if (explanationMarkdown.present) {
      map['explanation_markdown'] = Variable<String>(explanationMarkdown.value);
    }
    if (confidenceLevel.present) {
      map['confidence_level'] = Variable<String>(confidenceLevel.value);
    }
    if (modelKnowledgeUsed.present) {
      map['model_knowledge_used'] = Variable<int>(modelKnowledgeUsed.value);
    }
    if (missingInformation.present) {
      map['missing_information'] = Variable<int>(missingInformation.value);
    }
    if (warningsJson.present) {
      map['warnings_json'] = Variable<String>(warningsJson.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<String>(promptVersion.value);
    }
    if (rawResponseJson.present) {
      map['raw_response_json'] = Variable<String>(rawResponseJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolveResultsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('questionType: $questionType, ')
          ..write('finalAnswerLabel: $finalAnswerLabel, ')
          ..write('finalAnswerContent: $finalAnswerContent, ')
          ..write('shortAnswer: $shortAnswer, ')
          ..write('explanationMarkdown: $explanationMarkdown, ')
          ..write('confidenceLevel: $confidenceLevel, ')
          ..write('modelKnowledgeUsed: $modelKnowledgeUsed, ')
          ..write('missingInformation: $missingInformation, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('rawResponseJson: $rawResponseJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResultReferencesTable extends ResultReferences
    with TableInfo<$ResultReferencesTable, ResultReferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResultReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultIdMeta = const VerificationMeta(
    'resultId',
  );
  @override
  late final GeneratedColumn<String> resultId = GeneratedColumn<String>(
    'result_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES solve_results (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _evidenceIdMeta = const VerificationMeta(
    'evidenceId',
  );
  @override
  late final GeneratedColumn<String> evidenceId = GeneratedColumn<String>(
    'evidence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resultId,
    evidenceId,
    localId,
    sourceTitle,
    page,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'result_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResultReferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('result_id')) {
      context.handle(
        _resultIdMeta,
        resultId.isAcceptableOrUnknown(data['result_id']!, _resultIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resultIdMeta);
    }
    if (data.containsKey('evidence_id')) {
      context.handle(
        _evidenceIdMeta,
        evidenceId.isAcceptableOrUnknown(data['evidence_id']!, _evidenceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_evidenceIdMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResultReferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResultReferenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      resultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_id'],
      )!,
      evidenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      ),
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ResultReferencesTable createAlias(String alias) {
    return $ResultReferencesTable(attachedDatabase, alias);
  }
}

class ResultReferenceRow extends DataClass
    implements Insertable<ResultReferenceRow> {
  final String id;
  final String resultId;
  final String evidenceId;
  final String localId;
  final String? sourceTitle;
  final int? page;
  final int sortOrder;
  const ResultReferenceRow({
    required this.id,
    required this.resultId,
    required this.evidenceId,
    required this.localId,
    this.sourceTitle,
    this.page,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['result_id'] = Variable<String>(resultId);
    map['evidence_id'] = Variable<String>(evidenceId);
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || sourceTitle != null) {
      map['source_title'] = Variable<String>(sourceTitle);
    }
    if (!nullToAbsent || page != null) {
      map['page'] = Variable<int>(page);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ResultReferencesCompanion toCompanion(bool nullToAbsent) {
    return ResultReferencesCompanion(
      id: Value(id),
      resultId: Value(resultId),
      evidenceId: Value(evidenceId),
      localId: Value(localId),
      sourceTitle: sourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTitle),
      page: page == null && nullToAbsent ? const Value.absent() : Value(page),
      sortOrder: Value(sortOrder),
    );
  }

  factory ResultReferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResultReferenceRow(
      id: serializer.fromJson<String>(json['id']),
      resultId: serializer.fromJson<String>(json['resultId']),
      evidenceId: serializer.fromJson<String>(json['evidenceId']),
      localId: serializer.fromJson<String>(json['localId']),
      sourceTitle: serializer.fromJson<String?>(json['sourceTitle']),
      page: serializer.fromJson<int?>(json['page']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'resultId': serializer.toJson<String>(resultId),
      'evidenceId': serializer.toJson<String>(evidenceId),
      'localId': serializer.toJson<String>(localId),
      'sourceTitle': serializer.toJson<String?>(sourceTitle),
      'page': serializer.toJson<int?>(page),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ResultReferenceRow copyWith({
    String? id,
    String? resultId,
    String? evidenceId,
    String? localId,
    Value<String?> sourceTitle = const Value.absent(),
    Value<int?> page = const Value.absent(),
    int? sortOrder,
  }) => ResultReferenceRow(
    id: id ?? this.id,
    resultId: resultId ?? this.resultId,
    evidenceId: evidenceId ?? this.evidenceId,
    localId: localId ?? this.localId,
    sourceTitle: sourceTitle.present ? sourceTitle.value : this.sourceTitle,
    page: page.present ? page.value : this.page,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ResultReferenceRow copyWithCompanion(ResultReferencesCompanion data) {
    return ResultReferenceRow(
      id: data.id.present ? data.id.value : this.id,
      resultId: data.resultId.present ? data.resultId.value : this.resultId,
      evidenceId: data.evidenceId.present
          ? data.evidenceId.value
          : this.evidenceId,
      localId: data.localId.present ? data.localId.value : this.localId,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      page: data.page.present ? data.page.value : this.page,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResultReferenceRow(')
          ..write('id: $id, ')
          ..write('resultId: $resultId, ')
          ..write('evidenceId: $evidenceId, ')
          ..write('localId: $localId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('page: $page, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    resultId,
    evidenceId,
    localId,
    sourceTitle,
    page,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResultReferenceRow &&
          other.id == this.id &&
          other.resultId == this.resultId &&
          other.evidenceId == this.evidenceId &&
          other.localId == this.localId &&
          other.sourceTitle == this.sourceTitle &&
          other.page == this.page &&
          other.sortOrder == this.sortOrder);
}

class ResultReferencesCompanion extends UpdateCompanion<ResultReferenceRow> {
  final Value<String> id;
  final Value<String> resultId;
  final Value<String> evidenceId;
  final Value<String> localId;
  final Value<String?> sourceTitle;
  final Value<int?> page;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ResultReferencesCompanion({
    this.id = const Value.absent(),
    this.resultId = const Value.absent(),
    this.evidenceId = const Value.absent(),
    this.localId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.page = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResultReferencesCompanion.insert({
    required String id,
    required String resultId,
    required String evidenceId,
    required String localId,
    this.sourceTitle = const Value.absent(),
    this.page = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       resultId = Value(resultId),
       evidenceId = Value(evidenceId),
       localId = Value(localId),
       sortOrder = Value(sortOrder);
  static Insertable<ResultReferenceRow> custom({
    Expression<String>? id,
    Expression<String>? resultId,
    Expression<String>? evidenceId,
    Expression<String>? localId,
    Expression<String>? sourceTitle,
    Expression<int>? page,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resultId != null) 'result_id': resultId,
      if (evidenceId != null) 'evidence_id': evidenceId,
      if (localId != null) 'local_id': localId,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (page != null) 'page': page,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResultReferencesCompanion copyWith({
    Value<String>? id,
    Value<String>? resultId,
    Value<String>? evidenceId,
    Value<String>? localId,
    Value<String?>? sourceTitle,
    Value<int?>? page,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ResultReferencesCompanion(
      id: id ?? this.id,
      resultId: resultId ?? this.resultId,
      evidenceId: evidenceId ?? this.evidenceId,
      localId: localId ?? this.localId,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      page: page ?? this.page,
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
    if (resultId.present) {
      map['result_id'] = Variable<String>(resultId.value);
    }
    if (evidenceId.present) {
      map['evidence_id'] = Variable<String>(evidenceId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
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
    return (StringBuffer('ResultReferencesCompanion(')
          ..write('id: $id, ')
          ..write('resultId: $resultId, ')
          ..write('evidenceId: $evidenceId, ')
          ..write('localId: $localId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('page: $page, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserFeedbackTable extends UserFeedback
    with TableInfo<$UserFeedbackTable, UserFeedbackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultIdMeta = const VerificationMeta(
    'resultId',
  );
  @override
  late final GeneratedColumn<String> resultId = GeneratedColumn<String>(
    'result_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES solve_results (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _feedbackTypeMeta = const VerificationMeta(
    'feedbackType',
  );
  @override
  late final GeneratedColumn<String> feedbackType = GeneratedColumn<String>(
    'feedback_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resultId,
    feedbackType,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserFeedbackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('result_id')) {
      context.handle(
        _resultIdMeta,
        resultId.isAcceptableOrUnknown(data['result_id']!, _resultIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resultIdMeta);
    }
    if (data.containsKey('feedback_type')) {
      context.handle(
        _feedbackTypeMeta,
        feedbackType.isAcceptableOrUnknown(
          data['feedback_type']!,
          _feedbackTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_feedbackTypeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserFeedbackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFeedbackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      resultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_id'],
      )!,
      feedbackType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback_type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserFeedbackTable createAlias(String alias) {
    return $UserFeedbackTable(attachedDatabase, alias);
  }
}

class UserFeedbackRow extends DataClass implements Insertable<UserFeedbackRow> {
  final String id;
  final String resultId;
  final String feedbackType;
  final String? note;
  final int createdAt;
  const UserFeedbackRow({
    required this.id,
    required this.resultId,
    required this.feedbackType,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['result_id'] = Variable<String>(resultId);
    map['feedback_type'] = Variable<String>(feedbackType);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UserFeedbackCompanion toCompanion(bool nullToAbsent) {
    return UserFeedbackCompanion(
      id: Value(id),
      resultId: Value(resultId),
      feedbackType: Value(feedbackType),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory UserFeedbackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFeedbackRow(
      id: serializer.fromJson<String>(json['id']),
      resultId: serializer.fromJson<String>(json['resultId']),
      feedbackType: serializer.fromJson<String>(json['feedbackType']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'resultId': serializer.toJson<String>(resultId),
      'feedbackType': serializer.toJson<String>(feedbackType),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UserFeedbackRow copyWith({
    String? id,
    String? resultId,
    String? feedbackType,
    Value<String?> note = const Value.absent(),
    int? createdAt,
  }) => UserFeedbackRow(
    id: id ?? this.id,
    resultId: resultId ?? this.resultId,
    feedbackType: feedbackType ?? this.feedbackType,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  UserFeedbackRow copyWithCompanion(UserFeedbackCompanion data) {
    return UserFeedbackRow(
      id: data.id.present ? data.id.value : this.id,
      resultId: data.resultId.present ? data.resultId.value : this.resultId,
      feedbackType: data.feedbackType.present
          ? data.feedbackType.value
          : this.feedbackType,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFeedbackRow(')
          ..write('id: $id, ')
          ..write('resultId: $resultId, ')
          ..write('feedbackType: $feedbackType, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, resultId, feedbackType, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFeedbackRow &&
          other.id == this.id &&
          other.resultId == this.resultId &&
          other.feedbackType == this.feedbackType &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class UserFeedbackCompanion extends UpdateCompanion<UserFeedbackRow> {
  final Value<String> id;
  final Value<String> resultId;
  final Value<String> feedbackType;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> rowid;
  const UserFeedbackCompanion({
    this.id = const Value.absent(),
    this.resultId = const Value.absent(),
    this.feedbackType = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserFeedbackCompanion.insert({
    required String id,
    required String resultId,
    required String feedbackType,
    this.note = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       resultId = Value(resultId),
       feedbackType = Value(feedbackType),
       createdAt = Value(createdAt);
  static Insertable<UserFeedbackRow> custom({
    Expression<String>? id,
    Expression<String>? resultId,
    Expression<String>? feedbackType,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resultId != null) 'result_id': resultId,
      if (feedbackType != null) 'feedback_type': feedbackType,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserFeedbackCompanion copyWith({
    Value<String>? id,
    Value<String>? resultId,
    Value<String>? feedbackType,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return UserFeedbackCompanion(
      id: id ?? this.id,
      resultId: resultId ?? this.resultId,
      feedbackType: feedbackType ?? this.feedbackType,
      note: note ?? this.note,
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
    if (resultId.present) {
      map['result_id'] = Variable<String>(resultId.value);
    }
    if (feedbackType.present) {
      map['feedback_type'] = Variable<String>(feedbackType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFeedbackCompanion(')
          ..write('id: $id, ')
          ..write('resultId: $resultId, ')
          ..write('feedbackType: $feedbackType, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubjectSettingsTable extends SubjectSettings
    with TableInfo<$SubjectSettingsTable, SubjectSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subject_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectSettingRow> instance, {
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SubjectSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubjectSettingsTable createAlias(String alias) {
    return $SubjectSettingsTable(attachedDatabase, alias);
  }
}

class SubjectSettingRow extends DataClass
    implements Insertable<SubjectSettingRow> {
  final String key;
  final String value;
  final int updatedAt;
  const SubjectSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SubjectSettingsCompanion toCompanion(bool nullToAbsent) {
    return SubjectSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubjectSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SubjectSettingRow copyWith({String? key, String? value, int? updatedAt}) =>
      SubjectSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SubjectSettingRow copyWithCompanion(SubjectSettingsCompanion data) {
    return SubjectSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SubjectSettingsCompanion extends UpdateCompanion<SubjectSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SubjectSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectSettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SubjectSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SubjectSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SubjectDatabase extends GeneratedDatabase {
  _$SubjectDatabase(QueryExecutor e) : super(e);
  $SubjectDatabaseManager get managers => $SubjectDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $SourcePagesTable sourcePages = $SourcePagesTable(this);
  late final $KnowledgeUnitsTable knowledgeUnits = $KnowledgeUnitsTable(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $QuestionChoicesTable questionChoices = $QuestionChoicesTable(
    this,
  );
  late final $KnowledgeRelationsTable knowledgeRelations =
      $KnowledgeRelationsTable(this);
  late final $OcrRunsTable ocrRuns = $OcrRunsTable(this);
  late final $IngestionJobsTable ingestionJobs = $IngestionJobsTable(this);
  late final $SolveSessionsTable solveSessions = $SolveSessionsTable(this);
  late final $SolveResultsTable solveResults = $SolveResultsTable(this);
  late final $ResultReferencesTable resultReferences = $ResultReferencesTable(
    this,
  );
  late final $UserFeedbackTable userFeedback = $UserFeedbackTable(this);
  late final $SubjectSettingsTable subjectSettings = $SubjectSettingsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    sourcePages,
    knowledgeUnits,
    questions,
    questionChoices,
    knowledgeRelations,
    ocrRuns,
    ingestionJobs,
    solveSessions,
    solveResults,
    resultReferences,
    userFeedback,
    subjectSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('source_pages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('knowledge_units', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'knowledge_units',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('questions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'questions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('question_choices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'knowledge_units',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('knowledge_relations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'knowledge_units',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('knowledge_relations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ocr_runs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'solve_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('solve_results', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'solve_results',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('result_references', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'solve_results',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_feedback', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      required String id,
      required String type,
      required String title,
      Value<String?> originalRelativePath,
      required String contentSha256,
      Value<int?> pageCount,
      required String processingStatus,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String?> originalRelativePath,
      Value<String> contentSha256,
      Value<int?> pageCount,
      Value<String> processingStatus,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$SourcesTableReferences
    extends BaseReferences<_$SubjectDatabase, $SourcesTable, SourceRow> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SourcePagesTable, List<SourcePageRow>>
  _sourcePagesRefsTable(_$SubjectDatabase db) => MultiTypedResultKey.fromTable(
    db.sourcePages,
    aliasName: 'sources__id__source_pages__source_id',
  );

  $$SourcePagesTableProcessedTableManager get sourcePagesRefs {
    final manager = $$SourcePagesTableTableManager(
      $_db,
      $_db.sourcePages,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourcePagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KnowledgeUnitsTable, List<KnowledgeUnitRow>>
  _knowledgeUnitsRefsTable(_$SubjectDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.knowledgeUnits,
        aliasName: 'sources__id__knowledge_units__source_id',
      );

  $$KnowledgeUnitsTableProcessedTableManager get knowledgeUnitsRefs {
    final manager = $$KnowledgeUnitsTableTableManager(
      $_db,
      $_db.knowledgeUnits,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_knowledgeUnitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OcrRunsTable, List<OcrRunRow>> _ocrRunsRefsTable(
    _$SubjectDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ocrRuns,
    aliasName: 'sources__id__ocr_runs__source_id',
  );

  $$OcrRunsTableProcessedTableManager get ocrRunsRefs {
    final manager = $$OcrRunsTableTableManager(
      $_db,
      $_db.ocrRuns,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ocrRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$SubjectDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalRelativePath => $composableBuilder(
    column: $table.originalRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentSha256 => $composableBuilder(
    column: $table.contentSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sourcePagesRefs(
    Expression<bool> Function($$SourcePagesTableFilterComposer f) f,
  ) {
    final $$SourcePagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourcePages,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcePagesTableFilterComposer(
            $db: $db,
            $table: $db.sourcePages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> knowledgeUnitsRefs(
    Expression<bool> Function($$KnowledgeUnitsTableFilterComposer f) f,
  ) {
    final $$KnowledgeUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableFilterComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ocrRunsRefs(
    Expression<bool> Function($$OcrRunsTableFilterComposer f) f,
  ) {
    final $$OcrRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ocrRuns,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrRunsTableFilterComposer(
            $db: $db,
            $table: $db.ocrRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$SubjectDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalRelativePath => $composableBuilder(
    column: $table.originalRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentSha256 => $composableBuilder(
    column: $table.contentSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalRelativePath => $composableBuilder(
    column: $table.originalRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentSha256 => $composableBuilder(
    column: $table.contentSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sourcePagesRefs<T extends Object>(
    Expression<T> Function($$SourcePagesTableAnnotationComposer a) f,
  ) {
    final $$SourcePagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourcePages,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcePagesTableAnnotationComposer(
            $db: $db,
            $table: $db.sourcePages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> knowledgeUnitsRefs<T extends Object>(
    Expression<T> Function($$KnowledgeUnitsTableAnnotationComposer a) f,
  ) {
    final $$KnowledgeUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ocrRunsRefs<T extends Object>(
    Expression<T> Function($$OcrRunsTableAnnotationComposer a) f,
  ) {
    final $$OcrRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ocrRuns,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.ocrRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $SourcesTable,
          SourceRow,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (SourceRow, $$SourcesTableReferences),
          SourceRow,
          PrefetchHooks Function({
            bool sourcePagesRefs,
            bool knowledgeUnitsRefs,
            bool ocrRunsRefs,
          })
        > {
  $$SourcesTableTableManager(_$SubjectDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalRelativePath = const Value.absent(),
                Value<String> contentSha256 = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                type: type,
                title: title,
                originalRelativePath: originalRelativePath,
                contentSha256: contentSha256,
                pageCount: pageCount,
                processingStatus: processingStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String title,
                Value<String?> originalRelativePath = const Value.absent(),
                required String contentSha256,
                Value<int?> pageCount = const Value.absent(),
                required String processingStatus,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                type: type,
                title: title,
                originalRelativePath: originalRelativePath,
                contentSha256: contentSha256,
                pageCount: pageCount,
                processingStatus: processingStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourcePagesRefs = false,
                knowledgeUnitsRefs = false,
                ocrRunsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourcePagesRefs) db.sourcePages,
                    if (knowledgeUnitsRefs) db.knowledgeUnits,
                    if (ocrRunsRefs) db.ocrRuns,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourcePagesRefs)
                        await $_getPrefetchedData<
                          SourceRow,
                          $SourcesTable,
                          SourcePageRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._sourcePagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).sourcePagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (knowledgeUnitsRefs)
                        await $_getPrefetchedData<
                          SourceRow,
                          $SourcesTable,
                          KnowledgeUnitRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._knowledgeUnitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).knowledgeUnitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ocrRunsRefs)
                        await $_getPrefetchedData<
                          SourceRow,
                          $SourcesTable,
                          OcrRunRow
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._ocrRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).ocrRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
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

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $SourcesTable,
      SourceRow,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (SourceRow, $$SourcesTableReferences),
      SourceRow,
      PrefetchHooks Function({
        bool sourcePagesRefs,
        bool knowledgeUnitsRefs,
        bool ocrRunsRefs,
      })
    >;
typedef $$SourcePagesTableCreateCompanionBuilder =
    SourcePagesCompanion Function({
      required String id,
      required String sourceId,
      required int pageNumber,
      Value<String?> imageRelativePath,
      Value<String?> textLayer,
      Value<String?> rawOcrRelativePath,
      Value<String?> normalizedText,
      Value<String?> ocrEngine,
      Value<String?> ocrModelVersion,
      Value<double?> ocrConfidence,
      required String processingStatus,
      Value<int> rowid,
    });
typedef $$SourcePagesTableUpdateCompanionBuilder =
    SourcePagesCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<int> pageNumber,
      Value<String?> imageRelativePath,
      Value<String?> textLayer,
      Value<String?> rawOcrRelativePath,
      Value<String?> normalizedText,
      Value<String?> ocrEngine,
      Value<String?> ocrModelVersion,
      Value<double?> ocrConfidence,
      Value<String> processingStatus,
      Value<int> rowid,
    });

final class $$SourcePagesTableReferences
    extends
        BaseReferences<_$SubjectDatabase, $SourcePagesTable, SourcePageRow> {
  $$SourcePagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$SubjectDatabase db) =>
      db.sources.createAlias('source_pages__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SourcePagesTableFilterComposer
    extends Composer<_$SubjectDatabase, $SourcePagesTable> {
  $$SourcePagesTableFilterComposer({
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

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageRelativePath => $composableBuilder(
    column: $table.imageRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textLayer => $composableBuilder(
    column: $table.textLayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawOcrRelativePath => $composableBuilder(
    column: $table.rawOcrRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrEngine => $composableBuilder(
    column: $table.ocrEngine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrModelVersion => $composableBuilder(
    column: $table.ocrModelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePagesTableOrderingComposer
    extends Composer<_$SubjectDatabase, $SourcePagesTable> {
  $$SourcePagesTableOrderingComposer({
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

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageRelativePath => $composableBuilder(
    column: $table.imageRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textLayer => $composableBuilder(
    column: $table.textLayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawOcrRelativePath => $composableBuilder(
    column: $table.rawOcrRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrEngine => $composableBuilder(
    column: $table.ocrEngine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrModelVersion => $composableBuilder(
    column: $table.ocrModelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePagesTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $SourcePagesTable> {
  $$SourcePagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageRelativePath => $composableBuilder(
    column: $table.imageRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textLayer =>
      $composableBuilder(column: $table.textLayer, builder: (column) => column);

  GeneratedColumn<String> get rawOcrRelativePath => $composableBuilder(
    column: $table.rawOcrRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrEngine =>
      $composableBuilder(column: $table.ocrEngine, builder: (column) => column);

  GeneratedColumn<String> get ocrModelVersion => $composableBuilder(
    column: $table.ocrModelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePagesTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $SourcePagesTable,
          SourcePageRow,
          $$SourcePagesTableFilterComposer,
          $$SourcePagesTableOrderingComposer,
          $$SourcePagesTableAnnotationComposer,
          $$SourcePagesTableCreateCompanionBuilder,
          $$SourcePagesTableUpdateCompanionBuilder,
          (SourcePageRow, $$SourcePagesTableReferences),
          SourcePageRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$SourcePagesTableTableManager(_$SubjectDatabase db, $SourcePagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcePagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcePagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcePagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String?> imageRelativePath = const Value.absent(),
                Value<String?> textLayer = const Value.absent(),
                Value<String?> rawOcrRelativePath = const Value.absent(),
                Value<String?> normalizedText = const Value.absent(),
                Value<String?> ocrEngine = const Value.absent(),
                Value<String?> ocrModelVersion = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcePagesCompanion(
                id: id,
                sourceId: sourceId,
                pageNumber: pageNumber,
                imageRelativePath: imageRelativePath,
                textLayer: textLayer,
                rawOcrRelativePath: rawOcrRelativePath,
                normalizedText: normalizedText,
                ocrEngine: ocrEngine,
                ocrModelVersion: ocrModelVersion,
                ocrConfidence: ocrConfidence,
                processingStatus: processingStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required int pageNumber,
                Value<String?> imageRelativePath = const Value.absent(),
                Value<String?> textLayer = const Value.absent(),
                Value<String?> rawOcrRelativePath = const Value.absent(),
                Value<String?> normalizedText = const Value.absent(),
                Value<String?> ocrEngine = const Value.absent(),
                Value<String?> ocrModelVersion = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                required String processingStatus,
                Value<int> rowid = const Value.absent(),
              }) => SourcePagesCompanion.insert(
                id: id,
                sourceId: sourceId,
                pageNumber: pageNumber,
                imageRelativePath: imageRelativePath,
                textLayer: textLayer,
                rawOcrRelativePath: rawOcrRelativePath,
                normalizedText: normalizedText,
                ocrEngine: ocrEngine,
                ocrModelVersion: ocrModelVersion,
                ocrConfidence: ocrConfidence,
                processingStatus: processingStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcePagesTable, SourcePageRow>(table),
                  $$SourcePagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$SourcePagesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$SourcePagesTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$SourcePagesTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $SourcePagesTable,
      SourcePageRow,
      $$SourcePagesTableFilterComposer,
      $$SourcePagesTableOrderingComposer,
      $$SourcePagesTableAnnotationComposer,
      $$SourcePagesTableCreateCompanionBuilder,
      $$SourcePagesTableUpdateCompanionBuilder,
      (SourcePageRow, $$SourcePagesTableReferences),
      SourcePageRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$KnowledgeUnitsTableCreateCompanionBuilder =
    KnowledgeUnitsCompanion Function({
      required String id,
      required String sourceId,
      Value<String?> sourcePageId,
      required String type,
      required String content,
      required String normalizedContent,
      Value<String?> bboxJson,
      required String verificationStatus,
      Value<int> sourcePriority,
      required String contentHash,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$KnowledgeUnitsTableUpdateCompanionBuilder =
    KnowledgeUnitsCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String?> sourcePageId,
      Value<String> type,
      Value<String> content,
      Value<String> normalizedContent,
      Value<String?> bboxJson,
      Value<String> verificationStatus,
      Value<int> sourcePriority,
      Value<String> contentHash,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$KnowledgeUnitsTableReferences
    extends
        BaseReferences<
          _$SubjectDatabase,
          $KnowledgeUnitsTable,
          KnowledgeUnitRow
        > {
  $$KnowledgeUnitsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$SubjectDatabase db) =>
      db.sources.createAlias('knowledge_units__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestionsTable, List<QuestionRow>>
  _questionsRefsTable(_$SubjectDatabase db) => MultiTypedResultKey.fromTable(
    db.questions,
    aliasName: 'knowledge_units__id__questions__knowledge_unit_id',
  );

  $$QuestionsTableProcessedTableManager get questionsRefs {
    final manager = $$QuestionsTableTableManager($_db, $_db.questions).filter(
      (f) => f.knowledgeUnitId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_questionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $KnowledgeRelationsTable,
    List<KnowledgeRelationRow>
  >
  _knowledgeRelationsRefsTable(_$SubjectDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.knowledgeRelations,
        aliasName: 'knowledge_units__id__knowledge_relations__from_unit_id',
      );

  $$KnowledgeRelationsTableProcessedTableManager get knowledgeRelationsRefs {
    final manager = $$KnowledgeRelationsTableTableManager(
      $_db,
      $_db.knowledgeRelations,
    ).filter((f) => f.fromUnitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _knowledgeRelationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $KnowledgeRelationsTable,
    List<KnowledgeRelationRow>
  >
  _incomingRelationsTable(_$SubjectDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.knowledgeRelations,
        aliasName: 'knowledge_units__id__knowledge_relations__to_unit_id',
      );

  $$KnowledgeRelationsTableProcessedTableManager get incomingRelations {
    final manager = $$KnowledgeRelationsTableTableManager(
      $_db,
      $_db.knowledgeRelations,
    ).filter((f) => f.toUnitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingRelationsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KnowledgeUnitsTableFilterComposer
    extends Composer<_$SubjectDatabase, $KnowledgeUnitsTable> {
  $$KnowledgeUnitsTableFilterComposer({
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

  ColumnFilters<String> get sourcePageId => $composableBuilder(
    column: $table.sourcePageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bboxJson => $composableBuilder(
    column: $table.bboxJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourcePriority => $composableBuilder(
    column: $table.sourcePriority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questionsRefs(
    Expression<bool> Function($$QuestionsTableFilterComposer f) f,
  ) {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.knowledgeUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> knowledgeRelationsRefs(
    Expression<bool> Function($$KnowledgeRelationsTableFilterComposer f) f,
  ) {
    final $$KnowledgeRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.knowledgeRelations,
      getReferencedColumn: (t) => t.fromUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeRelationsTableFilterComposer(
            $db: $db,
            $table: $db.knowledgeRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingRelations(
    Expression<bool> Function($$KnowledgeRelationsTableFilterComposer f) f,
  ) {
    final $$KnowledgeRelationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.knowledgeRelations,
      getReferencedColumn: (t) => t.toUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeRelationsTableFilterComposer(
            $db: $db,
            $table: $db.knowledgeRelations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KnowledgeUnitsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $KnowledgeUnitsTable> {
  $$KnowledgeUnitsTableOrderingComposer({
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

  ColumnOrderings<String> get sourcePageId => $composableBuilder(
    column: $table.sourcePageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bboxJson => $composableBuilder(
    column: $table.bboxJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourcePriority => $composableBuilder(
    column: $table.sourcePriority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KnowledgeUnitsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $KnowledgeUnitsTable> {
  $$KnowledgeUnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePageId => $composableBuilder(
    column: $table.sourcePageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bboxJson =>
      $composableBuilder(column: $table.bboxJson, builder: (column) => column);

  GeneratedColumn<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourcePriority => $composableBuilder(
    column: $table.sourcePriority,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questionsRefs<T extends Object>(
    Expression<T> Function($$QuestionsTableAnnotationComposer a) f,
  ) {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.knowledgeUnitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> knowledgeRelationsRefs<T extends Object>(
    Expression<T> Function($$KnowledgeRelationsTableAnnotationComposer a) f,
  ) {
    final $$KnowledgeRelationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.knowledgeRelations,
          getReferencedColumn: (t) => t.fromUnitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$KnowledgeRelationsTableAnnotationComposer(
                $db: $db,
                $table: $db.knowledgeRelations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> incomingRelations<T extends Object>(
    Expression<T> Function($$KnowledgeRelationsTableAnnotationComposer a) f,
  ) {
    final $$KnowledgeRelationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.knowledgeRelations,
          getReferencedColumn: (t) => t.toUnitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$KnowledgeRelationsTableAnnotationComposer(
                $db: $db,
                $table: $db.knowledgeRelations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$KnowledgeUnitsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $KnowledgeUnitsTable,
          KnowledgeUnitRow,
          $$KnowledgeUnitsTableFilterComposer,
          $$KnowledgeUnitsTableOrderingComposer,
          $$KnowledgeUnitsTableAnnotationComposer,
          $$KnowledgeUnitsTableCreateCompanionBuilder,
          $$KnowledgeUnitsTableUpdateCompanionBuilder,
          (KnowledgeUnitRow, $$KnowledgeUnitsTableReferences),
          KnowledgeUnitRow,
          PrefetchHooks Function({
            bool sourceId,
            bool questionsRefs,
            bool knowledgeRelationsRefs,
            bool incomingRelations,
          })
        > {
  $$KnowledgeUnitsTableTableManager(
    _$SubjectDatabase db,
    $KnowledgeUnitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgeUnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgeUnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgeUnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> sourcePageId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> normalizedContent = const Value.absent(),
                Value<String?> bboxJson = const Value.absent(),
                Value<String> verificationStatus = const Value.absent(),
                Value<int> sourcePriority = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnowledgeUnitsCompanion(
                id: id,
                sourceId: sourceId,
                sourcePageId: sourcePageId,
                type: type,
                content: content,
                normalizedContent: normalizedContent,
                bboxJson: bboxJson,
                verificationStatus: verificationStatus,
                sourcePriority: sourcePriority,
                contentHash: contentHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                Value<String?> sourcePageId = const Value.absent(),
                required String type,
                required String content,
                required String normalizedContent,
                Value<String?> bboxJson = const Value.absent(),
                required String verificationStatus,
                Value<int> sourcePriority = const Value.absent(),
                required String contentHash,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => KnowledgeUnitsCompanion.insert(
                id: id,
                sourceId: sourceId,
                sourcePageId: sourcePageId,
                type: type,
                content: content,
                normalizedContent: normalizedContent,
                bboxJson: bboxJson,
                verificationStatus: verificationStatus,
                sourcePriority: sourcePriority,
                contentHash: contentHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnowledgeUnitsTable, KnowledgeUnitRow>(table),
                  $$KnowledgeUnitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceId = false,
                questionsRefs = false,
                knowledgeRelationsRefs = false,
                incomingRelations = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionsRefs) db.questions,
                    if (knowledgeRelationsRefs) db.knowledgeRelations,
                    if (incomingRelations) db.knowledgeRelations,
                  ],
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
                        if (sourceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceId,
                                    referencedTable:
                                        $$KnowledgeUnitsTableReferences
                                            ._sourceIdTable(db),
                                    referencedColumn:
                                        $$KnowledgeUnitsTableReferences
                                            ._sourceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionsRefs)
                        await $_getPrefetchedData<
                          KnowledgeUnitRow,
                          $KnowledgeUnitsTable,
                          QuestionRow
                        >(
                          currentTable: table,
                          referencedTable: $$KnowledgeUnitsTableReferences
                              ._questionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KnowledgeUnitsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.knowledgeUnitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (knowledgeRelationsRefs)
                        await $_getPrefetchedData<
                          KnowledgeUnitRow,
                          $KnowledgeUnitsTable,
                          KnowledgeRelationRow
                        >(
                          currentTable: table,
                          referencedTable: $$KnowledgeUnitsTableReferences
                              ._knowledgeRelationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KnowledgeUnitsTableReferences(
                                db,
                                table,
                                p0,
                              ).knowledgeRelationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromUnitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incomingRelations)
                        await $_getPrefetchedData<
                          KnowledgeUnitRow,
                          $KnowledgeUnitsTable,
                          KnowledgeRelationRow
                        >(
                          currentTable: table,
                          referencedTable: $$KnowledgeUnitsTableReferences
                              ._incomingRelationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KnowledgeUnitsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingRelations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toUnitId == item.id,
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

typedef $$KnowledgeUnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $KnowledgeUnitsTable,
      KnowledgeUnitRow,
      $$KnowledgeUnitsTableFilterComposer,
      $$KnowledgeUnitsTableOrderingComposer,
      $$KnowledgeUnitsTableAnnotationComposer,
      $$KnowledgeUnitsTableCreateCompanionBuilder,
      $$KnowledgeUnitsTableUpdateCompanionBuilder,
      (KnowledgeUnitRow, $$KnowledgeUnitsTableReferences),
      KnowledgeUnitRow,
      PrefetchHooks Function({
        bool sourceId,
        bool questionsRefs,
        bool knowledgeRelationsRefs,
        bool incomingRelations,
      })
    >;
typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      required String id,
      required String knowledgeUnitId,
      Value<String?> questionNumber,
      required String questionType,
      required String content,
      required String normalizedContent,
      required String questionFingerprint,
      Value<String?> answerLabel,
      Value<String?> answerContent,
      Value<String?> explanation,
      required String verificationStatus,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<String> id,
      Value<String> knowledgeUnitId,
      Value<String?> questionNumber,
      Value<String> questionType,
      Value<String> content,
      Value<String> normalizedContent,
      Value<String> questionFingerprint,
      Value<String?> answerLabel,
      Value<String?> answerContent,
      Value<String?> explanation,
      Value<String> verificationStatus,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$QuestionsTableReferences
    extends BaseReferences<_$SubjectDatabase, $QuestionsTable, QuestionRow> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $KnowledgeUnitsTable _knowledgeUnitIdTable(_$SubjectDatabase db) => db
      .knowledgeUnits
      .createAlias('questions__knowledge_unit_id__knowledge_units__id');

  $$KnowledgeUnitsTableProcessedTableManager get knowledgeUnitId {
    final $_column = $_itemColumn<String>('knowledge_unit_id')!;

    final manager = $$KnowledgeUnitsTableTableManager(
      $_db,
      $_db.knowledgeUnits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_knowledgeUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestionChoicesTable, List<QuestionChoiceRow>>
  _questionChoicesRefsTable(_$SubjectDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.questionChoices,
        aliasName: 'questions__id__question_choices__question_id',
      );

  $$QuestionChoicesTableProcessedTableManager get questionChoicesRefs {
    final manager = $$QuestionChoicesTableTableManager(
      $_db,
      $_db.questionChoices,
    ).filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _questionChoicesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$SubjectDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
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

  ColumnFilters<String> get questionNumber => $composableBuilder(
    column: $table.questionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionFingerprint => $composableBuilder(
    column: $table.questionFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerLabel => $composableBuilder(
    column: $table.answerLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerContent => $composableBuilder(
    column: $table.answerContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$KnowledgeUnitsTableFilterComposer get knowledgeUnitId {
    final $$KnowledgeUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.knowledgeUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableFilterComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questionChoicesRefs(
    Expression<bool> Function($$QuestionChoicesTableFilterComposer f) f,
  ) {
    final $$QuestionChoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionChoices,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionChoicesTableFilterComposer(
            $db: $db,
            $table: $db.questionChoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
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

  ColumnOrderings<String> get questionNumber => $composableBuilder(
    column: $table.questionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionFingerprint => $composableBuilder(
    column: $table.questionFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerLabel => $composableBuilder(
    column: $table.answerLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerContent => $composableBuilder(
    column: $table.answerContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$KnowledgeUnitsTableOrderingComposer get knowledgeUnitId {
    final $$KnowledgeUnitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.knowledgeUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableOrderingComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionNumber => $composableBuilder(
    column: $table.questionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionFingerprint => $composableBuilder(
    column: $table.questionFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerLabel => $composableBuilder(
    column: $table.answerLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerContent => $composableBuilder(
    column: $table.answerContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$KnowledgeUnitsTableAnnotationComposer get knowledgeUnitId {
    final $$KnowledgeUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.knowledgeUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questionChoicesRefs<T extends Object>(
    Expression<T> Function($$QuestionChoicesTableAnnotationComposer a) f,
  ) {
    final $$QuestionChoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionChoices,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionChoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.questionChoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $QuestionsTable,
          QuestionRow,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (QuestionRow, $$QuestionsTableReferences),
          QuestionRow,
          PrefetchHooks Function({
            bool knowledgeUnitId,
            bool questionChoicesRefs,
          })
        > {
  $$QuestionsTableTableManager(_$SubjectDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> knowledgeUnitId = const Value.absent(),
                Value<String?> questionNumber = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> normalizedContent = const Value.absent(),
                Value<String> questionFingerprint = const Value.absent(),
                Value<String?> answerLabel = const Value.absent(),
                Value<String?> answerContent = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String> verificationStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                knowledgeUnitId: knowledgeUnitId,
                questionNumber: questionNumber,
                questionType: questionType,
                content: content,
                normalizedContent: normalizedContent,
                questionFingerprint: questionFingerprint,
                answerLabel: answerLabel,
                answerContent: answerContent,
                explanation: explanation,
                verificationStatus: verificationStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String knowledgeUnitId,
                Value<String?> questionNumber = const Value.absent(),
                required String questionType,
                required String content,
                required String normalizedContent,
                required String questionFingerprint,
                Value<String?> answerLabel = const Value.absent(),
                Value<String?> answerContent = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                required String verificationStatus,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                knowledgeUnitId: knowledgeUnitId,
                questionNumber: questionNumber,
                questionType: questionType,
                content: content,
                normalizedContent: normalizedContent,
                questionFingerprint: questionFingerprint,
                answerLabel: answerLabel,
                answerContent: answerContent,
                explanation: explanation,
                verificationStatus: verificationStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestionsTable, QuestionRow>(table),
                  $$QuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({knowledgeUnitId = false, questionChoicesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionChoicesRefs) db.questionChoices,
                  ],
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
                        if (knowledgeUnitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.knowledgeUnitId,
                                    referencedTable: $$QuestionsTableReferences
                                        ._knowledgeUnitIdTable(db),
                                    referencedColumn: $$QuestionsTableReferences
                                        ._knowledgeUnitIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionChoicesRefs)
                        await $_getPrefetchedData<
                          QuestionRow,
                          $QuestionsTable,
                          QuestionChoiceRow
                        >(
                          currentTable: table,
                          referencedTable: $$QuestionsTableReferences
                              ._questionChoicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$QuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionChoicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionId == item.id,
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

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $QuestionsTable,
      QuestionRow,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (QuestionRow, $$QuestionsTableReferences),
      QuestionRow,
      PrefetchHooks Function({bool knowledgeUnitId, bool questionChoicesRefs})
    >;
typedef $$QuestionChoicesTableCreateCompanionBuilder =
    QuestionChoicesCompanion Function({
      required String id,
      required String questionId,
      required String label,
      required String content,
      required String normalizedContent,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$QuestionChoicesTableUpdateCompanionBuilder =
    QuestionChoicesCompanion Function({
      Value<String> id,
      Value<String> questionId,
      Value<String> label,
      Value<String> content,
      Value<String> normalizedContent,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$QuestionChoicesTableReferences
    extends
        BaseReferences<
          _$SubjectDatabase,
          $QuestionChoicesTable,
          QuestionChoiceRow
        > {
  $$QuestionChoicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $QuestionsTable _questionIdTable(_$SubjectDatabase db) =>
      db.questions.createAlias('question_choices__question_id__questions__id');

  $$QuestionsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<String>('question_id')!;

    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionChoicesTableFilterComposer
    extends Composer<_$SubjectDatabase, $QuestionChoicesTable> {
  $$QuestionChoicesTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$QuestionsTableFilterComposer get questionId {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionChoicesTableOrderingComposer
    extends Composer<_$SubjectDatabase, $QuestionChoicesTable> {
  $$QuestionChoicesTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuestionsTableOrderingComposer get questionId {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionChoicesTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $QuestionChoicesTable> {
  $$QuestionChoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get normalizedContent => $composableBuilder(
    column: $table.normalizedContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$QuestionsTableAnnotationComposer get questionId {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionChoicesTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $QuestionChoicesTable,
          QuestionChoiceRow,
          $$QuestionChoicesTableFilterComposer,
          $$QuestionChoicesTableOrderingComposer,
          $$QuestionChoicesTableAnnotationComposer,
          $$QuestionChoicesTableCreateCompanionBuilder,
          $$QuestionChoicesTableUpdateCompanionBuilder,
          (QuestionChoiceRow, $$QuestionChoicesTableReferences),
          QuestionChoiceRow,
          PrefetchHooks Function({bool questionId})
        > {
  $$QuestionChoicesTableTableManager(
    _$SubjectDatabase db,
    $QuestionChoicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionChoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionChoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionChoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> normalizedContent = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionChoicesCompanion(
                id: id,
                questionId: questionId,
                label: label,
                content: content,
                normalizedContent: normalizedContent,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String questionId,
                required String label,
                required String content,
                required String normalizedContent,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => QuestionChoicesCompanion.insert(
                id: id,
                questionId: questionId,
                label: label,
                content: content,
                normalizedContent: normalizedContent,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestionChoicesTable, QuestionChoiceRow>(table),
                  $$QuestionChoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({questionId = false}) {
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
                    if (questionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.questionId,
                                referencedTable:
                                    $$QuestionChoicesTableReferences
                                        ._questionIdTable(db),
                                referencedColumn:
                                    $$QuestionChoicesTableReferences
                                        ._questionIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$QuestionChoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $QuestionChoicesTable,
      QuestionChoiceRow,
      $$QuestionChoicesTableFilterComposer,
      $$QuestionChoicesTableOrderingComposer,
      $$QuestionChoicesTableAnnotationComposer,
      $$QuestionChoicesTableCreateCompanionBuilder,
      $$QuestionChoicesTableUpdateCompanionBuilder,
      (QuestionChoiceRow, $$QuestionChoicesTableReferences),
      QuestionChoiceRow,
      PrefetchHooks Function({bool questionId})
    >;
typedef $$KnowledgeRelationsTableCreateCompanionBuilder =
    KnowledgeRelationsCompanion Function({
      required String id,
      required String fromUnitId,
      required String toUnitId,
      required String relationType,
      Value<String?> note,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$KnowledgeRelationsTableUpdateCompanionBuilder =
    KnowledgeRelationsCompanion Function({
      Value<String> id,
      Value<String> fromUnitId,
      Value<String> toUnitId,
      Value<String> relationType,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$KnowledgeRelationsTableReferences
    extends
        BaseReferences<
          _$SubjectDatabase,
          $KnowledgeRelationsTable,
          KnowledgeRelationRow
        > {
  $$KnowledgeRelationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $KnowledgeUnitsTable _fromUnitIdTable(_$SubjectDatabase db) => db
      .knowledgeUnits
      .createAlias('knowledge_relations__from_unit_id__knowledge_units__id');

  $$KnowledgeUnitsTableProcessedTableManager get fromUnitId {
    final $_column = $_itemColumn<String>('from_unit_id')!;

    final manager = $$KnowledgeUnitsTableTableManager(
      $_db,
      $_db.knowledgeUnits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $KnowledgeUnitsTable _toUnitIdTable(_$SubjectDatabase db) => db
      .knowledgeUnits
      .createAlias('knowledge_relations__to_unit_id__knowledge_units__id');

  $$KnowledgeUnitsTableProcessedTableManager get toUnitId {
    final $_column = $_itemColumn<String>('to_unit_id')!;

    final manager = $$KnowledgeUnitsTableTableManager(
      $_db,
      $_db.knowledgeUnits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toUnitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KnowledgeRelationsTableFilterComposer
    extends Composer<_$SubjectDatabase, $KnowledgeRelationsTable> {
  $$KnowledgeRelationsTableFilterComposer({
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

  ColumnFilters<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$KnowledgeUnitsTableFilterComposer get fromUnitId {
    final $$KnowledgeUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableFilterComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KnowledgeUnitsTableFilterComposer get toUnitId {
    final $$KnowledgeUnitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableFilterComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KnowledgeRelationsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $KnowledgeRelationsTable> {
  $$KnowledgeRelationsTableOrderingComposer({
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

  ColumnOrderings<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$KnowledgeUnitsTableOrderingComposer get fromUnitId {
    final $$KnowledgeUnitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableOrderingComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KnowledgeUnitsTableOrderingComposer get toUnitId {
    final $$KnowledgeUnitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableOrderingComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KnowledgeRelationsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $KnowledgeRelationsTable> {
  $$KnowledgeRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relationType => $composableBuilder(
    column: $table.relationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$KnowledgeUnitsTableAnnotationComposer get fromUnitId {
    final $$KnowledgeUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KnowledgeUnitsTableAnnotationComposer get toUnitId {
    final $$KnowledgeUnitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toUnitId,
      referencedTable: $db.knowledgeUnits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KnowledgeUnitsTableAnnotationComposer(
            $db: $db,
            $table: $db.knowledgeUnits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KnowledgeRelationsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $KnowledgeRelationsTable,
          KnowledgeRelationRow,
          $$KnowledgeRelationsTableFilterComposer,
          $$KnowledgeRelationsTableOrderingComposer,
          $$KnowledgeRelationsTableAnnotationComposer,
          $$KnowledgeRelationsTableCreateCompanionBuilder,
          $$KnowledgeRelationsTableUpdateCompanionBuilder,
          (KnowledgeRelationRow, $$KnowledgeRelationsTableReferences),
          KnowledgeRelationRow,
          PrefetchHooks Function({bool fromUnitId, bool toUnitId})
        > {
  $$KnowledgeRelationsTableTableManager(
    _$SubjectDatabase db,
    $KnowledgeRelationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgeRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgeRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgeRelationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fromUnitId = const Value.absent(),
                Value<String> toUnitId = const Value.absent(),
                Value<String> relationType = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnowledgeRelationsCompanion(
                id: id,
                fromUnitId: fromUnitId,
                toUnitId: toUnitId,
                relationType: relationType,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fromUnitId,
                required String toUnitId,
                required String relationType,
                Value<String?> note = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => KnowledgeRelationsCompanion.insert(
                id: id,
                fromUnitId: fromUnitId,
                toUnitId: toUnitId,
                relationType: relationType,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnowledgeRelationsTable, KnowledgeRelationRow>(
                    table,
                  ),
                  $$KnowledgeRelationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fromUnitId = false, toUnitId = false}) {
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
                    if (fromUnitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fromUnitId,
                                referencedTable:
                                    $$KnowledgeRelationsTableReferences
                                        ._fromUnitIdTable(db),
                                referencedColumn:
                                    $$KnowledgeRelationsTableReferences
                                        ._fromUnitIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (toUnitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.toUnitId,
                                referencedTable:
                                    $$KnowledgeRelationsTableReferences
                                        ._toUnitIdTable(db),
                                referencedColumn:
                                    $$KnowledgeRelationsTableReferences
                                        ._toUnitIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$KnowledgeRelationsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $KnowledgeRelationsTable,
      KnowledgeRelationRow,
      $$KnowledgeRelationsTableFilterComposer,
      $$KnowledgeRelationsTableOrderingComposer,
      $$KnowledgeRelationsTableAnnotationComposer,
      $$KnowledgeRelationsTableCreateCompanionBuilder,
      $$KnowledgeRelationsTableUpdateCompanionBuilder,
      (KnowledgeRelationRow, $$KnowledgeRelationsTableReferences),
      KnowledgeRelationRow,
      PrefetchHooks Function({bool fromUnitId, bool toUnitId})
    >;
typedef $$OcrRunsTableCreateCompanionBuilder =
    OcrRunsCompanion Function({
      required String id,
      required String sourceId,
      Value<String?> sourcePageId,
      required String engine,
      required String modelVersion,
      required String status,
      Value<double?> confidence,
      Value<String?> errorMessage,
      required int startedAt,
      Value<int?> finishedAt,
      Value<int> rowid,
    });
typedef $$OcrRunsTableUpdateCompanionBuilder =
    OcrRunsCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String?> sourcePageId,
      Value<String> engine,
      Value<String> modelVersion,
      Value<String> status,
      Value<double?> confidence,
      Value<String?> errorMessage,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<int> rowid,
    });

final class $$OcrRunsTableReferences
    extends BaseReferences<_$SubjectDatabase, $OcrRunsTable, OcrRunRow> {
  $$OcrRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$SubjectDatabase db) =>
      db.sources.createAlias('ocr_runs__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OcrRunsTableFilterComposer
    extends Composer<_$SubjectDatabase, $OcrRunsTable> {
  $$OcrRunsTableFilterComposer({
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

  ColumnFilters<String> get sourcePageId => $composableBuilder(
    column: $table.sourcePageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OcrRunsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $OcrRunsTable> {
  $$OcrRunsTableOrderingComposer({
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

  ColumnOrderings<String> get sourcePageId => $composableBuilder(
    column: $table.sourcePageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OcrRunsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $OcrRunsTable> {
  $$OcrRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePageId => $composableBuilder(
    column: $table.sourcePageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OcrRunsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $OcrRunsTable,
          OcrRunRow,
          $$OcrRunsTableFilterComposer,
          $$OcrRunsTableOrderingComposer,
          $$OcrRunsTableAnnotationComposer,
          $$OcrRunsTableCreateCompanionBuilder,
          $$OcrRunsTableUpdateCompanionBuilder,
          (OcrRunRow, $$OcrRunsTableReferences),
          OcrRunRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$OcrRunsTableTableManager(_$SubjectDatabase db, $OcrRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OcrRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OcrRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OcrRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> sourcePageId = const Value.absent(),
                Value<String> engine = const Value.absent(),
                Value<String> modelVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OcrRunsCompanion(
                id: id,
                sourceId: sourceId,
                sourcePageId: sourcePageId,
                engine: engine,
                modelVersion: modelVersion,
                status: status,
                confidence: confidence,
                errorMessage: errorMessage,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                Value<String?> sourcePageId = const Value.absent(),
                required String engine,
                required String modelVersion,
                required String status,
                Value<double?> confidence = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required int startedAt,
                Value<int?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OcrRunsCompanion.insert(
                id: id,
                sourceId: sourceId,
                sourcePageId: sourcePageId,
                engine: engine,
                modelVersion: modelVersion,
                status: status,
                confidence: confidence,
                errorMessage: errorMessage,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OcrRunsTable, OcrRunRow>(table),
                  $$OcrRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$OcrRunsTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$OcrRunsTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$OcrRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $OcrRunsTable,
      OcrRunRow,
      $$OcrRunsTableFilterComposer,
      $$OcrRunsTableOrderingComposer,
      $$OcrRunsTableAnnotationComposer,
      $$OcrRunsTableCreateCompanionBuilder,
      $$OcrRunsTableUpdateCompanionBuilder,
      (OcrRunRow, $$OcrRunsTableReferences),
      OcrRunRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$IngestionJobsTableCreateCompanionBuilder =
    IngestionJobsCompanion Function({
      required String id,
      Value<String?> sourceId,
      required String status,
      Value<int?> currentPage,
      Value<int?> totalPages,
      Value<String?> errorMessage,
      Value<String?> draftJson,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$IngestionJobsTableUpdateCompanionBuilder =
    IngestionJobsCompanion Function({
      Value<String> id,
      Value<String?> sourceId,
      Value<String> status,
      Value<int?> currentPage,
      Value<int?> totalPages,
      Value<String?> errorMessage,
      Value<String?> draftJson,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$IngestionJobsTableFilterComposer
    extends Composer<_$SubjectDatabase, $IngestionJobsTable> {
  $$IngestionJobsTableFilterComposer({
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

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftJson => $composableBuilder(
    column: $table.draftJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngestionJobsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $IngestionJobsTable> {
  $$IngestionJobsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftJson => $composableBuilder(
    column: $table.draftJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngestionJobsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $IngestionJobsTable> {
  $$IngestionJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get draftJson =>
      $composableBuilder(column: $table.draftJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$IngestionJobsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $IngestionJobsTable,
          IngestionJobRow,
          $$IngestionJobsTableFilterComposer,
          $$IngestionJobsTableOrderingComposer,
          $$IngestionJobsTableAnnotationComposer,
          $$IngestionJobsTableCreateCompanionBuilder,
          $$IngestionJobsTableUpdateCompanionBuilder,
          (
            IngestionJobRow,
            BaseReferences<
              _$SubjectDatabase,
              $IngestionJobsTable,
              IngestionJobRow
            >,
          ),
          IngestionJobRow,
          PrefetchHooks Function()
        > {
  $$IngestionJobsTableTableManager(
    _$SubjectDatabase db,
    $IngestionJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngestionJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngestionJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngestionJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> currentPage = const Value.absent(),
                Value<int?> totalPages = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> draftJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngestionJobsCompanion(
                id: id,
                sourceId: sourceId,
                status: status,
                currentPage: currentPage,
                totalPages: totalPages,
                errorMessage: errorMessage,
                draftJson: draftJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> sourceId = const Value.absent(),
                required String status,
                Value<int?> currentPage = const Value.absent(),
                Value<int?> totalPages = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String?> draftJson = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => IngestionJobsCompanion.insert(
                id: id,
                sourceId: sourceId,
                status: status,
                currentPage: currentPage,
                totalPages: totalPages,
                errorMessage: errorMessage,
                draftJson: draftJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IngestionJobsTable, IngestionJobRow>(table),
                  BaseReferences<
                    _$SubjectDatabase,
                    $IngestionJobsTable,
                    IngestionJobRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngestionJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $IngestionJobsTable,
      IngestionJobRow,
      $$IngestionJobsTableFilterComposer,
      $$IngestionJobsTableOrderingComposer,
      $$IngestionJobsTableAnnotationComposer,
      $$IngestionJobsTableCreateCompanionBuilder,
      $$IngestionJobsTableUpdateCompanionBuilder,
      (
        IngestionJobRow,
        BaseReferences<_$SubjectDatabase, $IngestionJobsTable, IngestionJobRow>,
      ),
      IngestionJobRow,
      PrefetchHooks Function()
    >;
typedef $$SolveSessionsTableCreateCompanionBuilder =
    SolveSessionsCompanion Function({
      required String id,
      required String inputType,
      Value<String?> rawInputText,
      Value<String?> parsedQuestionJson,
      required String status,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SolveSessionsTableUpdateCompanionBuilder =
    SolveSessionsCompanion Function({
      Value<String> id,
      Value<String> inputType,
      Value<String?> rawInputText,
      Value<String?> parsedQuestionJson,
      Value<String> status,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$SolveSessionsTableReferences
    extends
        BaseReferences<
          _$SubjectDatabase,
          $SolveSessionsTable,
          SolveSessionRow
        > {
  $$SolveSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SolveResultsTable, List<SolveResultRow>>
  _solveResultsRefsTable(_$SubjectDatabase db) => MultiTypedResultKey.fromTable(
    db.solveResults,
    aliasName: 'solve_sessions__id__solve_results__session_id',
  );

  $$SolveResultsTableProcessedTableManager get solveResultsRefs {
    final manager = $$SolveResultsTableTableManager(
      $_db,
      $_db.solveResults,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_solveResultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SolveSessionsTableFilterComposer
    extends Composer<_$SubjectDatabase, $SolveSessionsTable> {
  $$SolveSessionsTableFilterComposer({
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

  ColumnFilters<String> get inputType => $composableBuilder(
    column: $table.inputType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawInputText => $composableBuilder(
    column: $table.rawInputText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedQuestionJson => $composableBuilder(
    column: $table.parsedQuestionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> solveResultsRefs(
    Expression<bool> Function($$SolveResultsTableFilterComposer f) f,
  ) {
    final $$SolveResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableFilterComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SolveSessionsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $SolveSessionsTable> {
  $$SolveSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get inputType => $composableBuilder(
    column: $table.inputType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawInputText => $composableBuilder(
    column: $table.rawInputText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedQuestionJson => $composableBuilder(
    column: $table.parsedQuestionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolveSessionsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $SolveSessionsTable> {
  $$SolveSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inputType =>
      $composableBuilder(column: $table.inputType, builder: (column) => column);

  GeneratedColumn<String> get rawInputText => $composableBuilder(
    column: $table.rawInputText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parsedQuestionJson => $composableBuilder(
    column: $table.parsedQuestionJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> solveResultsRefs<T extends Object>(
    Expression<T> Function($$SolveResultsTableAnnotationComposer a) f,
  ) {
    final $$SolveResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SolveSessionsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $SolveSessionsTable,
          SolveSessionRow,
          $$SolveSessionsTableFilterComposer,
          $$SolveSessionsTableOrderingComposer,
          $$SolveSessionsTableAnnotationComposer,
          $$SolveSessionsTableCreateCompanionBuilder,
          $$SolveSessionsTableUpdateCompanionBuilder,
          (SolveSessionRow, $$SolveSessionsTableReferences),
          SolveSessionRow,
          PrefetchHooks Function({bool solveResultsRefs})
        > {
  $$SolveSessionsTableTableManager(
    _$SubjectDatabase db,
    $SolveSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolveSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolveSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolveSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inputType = const Value.absent(),
                Value<String?> rawInputText = const Value.absent(),
                Value<String?> parsedQuestionJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolveSessionsCompanion(
                id: id,
                inputType: inputType,
                rawInputText: rawInputText,
                parsedQuestionJson: parsedQuestionJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inputType,
                Value<String?> rawInputText = const Value.absent(),
                Value<String?> parsedQuestionJson = const Value.absent(),
                required String status,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SolveSessionsCompanion.insert(
                id: id,
                inputType: inputType,
                rawInputText: rawInputText,
                parsedQuestionJson: parsedQuestionJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SolveSessionsTable, SolveSessionRow>(table),
                  $$SolveSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({solveResultsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (solveResultsRefs) db.solveResults],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (solveResultsRefs)
                    await $_getPrefetchedData<
                      SolveSessionRow,
                      $SolveSessionsTable,
                      SolveResultRow
                    >(
                      currentTable: table,
                      referencedTable: $$SolveSessionsTableReferences
                          ._solveResultsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SolveSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).solveResultsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SolveSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $SolveSessionsTable,
      SolveSessionRow,
      $$SolveSessionsTableFilterComposer,
      $$SolveSessionsTableOrderingComposer,
      $$SolveSessionsTableAnnotationComposer,
      $$SolveSessionsTableCreateCompanionBuilder,
      $$SolveSessionsTableUpdateCompanionBuilder,
      (SolveSessionRow, $$SolveSessionsTableReferences),
      SolveSessionRow,
      PrefetchHooks Function({bool solveResultsRefs})
    >;
typedef $$SolveResultsTableCreateCompanionBuilder =
    SolveResultsCompanion Function({
      required String id,
      required String sessionId,
      required String questionType,
      Value<String?> finalAnswerLabel,
      Value<String?> finalAnswerContent,
      Value<String?> shortAnswer,
      Value<String?> explanationMarkdown,
      required String confidenceLevel,
      Value<int> modelKnowledgeUsed,
      Value<int> missingInformation,
      Value<String?> warningsJson,
      Value<String?> promptVersion,
      Value<String?> rawResponseJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SolveResultsTableUpdateCompanionBuilder =
    SolveResultsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> questionType,
      Value<String?> finalAnswerLabel,
      Value<String?> finalAnswerContent,
      Value<String?> shortAnswer,
      Value<String?> explanationMarkdown,
      Value<String> confidenceLevel,
      Value<int> modelKnowledgeUsed,
      Value<int> missingInformation,
      Value<String?> warningsJson,
      Value<String?> promptVersion,
      Value<String?> rawResponseJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$SolveResultsTableReferences
    extends
        BaseReferences<_$SubjectDatabase, $SolveResultsTable, SolveResultRow> {
  $$SolveResultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SolveSessionsTable _sessionIdTable(_$SubjectDatabase db) => db
      .solveSessions
      .createAlias('solve_results__session_id__solve_sessions__id');

  $$SolveSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SolveSessionsTableTableManager(
      $_db,
      $_db.solveSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ResultReferencesTable, List<ResultReferenceRow>>
  _resultReferencesRefsTable(_$SubjectDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.resultReferences,
        aliasName: 'solve_results__id__result_references__result_id',
      );

  $$ResultReferencesTableProcessedTableManager get resultReferencesRefs {
    final manager = $$ResultReferencesTableTableManager(
      $_db,
      $_db.resultReferences,
    ).filter((f) => f.resultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _resultReferencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserFeedbackTable, List<UserFeedbackRow>>
  _userFeedbackRefsTable(_$SubjectDatabase db) => MultiTypedResultKey.fromTable(
    db.userFeedback,
    aliasName: 'solve_results__id__user_feedback__result_id',
  );

  $$UserFeedbackTableProcessedTableManager get userFeedbackRefs {
    final manager = $$UserFeedbackTableTableManager(
      $_db,
      $_db.userFeedback,
    ).filter((f) => f.resultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userFeedbackRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SolveResultsTableFilterComposer
    extends Composer<_$SubjectDatabase, $SolveResultsTable> {
  $$SolveResultsTableFilterComposer({
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

  ColumnFilters<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalAnswerLabel => $composableBuilder(
    column: $table.finalAnswerLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalAnswerContent => $composableBuilder(
    column: $table.finalAnswerContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortAnswer => $composableBuilder(
    column: $table.shortAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationMarkdown => $composableBuilder(
    column: $table.explanationMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidenceLevel => $composableBuilder(
    column: $table.confidenceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modelKnowledgeUsed => $composableBuilder(
    column: $table.modelKnowledgeUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missingInformation => $composableBuilder(
    column: $table.missingInformation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawResponseJson => $composableBuilder(
    column: $table.rawResponseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SolveSessionsTableFilterComposer get sessionId {
    final $$SolveSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.solveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveSessionsTableFilterComposer(
            $db: $db,
            $table: $db.solveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> resultReferencesRefs(
    Expression<bool> Function($$ResultReferencesTableFilterComposer f) f,
  ) {
    final $$ResultReferencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resultReferences,
      getReferencedColumn: (t) => t.resultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultReferencesTableFilterComposer(
            $db: $db,
            $table: $db.resultReferences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userFeedbackRefs(
    Expression<bool> Function($$UserFeedbackTableFilterComposer f) f,
  ) {
    final $$UserFeedbackTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFeedback,
      getReferencedColumn: (t) => t.resultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFeedbackTableFilterComposer(
            $db: $db,
            $table: $db.userFeedback,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SolveResultsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $SolveResultsTable> {
  $$SolveResultsTableOrderingComposer({
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

  ColumnOrderings<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalAnswerLabel => $composableBuilder(
    column: $table.finalAnswerLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalAnswerContent => $composableBuilder(
    column: $table.finalAnswerContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortAnswer => $composableBuilder(
    column: $table.shortAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationMarkdown => $composableBuilder(
    column: $table.explanationMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidenceLevel => $composableBuilder(
    column: $table.confidenceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modelKnowledgeUsed => $composableBuilder(
    column: $table.modelKnowledgeUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missingInformation => $composableBuilder(
    column: $table.missingInformation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawResponseJson => $composableBuilder(
    column: $table.rawResponseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SolveSessionsTableOrderingComposer get sessionId {
    final $$SolveSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.solveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.solveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SolveResultsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $SolveResultsTable> {
  $$SolveResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalAnswerLabel => $composableBuilder(
    column: $table.finalAnswerLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalAnswerContent => $composableBuilder(
    column: $table.finalAnswerContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shortAnswer => $composableBuilder(
    column: $table.shortAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationMarkdown => $composableBuilder(
    column: $table.explanationMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidenceLevel => $composableBuilder(
    column: $table.confidenceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modelKnowledgeUsed => $composableBuilder(
    column: $table.modelKnowledgeUsed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get missingInformation => $composableBuilder(
    column: $table.missingInformation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawResponseJson => $composableBuilder(
    column: $table.rawResponseJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SolveSessionsTableAnnotationComposer get sessionId {
    final $$SolveSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.solveSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.solveSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> resultReferencesRefs<T extends Object>(
    Expression<T> Function($$ResultReferencesTableAnnotationComposer a) f,
  ) {
    final $$ResultReferencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.resultReferences,
      getReferencedColumn: (t) => t.resultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultReferencesTableAnnotationComposer(
            $db: $db,
            $table: $db.resultReferences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userFeedbackRefs<T extends Object>(
    Expression<T> Function($$UserFeedbackTableAnnotationComposer a) f,
  ) {
    final $$UserFeedbackTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFeedback,
      getReferencedColumn: (t) => t.resultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFeedbackTableAnnotationComposer(
            $db: $db,
            $table: $db.userFeedback,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SolveResultsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $SolveResultsTable,
          SolveResultRow,
          $$SolveResultsTableFilterComposer,
          $$SolveResultsTableOrderingComposer,
          $$SolveResultsTableAnnotationComposer,
          $$SolveResultsTableCreateCompanionBuilder,
          $$SolveResultsTableUpdateCompanionBuilder,
          (SolveResultRow, $$SolveResultsTableReferences),
          SolveResultRow,
          PrefetchHooks Function({
            bool sessionId,
            bool resultReferencesRefs,
            bool userFeedbackRefs,
          })
        > {
  $$SolveResultsTableTableManager(
    _$SubjectDatabase db,
    $SolveResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolveResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolveResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolveResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<String?> finalAnswerLabel = const Value.absent(),
                Value<String?> finalAnswerContent = const Value.absent(),
                Value<String?> shortAnswer = const Value.absent(),
                Value<String?> explanationMarkdown = const Value.absent(),
                Value<String> confidenceLevel = const Value.absent(),
                Value<int> modelKnowledgeUsed = const Value.absent(),
                Value<int> missingInformation = const Value.absent(),
                Value<String?> warningsJson = const Value.absent(),
                Value<String?> promptVersion = const Value.absent(),
                Value<String?> rawResponseJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolveResultsCompanion(
                id: id,
                sessionId: sessionId,
                questionType: questionType,
                finalAnswerLabel: finalAnswerLabel,
                finalAnswerContent: finalAnswerContent,
                shortAnswer: shortAnswer,
                explanationMarkdown: explanationMarkdown,
                confidenceLevel: confidenceLevel,
                modelKnowledgeUsed: modelKnowledgeUsed,
                missingInformation: missingInformation,
                warningsJson: warningsJson,
                promptVersion: promptVersion,
                rawResponseJson: rawResponseJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String questionType,
                Value<String?> finalAnswerLabel = const Value.absent(),
                Value<String?> finalAnswerContent = const Value.absent(),
                Value<String?> shortAnswer = const Value.absent(),
                Value<String?> explanationMarkdown = const Value.absent(),
                required String confidenceLevel,
                Value<int> modelKnowledgeUsed = const Value.absent(),
                Value<int> missingInformation = const Value.absent(),
                Value<String?> warningsJson = const Value.absent(),
                Value<String?> promptVersion = const Value.absent(),
                Value<String?> rawResponseJson = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SolveResultsCompanion.insert(
                id: id,
                sessionId: sessionId,
                questionType: questionType,
                finalAnswerLabel: finalAnswerLabel,
                finalAnswerContent: finalAnswerContent,
                shortAnswer: shortAnswer,
                explanationMarkdown: explanationMarkdown,
                confidenceLevel: confidenceLevel,
                modelKnowledgeUsed: modelKnowledgeUsed,
                missingInformation: missingInformation,
                warningsJson: warningsJson,
                promptVersion: promptVersion,
                rawResponseJson: rawResponseJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SolveResultsTable, SolveResultRow>(table),
                  $$SolveResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionId = false,
                resultReferencesRefs = false,
                userFeedbackRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (resultReferencesRefs) db.resultReferences,
                    if (userFeedbackRefs) db.userFeedback,
                  ],
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
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$SolveResultsTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$SolveResultsTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (resultReferencesRefs)
                        await $_getPrefetchedData<
                          SolveResultRow,
                          $SolveResultsTable,
                          ResultReferenceRow
                        >(
                          currentTable: table,
                          referencedTable: $$SolveResultsTableReferences
                              ._resultReferencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SolveResultsTableReferences(
                                db,
                                table,
                                p0,
                              ).resultReferencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resultId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userFeedbackRefs)
                        await $_getPrefetchedData<
                          SolveResultRow,
                          $SolveResultsTable,
                          UserFeedbackRow
                        >(
                          currentTable: table,
                          referencedTable: $$SolveResultsTableReferences
                              ._userFeedbackRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SolveResultsTableReferences(
                                db,
                                table,
                                p0,
                              ).userFeedbackRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resultId == item.id,
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

typedef $$SolveResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $SolveResultsTable,
      SolveResultRow,
      $$SolveResultsTableFilterComposer,
      $$SolveResultsTableOrderingComposer,
      $$SolveResultsTableAnnotationComposer,
      $$SolveResultsTableCreateCompanionBuilder,
      $$SolveResultsTableUpdateCompanionBuilder,
      (SolveResultRow, $$SolveResultsTableReferences),
      SolveResultRow,
      PrefetchHooks Function({
        bool sessionId,
        bool resultReferencesRefs,
        bool userFeedbackRefs,
      })
    >;
typedef $$ResultReferencesTableCreateCompanionBuilder =
    ResultReferencesCompanion Function({
      required String id,
      required String resultId,
      required String evidenceId,
      required String localId,
      Value<String?> sourceTitle,
      Value<int?> page,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$ResultReferencesTableUpdateCompanionBuilder =
    ResultReferencesCompanion Function({
      Value<String> id,
      Value<String> resultId,
      Value<String> evidenceId,
      Value<String> localId,
      Value<String?> sourceTitle,
      Value<int?> page,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$ResultReferencesTableReferences
    extends
        BaseReferences<
          _$SubjectDatabase,
          $ResultReferencesTable,
          ResultReferenceRow
        > {
  $$ResultReferencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SolveResultsTable _resultIdTable(_$SubjectDatabase db) => db
      .solveResults
      .createAlias('result_references__result_id__solve_results__id');

  $$SolveResultsTableProcessedTableManager get resultId {
    final $_column = $_itemColumn<String>('result_id')!;

    final manager = $$SolveResultsTableTableManager(
      $_db,
      $_db.solveResults,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResultReferencesTableFilterComposer
    extends Composer<_$SubjectDatabase, $ResultReferencesTable> {
  $$ResultReferencesTableFilterComposer({
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

  ColumnFilters<String> get evidenceId => $composableBuilder(
    column: $table.evidenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$SolveResultsTableFilterComposer get resultId {
    final $$SolveResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableFilterComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResultReferencesTableOrderingComposer
    extends Composer<_$SubjectDatabase, $ResultReferencesTable> {
  $$ResultReferencesTableOrderingComposer({
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

  ColumnOrderings<String> get evidenceId => $composableBuilder(
    column: $table.evidenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$SolveResultsTableOrderingComposer get resultId {
    final $$SolveResultsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableOrderingComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResultReferencesTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $ResultReferencesTable> {
  $$ResultReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get evidenceId => $composableBuilder(
    column: $table.evidenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$SolveResultsTableAnnotationComposer get resultId {
    final $$SolveResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResultReferencesTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $ResultReferencesTable,
          ResultReferenceRow,
          $$ResultReferencesTableFilterComposer,
          $$ResultReferencesTableOrderingComposer,
          $$ResultReferencesTableAnnotationComposer,
          $$ResultReferencesTableCreateCompanionBuilder,
          $$ResultReferencesTableUpdateCompanionBuilder,
          (ResultReferenceRow, $$ResultReferencesTableReferences),
          ResultReferenceRow,
          PrefetchHooks Function({bool resultId})
        > {
  $$ResultReferencesTableTableManager(
    _$SubjectDatabase db,
    $ResultReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResultReferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResultReferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResultReferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> resultId = const Value.absent(),
                Value<String> evidenceId = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<int?> page = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResultReferencesCompanion(
                id: id,
                resultId: resultId,
                evidenceId: evidenceId,
                localId: localId,
                sourceTitle: sourceTitle,
                page: page,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String resultId,
                required String evidenceId,
                required String localId,
                Value<String?> sourceTitle = const Value.absent(),
                Value<int?> page = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => ResultReferencesCompanion.insert(
                id: id,
                resultId: resultId,
                evidenceId: evidenceId,
                localId: localId,
                sourceTitle: sourceTitle,
                page: page,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ResultReferencesTable, ResultReferenceRow>(
                    table,
                  ),
                  $$ResultReferencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resultId = false}) {
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
                    if (resultId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resultId,
                                referencedTable:
                                    $$ResultReferencesTableReferences
                                        ._resultIdTable(db),
                                referencedColumn:
                                    $$ResultReferencesTableReferences
                                        ._resultIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ResultReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $ResultReferencesTable,
      ResultReferenceRow,
      $$ResultReferencesTableFilterComposer,
      $$ResultReferencesTableOrderingComposer,
      $$ResultReferencesTableAnnotationComposer,
      $$ResultReferencesTableCreateCompanionBuilder,
      $$ResultReferencesTableUpdateCompanionBuilder,
      (ResultReferenceRow, $$ResultReferencesTableReferences),
      ResultReferenceRow,
      PrefetchHooks Function({bool resultId})
    >;
typedef $$UserFeedbackTableCreateCompanionBuilder =
    UserFeedbackCompanion Function({
      required String id,
      required String resultId,
      required String feedbackType,
      Value<String?> note,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$UserFeedbackTableUpdateCompanionBuilder =
    UserFeedbackCompanion Function({
      Value<String> id,
      Value<String> resultId,
      Value<String> feedbackType,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$UserFeedbackTableReferences
    extends
        BaseReferences<_$SubjectDatabase, $UserFeedbackTable, UserFeedbackRow> {
  $$UserFeedbackTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SolveResultsTable _resultIdTable(_$SubjectDatabase db) => db
      .solveResults
      .createAlias('user_feedback__result_id__solve_results__id');

  $$SolveResultsTableProcessedTableManager get resultId {
    final $_column = $_itemColumn<String>('result_id')!;

    final manager = $$SolveResultsTableTableManager(
      $_db,
      $_db.solveResults,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserFeedbackTableFilterComposer
    extends Composer<_$SubjectDatabase, $UserFeedbackTable> {
  $$UserFeedbackTableFilterComposer({
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

  ColumnFilters<String> get feedbackType => $composableBuilder(
    column: $table.feedbackType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SolveResultsTableFilterComposer get resultId {
    final $$SolveResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableFilterComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserFeedbackTableOrderingComposer
    extends Composer<_$SubjectDatabase, $UserFeedbackTable> {
  $$UserFeedbackTableOrderingComposer({
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

  ColumnOrderings<String> get feedbackType => $composableBuilder(
    column: $table.feedbackType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SolveResultsTableOrderingComposer get resultId {
    final $$SolveResultsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableOrderingComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserFeedbackTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $UserFeedbackTable> {
  $$UserFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get feedbackType => $composableBuilder(
    column: $table.feedbackType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SolveResultsTableAnnotationComposer get resultId {
    final $$SolveResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.solveResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SolveResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.solveResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserFeedbackTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $UserFeedbackTable,
          UserFeedbackRow,
          $$UserFeedbackTableFilterComposer,
          $$UserFeedbackTableOrderingComposer,
          $$UserFeedbackTableAnnotationComposer,
          $$UserFeedbackTableCreateCompanionBuilder,
          $$UserFeedbackTableUpdateCompanionBuilder,
          (UserFeedbackRow, $$UserFeedbackTableReferences),
          UserFeedbackRow,
          PrefetchHooks Function({bool resultId})
        > {
  $$UserFeedbackTableTableManager(
    _$SubjectDatabase db,
    $UserFeedbackTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFeedbackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFeedbackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> resultId = const Value.absent(),
                Value<String> feedbackType = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserFeedbackCompanion(
                id: id,
                resultId: resultId,
                feedbackType: feedbackType,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String resultId,
                required String feedbackType,
                Value<String?> note = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UserFeedbackCompanion.insert(
                id: id,
                resultId: resultId,
                feedbackType: feedbackType,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserFeedbackTable, UserFeedbackRow>(table),
                  $$UserFeedbackTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resultId = false}) {
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
                    if (resultId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resultId,
                                referencedTable: $$UserFeedbackTableReferences
                                    ._resultIdTable(db),
                                referencedColumn: $$UserFeedbackTableReferences
                                    ._resultIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$UserFeedbackTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $UserFeedbackTable,
      UserFeedbackRow,
      $$UserFeedbackTableFilterComposer,
      $$UserFeedbackTableOrderingComposer,
      $$UserFeedbackTableAnnotationComposer,
      $$UserFeedbackTableCreateCompanionBuilder,
      $$UserFeedbackTableUpdateCompanionBuilder,
      (UserFeedbackRow, $$UserFeedbackTableReferences),
      UserFeedbackRow,
      PrefetchHooks Function({bool resultId})
    >;
typedef $$SubjectSettingsTableCreateCompanionBuilder =
    SubjectSettingsCompanion Function({
      required String key,
      required String value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SubjectSettingsTableUpdateCompanionBuilder =
    SubjectSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$SubjectSettingsTableFilterComposer
    extends Composer<_$SubjectDatabase, $SubjectSettingsTable> {
  $$SubjectSettingsTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectSettingsTableOrderingComposer
    extends Composer<_$SubjectDatabase, $SubjectSettingsTable> {
  $$SubjectSettingsTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectSettingsTableAnnotationComposer
    extends Composer<_$SubjectDatabase, $SubjectSettingsTable> {
  $$SubjectSettingsTableAnnotationComposer({
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

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubjectSettingsTableTableManager
    extends
        RootTableManager<
          _$SubjectDatabase,
          $SubjectSettingsTable,
          SubjectSettingRow,
          $$SubjectSettingsTableFilterComposer,
          $$SubjectSettingsTableOrderingComposer,
          $$SubjectSettingsTableAnnotationComposer,
          $$SubjectSettingsTableCreateCompanionBuilder,
          $$SubjectSettingsTableUpdateCompanionBuilder,
          (
            SubjectSettingRow,
            BaseReferences<
              _$SubjectDatabase,
              $SubjectSettingsTable,
              SubjectSettingRow
            >,
          ),
          SubjectSettingRow,
          PrefetchHooks Function()
        > {
  $$SubjectSettingsTableTableManager(
    _$SubjectDatabase db,
    $SubjectSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SubjectSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectSettingsTable, SubjectSettingRow>(table),
                  BaseReferences<
                    _$SubjectDatabase,
                    $SubjectSettingsTable,
                    SubjectSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubjectSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$SubjectDatabase,
      $SubjectSettingsTable,
      SubjectSettingRow,
      $$SubjectSettingsTableFilterComposer,
      $$SubjectSettingsTableOrderingComposer,
      $$SubjectSettingsTableAnnotationComposer,
      $$SubjectSettingsTableCreateCompanionBuilder,
      $$SubjectSettingsTableUpdateCompanionBuilder,
      (
        SubjectSettingRow,
        BaseReferences<
          _$SubjectDatabase,
          $SubjectSettingsTable,
          SubjectSettingRow
        >,
      ),
      SubjectSettingRow,
      PrefetchHooks Function()
    >;

class $SubjectDatabaseManager {
  final _$SubjectDatabase _db;
  $SubjectDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$SourcePagesTableTableManager get sourcePages =>
      $$SourcePagesTableTableManager(_db, _db.sourcePages);
  $$KnowledgeUnitsTableTableManager get knowledgeUnits =>
      $$KnowledgeUnitsTableTableManager(_db, _db.knowledgeUnits);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$QuestionChoicesTableTableManager get questionChoices =>
      $$QuestionChoicesTableTableManager(_db, _db.questionChoices);
  $$KnowledgeRelationsTableTableManager get knowledgeRelations =>
      $$KnowledgeRelationsTableTableManager(_db, _db.knowledgeRelations);
  $$OcrRunsTableTableManager get ocrRuns =>
      $$OcrRunsTableTableManager(_db, _db.ocrRuns);
  $$IngestionJobsTableTableManager get ingestionJobs =>
      $$IngestionJobsTableTableManager(_db, _db.ingestionJobs);
  $$SolveSessionsTableTableManager get solveSessions =>
      $$SolveSessionsTableTableManager(_db, _db.solveSessions);
  $$SolveResultsTableTableManager get solveResults =>
      $$SolveResultsTableTableManager(_db, _db.solveResults);
  $$ResultReferencesTableTableManager get resultReferences =>
      $$ResultReferencesTableTableManager(_db, _db.resultReferences);
  $$UserFeedbackTableTableManager get userFeedback =>
      $$UserFeedbackTableTableManager(_db, _db.userFeedback);
  $$SubjectSettingsTableTableManager get subjectSettings =>
      $$SubjectSettingsTableTableManager(_db, _db.subjectSettings);
}

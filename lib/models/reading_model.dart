class Reading {
  final String id;
  final String userId;
  final String customerId;
  final double reading;
  final String date;
  final String? createdAt;
  final String? lastModified;
  final String? lastSyncedAt;
  final int pendingSync;
  final int deleted;

  Reading({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.reading,
    required this.date,
    this.createdAt,
    this.lastModified,
    this.lastSyncedAt,
    this.pendingSync = 0,
    this.deleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerId': customerId,
      'reading': reading,
      'date': date,
      'createdAt': createdAt,
      'lastModified': lastModified,
      'lastSyncedAt': lastSyncedAt,
      'pendingSync': pendingSync,
      'deleted': deleted,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toMap();
    map.remove('pendingSync');
    map.remove('lastSyncedAt');
    return map;
  }

  factory Reading.fromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? 'default_user',
      customerId: map['customerId'] as String,
      reading: (map['reading'] as num).toDouble(),
      date: map['date'] as String,
      createdAt: map['createdAt'] as String?,
      lastModified: map['lastModified'] as String?,
      lastSyncedAt: map['lastSyncedAt'] as String?,
      pendingSync: (map['pendingSync'] as int?) ?? 0,
      deleted: (map['deleted'] as int?) ?? 0,
    );
  }

  Reading copyWith({
    String? id,
    String? userId,
    String? customerId,
    double? reading,
    String? date,
    String? createdAt,
    String? lastModified,
    String? lastSyncedAt,
    int? pendingSync,
    int? deleted,
  }) {
    return Reading(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      reading: reading ?? this.reading,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      deleted: deleted ?? this.deleted,
    );
  }
}

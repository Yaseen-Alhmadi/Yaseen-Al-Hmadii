class Customer {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? address;
  final String? meterNumber;
  final double lastReading;
  final String? lastReadingDate;
  final String status;
  final String? createdAt;
  final String? lastModified;
  final String? lastSyncedAt;
  final int pendingSync;
  final int deleted;

  Customer({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.address,
    this.meterNumber,
    this.lastReading = 0.0,
    this.lastReadingDate,
    this.status = 'active',
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
      'name': name,
      'phone': phone,
      'address': address,
      'meterNumber': meterNumber,
      'lastReading': lastReading,
      'lastReadingDate': lastReadingDate,
      'status': status,
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

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? 'default_user',
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      meterNumber: map['meterNumber'] as String?,
      lastReading: (map['lastReading'] as num?)?.toDouble() ?? 0.0,
      lastReadingDate: map['lastReadingDate'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] as String?,
      lastModified: map['lastModified'] as String?,
      lastSyncedAt: map['lastSyncedAt'] as String?,
      pendingSync: (map['pendingSync'] as int?) ?? 0,
      deleted: (map['deleted'] as int?) ?? 0,
    );
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? address,
    String? meterNumber,
    double? lastReading,
    String? lastReadingDate,
    String? status,
    String? createdAt,
    String? lastModified,
    String? lastSyncedAt,
    int? pendingSync,
    int? deleted,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      meterNumber: meterNumber ?? this.meterNumber,
      lastReading: lastReading ?? this.lastReading,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      deleted: deleted ?? this.deleted,
    );
  }
}

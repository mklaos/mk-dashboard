class Branch {
  final String id;
  final String code;
  final String name;
  final String? nameEn;
  final String? nameLao;
  final String? location;
  final bool isActive;

  const Branch({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
    this.nameLao,
    this.location,
    this.isActive = true,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      nameLao: json['name_lao'] as String?,
      location: json['location'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'name_en': nameEn,
      'name_lao': nameLao,
      'location': location,
      'is_active': isActive,
    };
  }

  /// Returns the display name with tri-lingual priority:
  /// Lao → English → Thai → code (fallback)
  String get displayName {
    if (nameLao != null && nameLao!.isNotEmpty) {
      return nameLao!;
    }
    if (nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return name.isNotEmpty ? name : code;
  }

  /// Returns short code (e.g., "MK001")
  String get shortCode => code;

  /// Returns full display name with code (e.g., "MK001 (Watnak)")
  String get displayWithCode {
    final display = displayName;
    return display == code ? code : '$code ($display)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Branch{id: $id, code: $code, displayName: $displayName}';
  }
}
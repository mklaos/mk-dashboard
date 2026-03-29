class Brand {
  final String id;
  final String name;
  final String? nameLao;
  final String? nameEn;
  final String? logoUrl;
  final String primaryColor;

  Brand({
    required this.id,
    required this.name,
    this.nameLao,
    this.nameEn,
    this.logoUrl,
    required this.primaryColor,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      nameLao: json['name_lao'],
      nameEn: json['name_en'],
      logoUrl: json['logo_url'],
      primaryColor: json['primary_color'] ?? '#E31E24',
    );
  }

  String get displayName => nameLao ?? nameEn ?? name;
}

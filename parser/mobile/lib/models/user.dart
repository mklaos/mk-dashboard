class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'owner', 'manager', 'viewer'
  final List<String> allowedBrands;
  final List<String> allowedBranches;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.allowedBrands,
    required this.allowedBranches,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'viewer',
      allowedBrands: List<String>.from(json['allowed_brands'] ?? []),
      allowedBranches: List<String>.from(json['allowed_branches'] ?? []),
    );
  }
}

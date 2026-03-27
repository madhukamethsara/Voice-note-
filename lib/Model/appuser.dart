class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String university;
  final String? degree;
  final String? yearOfStudy;
  final String? department;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.university,
    this.degree,
    this.yearOfStudy,
    this.department,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'university': university,
      'degree': degree,
      'yearOfStudy': yearOfStudy,
      'department': department,
      'createdAt': DateTime.now(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      university: map['university'] ?? '',
      degree: map['degree'] as String?,
      yearOfStudy: map['yearOfStudy'] as String?,
      department: map['department'] as String?,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, fullName: $fullName, email: $email, role: $role)';
  }
}
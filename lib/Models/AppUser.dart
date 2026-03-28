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

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      university: map['university'] ?? '',
      degree: map['degree'],
      yearOfStudy: map['yearOfStudy'],
      department: map['department'],
    );
  }

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
    };
  }
}
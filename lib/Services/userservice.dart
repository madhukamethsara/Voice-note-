import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/AppUser.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collectionName = 'users';

  Future<void> saveUser(AppUser user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return AppUser.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Stream<AppUser?> streamUserByUid(String uid) {
    try {
      return _firestore.collection(_collectionName).doc(uid).snapshots().map(
        (doc) {
          if (!doc.exists || doc.data() == null) {
            return null;
          }

          return AppUser.fromMap(doc.data()!);
        },
      );
    } catch (e) {
      throw Exception('Failed to stream user: $e');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String university,
    String? degree,       
    String? yearOfStudy,  
    String? department,   
  }) async {
    try {
      
      Map<String, dynamic> updateData = {
        'fullName': fullName.trim(),
        'university': university.trim(),
      };

      
      if (degree != null) updateData['degree'] = degree.trim();
      if (yearOfStudy != null) updateData['yearOfStudy'] = yearOfStudy.trim();
      if (department != null) updateData['department'] = department.trim();

      await _firestore.collection(_collectionName).doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
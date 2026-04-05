import 'package:firebase_auth/firebase_auth.dart';
import '../../Models/AppUser.dart';
import 'package:voicenote/Services/userservice.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AppUser> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String university,
    String? degree,
    String? yearOfStudy,
    String? department,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final user = credential.user;

      if (user == null) {
        throw Exception('User registration failed.');
      }

      final appUser = AppUser(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        role: role.trim(),
        university: university.trim(),
        degree: degree?.trim(),
        yearOfStudy: yearOfStudy?.trim(),
        department: department?.trim(),
      );

      await _userService.saveUser(appUser);

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }

  Future<AppUser> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Login failed.');
      }

      final appUser = await _userService.getUserByUid(user.uid);

      if (appUser == null) {
        throw Exception('User profile not found in database.');
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return await _userService.getUserByUid(user.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}

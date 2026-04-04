import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Models/AppUser.dart';
import 'UserService.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  bool _isGoogleInitialized = false;

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
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
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

  Future<AppUser> signInWithGoogle({String? defaultRole}) async {
    try {
      
      if (!_isGoogleInitialized) {
        await _googleSignIn.initialize(
          serverClientId: '114336459925-nc31mcg0jpigp0k5ddimkf66e7fo38vq.apps.googleusercontent.com', 
        );
        _isGoogleInitialized = true;
      }

      
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled.');
      }

      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase sign in with Google failed.');
      }

      
      AppUser? appUser = await _userService.getUserByUid(user.uid);

      
      if (appUser == null) {
        appUser = AppUser(
          uid: user.uid,
          fullName: user.displayName ?? 'Unknown User',
          email: user.email ?? '',
          role: defaultRole ?? 'student', 
          university: 'Not Specified',    
          degree: defaultRole == 'student' ? 'Not Specified' : null,
          department: defaultRole == 'lecturer' ? 'Not Specified' : null,
        );
        
        await _userService.saveUser(appUser);
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Google authentication failed: $e');
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
    
    if (_isGoogleInitialized) {
      await _googleSignIn.signOut();
    }
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
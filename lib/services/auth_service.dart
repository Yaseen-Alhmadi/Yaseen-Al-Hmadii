import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // تسجيل الدخول بالإيميل وكلمة المرور
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // تحديث بيانات المستخدم في Firestore
        await _updateUserData(user);
        
        return {
          'success': true,
          'user': user,
          'message': 'تم تسجيل الدخول بنجاح'
        };
      }
      
      return {'success': false, 'message': 'فشل تسجيل الدخول'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // التسجيل بحساب جديد
  Future<Map<String, dynamic>> signUpWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // تحديث الملف الشخصي
        await user.updateDisplayName(username);
        
        // إرسال verification email
        await user.sendEmailVerification();
        
        // حفظ بيانات المستخدم في Firestore
        await _saveUserData(user, username, 'email');
        
        return {
          'success': true,
          'user': user,
          'message': 'تم إنشاء الحساب بنجاح. يرجى التحقق من بريدك الإلكتروني'
        };
      }
      
      return {'success': false, 'message': 'فشل إنشاء الحساب'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // تسجيل الدخول بحساب Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'تم إلغاء عملية التسجيل'};
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        await _saveUserData(user, user.displayName ?? 'مستخدم', 'google');
        return {
          'success': true,
          'user': user,
          'message': 'تم تسجيل الدخول بحساب Google بنجاح'
        };
      }
      
      return {'success': false, 'message': 'فشل تسجيل الدخول بحساب Google'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول بحساب Google'};
    }
  }

  // إعادة تعيين كلمة المرور
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // تحديث الملف الشخصي
  Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    required String phone,
    required String address,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // تحديث البيانات في Firebase Auth
        await user.updateDisplayName(displayName);
        
        // تحديث البيانات في Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': displayName,
          'phone': phone,
          'address': address,
          'updatedAt': DateTime.now(),
        });

        return {
          'success': true,
          'message': 'تم تحديث الملف الشخصي بنجاح'
        };
      }
      
      return {'success': false, 'message': 'لم يتم العثور على مستخدم'};
    } catch (e) {
      return {'success': false, 'message': 'فشل في تحديث الملف الشخصي: $e'};
    }
  }

  // تغيير كلمة المرور
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null && user.email != null) {
        // إعادة المصادقة بالمستخدم الحالي
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        
        return {
          'success': true,
          'message': 'تم تغيير كلمة المرور بنجاح'
        };
      }
      
      return {'success': false, 'message': 'لم يتم العثور على مستخدم'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // حفظ بيانات المستخدم في Firestore
  Future<void> _saveUserData(User user, String username, String loginMethod) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': username,
      'phone': '',
      'address': '',
      'loginMethod': loginMethod,
      'role': 'admin',
      'createdAt': DateTime.now(),
      'lastLogin': DateTime.now(),
      'isActive': true,
    }, SetOptions(merge: true));
  }

  // تحديث بيانات المستخدم
  Future<void> _updateUserData(User user) async {
    await _firestore.collection('users').doc(user.uid).update({
      'lastLogin': DateTime.now(),
      'isActive': true,
    });
  }

  // الحصول على بيانات المستخدم الحالي
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // الحصول على رسالة الخطأ
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، يرجى اختيار كلمة مرور أقوى';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'عدد محاولات الدخول كبير جداً، يرجى المحاولة لاحقاً';
      case 'requires-recent-login':
        return 'يجب تسجيل الدخول مرة أخرى لإكمال هذه العملية';
      default:
        return e.message ?? 'حدث خطأ غير متوقع';
    }
  }

  // التحقق من verified email
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // إعادة إرسال verification email
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // الحصول على حالة المستخدم
  Stream<User?> get userStream => _auth.authStateChanges();
}
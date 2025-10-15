import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة المصادقة البيومترية (البصمة/الوجه)
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // مفاتيح التخزين
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';

  /// التحقق من توفر البصمة على الجهاز
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      print('خطأ في فحص توفر البصمة: $e');
      return false;
    }
  }

  /// الحصول على أنواع البصمة المتاحة
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('خطأ في الحصول على أنواع البصمة: $e');
      return [];
    }
  }

  /// المصادقة باستخدام البصمة
  Future<bool> authenticate({String reason = 'يرجى المصادقة للمتابعة'}) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      print('خطأ في المصادقة: $e');
      return false;
    }
  }

  /// تفعيل البصمة وحفظ بيانات المستخدم
  Future<bool> enableBiometric({
    required String email,
    required String password,
  }) async {
    try {
      // التحقق من توفر البصمة
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      // طلب المصادقة
      final authenticated = await authenticate(
        reason: 'قم بالمصادقة لتفعيل تسجيل الدخول بالبصمة',
      );

      if (!authenticated) {
        return false;
      }

      // حفظ البيانات بشكل آمن
      final user = _auth.currentUser;
      await _secureStorage.write(key: _keyBiometricEnabled, value: 'true');
      await _secureStorage.write(key: _keyUserEmail, value: email);
      await _secureStorage.write(key: _keyUserPassword, value: password);

      if (user != null) {
        await _secureStorage.write(key: _keyUserId, value: user.uid);
        await _secureStorage.write(
            key: _keyUserName, value: user.displayName ?? '');
      }

      return true;
    } catch (e) {
      print('خطأ في تفعيل البصمة: $e');
      return false;
    }
  }

  /// تعطيل البصمة
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _keyBiometricEnabled);
      await _secureStorage.delete(key: _keyUserEmail);
      await _secureStorage.delete(key: _keyUserPassword);
      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyUserName);
    } catch (e) {
      print('خطأ في تعطيل البصمة: $e');
    }
  }

  /// التحقق من تفعيل البصمة
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _keyBiometricEnabled);
      return enabled == 'true';
    } catch (e) {
      print('خطأ في التحقق من تفعيل البصمة: $e');
      return false;
    }
  }

  /// الحصول على بيانات المستخدم المحفوظة
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keyUserEmail);
      final password = await _secureStorage.read(key: _keyUserPassword);
      final userId = await _secureStorage.read(key: _keyUserId);
      final userName = await _secureStorage.read(key: _keyUserName);

      if (email != null && password != null) {
        return {
          'email': email,
          'password': password,
          'userId': userId ?? '',
          'userName': userName ?? '',
        };
      }
      return null;
    } catch (e) {
      print('خطأ في الحصول على البيانات المحفوظة: $e');
      return null;
    }
  }

  /// تسجيل الدخول بالبصمة
  Future<Map<String, dynamic>> signInWithBiometric() async {
    try {
      // التحقق من تفعيل البصمة
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return {
          'success': false,
          'message': 'البصمة غير مفعلة. يرجى تسجيل الدخول بكلمة المرور أولاً'
        };
      }

      // طلب المصادقة
      final authenticated = await authenticate(
        reason: 'قم بالمصادقة لتسجيل الدخول',
      );

      if (!authenticated) {
        return {'success': false, 'message': 'فشلت المصادقة'};
      }

      // الحصول على البيانات المحفوظة
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        return {'success': false, 'message': 'لم يتم العثور على بيانات محفوظة'};
      }

      // تسجيل الدخول
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: credentials['email']!,
          password: credentials['password']!,
        );

        return {
          'success': true,
          'user': userCredential.user,
          'message': 'تم تسجيل الدخول بنجاح',
          'credentials': credentials,
        };
      } on FirebaseAuthException catch (e) {
        // إذا فشل تسجيل الدخول عبر Firebase (بدون نت)
        // نستخدم البيانات المحفوظة محلياً
        return {
          'success': true,
          'offline': true,
          'credentials': credentials,
          'message': 'تم تسجيل الدخول محلياً (بدون إنترنت)',
        };
      }
    } catch (e) {
      print('خطأ في تسجيل الدخول بالبصمة: $e');
      return {'success': false, 'message': 'حدث خطأ أثناء تسجيل الدخول: $e'};
    }
  }

  /// حفظ معرف المستخدم الحالي
  Future<void> saveCurrentUserId(String userId) async {
    try {
      await _secureStorage.write(key: _keyUserId, value: userId);
    } catch (e) {
      print('خطأ في حفظ معرف المستخدم: $e');
    }
  }

  /// الحصول على معرف المستخدم الحالي
  Future<String?> getCurrentUserId() async {
    try {
      return await _secureStorage.read(key: _keyUserId);
    } catch (e) {
      print('خطأ في الحصول على معرف المستخدم: $e');
      return null;
    }
  }

  /// مسح جميع البيانات
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('خطأ في مسح البيانات: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final available = await authService.isBiometricAvailable();
    final enabled = await authService.isBiometricEnabled();

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      AuthService authService =
          Provider.of<AuthService>(context, listen: false);
      final result = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        final isVerified = await authService.isEmailVerified();

        // عرض خيار تفعيل البصمة
        if (_biometricAvailable && !_biometricEnabled) {
          _showEnableBiometricDialog(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }

        // مزامنة بيانات العملاء بعد تسجيل الدخول
        try {
          final syncService = Provider.of<SyncService>(context, listen: false);
          await syncService.syncAll();
          await syncService.startRealtimeSync();
          debugPrint('✅ تمت مزامنة البيانات بعد تسجيل الدخول');
        } catch (e) {
          debugPrint('⚠️ خطأ في المزامنة بعد تسجيل الدخول: $e');
          // نستمر حتى لو فشلت المزامنة
        }

        setState(() => _isLoading = false);

        if (isVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'تحقق من بريدك الإلكتروني',
            desc: 'يجب التحقق من بريدك الإلكتروني قبل الدخول',
            btnCancelText: 'تخطي',
            btnOkText: 'إعادة الإرسال',
            btnCancelOnPress: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
            btnOkOnPress: () {
              authService.sendEmailVerification();
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.rightSlide,
                title: 'تم الإرسال',
                desc: 'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
              ).show();
            },
          ).show();
        }
      } else {
        setState(() => _isLoading = false);
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'خطأ في التسجيل',
          desc: result['message'],
        ).show();
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    AuthService authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.signInWithGoogle();

    if (result['success'] == true) {
      // مزامنة بيانات العملاء بعد تسجيل الدخول
      try {
        final syncService = Provider.of<SyncService>(context, listen: false);
        await syncService.syncAll();
        await syncService.startRealtimeSync();
        debugPrint('✅ تمت مزامنة البيانات بعد تسجيل الدخول بـ Google');
      } catch (e) {
        debugPrint('⚠️ خطأ في المزامنة بعد تسجيل الدخول: $e');
        // نستمر حتى لو فشلت المزامنة
      }

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      setState(() => _isLoading = false);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'خطأ في التسجيل',
        desc: result['message'],
      ).show();
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        animType: AnimType.rightSlide,
        title: 'معلومات',
        desc: 'يرجى إدخال بريدك الإلكتروني أولاً',
      ).show();
      return;
    }

    AuthService authService = Provider.of<AuthService>(context, listen: false);
    final result =
        await authService.resetPassword(_emailController.text.trim());

    AwesomeDialog(
      context: context,
      dialogType: result['success'] ? DialogType.success : DialogType.error,
      animType: AnimType.rightSlide,
      title: result['success'] ? 'تم الإرسال' : 'خطأ',
      desc: result['message'],
    ).show();
  }

  Future<void> _signInWithBiometric() async {
    setState(() => _isLoading = true);

    AuthService authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.signInWithBiometric();

    if (result['success'] == true) {
      // مزامنة بيانات العملاء بعد تسجيل الدخول
      try {
        final syncService = Provider.of<SyncService>(context, listen: false);
        await syncService.syncAll();
        await syncService.startRealtimeSync();
        debugPrint('✅ تمت مزامنة البيانات بعد تسجيل الدخول بالبصمة');
      } catch (e) {
        debugPrint('⚠️ خطأ في المزامنة بعد تسجيل الدخول: $e');
        // نستمر حتى لو فشلت المزامنة
      }

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      setState(() => _isLoading = false);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'خطأ في التسجيل',
        desc: result['message'],
      ).show();
    }
  }

  void _showEnableBiometricDialog(String email, String password) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.rightSlide,
      title: 'تفعيل البصمة',
      desc: 'هل تريد تفعيل تسجيل الدخول بالبصمة للمرات القادمة؟',
      btnCancelText: 'لا',
      btnOkText: 'نعم',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final authService = Provider.of<AuthService>(context, listen: false);
        final enabled = await authService.enableBiometric(email, password);

        if (enabled) {
          setState(() => _biometricEnabled = true);
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'تم التفعيل',
            desc: 'تم تفعيل تسجيل الدخول بالبصمة بنجاح',
          ).show();
        }
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // شعار التطبيق
                      _buildLogo(),
                      SizedBox(height: 30),

                      // عنوان الصفحة
                      _buildHeader(),
                      SizedBox(height: 30),

                      // حقول الإدخال
                      _buildLoginForm(),
                      SizedBox(height: 20),

                      // زر تسجيل الدخول
                      _buildLoginButton(),
                      SizedBox(height: 20),

                      // تسجيل الدخول بحساب Google
                      _buildGoogleLoginButton(),
                      SizedBox(height: 20),

                      // زر البصمة (إذا كان متاحاً ومفعلاً)
                      if (_biometricAvailable && _biometricEnabled)
                        _buildBiometricButton(),
                      if (_biometricAvailable && _biometricEnabled)
                        SizedBox(height: 20),

                      // رابط التسجيل
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.water_drop,
          size: 80,
          color: Colors.blue,
        ),
        SizedBox(height: 10),
        Text(
          'نظام إدارة المياه',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "تسجيل الدخول",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "سجل الدخول لإدارة نظام المياه",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "البريد الإلكتروني",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "أدخل بريدك الإلكتروني",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال البريد الإلكتروني';
            }
            if (!value.contains('@')) {
              return 'صيغة البريد الإلكتروني غير صحيحة';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        Text(
          "كلمة المرور",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: "أدخل كلمة المرور",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال كلمة المرور';
            }
            if (value.length < 6) {
              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
            }
            return null;
          },
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _resetPassword,
            child: Text(
              "نسيت كلمة المرور؟",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _login,
        child: Text(
          "تسجيل الدخول",
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _signInWithGoogle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "تسجيل الدخول بـ Google",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _signInWithBiometric,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 28, color: Colors.green),
            SizedBox(width: 8),
            Text(
              "تسجيل الدخول بالبصمة",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("ليس لديك حساب؟"),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/signup');
          },
          child: Text(
            "إنشاء حساب جديد",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

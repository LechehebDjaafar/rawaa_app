import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscure = true;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ

  Future<void> loginUser() async {
    setState(() => isLoading = true);
    
    try {
      // التحقق من صحة البريد الإلكتروني
      if (!_isValidEmail(emailController.text.trim())) {
        throw Exception('يرجى إدخال بريد إلكتروني صحيح');
      }
      
      // 1. البحث عن المستخدم بالبريد الإلكتروني
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('البريد الإلكتروني غير موجود');
      }

      final userData = query.docs.first.data();
      final email = userData['email'];
      final role = userData['role'];

      // 2. تسجيل الدخول بالبريد وكلمة السر
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      // حفظ حالة تسجيل الدخول
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_type', role);

      // 3. التوجيه حسب نوع الحساب
      if (!mounted) return;
      
      switch (role) {
        case 'customer':
          Navigator.pushReplacementNamed(context, '/customer_dashboard');
          break;
        case 'seller':
          Navigator.pushReplacementNamed(context, '/seller_dashboard');
          break;
        case 'delivery':
          Navigator.pushReplacementNamed(context, '/delivery_main');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
          break;
        default:
          throw Exception('نوع الحساب غير معروف');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'البريد الإلكتروني غير موجود';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          errorMessage = 'هذا الحساب معطل';
          break;
        case 'too-many-requests':
          errorMessage = 'محاولات كثيرة، حاول لاحقاً';
          break;
        default:
          errorMessage = e.message ?? 'حدث خطأ أثناء تسجيل الدخول';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  // دالة للتحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // دالة لاستعادة كلمة المرور
  Future<void> _resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال البريد الإلكتروني أولاً'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // الحصول على معلومات الشاشة
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenHeight < 600;
          final isVerySmallScreen = screenHeight < 500;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.9),
                  secondaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: isVerySmallScreen ? 16 : 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // مساحة علوية مرنة
                      SizedBox(height: isVerySmallScreen ? 10 : 20),
                      
                      // لوغو التطبيق
                      Container(
                        height: isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120),
                        width: isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isVerySmallScreen ? 15 : 20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.water_drop_rounded,
                              size: isVerySmallScreen ? 40 : (isSmallScreen ? 50 : 60),
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 20 : 32),
                      
                      // عنوان الصفحة
                      FittedBox(
                        child: Text(
                          'مرحبًا بك في RAWAA',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 4 : 8),
                      
                      Text(
                        'سجّل دخولك للاستمرار',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          color: Colors.white.withOpacity(0.8),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 30 : 40),
                      
                      // حقل البريد الإلكتروني
                      _buildTextField(
                        controller: emailController,
                        icon: Icons.email_outlined,
                        label: 'البريد الإلكتروني',
                        keyboardType: TextInputType.emailAddress,
                        isSmallScreen: isVerySmallScreen,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      // حقل كلمة المرور
                      _buildTextField(
                        controller: passwordController,
                        icon: Icons.lock_outline,
                        label: 'كلمة المرور',
                        isPassword: true,
                        isSmallScreen: isVerySmallScreen,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 8 : 12),
                      
                      // نسيت كلمة المرور
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _resetPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 8 : 12,
                              vertical: isVerySmallScreen ? 4 : 8,
                            ),
                          ),
                          child: Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 12 : 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 16 : 24),
                      
                      // زر تسجيل الدخول
                      SizedBox(
                        width: double.infinity,
                        height: isVerySmallScreen ? 45 : 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            elevation: 8,
                            shadowColor: accentColor.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: isVerySmallScreen ? 20 : 24,
                                  height: isVerySmallScreen ? 20 : 24,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : FittedBox(
                                  child: Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 24 : 32),
                      
                      // إنشاء حساب جديد
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isVerySmallScreen ? 12 : 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/select_account_type',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 4 : 8,
                                vertical: isVerySmallScreen ? 2 : 4,
                              ),
                            ),
                            child: Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isVerySmallScreen ? 12 : 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // مساحة سفلية مرنة
                      SizedBox(height: isVerySmallScreen ? 10 : 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // دالة لإنشاء حقول الإدخال بتصميم موحد ومرن
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool isSmallScreen = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 14 : 16,
          fontFamily: 'Cairo',
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.white70,
            size: isSmallScreen ? 20 : 24,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white70,
            fontSize: isSmallScreen ? 12 : 14,
            fontFamily: 'Cairo',
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: 16,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  onPressed: () => setState(() => obscure = !obscure),
                )
              : null,
        ),
      ),
    );
  }
}

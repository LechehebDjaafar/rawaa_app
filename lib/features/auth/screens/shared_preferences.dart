import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;
  int resendCountdown = 0;
  bool isLoading = false;

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  void initState() {
    super.initState();
    // التحقق من حالة البريد الإلكتروني كل 3 ثوانٍ
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
    
    // السماح بإعادة الإرسال بعد 60 ثانية
    startResendCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // بدء العد التنازلي لإعادة الإرسال
  void startResendCountdown() {
    setState(() {
      resendCountdown = 60;
      canResendEmail = false;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown > 0) {
        setState(() {
          resendCountdown--;
        });
      } else {
        setState(() {
          canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  // التحقق من تأكيد البريد الإلكتروني
  Future<void> checkEmailVerified() async {
    try {
      // تسجيل دخول مؤقت للتحقق من حالة البريد
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      await credential.user!.reload();
      
      if (credential.user!.emailVerified) {
        setState(() {
          isEmailVerified = true;
        });
        
        timer?.cancel();
        
        // تحديث حالة التحقق في Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .update({'emailVerified': true});

        // حفظ حالة تسجيل الدخول
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_type', 'customer');

        if (mounted) {
          // عرض رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تأكيد البريد الإلكتروني بنجاح!'),
              backgroundColor: secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // التوجيه إلى لوحة الزبون بعد ثانيتين
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/customer_dashboard',
                (route) => false,
              );
            }
          });
        }
      } else {
        // تسجيل خروج إذا لم يتم التحقق بعد
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      // في حالة الخطأ، لا نفعل شيئاً ونستمر في المحاولة
      print('خطأ في التحقق من البريد: $e');
    }
  }

  // إعادة إرسال بريد التحقق
  Future<void> resendVerificationEmail() async {
    try {
      setState(() => isLoading = true);
      
      // تسجيل دخول مؤقت لإرسال البريد
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      await credential.user!.sendEmailVerification();
      
      // تسجيل خروج مرة أخرى
      await FirebaseAuth.instance.signOut();

      startResendCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إرسال بريد التحقق مرة أخرى'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: isVerySmallScreen ? 16 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة البريد الإلكتروني
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
                      child: Icon(
                        isEmailVerified ? Icons.mark_email_read : Icons.mark_email_unread,
                        size: isVerySmallScreen ? 40 : (isSmallScreen ? 50 : 60),
                        color: isEmailVerified ? secondaryColor : primaryColor,
                      ),
                    ),

                    SizedBox(height: isVerySmallScreen ? 24 : 32),

                    // العنوان
                    FittedBox(
                      child: Text(
                        isEmailVerified ? 'تم تأكيد البريد الإلكتروني!' : 'تحقق من بريدك الإلكتروني',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: isVerySmallScreen ? 12 : 16),

                    // الوصف
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        isEmailVerified
                            ? 'تم تأكيد بريدك الإلكتروني بنجاح. سيتم توجيهك إلى التطبيق قريباً.'
                            : 'لقد أرسلنا رابط تأكيد إلى بريدك الإلكتروني. يرجى النقر على الرابط لتأكيد حسابك.',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: isVerySmallScreen ? 16 : 24),

                    // عرض البريد الإلكتروني
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isVerySmallScreen ? 12 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: Colors.white70,
                            size: isVerySmallScreen ? 20 : 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.email,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isVerySmallScreen ? 14 : 16,
                                fontFamily: 'Cairo',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isVerySmallScreen ? 24 : 32),

                    if (!isEmailVerified) ...[
                      // زر إعادة الإرسال
                      SizedBox(
                        width: double.infinity,
                        height: isVerySmallScreen ? 45 : 50,
                        child: ElevatedButton.icon(
                          onPressed: (canResendEmail && !isLoading) ? resendVerificationEmail : null,
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
                          icon: isLoading
                              ? SizedBox(
                                  width: isVerySmallScreen ? 16 : 20,
                                  height: isVerySmallScreen ? 16 : 20,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.refresh,
                                  size: isVerySmallScreen ? 18 : 22,
                                ),
                          label: FittedBox(
                            child: Text(
                              canResendEmail
                                  ? 'إعادة إرسال البريد'
                                  : 'إعادة الإرسال خلال ${resendCountdown}s',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isVerySmallScreen ? 16 : 20),

                      // زر التحقق اليدوي
                      SizedBox(
                        width: double.infinity,
                        height: isVerySmallScreen ? 45 : 50,
                        child: OutlinedButton.icon(
                          onPressed: checkEmailVerified,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            Icons.check_circle_outline,
                            size: isVerySmallScreen ? 18 : 22,
                          ),
                          label: FittedBox(
                            child: Text(
                              'لقد أكدت البريد',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (isEmailVerified) ...[
                      // مؤشر التحميل عند النجاح
                      SizedBox(
                        width: isVerySmallScreen ? 40 : 50,
                        height: isVerySmallScreen ? 40 : 50,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      Text(
                        'جاري التوجيه...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isVerySmallScreen ? 14 : 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],

                    SizedBox(height: isVerySmallScreen ? 24 : 32),

                    // زر العودة لتسجيل الدخول
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.8),
                      ),
                      icon: Icon(
                        Icons.arrow_back,
                        size: isVerySmallScreen ? 18 : 20,
                      ),
                      label: Text(
                        'العودة لتسجيل الدخول',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 12 : 14,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

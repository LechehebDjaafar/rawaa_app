import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterSellerScreen extends StatefulWidget {
  const RegisterSellerScreen({super.key});

  @override
  State<RegisterSellerScreen> createState() => _RegisterSellerScreenState();
}

class _RegisterSellerScreenState extends State<RegisterSellerScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final addressController = TextEditingController();
  final regNumberController = TextEditingController();
  final serviceTypeController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool isLoading = false;
  bool acceptTerms = false;
  
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // المفتاح الآن سيكون مرتبطًا بالنموذج الشامل
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'تسجيل حساب بائع',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ... (Progress indicator and step titles remain the same)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentStep ? primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المعلومات الشخصية', style: TextStyle(color: _currentStep == 0 ? primaryColor : Colors.grey, fontWeight: _currentStep == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 12, fontFamily: 'Cairo')),
                  Text('معلومات النشاط', style: TextStyle(color: _currentStep == 1 ? primaryColor : Colors.grey, fontWeight: _currentStep == 1 ? FontWeight.bold : FontWeight.normal, fontSize: 12, fontFamily: 'Cairo')),
                  Text('معلومات الحساب', style: TextStyle(color: _currentStep == 2 ? primaryColor : Colors.grey, fontWeight: _currentStep == 2 ? FontWeight.bold : FontWeight.normal, fontSize: 12, fontFamily: 'Cairo')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              // 1. تم نقل Form ليصبح الحاوية الرئيسية للمحتوى
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCurrentStepContent(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () {
                        // الآن هذا الشرط سيعمل في جميع الخطوات دون مشاكل
                        if (_formKey.currentState!.validate()) {
                          if (_currentStep < 2) {
                            setState(() {
                              _currentStep += 1;
                            });
                          } else {
                            if (acceptTerms) {
                              _registerSeller(); // تمت إعادة تفعيل إنشاء الحساب للاختبار
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('الرجاء الموافقة على الشروط والأحكام'),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _currentStep == 2 ? 'تسجيل' : 'التالي',
                              style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep -= 1;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('السابق', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        // 2. تم إزالة Form من هنا لأنه أصبح في الأعلى
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أدخل معلوماتك الشخصية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryColor, fontFamily: 'Cairo')),
            const SizedBox(height: 20),
            _buildTextField(
              controller: nameController,
              icon: Icons.person,
              label: 'الاسم واللقب',
              validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال الاسم واللقب' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: usernameController,
              icon: Icons.account_circle,
              label: 'اسم المستخدم',
              validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال اسم المستخدم' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: addressController,
              icon: Icons.location_on,
              label: 'العنوان الكامل',
              validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال العنوان' : null,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أدخل معلومات نشاطك التجاري', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryColor, fontFamily: 'Cairo')),
            const SizedBox(height: 20),
            _buildTextField(
              controller: regNumberController,
              icon: Icons.badge,
              label: 'رقم تسجيل تجاري/بطاقة حرفي',
              validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال رقم التسجيل' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: serviceTypeController,
              icon: Icons.build,
              label: 'نوع الخدمة',
              validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال نوع الخدمة' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: phoneController,
              icon: Icons.phone,
              label: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أنشئ حسابك الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryColor, fontFamily: 'Cairo')),
            const SizedBox(height: 20),
            _buildTextField(
              controller: emailController,
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                if (!value.contains('@')) return 'الرجاء إدخال بريد إلكتروني صحيح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              icon: Icons.lock,
              label: 'كلمة المرور',
              obscureText: obscure,
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                onPressed: () => setState(() => obscure = !obscure),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
                if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: acceptTerms,
              onChanged: (value) => setState(() => acceptTerms = value ?? false),
              title: Text('أوافق على شروط الاستخدام وسياسة الخصوصية', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontFamily: 'Cairo')),
              activeColor: primaryColor,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        );
      default:
        return Container();
    }
  }

  // _buildTextField and _registerSeller methods remain the same
  // ...
    Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _registerSeller() async {
    setState(() => isLoading = true);
    
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': nameController.text.trim(),
        'username': usernameController.text.trim(),
        'address': addressController.text.trim(),
        'regNumber': regNumberController.text.trim(),
        'serviceType': serviceTypeController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'seller',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_type', 'seller');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تسجيل الحساب بنجاح!'),
            backgroundColor: secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/seller_dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة جدًا';
          break;
        default:
          errorMessage = e.message ?? 'حدث خطأ أثناء التسجيل';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}


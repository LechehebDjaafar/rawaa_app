import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('تسجيل بائع'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                labelText: 'الاسم و اللقب',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_circle),
                labelText: 'اسم المستخدم',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on),
                labelText: 'العنوان الكامل',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regNumberController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge),
                labelText: 'رقم تسجيل تجاري/بطاقة حرفي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: serviceTypeController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.build),
                labelText: 'نوع الخدمة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone),
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email),
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.store),
                label: const Text('تسجيل', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
onPressed: isLoading
    ? null
    : () async {
        setState(() => isLoading = true);
        try {
          // إنشاء مستخدم في Firebase Auth
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
          // إضافة بيانات المستخدم في Firestore
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
          // التوجيه إلى لوحة البائع
          Navigator.pushReplacementNamed(context, '/seller_dashboard');
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'حدث خطأ أثناء التسجيل')),
          );
        } finally {
          setState(() => isLoading = false);
        }
      },

              ),
            ),
          ],
        ),
      ),
    );
  }
}

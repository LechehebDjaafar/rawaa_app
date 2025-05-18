import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('لا توجد بيانات للمستخدم'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person,
                    size: 48, color: Color(0xFF2F5233)),
              ),
              const SizedBox(height: 16),
              Text(
                data['name'] ?? '',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 4),
              Text(
                '@${data['username'] ?? ''}',
                style: const TextStyle(
                    fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Column(
                    children: [
                      ProfileInfoRow(
                          icon: Icons.email,
                          label: 'البريد الإلكتروني',
                          value: data['email'] ?? ''),
                      const Divider(),
                      ProfileInfoRow(
                          icon: Icons.phone,
                          label: 'رقم الهاتف',
                          value: data['phone'] ?? ''),
                      const Divider(),
                      ProfileInfoRow(
                          icon: Icons.location_on,
                          label: 'العنوان',
                          value: data['address'] ?? ''),
                      // أضف المزيد من الحقول إذا أردت
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج',
                      style: TextStyle(fontSize: 18, fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2F5233)),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Cairo'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

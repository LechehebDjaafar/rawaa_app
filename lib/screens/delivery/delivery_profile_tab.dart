// lib/delivery/delivery_profile_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class DeliveryProfileTab extends StatefulWidget {
  const DeliveryProfileTab({super.key});

  @override
  State<DeliveryProfileTab> createState() => _DeliveryProfileTabState();
}

class _DeliveryProfileTabState extends State<DeliveryProfileTab> {
  final Color deliveryColor = const Color(0xFFFF6B35);
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  String? profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // تحميل بيانات المستخدم من Firestore
  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data()!;
          profileImageBase64 = userData['profileImage'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('خطأ في تحميل بيانات المستخدم: $e');
      setState(() => isLoading = false);
    }
  }

  // اختيار وضغط الصورة
  Future<void> _pickAndCompressImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // عرض خيارات اختيار الصورة
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر مصدر الصورة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'الكاميرا',
                    source: ImageSource.camera,
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'المعرض',
                    source: ImageSource.gallery,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // ضغط الصورة
      final compressedImage = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 400,
        minHeight: 400,
        quality: 70,
      );

      if (compressedImage == null) return;

      // تحويل إلى Base64
      final String base64Image = base64Encode(compressedImage);
      
      // حفظ في Firestore
      await _updateProfileImage(base64Image);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: deliveryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 40, color: deliveryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'Cairo')),
        ],
      ),
    );
  }

  // تحديث صورة الملف الشخصي
  Future<void> _updateProfileImage(String base64Image) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'profileImage': base64Image});

      setState(() {
        profileImageBase64 = base64Image;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث الصورة بنجاح!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // عرض وتعديل المعلومات الشخصية
  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final phoneController = TextEditingController(text: userData['phone'] ?? '');
    final addressController = TextEditingController(text: userData['address'] ?? '');
    String selectedVehicleType = userData['vehicleType'] ?? 'دراجة نارية';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المعلومات الشخصية', style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: Icon(Icons.person),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: Icon(Icons.phone),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: Icon(Icons.location_on),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedVehicleType,
                decoration: const InputDecoration(
                  labelText: 'نوع المركبة',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: Icon(Icons.two_wheeler),
                ),
                items: ['دراجة نارية', 'سيارة', 'دراجة هوائية', 'مشي على الأقدام']
                    .map((vehicle) => DropdownMenuItem(
                          value: vehicle,
                          child: Text(vehicle, style: const TextStyle(fontFamily: 'Cairo')),
                        ))
                    .toList(),
                onChanged: (value) => selectedVehicleType = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUserData(
                nameController.text,
                phoneController.text,
                addressController.text,
                selectedVehicleType,
              );
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: deliveryColor),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadUserData(); // إعادة تحميل البيانات
    }
  }

  // تحديث بيانات المستخدم
  Future<void> _updateUserData(String name, String phone, String address, String vehicleType) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'name': name,
        'phone': phone,
        'address': address,
        'vehicleType': vehicleType,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث المعلومات بنجاح!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // تسجيل الخروج
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في تسجيل الخروج: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: deliveryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // قسم الصورة والمعلومات الأساسية
            Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: deliveryColor.withOpacity(0.1),
                      backgroundImage: profileImageBase64 != null
                          ? MemoryImage(base64Decode(profileImageBase64!))
                          : null,
                      child: profileImageBase64 == null
                          ? Icon(Icons.delivery_dining, size: 60, color: deliveryColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndCompressImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: deliveryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userData['name'] ?? 'عامل التوصيل',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  userData['email'] ?? 'البريد الإلكتروني غير متاح',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: deliveryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userData['vehicleType'] ?? 'دراجة نارية',
                    style: TextStyle(fontFamily: 'Cairo', color: deliveryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // قسم المعلومات التفصيلية
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المعلومات الشخصية',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.phone, 'رقم الهاتف', userData['phone'] ?? 'غير محدد'),
                    _buildInfoRow(Icons.location_on, 'العنوان', userData['address'] ?? 'غير محدد'),
                    _buildInfoRow(Icons.badge, 'رقم الهوية', userData['nationalId'] ?? 'غير محدد'),
                    _buildInfoRow(Icons.credit_card, 'رخصة القيادة', userData['licenseNumber'] ?? 'غير محدد'),
                    _buildInfoRow(Icons.star, 'التقييم', '${userData['rating'] ?? 5.0}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // قائمة الخيارات
            _buildMenuTile(Icons.edit, 'تعديل المعلومات', _showEditProfileDialog),
            _buildMenuTile(Icons.settings, 'إعدادات الحساب', () {}),
            _buildMenuTile(Icons.help_outline, 'مركز المساعدة', () {}),
            _buildMenuTile(Icons.policy, 'الشروط والخصوصية', () {}),
            
            const Divider(height: 32),
            
            _buildMenuTile(Icons.logout, 'تسجيل الخروج', _signOut, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: deliveryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : deliveryColor),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isDestructive ? Colors.red : null,
            fontWeight: isDestructive ? FontWeight.bold : null,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

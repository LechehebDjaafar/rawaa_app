import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  
  // متحكمات الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // اختيار صورة من المعرض
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  // رفع الصورة إلى Firebase Storage
  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;
    
    try {
      final String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = _storage.ref().child('profile_images/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل رفع الصورة: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  // حفظ التغييرات
  Future<void> _saveChanges(Map<String, dynamic> userData) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      String? profileImageUrl = userData['profileImage'];
      
      // رفع الصورة الجديدة إذا تم اختيارها
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage(user.uid);
      }
      
      // تحديث بيانات المستخدم
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'username': _usernameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'profileImage': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // تسجيل الخروج
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_type');
      await _auth.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تسجيل الخروج: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Container(
      color: backgroundColor,
      child: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'لا توجد بيانات للمستخدم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                ),
              ),
            );
          }
          
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          
          // تعبئة المتحكمات بالبيانات الحالية عند بدء التعديل
          if (_isEditing && _nameController.text.isEmpty) {
            _nameController.text = userData['name'] ?? '';
            _usernameController.text = userData['username'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _addressController.text = userData['address'] ?? '';
          }
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _isEditing
                ? _buildEditProfileForm(userData)
                : _buildProfileView(userData),
          );
        },
      ),
    );
  }

  // بناء صفحة عرض الملف الشخصي
  Widget _buildProfileView(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الصورة الخلفية والصورة الشخصية
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // الصورة الخلفية
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              
              // الصورة الشخصية
              Positioned(
                bottom: -50,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: userData['profileImage'] != null
                        ? NetworkImage(userData['profileImage'])
                        : null,
                    child: userData['profileImage'] == null
                        ? const Icon(
                            Icons.person,
                            size: 48,
                            color: Color(0xFF2F5233),
                          )
                        : null,
                  ),
                ),
              ),
              
              // زر التعديل
              Positioned(
                top: 16,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF2F5233)),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 60),
          
          // اسم المستخدم
          Text(
            userData['name'] ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          
          // اسم المستخدم
          Text(
            '@${userData['username'] ?? ''}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Cairo',
            ),
          ),
          
          // معلومات الاتصال
          Card(
            margin: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                children: [
                  ProfileInfoRow(
                    icon: Icons.email,
                    label: 'البريد الإلكتروني',
                    value: userData['email'] ?? '',
                  ),
                  const Divider(),
                  ProfileInfoRow(
                    icon: Icons.phone,
                    label: 'رقم الهاتف',
                    value: userData['phone'] ?? '',
                  ),
                  const Divider(),
                  ProfileInfoRow(
                    icon: Icons.location_on,
                    label: 'العنوان',
                    value: userData['address'] ?? '',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // زر تسجيل الخروج
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }

  // بناء نموذج تعديل الملف الشخصي
  Widget _buildEditProfileForm(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          
          // صورة المستخدم
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : (userData['profileImage'] != null
                          ? NetworkImage(userData['profileImage'])
                          : null),
                  child: (_imageFile == null && userData['profileImage'] == null)
                      ? const Icon(
                          Icons.person,
                          size: 56,
                          color: Color(0xFF2F5233),
                        )
                      : null,
                ),
              ),
              CircleAvatar(
                backgroundColor: primaryColor,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // حقول التعديل
          _buildTextField(
            controller: _nameController,
            label: 'الاسم واللقب',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _usernameController,
            label: 'اسم المستخدم',
            icon: Icons.account_circle,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _addressController,
            label: 'العنوان',
            icon: Icons.location_on,
          ),
          
          const SizedBox(height: 32),
          
          // أزرار الإلغاء والحفظ
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _imageFile = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveChanges(userData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'حفظ التغييرات',
                          style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء حقل إدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: secondaryColor),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2F5233)),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
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
      ),
    );
  }
}

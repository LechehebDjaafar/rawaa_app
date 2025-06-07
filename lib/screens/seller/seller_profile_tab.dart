import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class SellerProfileTab extends StatefulWidget {
  const SellerProfileTab({super.key});

  @override
  State<SellerProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<SellerProfileTab>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  String? _base64Image; // لحفظ الصورة كـ Base64

  // متحكمات الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor =  const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

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

  // اختيار صورة من المعرض وتحويلها إلى Base64 - مصحح بالطريقة الصحيحة
  Future<void> _pickImage() async {
    try {
      // عرض خيارات اختيار الصورة
      await _showImageSourceDialog();
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصورة: $e');
    }
  }

  // عرض نافذة اختيار مصدر الصورة
  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'اختيار الصورة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('من المعرض',
                    style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('من الكاميرا',
                    style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
  }

  // الحصول على الصورة من المصدر المحدد - مصحح بالطريقة الصحيحة
  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedImage != null) {
        // التحقق من وجود الملف
        final File imageFile = File(pickedImage.path);
        if (await imageFile.exists()) {
          setState(() {
            _imageFile = imageFile;
          });

          // تحويل الصورة إلى Base64 بالطريقة الصحيحة
          await _convertImageToBase64();
        } else {
          _showErrorSnackBar('لم يتم العثور على الصورة المحددة');
        }
      } else {
        _showErrorSnackBar('لم يتم اختيار أي صورة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  // تحويل الصورة إلى Base64 - مصحح بالطريقة الصحيحة من المراجع
  Future<void> _convertImageToBase64() async {
    if (_imageFile == null) return;

    try {
      // التحقق من وجود الملف
      if (!await _imageFile!.exists()) {
        _showErrorSnackBar('الملف غير موجود');
        return;
      }

      // قراءة الصورة كـ bytes - الطريقة الصحيحة من المراجع
      final bytes = await _imageFile!.readAsBytes();

      // التحقق من حجم الصورة (الحد الأقصى 1MB)
      if (bytes.length > 1024 * 1024) {
        _showErrorSnackBar(
            'حجم الصورة كبير جداً. يرجى اختيار صورة أصغر من 1MB');
        setState(() {
          _imageFile = null;
        });
        return;
      }

      // تحويل إلى Base64 - الطريقة الصحيحة من المراجع
      String base64String = base64Encode(bytes);

      setState(() {
        _base64Image = base64String;
      });

      _showSuccessSnackBar('تم تحضير الصورة بنجاح');
      print("imgbytes : $base64String"); // للتأكد من التحويل
    } catch (e) {
      _showErrorSnackBar('فشل في معالجة الصورة: $e');
      setState(() {
        _imageFile = null;
        _base64Image = null;
      });
    }
  }

  // حفظ التغييرات مع الصورة المحولة إلى Base64
  Future<void> _saveChanges(Map<String, dynamic> userData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // تحضير البيانات للحفظ
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // إضافة الصورة المحولة إلى Base64 إذا تم اختيار صورة جديدة
      if (_base64Image != null) {
        updateData['profileImageBase64'] = _base64Image;
        updateData['hasProfileImage'] = true;
      }

      // تحديث بيانات المستخدم في Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);

      setState(() {
        _isEditing = false;
        _isLoading = false;
        _imageFile = null;
        _base64Image = null;
      });

      _showSuccessSnackBar('تم تحديث البيانات بنجاح');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ: $e');
    }
  }

  // تسجيل الخروج
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج',
            style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', false);
                await prefs.remove('user_type');
                await _auth.signOut();

                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                _showErrorSnackBar('حدث خطأ أثناء تسجيل الخروج: $e');
              }
            },
            child: const Text('تسجيل الخروج',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // عرض رسائل النجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // عرض رسائل الخطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenHeight < 600;
        final isVerySmallScreen = screenHeight < 500;

        return Container(
          color: backgroundColor,
          child: FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(user?.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'لا توجد بيانات للمستخدم',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
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
                    ? _buildEditProfileForm(
                        userData, isVerySmallScreen, screenWidth)
                    : _buildProfileView(
                        userData, isVerySmallScreen, screenWidth),
              );
            },
          ),
        );
      },
    );
  }

  // بناء صفحة عرض الملف الشخصي
  Widget _buildProfileView(Map<String, dynamic> userData,
      bool isVerySmallScreen, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
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
                height: isVerySmallScreen ? 120 : 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              // الصورة الشخصية
              Positioned(
                bottom: isVerySmallScreen ? -30 : -40,
                child: CircleAvatar(
                  radius: isVerySmallScreen ? 35 : 45,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: isVerySmallScreen ? 32 : 42,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: _getProfileImage(userData),
                    child: _getProfileImage(userData) == null
                        ? Icon(
                            Icons.person,
                            size: isVerySmallScreen ? 32 : 40,
                            color: secondaryColor,
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
                  radius: isVerySmallScreen ? 18 : 22,
                  child: IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: secondaryColor,
                      size: isVerySmallScreen ? 16 : 20,
                    ),
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

          SizedBox(height: isVerySmallScreen ? 40 : 50),

          // اسم المستخدم
          Text(
            userData['name'] ?? '',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),

          // اسم المستخدم
          Text(
            '@${userData['username'] ?? ''}',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 14 : 16,
              color: Colors.grey,
              fontFamily: 'Cairo',
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 16 : 20),

          // معلومات الاتصال
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.email,
                    'البريد الإلكتروني',
                    userData['email'] ?? '',
                    isVerySmallScreen,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.phone,
                    'رقم الهاتف',
                    userData['phone'] ?? 'غير محدد',
                    isVerySmallScreen,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.location_on,
                    'العنوان',
                    userData['address'] ?? 'غير محدد',
                    isVerySmallScreen,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 20 : 24),

          // زر تسجيل الخروج
          SizedBox(
            width: double.infinity,
            height: isVerySmallScreen ? 45 : 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 16 : 18,
                  fontFamily: 'Cairo',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
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

  // بناء نموذج تعديل الملف الشخصي - مصحح
  Widget _buildEditProfileForm(Map<String, dynamic> userData,
      bool isVerySmallScreen, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isVerySmallScreen ? 10 : 16),

          // صورة المستخدم مع زر الكاميرا المصحح
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: isVerySmallScreen ? 50 : 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: isVerySmallScreen ? 46 : 56,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: _getEditProfileImage(userData),
                  child: _getEditProfileImage(userData) == null
                      ? Icon(
                          Icons.person,
                          size: isVerySmallScreen ? 40 : 50,
                          color: secondaryColor,
                        )
                      : null,
                ),
              ),
              // زر الكاميرا المصحح
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage, // استدعاء الدالة المصححة
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: isVerySmallScreen ? 16 : 20,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: isVerySmallScreen ? 16 : 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isVerySmallScreen ? 20 : 24),

          // حقول التعديل
          _buildTextField(
            controller: _nameController,
            label: 'الاسم واللقب',
            icon: Icons.person,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),

          _buildTextField(
            controller: _usernameController,
            label: 'اسم المستخدم',
            icon: Icons.account_circle,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),

          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),

          _buildTextField(
            controller: _addressController,
            label: 'العنوان',
            icon: Icons.location_on,
            isVerySmallScreen: isVerySmallScreen,
          ),

          SizedBox(height: isVerySmallScreen ? 24 : 32),

          // أزرار الإلغاء والحفظ
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _imageFile = null;
                      _base64Image = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(
                        vertical: isVerySmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 14 : 16,
                      fontFamily: 'Cairo',
                    ),
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
                    padding: EdgeInsets.symmetric(
                        vertical: isVerySmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: isVerySmallScreen ? 16 : 20,
                          width: isVerySmallScreen ? 16 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'حفظ التغييرات',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 16,
                            fontFamily: 'Cairo',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // الحصول على صورة الملف الشخصي من Base64
  ImageProvider? _getProfileImage(Map<String, dynamic> userData) {
    if (userData['profileImageBase64'] != null) {
      try {
        Uint8List bytes = base64Decode(userData['profileImageBase64']);
        return MemoryImage(bytes);
      } catch (e) {
        print('خطأ في تحويل Base64 إلى صورة: $e');
        return null;
      }
    }
    return null;
  }

  // الحصول على صورة الملف الشخصي أثناء التعديل
  ImageProvider? _getEditProfileImage(Map<String, dynamic> userData) {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (userData['profileImageBase64'] != null) {
      try {
        Uint8List bytes = base64Decode(userData['profileImageBase64']);
        return MemoryImage(bytes);
      } catch (e) {
        print('خطأ في تحويل Base64 إلى صورة: $e');
        return null;
      }
    }
    return null;
  }

  // بناء حقل إدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isVerySmallScreen,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: isVerySmallScreen ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: Colors.grey[700],
          fontSize: isVerySmallScreen ? 12 : 14,
        ),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isVerySmallScreen ? 12 : 16,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isVerySmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 6 : 8),
      child: Row(
        children: [
          Icon(icon, color: secondaryColor, size: isVerySmallScreen ? 20 : 24),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              fontSize: isVerySmallScreen ? 12 : 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

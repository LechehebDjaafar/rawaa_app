import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class SellerProfileTab extends StatefulWidget {
  const SellerProfileTab({super.key});

  @override
  State<SellerProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<SellerProfileTab>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة التحقق من معرف البائع الحالي
  String? get _currentUserId => _auth.currentUser?.uid;

  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  String? _base64Image;

  // متحكمات الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController(); // إضافة اسم المتجر
  final TextEditingController _businessDescriptionController = TextEditingController(); // إضافة وصف المتجر

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color.fromARGB(255, 78, 94, 243);
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
    _ensureUserProfileExists();
  }

  // التأكد من وجود ملف المستخدم وإنشاؤه إذا لم يكن موجوداً
  Future<void> _ensureUserProfileExists() async {
    if (_currentUserId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId!).get();
      
      if (!userDoc.exists) {
        // إنشاء ملف المستخدم إذا لم يكن موجوداً
        await _firestore.collection('users').doc(_currentUserId!).set({
          'email': _auth.currentUser?.email ?? '',
          'name': _auth.currentUser?.displayName ?? 'بائع جديد',
          'username': 'seller_${_currentUserId!.substring(0, 6)}',
          'phone': '',
          'address': '',
          'businessName': 'متجر الري والهيدروليك',
          'businessDescription': 'متخصصون في أنظمة الري ومعدات الهيدروليك',
          'userType': 'seller',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('خطأ في التحقق من ملف المستخدم: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // اختيار صورة من المعرض وتحويلها إلى Base64 - محسن
  Future<void> _pickImage() async {
    try {
      await _showImageSourceDialog();
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصورة: $e');
    }
  }

  // عرض نافذة اختيار مصدر الصورة - محسن
  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'اختيار الصورة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: const Text('من المعرض', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: secondaryColor),
                title: const Text('من الكاميرا', style: TextStyle(fontFamily: 'Cairo')),
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
              child: Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  // الحصول على الصورة من المصدر المحدد - محسن
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
        final File imageFile = File(pickedImage.path);
        if (await imageFile.exists()) {
          setState(() {
            _imageFile = imageFile;
          });
          await _convertImageToBase64();
        } else {
          _showErrorSnackBar('لم يتم العثور على الصورة المحددة');
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  // تحويل الصورة إلى Base64 مع ضغط محسن
  Future<void> _convertImageToBase64() async {
    if (_imageFile == null) return;

    try {
      if (!await _imageFile!.exists()) {
        _showErrorSnackBar('الملف غير موجود');
        return;
      }

      Uint8List imageBytes = await _imageFile!.readAsBytes();

      // فك تشفير الصورة وضغطها
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        _showErrorSnackBar('فشل في معالجة الصورة');
        return;
      }

      // تغيير حجم الصورة إذا كانت كبيرة
      if (image.width > 400 || image.height > 400) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 400 : null,
          height: image.height > image.width ? 400 : null,
        );
      }

      // ضغط الصورة وتحويلها إلى JPEG
      List<int> compressedBytes = img.encodeJpg(image, quality: 70);

      // التحقق من الحجم النهائي
      if (compressedBytes.length > 1024 * 1024) {
        compressedBytes = img.encodeJpg(image, quality: 50);
      }

      String base64String = base64Encode(compressedBytes);

      setState(() {
        _base64Image = base64String;
      });

      _showSuccessSnackBar('تم تحضير الصورة بنجاح');
    } catch (e) {
      _showErrorSnackBar('فشل في معالجة الصورة: $e');
      setState(() {
        _imageFile = null;
        _base64Image = null;
      });
    }
  }

  // التحقق من صحة رقم الهاتف - محسن[2]
  bool _isValidPhoneNumber(String phone) {
    // إزالة المسافات والرموز
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // التحقق من أن الرقم يبدأ بـ 06 أو 07 أو 05 ويحتوي على 10 أرقام تماماً
    return RegExp(r'^(06|07|05)\d{8}$').hasMatch(cleanPhone);
  }

  // حفظ التغييرات مع التحقق المحسن
  Future<void> _saveChanges(Map<String, dynamic> userData) async {
    if (_currentUserId == null) {
      _showErrorSnackBar('خطأ: لم يتم العثور على معرف المستخدم');
      return;
    }

    // التحقق من صحة البيانات
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى إدخال الاسم');
      return;
    }

    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى إدخال اسم المستخدم');
      return;
    }

    if (_phoneController.text.trim().isNotEmpty && !_isValidPhoneNumber(_phoneController.text.trim())) {
      _showErrorSnackBar('رقم الهاتف غير صحيح. يجب أن يبدأ بـ 06 أو 07 أو 05 ويحتوي على 10 أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'businessDescription': _businessDescriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // إضافة الصورة المحولة إلى Base64 إذا تم اختيار صورة جديدة
      if (_base64Image != null) {
        updateData['profileImageBase64'] = _base64Image;
        updateData['hasProfileImage'] = true;
      }

      // تحديث بيانات المستخدم في Firestore مع التأكد من المعرف
      await _firestore.collection('users').doc(_currentUserId!).update(updateData);

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

  // تسجيل الخروج - محسن
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', false);
                await prefs.remove('user_type');
                await _auth.signOut();

                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                _showErrorSnackBar('حدث خطأ أثناء تسجيل الخروج: $e');
              }
            },
            child: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // عرض رسائل النجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
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
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود المستخدم
    if (_currentUserId == null) {
      return Container(
        color: backgroundColor,
        child: const Center(
          child: Text(
            'خطأ: لم يتم العثور على معرف المستخدم\nيرجى تسجيل الدخول مرة أخرى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenHeight < 600;
        final isVerySmallScreen = screenHeight < 500;

        return Container(
          color: backgroundColor,
          child: FutureBuilder<DocumentSnapshot>(
            // التأكد من استخدام المعرف الصحيح
            future: _firestore.collection('users').doc(_currentUserId!).get(),
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
                _businessNameController.text = userData['businessName'] ?? '';
                _businessDescriptionController.text = userData['businessDescription'] ?? '';
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: _isEditing
                    ? _buildEditProfileForm(userData, isVerySmallScreen, screenWidth)
                    : _buildProfileView(userData, isVerySmallScreen, screenWidth),
              );
            },
          ),
        );
      },
    );
  }

  // بناء صفحة عرض الملف الشخصي - محسن
  Widget _buildProfileView(Map<String, dynamic> userData, bool isVerySmallScreen, double screenWidth) {
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
                  backgroundColor: Colors.white.withOpacity(0.9),
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
            userData['name'] ?? 'بائع',
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
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),

          SizedBox(height: isVerySmallScreen ? 16 : 20),

          // معلومات المتجر
          if (userData['businessName'] != null && userData['businessName'].isNotEmpty) ...[
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات المتجر',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.store,
                      'اسم المتجر',
                      userData['businessName'] ?? '',
                      isVerySmallScreen,
                    ),
                    if (userData['businessDescription'] != null && userData['businessDescription'].isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow(
                        Icons.description,
                        'وصف المتجر',
                        userData['businessDescription'] ?? '',
                        isVerySmallScreen,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // معلومات الاتصال
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات الاتصال',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
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

  // بناء نموذج تعديل الملف الشخصي - محسن
  Widget _buildEditProfileForm(Map<String, dynamic> userData, bool isVerySmallScreen, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isVerySmallScreen ? 10 : 16),

          // صورة المستخدم مع زر الكاميرا
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
              // زر الكاميرا
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
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

          // حقول التعديل الشخصية
          Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: primaryColor,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),

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
            label: 'رقم الهاتف (06xxxxxxxx)',
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

          SizedBox(height: isVerySmallScreen ? 20 : 24),

          // حقول معلومات المتجر
          Text(
            'معلومات المتجر',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: primaryColor,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),

          _buildTextField(
            controller: _businessNameController,
            label: 'اسم المتجر',
            icon: Icons.store,
            isVerySmallScreen: isVerySmallScreen,
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),

          _buildTextField(
            controller: _businessDescriptionController,
            label: 'وصف المتجر',
            icon: Icons.description,
            maxLines: 3,
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
                    padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 14),
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
                    padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 14),
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

  // بناء حقل إدخال - محسن
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isVerySmallScreen,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget _buildInfoRow(IconData icon, String label, String value, bool isVerySmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            ),
          ),
        ],
      ),
    );
  }
}

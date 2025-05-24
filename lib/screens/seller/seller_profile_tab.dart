import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class SellerProfileTab extends StatefulWidget {
  const SellerProfileTab({super.key});

  @override
  State<SellerProfileTab> createState() => _SellerProfileTabState();
}

class _SellerProfileTabState extends State<SellerProfileTab> with SingleTickerProviderStateMixin {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'seller_id';
  bool _isLoading = true;
  bool _isEditing = false;
  File? _imageFile;
  
  // متحكمات الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF64B5F6); // أزرق فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // بيانات المستخدم
  Map<String, dynamic> _userData = {};

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
    
    // التحقق من وجود مجموعة المستخدمين وإنشائها إذا لم تكن موجودة
    _ensureUsersCollectionExists().then((_) {
      // جلب بيانات المستخدم
      _fetchUserData();
    });
  }

  // دالة للتحقق من وجود مجموعة المستخدمين وإنشائها إذا لم تكن موجودة
  Future<void> _ensureUsersCollectionExists() async {
    try {
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await _usersCollection.limit(1).get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة المستخدمين لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await _usersCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة المستخدمين: $e');
    }
  }

  // جلب بيانات المستخدم
  Future<void> _fetchUserData() async {
    try {
      final docSnapshot = await _usersCollection.doc(_currentUserId).get();
      
      if (docSnapshot.exists) {
        setState(() {
          _userData = docSnapshot.data() as Map<String, dynamic>;
          _nameController.text = _userData['name'] ?? '';
          _usernameController.text = _userData['username'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';
          _addressController.text = _userData['address'] ?? '';
          _serviceTypeController.text = _userData['serviceType'] ?? '';
          _bioController.text = _userData['bio'] ?? '';
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        // إنشاء وثيقة جديدة للمستخدم إذا لم تكن موجودة
        await _usersCollection.doc(_currentUserId).set({
          'name': 'بائع جديد',
          'username': 'seller_${DateTime.now().millisecondsSinceEpoch}',
          'phone': '',
          'address': '',
          'serviceType': '',
          'bio': '',
          'role': 'seller',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // إعادة جلب البيانات
        _fetchUserData();
      }
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _serviceTypeController.dispose();
    _bioController.dispose();
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
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _userData['profileImage'];
    
    try {
      final String fileName = 'profile_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      
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
  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String? profileImageUrl = _userData['profileImage'];
      
      // رفع الصورة الجديدة إذا تم اختيارها
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage();
      }
      
      // تحديث بيانات المستخدم
      await _usersCollection.doc(_currentUserId).update({
        'name': _nameController.text,
        'username': _usernameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'serviceType': _serviceTypeController.text,
        'bio': _bioController.text,
        'profileImage': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // إعادة جلب البيانات المحدثة
      await _fetchUserData();
      
      setState(() {
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث البيانات بنجاح'),
          backgroundColor: secondaryColor,
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
      await FirebaseAuth.instance.signOut();
      
      // حذف بيانات الجلسة من SharedPreferences
      // يمكنك إضافة هذا الجزء إذا كنت تستخدم SharedPreferences
      
      // العودة إلى صفحة تسجيل الدخول
      if (mounted) {
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // الصورة الخلفية والصورة الشخصية
                    _buildProfileHeader(),
                    
                    // معلومات المستخدم
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isEditing
                          ? _buildEditForm()
                          : _buildProfileInfo(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // بناء رأس الصفحة (الصورة الخلفية والصورة الشخصية)
  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // الصورة الخلفية
        Container(
          height: 180,
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
          ),
        ),
        
        // الصورة الشخصية
        Positioned(
          bottom: -60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : (_userData['profileImage'] != null
                          ? NetworkImage(_userData['profileImage'])
                          : const AssetImage('assets/images/default_profile.png')) as ImageProvider,
                ),
              ),
              
              // زر تغيير الصورة
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // زر التعديل
        Positioned(
          top: 16,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    // إعادة تعيين القيم إذا تم إلغاء التعديل
                    _nameController.text = _userData['name'] ?? '';
                    _usernameController.text = _userData['username'] ?? '';
                    _phoneController.text = _userData['phone'] ?? '';
                    _addressController.text = _userData['address'] ?? '';
                    _serviceTypeController.text = _userData['serviceType'] ?? '';
                    _bioController.text = _userData['bio'] ?? '';
                    _imageFile = null;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // بناء معلومات الملف الشخصي (وضع العرض)
  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 70),
        
        // اسم المستخدم
        Text(
          _userData['name'] ?? 'بائع',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        
        // اسم المستخدم
        Text(
          '@${_userData['username'] ?? ''}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
        ),
        
        // السيرة الذاتية
        if (_userData['bio'] != null && _userData['bio'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _userData['bio'],
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        const SizedBox(height: 24),
        
        // معلومات الاتصال
        _buildInfoCard(
          title: 'معلومات الاتصال',
          items: [
            InfoItem(
              icon: Icons.phone,
              title: 'رقم الهاتف',
              value: _userData['phone'] ?? 'غير محدد',
            ),
            InfoItem(
              icon: Icons.location_on,
              title: 'العنوان',
              value: _userData['address'] ?? 'غير محدد',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // معلومات النشاط التجاري
        _buildInfoCard(
          title: 'معلومات النشاط التجاري',
          items: [
            InfoItem(
              icon: Icons.business,
              title: 'نوع الخدمة',
              value: _userData['serviceType'] ?? 'غير محدد',
            ),
            InfoItem(
              icon: Icons.date_range,
              title: 'تاريخ الانضمام',
              value: _userData['createdAt'] != null
                  ? _formatTimestamp(_userData['createdAt'])
                  : 'غير محدد',
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // زر تسجيل الخروج
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade700),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  // بناء نموذج التعديل
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 70),
        
        // عنوان النموذج
        const Text(
          'تعديل الملف الشخصي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        
        const SizedBox(height: 24),
        
        // حقول الإدخال
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
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _serviceTypeController,
          label: 'نوع الخدمة',
          icon: Icons.business,
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _bioController,
          label: 'نبذة شخصية',
          icon: Icons.info,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        
        // زر الحفظ
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حفظ التغييرات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // بناء بطاقة معلومات
  Widget _buildInfoCard({required String title, required List<InfoItem> items}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildInfoItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  // بناء عنصر معلومات
  Widget _buildInfoItem(InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(item.icon, color: primaryColor, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}

// فئة لتخزين معلومات العنصر
class InfoItem {
  final IconData icon;
  final String title;
  final String value;

  InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}

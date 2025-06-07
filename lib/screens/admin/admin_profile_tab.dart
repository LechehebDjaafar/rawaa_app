import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  
  // متحكمات الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);
  
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
      final String fileName = 'admin_profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = _storage.ref().child('admin_images/$fileName');
      
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
      
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage(user.uid);
      }
      
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(fontFamily: 'Cairo')),
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
            },
            child: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
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
              
              if (_isEditing && _nameController.text.isEmpty) {
                _nameController.text = userData['name'] ?? '';
                _phoneController.text = userData['phone'] ?? '';
                _addressController.text = userData['address'] ?? '';
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
                child: Center(
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: isVerySmallScreen ? 40 : 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              
              Positioned(
                bottom: isVerySmallScreen ? -30 : -40,
                child: CircleAvatar(
                  radius: isVerySmallScreen ? 35 : 45,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: isVerySmallScreen ? 32 : 42,
                    backgroundColor: accentColor.withOpacity(0.2),
                    backgroundImage: userData['profileImage'] != null
                        ? NetworkImage(userData['profileImage'])
                        : null,
                    child: userData['profileImage'] == null
                        ? Icon(
                            Icons.admin_panel_settings,
                            size: isVerySmallScreen ? 32 : 40,
                            color: secondaryColor,
                          )
                        : null,
                  ),
                ),
              ),
              
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
          
          Text(
            userData['name'] ?? 'مدير النظام',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'مدير النظام',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 12 : 14,
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 20 : 24),
          
          // معلومات الاتصال
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
          
          // إحصائيات سريعة
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إحصائيات سريعة',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: secondaryColor,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 12 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'المستخدمون',
                          Icons.people,
                          primaryColor,
                          'users',
                          isVerySmallScreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'المنتجات',
                          Icons.inventory,
                          secondaryColor,
                          'products',
                          isVerySmallScreen,
                        ),
                      ),
                    ],
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
                  fontWeight: FontWeight.bold,
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

  Widget _buildEditProfileForm(Map<String, dynamic> userData, bool isVerySmallScreen, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isVerySmallScreen ? 10 : 16),
          
          // صورة المستخدم
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: isVerySmallScreen ? 50 : 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: isVerySmallScreen ? 46 : 56,
                  backgroundColor: accentColor.withOpacity(0.2),
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : (userData['profileImage'] != null
                          ? NetworkImage(userData['profileImage'])
                          : null),
                  child: (_imageFile == null && userData['profileImage'] == null)
                      ? Icon(
                          Icons.admin_panel_settings,
                          size: isVerySmallScreen ? 40 : 50,
                          color: secondaryColor,
                        )
                      : null,
                ),
              ),
              CircleAvatar(
                backgroundColor: primaryColor,
                radius: isVerySmallScreen ? 16 : 20,
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: isVerySmallScreen ? 16 : 20,
                  ),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isVerySmallScreen ? 20 : 24),
          
          // حقول التعديل
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Icons.person,
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

  Widget _buildInfoRow(IconData icon, String label, String value, bool isVerySmallScreen) {
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

  Widget _buildStatCard(String title, IconData icon, Color color, String collection, bool isVerySmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Container(
          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: isVerySmallScreen ? 24 : 28),
              SizedBox(height: isVerySmallScreen ? 4 : 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 10 : 12,
                  color: color,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

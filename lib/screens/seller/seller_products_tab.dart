import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SellerProductsTab extends StatefulWidget {
  const SellerProductsTab({super.key});

  @override
  State<SellerProductsTab> createState() => _SellerProductsTabState();
}

class _SellerProductsTabState extends State<SellerProductsTab> with SingleTickerProviderStateMixin {
  // إضافة الفلترة الصحيحة - الحصول على معرف البائع الحالي
  final String? _currentSellerId = FirebaseAuth.instance.currentUser?.uid;
  
  // استخدام Firestore بدلاً من Firebase Storage
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  
  // متحكمات الإدخال
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  
  // متغيرات للصورة
  File? _imageFile;
  String? _base64Image;
  bool _isUploading = false;
  bool _isEditing = false;
  String? _editingProductId;
  
  // متغير الفئة المختارة
  String? _selectedCategory;
  
  // قائمة الفئات الهيدروليكية المحددة مسبقاً
  final List<Map<String, dynamic>> _hydraulicCategories = [
    {
      'name': 'معدات الهيدروليك الصناعية',
      'subcategories': [
        'مضخات هيدروليكية',
        'محركات هيدروليكية', 
        'أسطوانات هيدروليكية',
      ]
    },
    {
      'name': 'الأنابيب والوصلات',
      'subcategories': [
        'خراطيم هيدروليكية',
        'وصلات سريعة',
        'وصلات معدنية',
        'أنابيب فولاذية',
      ]
    },
    {
      'name': 'الصمامات',
      'subcategories': [
        'صمامات تحكم',
        'صمامات اتجاهية',
        'صمامات أمان',
        'موزعات هيدروليكية',
      ]
    },
    {
      'name': 'معدات الصيانة وقطع الغيار',
      'subcategories': [
        'فلاتر هيدروليكية',
        'زيوت هيدروليكية',
        'مانعات تسرب',
        'حلقات مطاطية',
      ]
    },
    {
      'name': 'أنظمة التحكم والقياس',
      'subcategories': [
        'مقاييس ضغط',
        'مستشعرات',
        'أدوات تحليل',
        'أجهزة قياس التدفق',
      ]
    },
    {
      'name': 'معدات متنقلة أو ثقيلة',
      'subcategories': [
        'رافعات هيدروليكية',
        'ملحقات آلات البناء',
        'معدات الحفر',
        'أنظمة الرفع',
      ]
    },
    {
      'name': 'الخدمات والتكوين',
      'subcategories': [
        'خدمات التركيب',
        'خدمات الصيانة',
        'التدريب والتكوين',
        'الاستشارات الفنية',
      ]
    },
  ];
  
  // قائمة مسطحة لجميع الفئات والفئات الفرعية
  List<String> _allCategories = [];
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFFFF8A65);
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
    
    _initializeCategories();
    _animationController.forward();
  }

  // تهيئة قائمة الفئات المسطحة
  void _initializeCategories() {
    _allCategories.clear();
    
    for (var category in _hydraulicCategories) {
      // إضافة الفئة الرئيسية
      _allCategories.add(category['name']);
      
      // إضافة الفئات الفرعية
      for (var subcategory in category['subcategories']) {
        _allCategories.add('${category['name']} - $subcategory');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // اختيار صورة من المعرض وتحويلها إلى Base64
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
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
          
          // تحويل الصورة إلى Base64
          await _convertImageToBase64();
        }
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصورة: $e');
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

      // تغيير حجم الصورة إذا كانت كبيرة - تحسين أفضل
      if (image.width > 600 || image.height > 600) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 600 : null,
          height: image.height > image.width ? 600 : null,
        );
      }

      // ضغط الصورة وتحويلها إلى JPEG بجودة محسنة
      List<int> compressedBytes = img.encodeJpg(image, quality: 75);

      // التحقق من الحجم النهائي وضغط أكثر إذا لزم الأمر
      if (compressedBytes.length > 800 * 1024) { // 800KB
        compressedBytes = img.encodeJpg(image, quality: 60);
      }
      
      if (compressedBytes.length > 1024 * 1024) { // 1MB
        compressedBytes = img.encodeJpg(image, quality: 45);
      }

      // تحويل إلى Base64
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

  // التحقق من الاشتراك
  Future<bool> _checkUserSubscription() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: _currentSellerId)
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: Timestamp.now())
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في التحقق من الاشتراك: $e');
      return false;
    }
  }

  // عرض نافذة الاشتراك
  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اشتراك مطلوب',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'يجب أن تكون مشتركاً لإضافة منتجات جديدة. هل تريد الاشتراك الآن؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSubscriptionPage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'اشترك الآن',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  // عرض صفحة الاشتراك
  void _showSubscriptionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionPage(),
      ),
    );
  }

  // إضافة أو تعديل منتج مع Base64 وفحص الاشتراك
  Future<void> _saveProduct() async {
    // التحقق من الاشتراك أولاً
    final hasValidSubscription = await _checkUserSubscription();
    
    if (!hasValidSubscription) {
      _showSubscriptionDialog();
      return;
    }

    final String name = _nameController.text.trim();
    final String description = _descriptionController.text.trim();
    final double? price = double.tryParse(_priceController.text.trim());
    final int? stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty || description.isEmpty || price == null || _selectedCategory == null || stock == null) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة واختيار فئة المنتج');
      return;
    }

    if (_currentSellerId == null) {
      _showErrorSnackBar('خطأ: لم يتم العثور على معرف البائع');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      if (_isEditing && _editingProductId != null) {
        // تعديل منتج موجود
        final String productId = _editingProductId!;
        
        final Map<String, dynamic> updates = {
          'name': name,
          'description': description,
          'price': price,
          'category': _selectedCategory,
          'stock': stock,
          'updatedAt': FieldValue.serverTimestamp(),
          'searchKeywords': _generateSearchKeywords(name, _selectedCategory!),
        };

        if (_base64Image != null) {
          updates['imageBase64'] = _base64Image;
          updates['hasImage'] = true;
        }

        await _productsCollection.doc(productId).update(updates);
        _showSuccessSnackBar('تم تعديل المنتج بنجاح');
      } else {
        // إنشاء منتج جديد
        final Map<String, dynamic> productData = {
          'name': name,
          'description': description,
          'price': price,
          'category': _selectedCategory,
          'stock': stock,
          'sellerId': _currentSellerId,
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': _generateSearchKeywords(name, _selectedCategory!),
        };

        if (_base64Image != null) {
          productData['imageBase64'] = _base64Image;
          productData['hasImage'] = true;
        }

        await _productsCollection.add(productData);
        _showSuccessSnackBar('تمت إضافة المنتج بنجاح');
      }

      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // توليد كلمات مفتاحية للبحث
  List<String> _generateSearchKeywords(String name, String category) {
    List<String> keywords = [];
    
    keywords.addAll(name.toLowerCase().split(' '));
    keywords.addAll(category.toLowerCase().split(' '));
    keywords.addAll(category.toLowerCase().split(' - '));
    
    keywords = keywords.where((keyword) => keyword.isNotEmpty).toSet().toList();
    
    return keywords;
  }

  // مسح النموذج
  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _stockController.clear();
      _selectedCategory = null;
      _imageFile = null;
      _base64Image = null;
      _isEditing = false;
      _editingProductId = null;
    });
  }

  // تعبئة النموذج بمنتج للتعديل
  void _editProduct(Map<String, dynamic> product, String productId) {
    setState(() {
      _isEditing = true;
      _editingProductId = productId;
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = product['price']?.toString() ?? '';
      _selectedCategory = product['category'];
      _stockController.text = product['stock']?.toString() ?? '';
    });
    _showAddProductSheet();
  }

  // حذف منتج
  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟', style: TextStyle(fontFamily: 'Cairo')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[700], fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _productsCollection.doc(productId).delete();
                _showSuccessSnackBar('تم حذف المنتج بنجاح');
              } catch (e) {
                _showErrorSnackBar('فشل حذف المنتج: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // عرض نافذة إضافة/تعديل منتج
  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final isVerySmallScreen = screenHeight < 500;
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: isVerySmallScreen ? 20 : 24,
                          ),
                          onPressed: () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                    _buildProductForm(isVerySmallScreen),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // نموذج إضافة/تعديل منتج
  Widget _buildProductForm(bool isVerySmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة المنتج مع Base64
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: isVerySmallScreen ? 100 : 120,
              height: isVerySmallScreen ? 100 : 120,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _getImageWidget(isVerySmallScreen),
            ),
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 16 : 20),

        // اسم المنتج
        _buildTextField(
          controller: _nameController,
          label: 'اسم المنتج',
          icon: Icons.shopping_bag_outlined,
          isVerySmallScreen: isVerySmallScreen,
        ),
        SizedBox(height: isVerySmallScreen ? 12 : 16),

        // وصف المنتج
        _buildTextField(
          controller: _descriptionController,
          label: 'وصف المنتج',
          icon: Icons.description_outlined,
          maxLines: 3,
          isVerySmallScreen: isVerySmallScreen,
        ),
        SizedBox(height: isVerySmallScreen ? 12 : 16),

        // قائمة منسدلة للفئات
        _buildCategoryDropdown(isVerySmallScreen),
        SizedBox(height: isVerySmallScreen ? 12 : 16),

        // سعر المنتج والكمية
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _priceController,
                label: 'السعر (د.ج)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                isVerySmallScreen: isVerySmallScreen,
              ),
            ),
            SizedBox(width: isVerySmallScreen ? 8 : 12),
            Expanded(
              child: _buildTextField(
                controller: _stockController,
                label: 'الكمية المتوفرة',
                icon: Icons.inventory_outlined,
                keyboardType: TextInputType.number,
                isVerySmallScreen: isVerySmallScreen,
              ),
            ),
          ],
        ),
        SizedBox(height: isVerySmallScreen ? 20 : 24),

        // زر الإضافة/التعديل
        SizedBox(
          width: double.infinity,
          height: isVerySmallScreen ? 40 : 48,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isUploading
                ? SizedBox(
                    height: isVerySmallScreen ? 16 : 20,
                    width: isVerySmallScreen ? 16 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'تعديل المنتج' : 'إضافة المنتج',
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // بناء قائمة منسدلة للفئات الهيدروليكية
  Widget _buildCategoryDropdown(bool isVerySmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'فئة المنتج',
          labelStyle: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.grey[700],
            fontSize: isVerySmallScreen ? 12 : 14,
          ),
          prefixIcon: Icon(
            Icons.category_outlined,
            color: primaryColor,
            size: isVerySmallScreen ? 20 : 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 12 : 16,
            vertical: isVerySmallScreen ? 12 : 16,
          ),
        ),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: isVerySmallScreen ? 14 : 16,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
        isExpanded: true,
        items: _allCategories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 12 : 14,
                color: category.contains(' - ') ? Colors.grey[600] : Colors.black87,
                fontWeight: category.contains(' - ') ? FontWeight.normal : FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى اختيار فئة المنتج';
          }
          return null;
        },
      ),
    );
  }

  // الحصول على widget الصورة مع دعم Base64
  Widget _getImageWidget(bool isVerySmallScreen) {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: isVerySmallScreen ? 30 : 40,
            color: primaryColor.withOpacity(0.7),
          ),
          SizedBox(height: isVerySmallScreen ? 4 : 8),
          Text(
            'إضافة صورة',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: primaryColor,
              fontSize: isVerySmallScreen ? 10 : 12,
            ),
          ),
        ],
      );
    }
  }

  // حقل إدخال موحد
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
        prefixIcon: Icon(
          icon,
          color: primaryColor,
          size: isVerySmallScreen ? 20 : 22,
        ),
        filled: true,
        fillColor: backgroundColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 12 : 16,
          vertical: isVerySmallScreen ? 12 : 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSellerId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: Text(
            'خطأ: لم يتم العثور على معرف البائع\nيرجى تسجيل الدخول مرة أخرى',
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
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenHeight < 500;
        
        return Scaffold(
          backgroundColor: backgroundColor,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'منتجاتي',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: secondaryColor,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _clearForm();
                          _showAddProductSheet();
                        },
                        icon: Icon(
                          Icons.add,
                          size: isVerySmallScreen ? 16 : 18,
                        ),
                        label: Text(
                          'إضافة منتج',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isVerySmallScreen ? 12 : 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 12 : 16,
                            vertical: isVerySmallScreen ? 8 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildProductsList(isSmallScreen, isVerySmallScreen),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsList(bool isSmallScreen, bool isVerySmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsCollection
          .where('sellerId', isEqualTo: _currentSellerId!)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isVerySmallScreen ? 50 : 60,
                  color: Colors.red[300],
                ),
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 14 : 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyProductsView(isVerySmallScreen);
        }

        final products = snapshot.data!.docs;

        // تحسين تخطيط الشبكة
        int crossAxisCount;
        double childAspectRatio;
        double horizontalPadding;
        double verticalSpacing;
        
        if (isSmallScreen) {
          if (isVerySmallScreen) {
            crossAxisCount = 2;
            childAspectRatio = 0.68; // تحسين النسبة لحل مشكلة الشرائط
            horizontalPadding = 8;
            verticalSpacing = 8;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 0.72;
            horizontalPadding = 12;
            verticalSpacing = 12;
          }
        } else {
          crossAxisCount = 3;
          childAspectRatio = 0.78;
          horizontalPadding = 16;
          verticalSpacing = 16;
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: primaryColor,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalSpacing,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: horizontalPadding,
              mainAxisSpacing: verticalSpacing,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              return _buildProductCard(product, productId, isVerySmallScreen);
            },
          ),
        );
      },
    );
  }

  // دالة لعرض حالة عدم وجود منتجات
  Widget _buildEmptyProductsView(bool isVerySmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: isVerySmallScreen ? 60 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Text(
              'لا يوجد منتجات بعد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 6 : 8),
            Text(
              'قم بإضافة منتجك الأول بالضغط على زر "إضافة منتج"',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 12 : 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isVerySmallScreen ? 20 : 24),
            ElevatedButton.icon(
              onPressed: () {
                _clearForm();
                _showAddProductSheet();
              },
              icon: Icon(
                Icons.add,
                size: isVerySmallScreen ? 16 : 18,
              ),
              label: Text(
                'إضافة منتج جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 14 : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 20 : 24,
                  vertical: isVerySmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String productId, bool isVerySmallScreen) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight( // إضافة IntrinsicHeight لحل مشكلة الشرائط
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            AspectRatio(
              aspectRatio: 1.2, // نسبة ثابتة للصورة
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[200],
                      child: _getProductImage(product),
                    ),
                    // أزرار التعديل والحذف
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: isVerySmallScreen ? 28 : 32,
                        height: isVerySmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: isVerySmallScreen ? 12 : 14,
                          ),
                          onPressed: () => _editProduct(product, productId),
                          color: primaryColor,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        width: isVerySmallScreen ? 28 : 32,
                        height: isVerySmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: isVerySmallScreen ? 12 : 14,
                          ),
                          onPressed: () => _deleteProduct(productId),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // معلومات المنتج
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      product['name'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: isVerySmallScreen ? 11 : 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isVerySmallScreen ? 4 : 6),
                    
                    // الفئة
                    Text(
                      product['category'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 9 : 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // السعر والمخزون
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${product['price']?.toString() ?? '0'} د.ج',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: isVerySmallScreen ? 11 : 13,
                              color: primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 4 : 6,
                            vertical: isVerySmallScreen ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'المخزون: ${product['stock']?.toString() ?? '0'}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 8 : 9,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الحصول على صورة المنتج من Base64
  Widget _getProductImage(Map<String, dynamic> product) {
    if (product['imageBase64'] != null && product['imageBase64'].toString().isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(product['imageBase64']);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_not_supported,
            size: 30,
            color: Colors.grey[400],
          ),
        );
      } catch (e) {
        print('خطأ في تحويل Base64 إلى صورة: $e');
        return Icon(
          Icons.image_not_supported,
          size: 30,
          color: Colors.grey[400],
        );
      }
    } else {
      return Icon(
        Icons.image_outlined,
        size: 30,
        color: Colors.grey[400],
      );
    }
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
}

// صفحة الاشتراك
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? _selectedPlan;
  String? _selectedPaymentMethod;
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  File? _receiptFile;
  bool _isUploading = false;

  // خطط الاشتراك
  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'id': 'monthly_basic',
      'name': 'الخطة الأساسية - شهرية',
      'duration': 'monthly',
      'price': 1000,
      'features': ['إضافة 50 منتج', 'دعم فني أساسي', 'تحليلات بسيطة']
    },
    {
      'id': 'monthly_premium',
      'name': 'الخطة المميزة - شهرية',
      'duration': 'monthly',
      'price': 2000,
      'features': ['إضافة 200 منتج', 'دعم فني متقدم', 'تحليلات متقدمة', 'أولوية في العرض']
    },
    {
      'id': '6months_basic',
      'name': 'الخطة الأساسية - 6 أشهر',
      'duration': '6months',
      'price': 5000,
      'features': ['إضافة 50 منتج', 'دعم فني أساسي', 'تحليلات بسيطة', 'خصم 15%']
    },
    {
      'id': '6months_premium',
      'name': 'الخطة المميزة - 6 أشهر',
      'duration': '6months',
      'price': 10000,
      'features': ['إضافة 200 منتج', 'دعم فني متقدم', 'تحليلات متقدمة', 'أولوية في العرض', 'خصم 15%']
    },
    {
      'id': 'yearly_basic',
      'name': 'الخطة الأساسية - سنوية',
      'duration': 'yearly',
      'price': 8000,
      'features': ['إضافة 50 منتج', 'دعم فني أساسي', 'تحليلات بسيطة', 'خصم 30%']
    },
    {
      'id': 'yearly_premium',
      'name': 'الخطة المميزة - سنوية',
      'duration': 'yearly',
      'price': 15000,
      'features': ['إضافة 200 منتج', 'دعم فني متقدم', 'تحليلات متقدمة', 'أولوية في العرض', 'خصم 30%']
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خطط الاشتراك', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlansSection(),
            const SizedBox(height: 24),
            if (_selectedPlan != null) _buildPaymentMethodSection(),
            const SizedBox(height: 24),
            if (_selectedPaymentMethod != null) _buildPaymentDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر خطة الاشتراك',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 16),
        ...(_subscriptionPlans.map((plan) => _buildPlanCard(plan)).toList()),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == plan['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '${plan['price']} د.ج',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isSelected ? const Color(0xFF1976D2) : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...((plan['features'] as List<String>).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: isSelected ? const Color(0xFF1976D2) : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر طريقة الدفع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard('baridimob', 'بريدي موب', Icons.phone_android),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodCard('ccp', 'CCP', Icons.account_balance),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String method, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل الدفع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 16),
        
        if (_selectedPaymentMethod == 'baridimob') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات الدفع عبر بريدي موب:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'رقم الهاتف: 0555123456',
                  style: TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                ),
                Text(
                  'البريد الإلكتروني: payment@rawaa.dz',
                  style: TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                ),
                SizedBox(height: 8),
                Text(
                  'يرجى إرسال المبلغ ثم رفع إثبات الدفع أدناه',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_selectedPaymentMethod == 'ccp') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات الدفع عبر CCP:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'رقم الحساب: 0020000123456789',
                  style: TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                ),
                Text(
                  'اسم الحساب: RAWAA HYDRAULIC',
                  style: TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                ),
                SizedBox(height: 8),
                Text(
                  'يرجى تحويل المبلغ ثم رفع إثبات التحويل أدناه',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // حقول الإدخال
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            labelStyle: TextStyle(fontFamily: 'Cairo'),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            labelStyle: TextStyle(fontFamily: 'Cairo'),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 16),
        
        // رفع الوصل
        GestureDetector(
          onTap: _pickReceiptFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  _receiptFile != null ? Icons.check_circle : Icons.upload_file,
                  size: 40,
                  color: _receiptFile != null ? Colors.green : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  _receiptFile != null ? 'تم اختيار الملف' : 'اضغط لرفع إثبات الدفع',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (_receiptFile != null)
                  Text(
                    _receiptFile!.path.split('/').last,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // زر الإرسال
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _submitSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'إرسال طلب الاشتراك',
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

  Future<void> _pickReceiptFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _receiptFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الملف: $e')),
      );
    }
  }

  Future<void> _submitSubscription() async {
    if (_phoneController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول ورفع إثبات الدفع')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // تحويل الملف إلى Base64 بدلاً من رفعه إلى Storage
      String receiptBase64 = '';
      if (_receiptFile != null) {
        final bytes = await _receiptFile!.readAsBytes();
        receiptBase64 = base64Encode(bytes);
      }

      // إنشاء طلب الاشتراك مع Base64
      final subscriptionData = {
        'userId': _currentUserId,
        'planId': _selectedPlan,
        'paymentMethod': _selectedPaymentMethod,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'receiptBase64': receiptBase64, // حفظ الملف كـ Base64
        'receiptFileName': _receiptFile!.path.split('/').last,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('subscription_requests')
          .add(subscriptionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب الاشتراك بنجاح! سيتم مراجعته قريباً'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إرسال الطلب: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

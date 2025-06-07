import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';
import 'dart:math';
import 'dart:convert';

// Extension لتدوير الأرقام العشرية
extension DoubleExtension on double {
  double roundToPrecision(int places) {
    double mod = pow(10.0, places).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> with SingleTickerProviderStateMixin {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _cartCollection = FirebaseFirestore.instance.collection('cart');
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  
  // الفئات الهيدروليكية المحدثة - نفس القائمة المستخدمة في واجهة البائع
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
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);
  final Color aiColor = const Color(0xFF9C27B0); // لون مخصص للـ AI
  
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
    
    _initializeCategories(); // تهيئة الفئات المحددة مسبقاً
    _ensureCollectionsExist().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // تهيئة قائمة الفئات المسطحة
  void _initializeCategories() {
    _allCategories.clear();
    _allCategories.add('الكل'); // إضافة خيار "الكل" في البداية
    
    for (var category in _hydraulicCategories) {
      // إضافة الفئة الرئيسية
      _allCategories.add(category['name']);
      
      // إضافة الفئات الفرعية
      for (var subcategory in category['subcategories']) {
        _allCategories.add('${category['name']} - $subcategory');
      }
    }
  }

  // التحقق من وجود المجموعات
  Future<void> _ensureCollectionsExist() async {
    try {
      final collections = [_productsCollection, _cartCollection, _ratingsCollection];
      
      for (var collection in collections) {
        final snapshot = await collection.limit(1).get();
        if (snapshot.docs.isEmpty) {
          print('إنشاء مجموعة ${collection.path} لأول مرة');
          DocumentReference tempDoc = await collection.add({
            'temp': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await tempDoc.delete();
        }
      }
    } catch (e) {
      print('خطأ في التحقق من وجود المجموعات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;
        final isVerySmallScreen = screenHeight < 500;
        
        int crossAxisCount;
        double childAspectRatio;
        double horizontalPadding;
        double verticalSpacing;
        
        if (isSmallScreen) {
          crossAxisCount = 2;
          childAspectRatio = isVerySmallScreen ? 0.55 : 0.58;
          horizontalPadding = 12;
          verticalSpacing = 12;
        } else if (isMediumScreen) {
          crossAxisCount = 3;
          childAspectRatio = 0.65;
          horizontalPadding = 16;
          verticalSpacing = 16;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.68;
          horizontalPadding = 20;
          verticalSpacing = 20;
        }
        
        return Scaffold(
          body: Container(
            color: backgroundColor,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // شريط البحث والفلترة - مرن
                        _buildSearchAndFilter(isVerySmallScreen),
                        
                        // شبكة المنتجات - مرنة ومتجاوبة
                        Expanded(
                          child: _buildProductsGrid(
                            crossAxisCount,
                            childAspectRatio,
                            horizontalPadding,
                            verticalSpacing,
                            isVerySmallScreen,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // الأيقونة العائمة للـ AI Chatbot
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [aiColor, aiColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: aiColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _showAIChatBot(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.smart_toy_rounded, // أيقونة الروبوت
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  // عرض نافذة الـ AI Chatbot
  void _showAIChatBot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIChatBotWidget(
        primaryColor: primaryColor,
        aiColor: aiColor,
        secondaryColor: secondaryColor,
      ),
    );
  }

  // بناء شريط البحث والفلترة المحدث
  Widget _buildSearchAndFilter(bool isVerySmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      child: Column(
        children: [
          // شريط البحث
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: isVerySmallScreen ? 40 : 48,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج هيدروليكي...',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 12 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: primaryColor,
                        size: isVerySmallScreen ? 20 : 24,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isVerySmallScreen ? 8 : 12,
                        horizontal: 16,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 6 : 8),
              Container(
                height: isVerySmallScreen ? 40 : 48,
                width: isVerySmallScreen ? 40 : 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: isVerySmallScreen ? 18 : 22,
                  ),
                  onPressed: () {
                    _showFilterBottomSheet(context, isVerySmallScreen);
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: isVerySmallScreen ? 8 : 12),
          
          // شريط الفئات الهيدروليكية المحدث
          SizedBox(
            height: isVerySmallScreen ? 35 : 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 4 : 8),
              itemCount: _allCategories.length > 8 ? 8 : _allCategories.length, // عرض أول 8 فئات فقط
              itemBuilder: (context, index) {
                final category = _allCategories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: EdgeInsets.only(right: isVerySmallScreen ? 6 : 8),
                  child: ChoiceChip(
                    label: Text(
                      _getCategoryDisplayName(category),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 9 : 11,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 6 : 10,
                      vertical: isVerySmallScreen ? 2 : 4,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // دالة لتقصير أسماء الفئات للعرض
  String _getCategoryDisplayName(String category) {
    if (category == 'الكل') return 'الكل';
    if (category.contains(' - ')) {
      return category.split(' - ')[1]; // عرض الفئة الفرعية فقط
    }
    // تقصير أسماء الفئات الطويلة
    if (category.length > 15) {
      return category.substring(0, 12) + '...';
    }
    return category;
  }

  // بناء شبكة المنتجات المرنة
  Widget _buildProductsGrid(
    int crossAxisCount,
    double childAspectRatio,
    double horizontalPadding,
    double verticalSpacing,
    bool isVerySmallScreen,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredProductsStream(),
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
                  'حدث خطأ في تحميل المنتجات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 14 : 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.precision_manufacturing_outlined,
                  size: isVerySmallScreen ? 60 : 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                Text(
                  _selectedCategory == 'الكل' 
                      ? 'لا توجد منتجات هيدروليكية متاحة'
                      : 'لا توجد منتجات في فئة "${_getCategoryDisplayName(_selectedCategory)}"',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'جرب البحث في فئة أخرى أو تصفح جميع المنتجات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final products = snapshot.data!.docs;
        
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
              mainAxisSpacing: verticalSpacing,
              crossAxisSpacing: horizontalPadding,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              
              return ProductCard(
                product: product,
                productId: productId,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                alertColor: alertColor,
                isVerySmallScreen: isVerySmallScreen,
                onAddToCart: () => _addToCart(productId, product),
                onAddToFavorites: () => _addToFavorites(productId),
              );
            },
          ),
        );
      },
    );
  }

  // الحصول على ستريم المنتجات المفلترة
  Stream<QuerySnapshot> _getFilteredProductsStream() {
    Query query = _productsCollection;
    
    if (_selectedCategory != 'الكل') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    if (_searchQuery.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: _searchQuery.toLowerCase());
    }
    
    try {
      return query.orderBy('createdAt', descending: true).snapshots();
    } catch (e) {
      // في حالة عدم وجود فهرس، ارجع بدون ترتيب
      return query.snapshots();
    }
  }

  // عرض نافذة الفلاتر المحدثة مع الفئات الهيدروليكية
  void _showFilterBottomSheet(BuildContext context, bool isVerySmallScreen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * (isVerySmallScreen ? 0.7 : 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تصفية المنتجات الهيدروليكية',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: secondaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: isVerySmallScreen ? 20 : 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            
            Text(
              'الفئات المتخصصة',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: primaryColor,
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 6 : 8),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // خيار "الكل"
                    _buildCategoryTile('الكل', Icons.all_inclusive, isVerySmallScreen),
                    
                    const SizedBox(height: 12),
                    
                    // الفئات الهيدروليكية المنظمة
                    ..._hydraulicCategories.map((categoryGroup) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الفئة الرئيسية
                          _buildCategoryGroupHeader(categoryGroup['name'], isVerySmallScreen),
                          
                          // الفئات الفرعية
                          ...categoryGroup['subcategories'].map<Widget>((subcategory) {
                            final fullCategory = '${categoryGroup['name']} - $subcategory';
                            return _buildSubcategoryTile(fullCategory, subcategory, isVerySmallScreen);
                          }).toList(),
                          
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: isVerySmallScreen ? 40 : 48,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'الكل';
                    _searchQuery = '';
                  });
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إعادة تعيين الفلاتر',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء عنوان مجموعة الفئات
  Widget _buildCategoryGroupHeader(String title, bool isVerySmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 8 : 10,
        horizontal: isVerySmallScreen ? 12 : 16,
      ),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: isVerySmallScreen ? 12 : 14,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  // بناء بلاطة الفئة
  Widget _buildCategoryTile(String category, IconData icon, bool isVerySmallScreen) {
    final isSelected = category == _selectedCategory;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isVerySmallScreen ? 10 : 12,
          horizontal: isVerySmallScreen ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey[600],
              size: isVerySmallScreen ? 18 : 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 12 : 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
                size: isVerySmallScreen ? 16 : 18,
              ),
          ],
        ),
      ),
    );
  }

  // بناء بلاطة الفئة الفرعية
  Widget _buildSubcategoryTile(String fullCategory, String displayName, bool isVerySmallScreen) {
    final isSelected = fullCategory == _selectedCategory;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = fullCategory;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(left: 20, bottom: 2),
        padding: EdgeInsets.symmetric(
          vertical: isVerySmallScreen ? 8 : 10,
          horizontal: isVerySmallScreen ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right,
              color: isSelected ? primaryColor : Colors.grey[500],
              size: isVerySmallScreen ? 14 : 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 11 : 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: primaryColor,
                size: isVerySmallScreen ? 14 : 16,
              ),
          ],
        ),
      ),
    );
  }

  // إضافة منتج إلى السلة
  Future<void> _addToCart(String productId, Map<String, dynamic> product) async {
    if (_currentUserId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      final cartSnapshot = await _cartCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: productId)
          .get();
      
      if (cartSnapshot.docs.isNotEmpty) {
        final cartItemId = cartSnapshot.docs.first.id;
        final data = cartSnapshot.docs.first.data() as Map<String, dynamic>;
        final currentQuantity = data['quantity'] as int;
        
        await _cartCollection.doc(cartItemId).update({
          'quantity': currentQuantity + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت زيادة كمية المنتج في السلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _cartCollection.add({
          'userId': _currentUserId,
          'productId': productId,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
          'productName': product['name'] ?? 'منتج',
          'productPrice': product['price'] ?? 0,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المنتج إلى السلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // إضافة منتج إلى المفضلة
  Future<void> _addToFavorites(String productId) async {
    if (_currentUserId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    try {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: productId)
          .get();
      
      if (favoritesSnapshot.docs.isNotEmpty) {
        final favoriteId = favoritesSnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('favorites').doc(favoriteId).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة المنتج من المفضلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': _currentUserId,
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المنتج إلى المفضلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ويدجت الـ AI Chatbot
class AIChatBotWidget extends StatefulWidget {
  final Color primaryColor;
  final Color aiColor;
  final Color secondaryColor;

  const AIChatBotWidget({
    super.key,
    required this.primaryColor,
    required this.aiColor,
    required this.secondaryColor,
  });

  @override
  State<AIChatBotWidget> createState() => _AIChatBotWidgetState();
}

class _AIChatBotWidgetState extends State<AIChatBotWidget> {
  List<ChatMessage> messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // الأسئلة المحددة مسبقاً
  final List<Map<String, String>> predefinedQuestions = [
    {
      'question': 'ما هي أفضل المنتجات الهيدروليكية؟',
      'answer': 'نحن نقدم مجموعة واسعة من المعدات الهيدروليكية عالية الجودة. أنصحك بالاطلاع على المضخات الهيدروليكية والصمامات المتخصصة.'
    },
    {
      'question': 'كيف أختار المضخة الهيدروليكية المناسبة؟',
      'answer': 'لاختيار المضخة المناسبة، انتبه إلى: معدل التدفق المطلوب، ضغط التشغيل، نوع السائل، والبيئة التشغيلية. يمكنك استشارة خبرائنا للمساعدة.'
    },
    {
      'question': 'هل تقدمون خدمات الصيانة؟',
      'answer': 'نعم! نقدم خدمات صيانة شاملة للمعدات الهيدروليكية، بما في ذلك الفحص الدوري وإصلاح الأعطال وتوفير قطع الغيار الأصلية.'
    },
    {
      'question': 'ما هي أوقات التوصيل للمعدات؟',
      'answer': 'نوصل المعدات الصغيرة خلال 24-48 ساعة، والمعدات الثقيلة خلال 3-5 أيام عمل. التوصيل مجاني للطلبات فوق 10,000 د.ج.'
    },
    {
      'question': 'هل المعدات مضمونة؟',
      'answer': 'بالطبع! جميع معداتنا أصلية ومضمونة لمدة سنتين. نعمل مع أفضل الشركات العالمية في مجال الهيدروليك.'
    },
    {
      'question': 'هل تقدمون التدريب التقني؟',
      'answer': 'نعم! نقدم دورات تدريبية متخصصة في الأنظمة الهيدروليكية، الصيانة الوقائية، وتشخيص الأعطال. اتصل بنا للتفاصيل.'
    },
  ];

  @override
  void initState() {
    super.initState();
    // إضافة رسالة ترحيب
    messages.add(ChatMessage(
      text: 'مرحباً! أنا مساعدك المتخصص في الأنظمة الهيدروليكية 🔧\nكيف يمكنني مساعدتك اليوم؟\nاختر أحد الأسئلة أدناه أو اكتب سؤالك:',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // رأس الشات
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.aiColor, widget.aiColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.precision_manufacturing, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مساعد RAWAA الهيدروليكي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'خبير الأنظمة الهيدروليكية',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // منطقة الرسائل
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ChatBubble(
                  message: message,
                  primaryColor: widget.primaryColor,
                  aiColor: widget.aiColor,
                );
              },
            ),
          ),

          // الأسئلة المحددة مسبقاً
          if (messages.length == 1) // فقط في البداية
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: predefinedQuestions.length,
                itemBuilder: (context, index) {
                  final question = predefinedQuestions[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _handlePredefinedQuestion(question),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.help_outline, color: widget.aiColor, size: 20),
                              const SizedBox(height: 8),
                              Text(
                                question['question']!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // حقل الإدخال
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اسأل عن المعدات الهيدروليكية...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.aiColor, widget.aiColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePredefinedQuestion(Map<String, String> question) {
    // إضافة سؤال المستخدم
    setState(() {
      messages.add(ChatMessage(
        text: question['question']!,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    // إضافة إجابة الـ AI بعد تأخير قصير
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add(ChatMessage(
          text: question['answer']!,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();

    // محاكاة رد الـ AI
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        messages.add(ChatMessage(
          text: _generateAIResponse(userMessage),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('مضخة') || message.contains('مضخات')) {
      return 'المضخات الهيدروليكية متوفرة بأنواع مختلفة: مضخات الترس، المكبسية، والطرد المركزي. أي نوع تحتاج؟ 🔧';
    } else if (message.contains('صمام') || message.contains('صمامات')) {
      return 'لدينا صمامات تحكم، اتجاهية، وأمان. كل نوع له استخدامات محددة. ما هو التطبيق المطلوب؟ ⚙️';
    } else if (message.contains('ضغط') || message.contains('تدفق')) {
      return 'مقاييس الضغط والتدفق ضرورية لمراقبة الأنظمة الهيدروليكية. نقدم أجهزة قياس دقيقة ومعايرة! 📊';
    } else if (message.contains('صيانة') || message.contains('إصلاح')) {
      return 'نقدم خدمات صيانة شاملة: فحص دوري، تغيير الزيوت، إصلاح التسريبات، وقطع غيار أصلية. 🔧';
    } else if (message.contains('زيت') || message.contains('هيدروليك')) {
      return 'الزيوت الهيدروليكية عالية الجودة متوفرة بدرجات لزوجة مختلفة. ما هو نوع المعدة المستخدمة؟ 🛢️';
    } else if (message.contains('سعر') || message.contains('تكلفة')) {
      return 'أسعارنا تنافسية جداً! نقدم عروض خاصة للكميات الكبيرة والعملاء المؤسسيين. 💰';
    } else {
      return 'شكراً لسؤالك! فريق الخبراء سيساعدك بتفاصيل أكثر. يمكنك أيضاً تصفح فئات المعدات المختلفة. 🤝';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// نموذج الرسالة
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// فقاعة الدردشة
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Color primaryColor;
  final Color aiColor;

  const ChatBubble({
    super.key,
    required this.message,
    required this.primaryColor,
    required this.aiColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: aiColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.precision_manufacturing, color: aiColor, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.person, color: primaryColor, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// بطاقة المنتج المحسنة مع تدوير التقييمات
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color alertColor;
  final bool isVerySmallScreen;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToFavorites;

  const ProductCard({
    super.key,
    required this.product,
    required this.productId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.alertColor,
    required this.isVerySmallScreen,
    required this.onAddToCart,
    required this.onAddToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetails(productId: productId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;
            final imageHeight = totalHeight * 0.35;
            final contentHeight = totalHeight * 0.65;
            
            return SizedBox(
              height: totalHeight,
              child: Column(
                children: [
                  // صورة المنتج
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        image: product['imageBase64'] != null
                            ? DecorationImage(
                                image: MemoryImage(base64Decode(product['imageBase64'])),
                                fit: BoxFit.cover,
                              )
                            : product['imageUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(product['imageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (product['imageBase64'] == null && product['imageUrl'] == null)
                          ? Center(
                              child: Icon(
                                Icons.precision_manufacturing_outlined,
                                size: isVerySmallScreen ? 20 : 28,
                                color: Colors.grey[400],
                              ),
                            )
                          : null,
                    ),
                  ),
                  
                  // محتوى البطاقة
                  SizedBox(
                    height: contentHeight,
                    child: Padding(
                      padding: EdgeInsets.all(isVerySmallScreen ? 4 : 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم المنتج
                          SizedBox(
                            height: isVerySmallScreen ? 24 : 28,
                            child: Text(
                              product['name'] ?? 'منتج',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                fontSize: isVerySmallScreen ? 10 : 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 2 : 3),
                          
                          // الفئة
                          SizedBox(
                            height: isVerySmallScreen ? 12 : 14,
                            child: Text(
                              'الفئة: ${_getCategoryDisplayName(product['category'] ?? 'غير محدد')}',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 8 : 10,
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 2 : 3),
                          
                          // التقييم مع تدوير رقمين بعد الفاصلة
                          SizedBox(
                            height: isVerySmallScreen ? 14 : 16,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('ratings')
                                  .where('productId', isEqualTo: productId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                double averageRating = 0.0;
                                int reviewCount = 0;
                                
                                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                  double totalRating = 0;
                                  reviewCount = snapshot.data!.docs.length;
                                  
                                  for (var doc in snapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    totalRating += (data['rating'] ?? 0).toDouble();
                                  }
                                  
                                  // تدوير التقييم إلى رقمين بعد الفاصلة
                                  averageRating = DoubleExtension((totalRating / reviewCount)).roundToPrecision(2);
                                }
                                
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: isVerySmallScreen ? 10 : 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      averageRating.toString(),
                                      style: TextStyle(
                                        fontSize: isVerySmallScreen ? 8 : 10,
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($reviewCount)',
                                      style: TextStyle(
                                        fontSize: isVerySmallScreen ? 7 : 9,
                                        color: Colors.grey[600],
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          
                          // مساحة مرنة
                          const Spacer(),
                          
                          // السعر والمفضلة
                          SizedBox(
                            height: isVerySmallScreen ? 16 : 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${product['price']?.toString() ?? '0'} د.ج',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor,
                                      fontFamily: 'Cairo',
                                      fontSize: isVerySmallScreen ? 9 : 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: isVerySmallScreen ? 20 : 24,
                                  height: isVerySmallScreen ? 20 : 24,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.favorite_border,
                                      color: Colors.red.shade400,
                                      size: isVerySmallScreen ? 12 : 14,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: onAddToFavorites,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 2 : 4),
                          
                          // زر إضافة للسلة
                          SizedBox(
                            width: double.infinity,
                            height: isVerySmallScreen ? 20 : 24,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: alertColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              onPressed: onAddToCart,
                              child: FittedBox(
                                child: Text(
                                  'أضف للسلة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: isVerySmallScreen ? 7 : 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    if (category.contains(' - ')) {
      return category.split(' - ')[1]; // عرض الفئة الفرعية فقط
    }
    return category;
  }
}

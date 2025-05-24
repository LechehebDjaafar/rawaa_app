import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> with SingleTickerProviderStateMixin {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _cartCollection = FirebaseFirestore.instance.collection('cart');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  List<String> _categories = ['الكل'];
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ
  
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
    
    // التحقق من وجود مجموعة المنتجات وإنشائها إذا لم تكن موجودة
    _ensureProductsCollectionExists().then((_) {
      // جلب الفئات المتاحة
      _fetchCategories();
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود مجموعة المنتجات وإنشائها إذا لم تكن موجودة
  Future<void> _ensureProductsCollectionExists() async {
    try {
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await _productsCollection.limit(1).get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة المنتجات لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await _productsCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
      
      // التحقق من وجود مجموعة السلة
      final cartSnapshot = await _cartCollection.limit(1).get();
      
      if (cartSnapshot.docs.isEmpty) {
        print('إنشاء مجموعة السلة لأول مرة');
        
        DocumentReference tempCartDoc = await _cartCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await tempCartDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود المجموعات: $e');
    }
  }

  // جلب الفئات المتاحة
  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _productsCollection.get();
      
      if (snapshot.docs.isNotEmpty) {
        Set<String> categories = {'الكل'};
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['category'] != null && data['category'].toString().isNotEmpty) {
            categories.add(data['category'].toString());
          }
        }
        
        setState(() {
          _categories = categories.toList();
        });
      }
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // شريط البحث
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'ابحث عن منتج...',
                              hintStyle: const TextStyle(fontFamily: 'Cairo'),
                              prefixIcon: Icon(Icons.search, color: primaryColor),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                            onPressed: () {
                              _showFilterBottomSheet(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // شريط الفئات
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: Colors.white,
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
                  
                  // شبكة المنتجات
                  Expanded(
                    child: _buildProductsGrid(),
                  ),
                ],
              ),
            ),
    );
  }

  // بناء شبكة المنتجات
  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
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
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد منتجات متاحة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
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
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.6, // تعديل النسبة لحل مشكلة الشريط الأسود والأصفر
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
    
    // فلترة حسب الفئة
    if (_selectedCategory != 'الكل') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      // نستخدم استعلام مركب للبحث في عدة حقول
      // ملاحظة: هذا يتطلب إنشاء فهارس مركبة في Firestore
      query = query.where('searchKeywords', arrayContains: _searchQuery.toLowerCase());
    }
    
    // ترتيب حسب تاريخ الإنشاء
    return query.orderBy('createdAt', descending: true).snapshots();
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
      // التحقق مما إذا كان المنتج موجودًا بالفعل في السلة
      final cartSnapshot = await _cartCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: productId)
          .get();
      
      if (cartSnapshot.docs.isNotEmpty) {
        // المنتج موجود بالفعل، زيادة الكمية
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
        // المنتج غير موجود، إضافته للسلة
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
      // التحقق مما إذا كان المنتج موجودًا بالفعل في المفضلة
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: productId)
          .get();
      
      if (favoritesSnapshot.docs.isNotEmpty) {
        // المنتج موجود بالفعل، إزالته من المفضلة
        final favoriteId = favoritesSnapshot.docs.first.id;
        
        await FirebaseFirestore.instance.collection('favorites').doc(favoriteId).delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة المنتج من المفضلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // المنتج غير موجود، إضافته للمفضلة
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

  // عرض نافذة الفلاتر
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تصفية المنتجات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: secondaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // فلترة حسب الفئة
            Text(
              'الفئة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                
                return ChoiceChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: Colors.grey[200],
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            
            // يمكن إضافة المزيد من الفلاتر هنا (السعر، التقييم، إلخ)
            
            const Spacer(),
            
            // زر إعادة تعيين الفلاتر
            SizedBox(
              width: double.infinity,
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إعادة تعيين الفلاتر',
                  style: TextStyle(
                    fontSize: 16,
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
}

// بطاقة المنتج
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color alertColor;
  final VoidCallback onAddToCart;
  final VoidCallback onAddToFavorites;

  const ProductCard({
    super.key,
    required this.product,
    required this.productId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.alertColor,
    required this.onAddToCart,
    required this.onAddToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              // الانتقال لتفاصيل المنتج
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetails(
                    productId: productId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المنتج (بحجم ثابت)
                Container(
                  height: constraints.maxHeight * 0.4, // 40% من ارتفاع البطاقة
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: product['imageUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(product['imageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product['imageUrl'] == null
                      ? Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
                
                // محتوى البطاقة (مع Expanded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المنتج
                        Text(
                          product['name'] ?? 'منتج',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // الفئة
                        Text(
                          'الفئة: ${product['category'] ?? 'غير محدد'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // التقييم
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              product['rating']?.toString() ?? '0.0',
                              style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // السعر والمفضلة
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${product['price']?.toString() ?? '0'} دج',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite_border, color: Colors.red.shade400, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: onAddToFavorites,
                            ),
                          ],
                        ),
                        
                        // مساحة متغيرة
                        const Spacer(),
                        
                        // زر إضافة للسلة
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: alertColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                            ),
                            onPressed: onAddToCart,
                            child: const Text(
                              'أضف للسلة',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            ),
                          ),
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
    );
  }
}

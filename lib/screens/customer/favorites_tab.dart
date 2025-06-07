import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';
import 'dart:math';

// Extension لتدوير الأرقام العشرية
extension DoubleExtension on double {
  double roundToPrecision(int places) {
    double mod = pow(10.0, places).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> with SingleTickerProviderStateMixin {
  final CollectionReference _favoritesCollection = FirebaseFirestore.instance.collection('favorites');
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _cartCollection = FirebaseFirestore.instance.collection('cart');
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isLoading = true;

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

    // التحقق من وجود المجموعات وإنشائها إذا لم تكن موجودة
    _ensureCollectionsExist().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود المجموعات وإنشائها إذا لم تكن موجودة
  Future<void> _ensureCollectionsExist() async {
    try {
      final collections = [
        _favoritesCollection,
        _productsCollection,
        _cartCollection,
        _ratingsCollection
      ];

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
        // الحصول على معلومات الشاشة للتصميم المتجاوب
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;
        final isVerySmallScreen = screenHeight < 500;
        
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
                  child: _buildFavoritesList(
                    isSmallScreen: isSmallScreen,
                    isMediumScreen: isMediumScreen,
                    isVerySmallScreen: isVerySmallScreen,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFavoritesList({
    required bool isSmallScreen,
    required bool isMediumScreen,
    required bool isVerySmallScreen,
    required double screenWidth,
    required double screenHeight,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _favoritesCollection
          .where('userId', isEqualTo: _currentUserId)
          .snapshots(),
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
          return Center(
            child: Padding(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_outlined,
                    size: isVerySmallScreen ? 60 : 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: isVerySmallScreen ? 12 : 16),
                  Text(
                    'لا توجد منتجات في المفضلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 6 : 8),
                  Text(
                    'أضف منتجات إلى المفضلة لتظهر هنا',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isVerySmallScreen ? 20 : 24),
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 200,
                    height: isVerySmallScreen ? 40 : 48,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        size: isVerySmallScreen ? 18 : 20,
                      ),
                      label: Text(
                        'تصفح المنتجات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: isVerySmallScreen ? 14 : 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // الانتقال إلى صفحة المنتجات
                        DefaultTabController.of(context)?.animateTo(0);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final favorites = snapshot.data!.docs;
        
        // تحديد عدد الأعمدة ونسب العرض إلى الارتفاع حسب حجم الشاشة
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
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index].data() as Map<String, dynamic>;
              final favoriteId = favorites[index].id;
              final productId = favorite['productId'] as String;

              return FutureBuilder<DocumentSnapshot>(
                future: _productsCollection.doc(productId).get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: SizedBox(
                          width: isVerySmallScreen ? 20 : 24,
                          height: isVerySmallScreen ? 20 : 24,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: isVerySmallScreen ? 30 : 40,
                              color: Colors.red[300],
                            ),
                            SizedBox(height: isVerySmallScreen ? 4 : 8),
                            Text(
                              'منتج غير متوفر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: isVerySmallScreen ? 10 : 12,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isVerySmallScreen ? 4 : 8),
                            SizedBox(
                              width: double.infinity,
                              height: isVerySmallScreen ? 20 : 24,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _removeFromFavorites(favoriteId),
                                child: Text(
                                  'إزالة',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 8 : 10,
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

                  final product = productSnapshot.data!.data() as Map<String, dynamic>;

                  return FavoriteProductCard(
                    product: product,
                    productId: productId,
                    favoriteId: favoriteId,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    alertColor: alertColor,
                    isVerySmallScreen: isVerySmallScreen,
                    isSmallScreen: isSmallScreen,
                    onRemoveFromFavorites: () => _removeFromFavorites(favoriteId),
                    onAddToCart: () => _addToCart(productId, product),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // إزالة من المفضلة
  Future<void> _removeFromFavorites(String favoriteId) async {
    try {
      await _favoritesCollection.doc(favoriteId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إزالة المنتج من المفضلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  // إضافة إلى السلة
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
      // التحقق من وجود المنتج في السلة
      final cartSnapshot = await _cartCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: productId)
          .get();

      if (cartSnapshot.docs.isNotEmpty) {
        // إذا كان المنتج موجود، زيادة الكمية
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
        // إضافة منتج جديد للسلة
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
}

// بطاقة المنتج المفضل المحسنة والمرنة
class FavoriteProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final String favoriteId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color alertColor;
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final VoidCallback onRemoveFromFavorites;
  final VoidCallback onAddToCart;

  const FavoriteProductCard({
    super.key,
    required this.product,
    required this.productId,
    required this.favoriteId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.alertColor,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.onRemoveFromFavorites,
    required this.onAddToCart,
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
            final imageHeight = totalHeight * 0.35; // 35% للصورة
            final contentHeight = totalHeight * 0.65; // 65% للمحتوى
            
            return SizedBox(
              height: totalHeight,
              child: Column(
                children: [
                  // صورة المنتج بحجم محدد
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                                size: isVerySmallScreen ? 20 : 28,
                                color: Colors.grey[400],
                              ),
                            )
                          : null,
                    ),
                  ),

                  // محتوى البطاقة بحجم محدد
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
                              'الفئة: ${product['category'] ?? 'غير محدد'}',
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
                                    '${product['price']?.toString() ?? '0'} دج',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor,
                                      fontFamily: 'Cairo',
                                      fontSize: isVerySmallScreen ? 9 : 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red.shade400,
                                  size: isVerySmallScreen ? 14 : 16,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 4 : 6),

                          // زر إزالة من المفضلة
                          SizedBox(
                            width: double.infinity,
                            height: isVerySmallScreen ? 20 : 24,
                            child: OutlinedButton.icon(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: isVerySmallScreen ? 10 : 12,
                              ),
                              label: FittedBox(
                                child: Text(
                                  'إزالة من المفضلة',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 7 : 9,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: onRemoveFromFavorites,
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 2 : 4),

                          // زر إضافة للسلة
                          SizedBox(
                            width: double.infinity,
                            height: isVerySmallScreen ? 20 : 24,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.shopping_cart_outlined,
                                size: isVerySmallScreen ? 10 : 12,
                              ),
                              label: FittedBox(
                                child: Text(
                                  'أضف للسلة',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 7 : 9,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: alertColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: onAddToCart,
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
}

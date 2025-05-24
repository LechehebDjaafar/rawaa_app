import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> with SingleTickerProviderStateMixin {
  final CollectionReference _favoritesCollection = FirebaseFirestore.instance.collection('favorites');
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isLoading = true;
  
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
    
    // التحقق من وجود مجموعة المفضلة وإنشائها إذا لم تكن موجودة
    _ensureFavoritesCollectionExists().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود مجموعة المفضلة وإنشائها إذا لم تكن موجودة
  Future<void> _ensureFavoritesCollectionExists() async {
    try {
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await _favoritesCollection.limit(1).get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة المفضلة لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await _favoritesCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة المفضلة: $e');
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
              child: _buildFavoritesList(),
            ),
    );
  }

  Widget _buildFavoritesList() {
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
                  Icons.favorite_border_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد منتجات في المفضلة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أضف منتجات إلى المفضلة لتظهر هنا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final favorites = snapshot.data!.docs;
        
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
              childAspectRatio: 0.7,
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
                    return const Card(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  
                  final product = productSnapshot.data!.data() as Map<String, dynamic>;
                  
                  return FavoriteProductCard(
                    product: product,
                    productId: productId,
                    favoriteId: favoriteId,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    alertColor: alertColor,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class FavoriteProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final String favoriteId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color alertColor;

  const FavoriteProductCard({
    super.key,
    required this.product,
    required this.productId,
    required this.favoriteId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.alertColor,
  });

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج
            Container(
              height: 120,
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        product['rating']?.toString() ?? '0.0',
                        style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text(
                        'إزالة من المفضلة',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _removeFromFavorites(context, favoriteId);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: const Text(
                        'أضف للسلة',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _addToCart(context, productId);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // إزالة من المفضلة
  void _removeFromFavorites(BuildContext context, String favoriteId) {
    FirebaseFirestore.instance.collection('favorites').doc(favoriteId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إزالة المنتج من المفضلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // إضافة إلى السلة
  void _addToCart(BuildContext context, String productId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    FirebaseFirestore.instance.collection('cart').add({
      'userId': userId,
      'productId': productId,
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة المنتج إلى السلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}

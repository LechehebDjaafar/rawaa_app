import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetails extends StatefulWidget {
  final String productId;

  const ProductDetails({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _cartCollection = FirebaseFirestore.instance.collection('cart');
  final CollectionReference _favoritesCollection = FirebaseFirestore.instance.collection('favorites');
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance.collection('reviews');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  
  bool _isLoading = true;
  bool _isFavorite = false;
  Map<String, dynamic> _productData = {};
  List<Map<String, dynamic>> _reviews = [];
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color.fromARGB(255, 89, 138, 243); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ

  @override
  void initState() {
    super.initState();
    _fetchProductData();
    _checkIfFavorite();
    _fetchReviews();
  }

  // جلب بيانات المنتج
  Future<void> _fetchProductData() async {
    try {
      final docSnapshot = await _productsCollection.doc(widget.productId).get();
      
      if (docSnapshot.exists) {
        setState(() {
          _productData = docSnapshot.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('المنتج غير موجود'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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

  // التحقق مما إذا كان المنتج في المفضلة
  Future<void> _checkIfFavorite() async {
    if (_currentUserId == 'guest') return;
    
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: widget.productId)
          .get();
      
      setState(() {
        _isFavorite = querySnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print('خطأ في التحقق من المفضلة: $e');
    }
  }

  // جلب التقييمات
  Future<void> _fetchReviews() async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('productId', isEqualTo: widget.productId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      List<Map<String, dynamic>> reviews = [];
      
      for (var doc in querySnapshot.docs) {
        final reviewData = doc.data() as Map<String, dynamic>;
        
        // جلب اسم المستخدم
        String reviewerName = 'مستخدم';
        if (reviewData['userId'] != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(reviewData['userId'])
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            reviewerName = userData['name'] ?? 'مستخدم';
          }
        }
        
        reviews.add({
          'id': doc.id,
          'reviewer': reviewerName,
          'rating': reviewData['rating'] ?? 5,
          'comment': reviewData['comment'] ?? '',
          'createdAt': reviewData['createdAt'],
        });
      }
      
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('خطأ في جلب التقييمات: $e');
    }
  }

  // إضافة إلى السلة
  Future<void> _addToCart() async {
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
          .where('productId', isEqualTo: widget.productId)
          .get();
      
      if (cartSnapshot.docs.isNotEmpty) {
        // المنتج موجود بالفعل، زيادة الكمية
        final cartItemId = cartSnapshot.docs.first.id;
        final currentQuantity = (cartSnapshot.docs.first.data() as Map<String, dynamic>)['quantity'] as int;
        
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
          'productId': widget.productId,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
          'productName': _productData['name'] ?? 'منتج',
          'productPrice': _productData['price'] ?? 0,
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

  // إضافة أو إزالة من المفضلة
  Future<void> _toggleFavorite() async {
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
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: widget.productId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // المنتج موجود في المفضلة، إزالته
        final favoriteId = querySnapshot.docs.first.id;
        await _favoritesCollection.doc(favoriteId).delete();
        
        setState(() {
          _isFavorite = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إزالة المنتج من المفضلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // المنتج غير موجود في المفضلة، إضافته
        await _favoritesCollection.add({
          'userId': _currentUserId,
          'productId': widget.productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _isFavorite = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('تفاصيل المنتج', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: secondaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // صورة المنتج
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                    image: _productData['imageUrl'] != null
                        ? DecorationImage(
                            image: NetworkImage(_productData['imageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _productData['imageUrl'] == null
                      ? Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                
                // اسم المنتج والسعر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _productData['name'] ?? 'منتج',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    Text(
                      '${_productData['price']?.toString() ?? '0'} دج',
                      style: TextStyle(
                        fontSize: 20,
                        color: secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // الفئة والتقييم
                Row(
                  children: [
                    Icon(Icons.category_outlined, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _productData['category'] ?? 'غير محدد',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text(
                      (_productData['rating'] ?? '0.0').toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_productData['ratingCount'] ?? '0'} تقييم)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // وصف المنتج
                Text(
                  _productData['description'] ?? 'لا يوجد وصف',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                
                // المخزون
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'المخزون المتاح: ${_productData['stock'] ?? '0'} قطعة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // أزرار
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text(
                          'أضف للسلة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: alertColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _addToCart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red.shade400,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // التقييمات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'آراء العملاء',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // الانتقال إلى صفحة كل التقييمات
                      },
                      child: Text(
                        'عرض الكل',
                        style: TextStyle(
                          color: primaryColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // قائمة التقييمات
                _reviews.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لا توجد تقييمات بعد',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _reviews.map((review) => ReviewCard(
                          reviewer: review['reviewer'],
                          rating: review['rating'],
                          comment: review['comment'],
                        )).toList(),
                      ),
                
                const SizedBox(height: 16),
                
                // زر إضافة تقييم
                OutlinedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text(
                    'أضف تقييمك',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // عرض نافذة إضافة تقييم
                    _showAddReviewSheet(context);
                  },
                ),
              ],
            ),
    );
  }

  // عرض نافذة إضافة تقييم
  void _showAddReviewSheet(BuildContext context) {
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
    
    int rating = 5;
    final commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أضف تقييمك',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // اختيار التقييم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              
              // حقل التعليق
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أضف تعليقك هنا...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  filled: true,
                  fillColor: backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 20),
              
              // زر إرسال التقييم
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // إضافة التقييم
                    try {
                      await _reviewsCollection.add({
                        'userId': _currentUserId,
                        'productId': widget.productId,
                        'rating': rating,
                        'comment': commentController.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      
                      // تحديث تقييم المنتج
                      await _updateProductRating();
                      
                      // إعادة جلب التقييمات
                      await _fetchReviews();
                      
                      // إغلاق النافذة
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إضافة تقييمك بنجاح'),
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إرسال التقييم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // تحديث تقييم المنتج
  Future<void> _updateProductRating() async {
    try {
      // جلب جميع تقييمات المنتج
      final querySnapshot = await _reviewsCollection
          .where('productId', isEqualTo: widget.productId)
          .get();
      
      if (querySnapshot.docs.isEmpty) return;
      
      // حساب متوسط التقييم
      double totalRating = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        totalRating += (data?['rating'] ?? 5).toDouble();
      }
      
      final averageRating = totalRating / querySnapshot.docs.length;
      
      // تحديث تقييم المنتج
      await _productsCollection.doc(widget.productId).update({
        'rating': averageRating,
        'ratingCount': querySnapshot.docs.length,
      });
      
      // تحديث البيانات المحلية
      setState(() {
        _productData['rating'] = averageRating;
        _productData['ratingCount'] = querySnapshot.docs.length;
      });
    } catch (e) {
      print('خطأ في تحديث تقييم المنتج: $e');
    }
  }
}

class ReviewCard extends StatelessWidget {
  final String reviewer;
  final int rating;
  final String comment;

  const ReviewCard({
    super.key,
    required this.reviewer,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            reviewer.isNotEmpty ? reviewer[0] : 'م',
            style: const TextStyle(color: Color(0xFF2F5233)),
          ),
        ),
        title: Row(
          children: [
            Text(
              reviewer,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          comment,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}

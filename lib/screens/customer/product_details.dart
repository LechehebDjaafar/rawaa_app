import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// Extension لتدوير الأرقام العشرية
extension DoubleExtension on double {
  double roundToPrecision(int places) {
    double mod = pow(10.0, places).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}

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
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  
  bool _isLoading = true;
  bool _isFavorite = false;
  Map<String, dynamic> _productData = {};
  List<Map<String, dynamic>> _reviews = [];
  bool _showAllReviews = false;
  bool _hasUserRated = false;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor =  const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // تهيئة البيانات بالترتيب الصحيح
  Future<void> _initializeData() async {
    try {
      await _ensureCollectionsExist();
      await _fetchProductData();
      await _checkIfFavorite();
      await _checkIfUserRated();
      await _fetchReviews();
    } catch (e) {
      print('خطأ في تهيئة البيانات: $e');
    }
  }

  // إنشاء المجموعات تلقائياً إذا لم تكن موجودة
  Future<void> _ensureCollectionsExist() async {
    try {
      final List<CollectionReference> collections = [
        _productsCollection,
        _cartCollection,
        _favoritesCollection,
        _ratingsCollection,
      ];

      for (var collection in collections) {
        final snapshot = await collection.limit(1).get();
        
        if (snapshot.docs.isEmpty) {
          print('إنشاء مجموعة ${collection.path} لأول مرة');
          
          DocumentReference tempDoc = await collection.add({
            'temp': true,
            'createdAt': FieldValue.serverTimestamp(),
            'description': 'مستند مؤقت لإنشاء المجموعة',
          });
          
          await tempDoc.delete();
          print('تم إنشاء مجموعة ${collection.path} بنجاح');
        }
      }
    } catch (e) {
      print('خطأ في إنشاء المجموعات: $e');
    }
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
      print('خطأ في جلب بيانات المنتج: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // التحقق من تقييم المستخدم
  Future<void> _checkIfUserRated() async {
    if (_currentUserId == 'guest') return;
    
    try {
      final querySnapshot = await _ratingsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: widget.productId)
          .get();
      
      setState(() {
        _hasUserRated = querySnapshot.docs.isNotEmpty;
      });
      print('حالة تقييم المستخدم: $_hasUserRated');
    } catch (e) {
      print('خطأ في التحقق من تقييم المستخدم: $e');
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

  // جلب التقييمات مع تحديث فوري - مصحح
  Future<void> _fetchReviews() async {
    try {
      print('بدء جلب التقييمات للمنتج: ${widget.productId}');
      
      final querySnapshot = await _ratingsCollection
          .where('productId', isEqualTo: widget.productId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('عدد التقييمات الموجودة: ${querySnapshot.docs.length}');
      
      List<Map<String, dynamic>> reviews = [];
      
      for (var doc in querySnapshot.docs) {
        final reviewData = doc.data() as Map<String, dynamic>;
        print('بيانات التقييم: $reviewData');
        
        // جلب اسم المستخدم
        String reviewerName = 'مستخدم';
        if (reviewData['userId'] != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(reviewData['userId'])
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              reviewerName = userData['name'] ?? 'مستخدم';
            }
          } catch (e) {
            print('خطأ في جلب اسم المستخدم: $e');
          }
        }

        reviews.add({
          'id': doc.id,
          'reviewer': reviewerName,
          'rating': reviewData['rating'] ?? 5,
          'comment': reviewData['comment'] ?? '',
          'createdAt': reviewData['createdAt'],
          'userId': reviewData['userId'],
        });
      }

      setState(() {
        _reviews = reviews;
      });
      
      print('تم جلب ${reviews.length} تقييم بنجاح وتحديث الواجهة');
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
      final cartSnapshot = await _cartCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: widget.productId)
          .get();
      
      if (cartSnapshot.docs.isNotEmpty) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenHeight < 500;
        
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'تفاصيل المنتج',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 16 : 18,
              ),
            ),
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
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // صورة المنتج - مرنة
                      Container(
                        height: isVerySmallScreen ? 180 : (isSmallScreen ? 200 : 220),
                        width: double.infinity,
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
                                  size: isVerySmallScreen ? 40 : 60,
                                  color: Colors.grey[400],
                                ),
                              )
                            : null,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      // اسم المنتج والسعر - مرن
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _productData['name'] ?? 'منتج',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          Text(
                            '${_productData['price']?.toString() ?? '0'} دج',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 16 : 20,
                              color: secondaryColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      
                      // الفئة والتقييم - مرن مع تدوير الأرقام
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: Colors.grey[600],
                            size: isVerySmallScreen ? 16 : 20,
                          ),
                          SizedBox(width: isVerySmallScreen ? 2 : 4),
                          Text(
                            _productData['category'] ?? 'غير محدد',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(width: isVerySmallScreen ? 12 : 16),
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: isVerySmallScreen ? 16 : 20,
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: _ratingsCollection
                                .where('productId', isEqualTo: widget.productId)
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
                                
                                averageRating = (totalRating / reviewCount).roundToPrecision(2);
                              }
                              
                              return Row(
                                children: [
                                  Text(
                                    averageRating.toString(),
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 12 : 14,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: isVerySmallScreen ? 4 : 8),
                                  Text(
                                    '($reviewCount تقييم)',
                                    style: TextStyle(
                                      fontSize: isVerySmallScreen ? 10 : 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      // وصف المنتج - مرن
                      Text(
                        _productData['description'] ?? 'لا يوجد وصف',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      // المخزون - مرن
                      Container(
                        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: accentColor,
                              size: isVerySmallScreen ? 18 : 22,
                            ),
                            SizedBox(width: isVerySmallScreen ? 6 : 8),
                            Text(
                              'المخزون المتاح: ${_productData['stock'] ?? '0'} قطعة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                                fontSize: isVerySmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 16 : 24),
                      
                      // أزرار - مرنة
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: isVerySmallScreen ? 40 : 48,
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: isVerySmallScreen ? 16 : 20,
                                ),
                                label: Text(
                                  'أضف للسلة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: alertColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _addToCart,
                              ),
                            ),
                          ),
                          SizedBox(width: isVerySmallScreen ? 8 : 12),
                          Container(
                            width: isVerySmallScreen ? 40 : 48,
                            height: isVerySmallScreen ? 40 : 48,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red.shade400,
                                size: isVerySmallScreen ? 20 : 24,
                              ),
                              onPressed: _toggleFavorite,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 16 : 24),
                      
                      // التقييمات - مرنة مع ميزة عرض الكل
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'آراء العملاء (${_reviews.length})',
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (_reviews.length > 3)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAllReviews = !_showAllReviews;
                                });
                              },
                              child: Text(
                                _showAllReviews ? 'عرض أقل' : 'عرض الكل',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      
                      // قائمة التقييمات - مرنة
                      _reviews.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.star_border,
                                      size: isVerySmallScreen ? 40 : 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 6 : 8),
                                    Text(
                                      'لا توجد تقييمات بعد',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: isVerySmallScreen ? 12 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'كن أول من يقيم هذا المنتج',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: isVerySmallScreen ? 10 : 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: (_showAllReviews ? _reviews : _reviews.take(3).toList())
                                  .map((review) => ReviewCard(
                                        reviewer: review['reviewer'],
                                        rating: review['rating'],
                                        comment: review['comment'],
                                        isVerySmallScreen: isVerySmallScreen,
                                      ))
                                  .toList(),
                            ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      // زر إضافة تقييم - مرن
                      SizedBox(
                        width: double.infinity,
                        height: isVerySmallScreen ? 40 : 48,
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.rate_review_outlined,
                            size: isVerySmallScreen ? 16 : 20,
                          ),
                          label: Text(
                            _hasUserRated ? 'تعديل تقييمك' : 'أضف تقييمك',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: isVerySmallScreen ? 12 : 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _showAddReviewSheet(context, isVerySmallScreen);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // عرض نافذة إضافة تقييم - محسنة ومصححة
  void _showAddReviewSheet(BuildContext context, bool isVerySmallScreen) {
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
    bool isLoading = false;

    // جلب التقييم الحالي إذا كان موجوداً
    if (_hasUserRated) {
      _ratingsCollection
          .where('userId', isEqualTo: _currentUserId)
          .where('productId', isEqualTo: widget.productId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data() as Map<String, dynamic>;
          rating = data['rating'] ?? 5;
          commentController.text = data['comment'] ?? '';
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: isVerySmallScreen ? 16 : 20,
            left: isVerySmallScreen ? 16 : 20,
            right: isVerySmallScreen ? 16 : 20,
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
                _hasUserRated ? 'تعديل تقييمك' : 'أضف تقييمك',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: secondaryColor,
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 12 : 16),
              
              // اختيار التقييم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: isVerySmallScreen ? 28 : 36,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              
              SizedBox(height: isVerySmallScreen ? 12 : 16),
              
              // حقل التعليق
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أضف تعليقك هنا...',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 12 : 14,
                  ),
                  filled: true,
                  fillColor: backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                ),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
              
              SizedBox(height: isVerySmallScreen ? 16 : 20),
              
              // زر إرسال التقييم
              SizedBox(
                width: double.infinity,
                height: isVerySmallScreen ? 40 : 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      print('بدء إضافة/تحديث التقييم');
                      
                      // التحقق من وجود تقييم سابق
                      final existingRating = await _ratingsCollection
                          .where('userId', isEqualTo: _currentUserId)
                          .where('productId', isEqualTo: widget.productId)
                          .get();

                      if (existingRating.docs.isNotEmpty) {
                        // تحديث التقييم الموجود
                        await _ratingsCollection.doc(existingRating.docs.first.id).update({
                          'rating': rating,
                          'comment': commentController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        print('تم تحديث التقييم بنجاح');
                      } else {
                        // إضافة تقييم جديد
                        await _ratingsCollection.add({
                          'userId': _currentUserId,
                          'productId': widget.productId,
                          'rating': rating,
                          'comment': commentController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        print('تم إضافة تقييم جديد بنجاح');
                      }

                      // إعادة جلب التقييمات لعرضها فوراً
                      await _fetchReviews();
                      await _checkIfUserRated();

                      // إغلاق النافذة
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_hasUserRated ? 'تم تحديث تقييمك بنجاح' : 'تم إضافة تقييمك بنجاح'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('خطأ في إضافة/تحديث التقييم: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: isVerySmallScreen ? 16 : 20,
                          height: isVerySmallScreen ? 16 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _hasUserRated ? 'تحديث التقييم' : 'إرسال التقييم',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: isVerySmallScreen ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }
}

// بطاقة التقييم المحسنة والمرنة
class ReviewCard extends StatelessWidget {
  final String reviewer;
  final int rating;
  final String comment;
  final bool isVerySmallScreen;

  const ReviewCard({
    super.key,
    required this.reviewer,
    required this.rating,
    required this.comment,
    required this.isVerySmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 4 : 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  radius: isVerySmallScreen ? 16 : 20,
                  child: Text(
                    reviewer.isNotEmpty ? reviewer[0] : 'م',
                    style: TextStyle(
                      color: const Color(0xFF2F5233),
                      fontSize: isVerySmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: isVerySmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewer,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          fontSize: isVerySmallScreen ? 12 : 14,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: isVerySmallScreen ? 12 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              SizedBox(height: isVerySmallScreen ? 6 : 8),
              Text(
                comment,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 11 : 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

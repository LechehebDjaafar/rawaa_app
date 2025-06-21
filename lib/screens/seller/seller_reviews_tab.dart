import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerReviewsTab extends StatefulWidget {
  const SellerReviewsTab({super.key});

  @override
  State<SellerReviewsTab> createState() => _SellerReviewsTabState();
}

class _SellerReviewsTabState extends State<SellerReviewsTab> with SingleTickerProviderStateMixin {
  // إضافة الفلترة الصحيحة - الحصول على معرف البائع الحالي
  final String? _currentSellerId = FirebaseAuth.instance.currentUser?.uid;
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance.collection('reviews');
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // متغيرات الإحصائيات
  double _averageRating = 0.0;
  int _totalReviews = 0;

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
    _ensureReviewsCollectionExists();
  }

  // التأكد من وجود مجموعة التقييمات مع إنشاء تقييمات تجريبية للبائع الحالي
  Future<void> _ensureReviewsCollectionExists() async {
    // التحقق من وجود معرف البائع أولاً
    if (_currentSellerId == null) {
      print('خطأ: لم يتم العثور على معرف البائع');
      return;
    }
    
    try {
      // التحقق من وجود تقييمات للبائع الحالي
      final snapshot = await _reviewsCollection
          .where('sellerId', isEqualTo: _currentSellerId!)
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) {
        print('إنشاء تقييمات تجريبية للبائع الحالي');
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة التقييمات: $e');
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // حساب متوسط التقييم
  void _calculateAverageRating(List<QueryDocumentSnapshot> reviews) {
    if (reviews.isEmpty) {
      _averageRating = 0.0;
      _totalReviews = 0;
      return;
    }
    
    double total = 0.0;
    for (var review in reviews) {
      final data = review.data() as Map<String, dynamic>;
      total += (data['rating'] ?? 0).toDouble();
    }
    
    _averageRating = total / reviews.length;
    _totalReviews = reviews.length;
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final DateTime date = (timestamp as Timestamp).toDate();
      final Duration difference = DateTime.now().difference(date);
      
      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود معرف البائع
    if (_currentSellerId == null) {
      return Container(
        color: backgroundColor,
        child: const Center(
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
        final screenHeight = constraints.maxHeight;
        final isVerySmallScreen = screenHeight < 500;
        
        return Container(
          color: backgroundColor,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس الصفحة مع الإحصائيات
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تقييمات المتجر',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: secondaryColor,
                        ),
                      ),
                      SizedBox(height: isVerySmallScreen ? 8 : 12),
                      
                      // بطاقة الإحصائيات
                      StreamBuilder<QuerySnapshot>(
                        stream: _reviewsCollection
                            .where('sellerId', isEqualTo: _currentSellerId!)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            _calculateAverageRating(snapshot.data!.docs);
                          }
                          
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                              child: Row(
                                children: [
                                  // متوسط التقييم
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: isVerySmallScreen ? 20 : 24,
                                            ),
                                            SizedBox(width: isVerySmallScreen ? 4 : 6),
                                            Text(
                                              _averageRating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: isVerySmallScreen ? 18 : 20,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 2 : 4),
                                        Text(
                                          'متوسط التقييم',
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 10 : 12,
                                            color: Colors.grey[600],
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  Container(
                                    height: isVerySmallScreen ? 30 : 40,
                                    width: 1,
                                    color: Colors.grey[300],
                                  ),
                                  
                                  // عدد التقييمات
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _totalReviews.toString(),
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 18 : 20,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                            color: secondaryColor,
                                          ),
                                        ),
                                        SizedBox(height: isVerySmallScreen ? 2 : 4),
                                        Text(
                                          'إجمالي التقييمات',
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 10 : 12,
                                            color: Colors.grey[600],
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // قائمة التقييمات
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // إضافة الفلترة الصحيحة هنا - عرض تقييمات البائع الحالي فقط
                    stream: _reviewsCollection
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_outline,
                                size: isVerySmallScreen ? 60 : 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: isVerySmallScreen ? 12 : 16),
                              Text(
                                'لا توجد تقييمات حتى الآن',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: isVerySmallScreen ? 6 : 8),
                              Text(
                                'ستظهر تقييمات الزبائن هنا',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final reviews = snapshot.data!.docs;

                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        color: primaryColor,
                        child: ListView.separated(
                          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
                          itemBuilder: (context, index) {
                            final review = reviews[index].data() as Map<String, dynamic>;
                            return _buildReviewCard(review, isVerySmallScreen);
                          },
                        ),
                      );
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

  // بناء بطاقة التقييم - محسنة ومرنة
  Widget _buildReviewCard(Map<String, dynamic> review, bool isVerySmallScreen) {
    final int rating = review['rating'] ?? 0;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                // صورة العميل
                CircleAvatar(
                  backgroundColor: _getCustomerColor(review['customer'] ?? ''),
                  radius: isVerySmallScreen ? 18 : 22,
                  child: Text(
                    review['customerAvatar'] ?? (review['customer']?.isNotEmpty == true ? review['customer'][0] : 'ز'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 14 : 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                SizedBox(width: isVerySmallScreen ? 8 : 12),
                
                // معلومات العميل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customer'] ?? 'زبون',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmallScreen ? 14 : 16,
                        ),
                      ),
                      if (review['productName'] != null) ...[
                        SizedBox(height: isVerySmallScreen ? 2 : 4),
                        Text(
                          review['productName'],
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isVerySmallScreen ? 11 : 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // التقييم والوقت
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // النجوم
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: isVerySmallScreen ? 14 : 16,
                        );
                      }),
                    ),
                    SizedBox(height: isVerySmallScreen ? 2 : 4),
                    // الوقت
                    Text(
                      _formatTimestamp(review['createdAt']),
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 9 : 11,
                        color: Colors.grey[500],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // التعليق
            if (review['comment'] != null && review['comment'].isNotEmpty) ...[
              SizedBox(height: isVerySmallScreen ? 8 : 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review['comment'],
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 12 : 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // الحصول على لون العميل بناءً على الاسم
  Color _getCustomerColor(String name) {
    final List<Color> colors = [
      primaryColor,
      secondaryColor,
      accentColor,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final int hash = name.hashCode;
    final int index = hash.abs() % colors.length;
    return colors[index];
  }
}

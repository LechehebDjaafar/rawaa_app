import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class SellerHomeTab extends StatefulWidget {
  const SellerHomeTab({Key? key}) : super(key: key);

  @override
  State<SellerHomeTab> createState() => _SellerHomeTabState();
}

class _SellerHomeTabState extends State<SellerHomeTab> with SingleTickerProviderStateMixin {
  // مراجع لقاعدة البيانات Firestore
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  final CollectionReference _salesCollection = FirebaseFirestore.instance.collection('sales');
  final CollectionReference _ratingsCollection = FirebaseFirestore.instance.collection('ratings');
  
  // متغيرات لتخزين البيانات
  int _newOrdersCount = 0;
  double _totalSales = 0;
  double _averageRating = 0;
  List<FlSpot> _salesData = [];
  bool _isLoading = true;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFFFF8A65); // برتقالي فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // تهيئة المتغيرات بقيم افتراضية
    _newOrdersCount = 0;
    _totalSales = 0;
    _averageRating = 0;
    _salesData = [];
    
    // التحقق من وجود المجموعات وإنشائها إذا لم تكن موجودة
    _ensureCollectionsExist().then((_) {
      // جلب البيانات الحقيقية
      _fetchRealTimeData();
      
      // بدء الأنيميشن
      _animationController.forward();
    });
  }
  
  // دالة للتحقق من وجود المجموعات الأساسية وإنشائها
  Future<void> _ensureCollectionsExist() async {
    try {
      // قائمة المجموعات الأساسية التي نحتاجها
      final List<String> requiredCollections = [
        'orders',
        'sales',
        'ratings',
      ];
      
      // التحقق من كل مجموعة وإنشائها إذا لم تكن موجودة
      for (String collection in requiredCollections) {
        await _ensureCollectionExists(collection);
      }
      
      print('تم التحقق من جميع المجموعات الأساسية بنجاح');
    } catch (e) {
      print('حدث خطأ أثناء التحقق من المجموعات: $e');
    }
  }
  
  // دالة للتحقق من وجود مجموعة معينة وإنشائها إذا لم تكن موجودة
  Future<void> _ensureCollectionExists(String collectionName) async {
    try {
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .limit(1)
          .get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة $collectionName لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .add({
              'temp': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة $collectionName: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchRealTimeData() {
    setState(() {
      _isLoading = true;
    });
    
    // استماع للطلبات الجديدة
    _ordersCollection
        .where('status', isEqualTo: 'جديد')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _newOrdersCount = snapshot.docs.length;
        _isLoading = false;
      });
    }, onError: (error) {
      print('خطأ في الاستماع للطلبات: $error');
      setState(() {
        _newOrdersCount = 0;
        _isLoading = false;
      });
    });

    // استماع لإجمالي المبيعات
    _salesCollection
        .snapshots()
        .listen((snapshot) {
      try {
        double total = 0;
        List<FlSpot> spots = [];
        int index = 0;
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          total += amount;
          
          if (data['date'] != null) {
            spots.add(FlSpot(index.toDouble(), amount));
            index++;
          }
        }
        
        setState(() {
          _totalSales = total;
          _salesData = spots;
          _isLoading = false;
        });
      } catch (e) {
        print('خطأ في معالجة بيانات المبيعات: $e');
        setState(() {
          _totalSales = 0;
          _salesData = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('خطأ في الاستماع للمبيعات: $error');
      setState(() {
        _totalSales = 0;
        _salesData = [];
        _isLoading = false;
      });
    });

    // استماع لمتوسط التقييمات
    _ratingsCollection
        .snapshots()
        .listen((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          setState(() {
            _averageRating = 0;
            _isLoading = false;
          });
          return;
        }
        
        double sum = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          sum += (data['value'] ?? 0).toDouble();
        }
        
        setState(() {
          _averageRating = sum / snapshot.docs.length;
          _isLoading = false;
        });
      } catch (e) {
        print('خطأ في معالجة بيانات التقييمات: $e');
        setState(() {
          _averageRating = 0;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('خطأ في الاستماع للتقييمات: $error');
      setState(() {
        _averageRating = 0;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchRealTimeData();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSalesChart(),
              const SizedBox(height: 20),
              _buildStatisticsCards(),
              const SizedBox(height: 20),
              _buildRecentOrdersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إحصائيات المبيعات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: primaryColor,
                  ),
                ),
                Text(
                  'إجمالي: ${_totalSales == 0 ? '0' : _totalSales.toStringAsFixed(2)} دج',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _isLoading
                ? Center(
                    child: Text(
                      'جاري تحميل البيانات...',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : _salesData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد بيانات مبيعات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _salesData,
                            isCurved: true,
                            color: primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: primaryColor.withOpacity(0.15),
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

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long_outlined,
            color: primaryColor,
            title: 'طلبات جديدة',
            value: _isLoading ? '-' : _newOrdersCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_outline,
            color: accentColor,
            title: 'التقييم',
            value: _isLoading ? '-' : (_averageRating == 0 ? '0.0' : _averageRating.toStringAsFixed(1)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.payments_outlined,
            color: secondaryColor,
            title: 'المبيعات',
            value: _isLoading ? '-' : (_totalSales == 0 ? '0' : '${_totalSales.toStringAsFixed(0)}'),
            suffix: ' دج',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String suffix = '',
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر الطلبات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: secondaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // انتقال إلى صفحة كل الطلبات
                  },
                  icon: Icon(Icons.arrow_forward, size: 16, color: primaryColor),
                  label: Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _ordersCollection.limit(5).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد طلبات حالياً',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                try {
                  final orders = snapshot.data!.docs;
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = orders[index].data() as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order['status'] ?? ''),
                          child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          'العميل: ${order['customer'] ?? 'غير معروف'}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'المنتج: ${order['product'] ?? 'غير محدد'}\nالحالة: ${order['status'] ?? 'غير محدد'}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                          onPressed: () {
                            // تفاصيل الطلب
                          },
                        ),
                      );
                    },
                  );
                } catch (e) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'حدث خطأ في تحميل البيانات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'جديد':
        return primaryColor;
      case 'قيد التنفيذ':
        return accentColor;
      case 'تم التسليم':
        return secondaryColor;
      default:
        return Colors.grey;
    }
  }
}

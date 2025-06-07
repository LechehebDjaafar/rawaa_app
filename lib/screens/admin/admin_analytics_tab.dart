import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);
  
  int _totalUsers = 0;
  int _totalProducts = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0;
  
  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }
  
  Future<void> _fetchAnalytics() async {
    try {
      // جلب عدد المستخدمين
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      // جلب عدد المنتجات
      final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
      
      // جلب عدد الطلبات
      final ordersSnapshot = await FirebaseFirestore.instance.collection('orders').get();
      
      // حساب إجمالي الإيرادات
      double revenue = 0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        revenue += (data['totalAmount'] ?? 0).toDouble();
      }
      
      setState(() {
        _totalUsers = usersSnapshot.docs.length;
        _totalProducts = productsSnapshot.docs.length;
        _totalOrders = ordersSnapshot.docs.length;
        _totalRevenue = revenue;
      });
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: _fetchAnalytics,
        color: primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقات الإحصائيات
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  title: 'المستخدمون',
                  value: _totalUsers.toString(),
                  icon: Icons.people,
                  color: primaryColor,
                ),
                _buildStatCard(
                  title: 'المنتجات',
                  value: _totalProducts.toString(),
                  icon: Icons.inventory,
                  color: secondaryColor,
                ),
                _buildStatCard(
                  title: 'الطلبات',
                  value: _totalOrders.toString(),
                  icon: Icons.receipt_long,
                  color: accentColor,
                ),
                _buildStatCard(
                  title: 'الإيرادات',
                  value: '${_totalRevenue.toStringAsFixed(0)} دج',
                  icon: Icons.monetization_on,
                  color: alertColor,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // رسم بياني للمبيعات
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبيعات الشهرية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildSalesChart(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // آخر الطلبات
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'آخر الطلبات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentOrders(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSalesChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 1),
              const FlSpot(2, 4),
              const FlSpot(3, 2),
              const FlSpot(4, 5),
              const FlSpot(5, 3),
            ],
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد طلبات حديثة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor,
                child: const Icon(Icons.receipt_long, color: Colors.white),
              ),
              title: Text(
                'طلب من ${order['customer'] ?? 'زبون'}',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              subtitle: Text(
                'المبلغ: ${order['totalAmount']?.toString() ?? '0'} دج',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status'] ?? ''),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'] ?? 'غير محدد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'جديد':
        return primaryColor;
      case 'قيد التنفيذ':
        return alertColor;
      case 'تم التسليم':
        return secondaryColor;
      default:
        return Colors.grey;
    }
  }
}

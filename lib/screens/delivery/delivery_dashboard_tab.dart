// lib/delivery/delivery_dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'delivery_order_details.dart';

class DeliveryDashboardTab extends StatefulWidget {
  const DeliveryDashboardTab({super.key});

  @override
  State<DeliveryDashboardTab> createState() => _DeliveryDashboardTabState();
}

class _DeliveryDashboardTabState extends State<DeliveryDashboardTab> {
  final Color deliveryColor = const Color(0xFFFF6B35);
  String userName = 'عامل التوصيل';
  double userRating = 0.0;
  int totalOrders = 0;
  int deliveredOrders = 0;
  int pendingOrders = 0;
  int inProgressOrders = 0;
  double totalEarnings = 0.0;
  double todayEarnings = 0.0;
  List<Map<String, dynamic>> urgentOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // جلب بيانات المستخدم الحقيقية
      await _loadUserData(currentUser.uid);
      
      // جلب إحصائيات الطلبات الحقيقية
      await _loadOrdersStatistics(currentUser.uid);
      
      // جلب الأرباح الحقيقية
      await _loadEarningsData(currentUser.uid);
      
      // جلب الطلبات العاجلة الحقيقية
      await _loadUrgentOrders(currentUser.uid);

      setState(() => isLoading = false);
    } catch (e) {
      print('خطأ في جلب البيانات: $e');
      setState(() => isLoading = false);
    }
  }

  // جلب بيانات المستخدم من قاعدة البيانات
  Future<void> _loadUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          userName = userData['name'] ?? 'عامل التوصيل';
          userRating = (userData['rating'] ?? 5.0).toDouble();
        });
      }
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  // جلب إحصائيات الطلبات الحقيقية
  Future<void> _loadOrdersStatistics(String userId) async {
    try {
      // جلب جميع الطلبات للمستخدم الحالي
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('delivery_orders')
          .where('deliveryId', isEqualTo: userId)
          .get();

      final orders = ordersSnapshot.docs;
      
      setState(() {
        totalOrders = orders.length;
        deliveredOrders = orders.where((doc) {
          final data = doc.data();
          return data['status'] == 'delivered';
        }).length;
        
        pendingOrders = orders.where((doc) {
          final data = doc.data();
          return data['status'] == 'pending' || data['status'] == 'new';
        }).length;
        
        inProgressOrders = orders.where((doc) {
          final data = doc.data();
          return data['status'] == 'in_progress';
        }).length;
      });
    } catch (e) {
      print('خطأ في جلب إحصائيات الطلبات: $e');
    }
  }

  // جلب بيانات الأرباح الحقيقية
  Future<void> _loadEarningsData(String userId) async {
    try {
      // جلب إجمالي الأرباح من الطلبات المكتملة
      final deliveredOrdersSnapshot = await FirebaseFirestore.instance
          .collection('delivery_orders')
          .where('deliveryId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .get();

      double totalEarningsCalc = 0.0;
      double todayEarningsCalc = 0.0;
      final today = DateTime.now();
      
      for (var doc in deliveredOrdersSnapshot.docs) {
        final data = doc.data();
        final earnings = (data['deliveryEarnings'] ?? data['deliveryFee'] ?? 200.0).toDouble();
        totalEarningsCalc += earnings;
        
        // حساب أرباح اليوم
        if (data['deliveredAt'] != null) {
          final deliveredDate = (data['deliveredAt'] as Timestamp).toDate();
          if (deliveredDate.year == today.year && 
              deliveredDate.month == today.month && 
              deliveredDate.day == today.day) {
            todayEarningsCalc += earnings;
          }
        }
      }

      setState(() {
        totalEarnings = totalEarningsCalc;
        todayEarnings = todayEarningsCalc;
      });
    } catch (e) {
      print('خطأ في جلب بيانات الأرباح: $e');
    }
  }

  // جلب الطلبات العاجلة الحقيقية
  Future<void> _loadUrgentOrders(String userId) async {
    try {
      final urgentOrdersSnapshot = await FirebaseFirestore.instance
          .collection('delivery_orders')
          .where('deliveryId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'new', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        urgentOrders = urgentOrdersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('خطأ في جلب الطلبات العاجلة: $e');
      // في حالة عدم وجود فهرس، جلب البيانات بدون ترتيب
      try {
        final urgentOrdersSnapshot = await FirebaseFirestore.instance
            .collection('delivery_orders')
            .where('deliveryId', isEqualTo: userId)
            .where('status', whereIn: ['pending', 'new', 'in_progress'])
            .limit(5)
            .get();

        setState(() {
          urgentOrders = urgentOrdersSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      } catch (e2) {
        print('خطأ في جلب الطلبات العاجلة (محاولة ثانية): $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: deliveryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ترحيب شخصي
                    Text(
                      'مرحباً بك، $userName!',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذا هو ملخص نشاطك اليوم في الجزائر.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),

                    // بطاقات الإحصائيات الحقيقية
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(context, 'قيد الانتظار', pendingOrders, Icons.hourglass_top, Colors.orange),
                        _buildStatCard(context, 'قيد التوصيل', inProgressOrders, Icons.local_shipping, Colors.blue),
                        _buildStatCard(context, 'تم توصيلها', deliveredOrders, Icons.check_circle, Colors.green),
                        _buildStatCard(context, 'تقييمك', userRating, Icons.star, Colors.amber),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // بطاقات الأرباح
                    Row(
                      children: [
                        Expanded(
                          child: _buildEarningsCard('أرباح اليوم', todayEarnings, Icons.today, Colors.teal),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEarningsCard('إجمالي الأرباح', totalEarnings, Icons.account_balance_wallet, Colors.purple),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // قسم الطلبات العاجلة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "الطلبات الحالية (${urgentOrders.length})",
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (urgentOrders.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // الانتقال إلى صفحة جميع الطلبات
                              DefaultTabController.of(context)?.animateTo(1);
                            },
                            child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // قائمة الطلبات العاجلة الحقيقية
                    urgentOrders.isEmpty
                        ? _buildEmptyOrdersCard()
                        : Column(
                            children: urgentOrders
                                .map((order) => OrderTile(order: order))
                                .toList(),
                          ),

                    const SizedBox(height: 24),

                    // ملخص الإحصائيات
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
    );
  }

  // بطاقة الأرباح
  Widget _buildEarningsCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(0)} د.ج',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة فارغة للطلبات
  Widget _buildEmptyOrdersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات حالياً',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر الطلبات الجديدة هنا عند توفرها',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة ملخص الإحصائيات
  Widget _buildSummaryCard() {
    final double successRate = totalOrders > 0 ? (deliveredOrders / totalOrders) * 100 : 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: deliveryColor),
                const SizedBox(width: 8),
                const Text(
                  'ملخص الأداء',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('إجمالي الطلبات', totalOrders.toString()),
                _buildSummaryItem('معدل النجاح', '${successRate.toStringAsFixed(1)}%'),
                _buildSummaryItem('متوسط الأرباح', totalOrders > 0 ? '${(totalEarnings / totalOrders).toStringAsFixed(0)} د.ج' : '0 د.ج'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // عنصر ملخص
  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: deliveryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, num value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value is double ? value.toStringAsFixed(1) : value.toString(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String orderId = order['orderId'] ?? 'غير محدد';
    final String address = order['address'] ?? 'عنوان غير محدد';
    final String customerName = order['customerName'] ?? 'عميل غير محدد';
    final double totalAmount = (order['totalAmount'] ?? 0.0).toDouble();
    final String status = order['status'] ?? 'pending';

    // تحديد لون الحالة
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
      case 'new':
        statusColor = Colors.orange;
        statusText = 'جديد';
        statusIcon = Icons.new_releases;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'قيد التوصيل';
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'تم التوصيل';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير محدد';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          'طلب #$orderId',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'العميل: $customerName',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              address,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalAmount.toStringAsFixed(0)} د.ج',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryOrderDetailsScreen(order: order),
            ),
          );
        },
      ),
    );
  }
}

// lib/delivery/delivery_history_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'delivery_order_details.dart';

class DeliveryHistoryTab extends StatefulWidget {
  const DeliveryHistoryTab({super.key});

  @override
  State<DeliveryHistoryTab> createState() => _DeliveryHistoryTabState();
}

class _DeliveryHistoryTabState extends State<DeliveryHistoryTab> {
  final Color deliveryColor = const Color(0xFFFF6B35);
  String selectedFilter = 'الكل';
  DateTimeRange? selectedDateRange;
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  // تهيئة اللغة العربية مع معالجة الأخطاء
  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('ar', null);
      await initializeDateFormatting('ar_SA', null);
      await initializeDateFormatting('ar_DZ', null);
      
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    } catch (e) {
      print('خطأ في تهيئة اللغة العربية: $e');
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true; // استمر حتى لو فشلت
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('سجل الطلبات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          backgroundColor: deliveryColor,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل البيانات...', style: TextStyle(fontFamily: 'Cairo')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: deliveryColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'الكل', child: Text('جميع الطلبات', style: TextStyle(fontFamily: 'Cairo'))),
              const PopupMenuItem(value: 'delivered', child: Text('تم التوصيل', style: TextStyle(fontFamily: 'Cairo'))),
              const PopupMenuItem(value: 'cancelled', child: Text('ملغية', style: TextStyle(fontFamily: 'Cairo'))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _getStatsQuery(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [deliveryColor.withOpacity(0.1), deliveryColor.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: deliveryColor.withOpacity(0.3)),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final orders = snapshot.data!.docs;
        final deliveredOrders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'delivered';
        }).toList();
        
        final cancelledOrders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'cancelled';
        }).toList();

        final totalEarnings = deliveredOrders.fold<double>(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + ((data['deliveryEarnings'] ?? data['deliveryFee'] ?? 200.0) as num).toDouble();
        });

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [deliveryColor.withOpacity(0.1), deliveryColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: deliveryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('إجمالي الطلبات', orders.length.toString(), Icons.list_alt),
                  _buildStatItem('تم التوصيل', deliveredOrders.length.toString(), Icons.check_circle),
                  _buildStatItem('ملغية', cancelledOrders.length.toString(), Icons.cancel),
                ],
              ),
              if (orders.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('إجمالي الأرباح', '${totalEarnings.toStringAsFixed(0)} د.ج', Icons.monetization_on),
                    _buildStatItem('معدل النجاح', '${deliveredOrders.isNotEmpty ? ((deliveredOrders.length / orders.length) * 100).toStringAsFixed(1) : 0}%', Icons.trending_up),
                    _buildStatItem('متوسط الربح', deliveredOrders.isNotEmpty ? '${(totalEarnings / deliveredOrders.length).toStringAsFixed(0)} د.ج' : '0 د.ج', Icons.analytics),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getStatsQuery(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('delivery_orders')
        .where('deliveryId', isEqualTo: userId)
        .where('status', whereIn: ['delivered', 'cancelled']);

    if (selectedDateRange != null) {
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.end.add(const Duration(days: 1))));
    }

    return query.snapshots();
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: deliveryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: deliveryColor,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('يرجى تسجيل الدخول', style: TextStyle(fontFamily: 'Cairo', fontSize: 18)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getHistoryQuery(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('حدث خطأ في تحميل السجل', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'تأكد من الاتصال بالإنترنت',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(backgroundColor: deliveryColor),
                  child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  selectedFilter == 'الكل' ? 'لا يوجد سجل للطلبات' : 'لا توجد طلبات ${_getFilterText()}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedFilter == 'الكل' 
                      ? 'ستظهر الطلبات المكتملة والملغاة هنا'
                      : 'جرب تغيير الفلتر لعرض طلبات أخرى',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (selectedFilter != 'الكل' || selectedDateRange != null) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedFilter = 'الكل';
                        selectedDateRange = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('إزالة الفلاتر', style: TextStyle(fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deliveryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: deliveryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final orderData = {'id': orderDoc.id, ...orderDoc.data() as Map<String, dynamic>};
              
              final bool showDateHeader = index == 0 || _shouldShowDateHeader(orders, index);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: deliveryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatDateHeader(orderData),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: deliveryColor,
                          ),
                        ),
                      ),
                    ),
                  HistoryOrderCard(order: orderData),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getHistoryQuery(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('delivery_orders')
        .where('deliveryId', isEqualTo: userId);

    if (selectedFilter == 'الكل') {
      query = query.where('status', whereIn: ['delivered', 'cancelled']);
    } else {
      query = query.where('status', isEqualTo: selectedFilter);
    }

    if (selectedDateRange != null) {
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.end.add(const Duration(days: 1))));
    }

    try {
      query = query.orderBy('createdAt', descending: true);
    } catch (e) {
      print('لا يمكن ترتيب البيانات: $e');
    }

    return query.snapshots();
  }

  String _getFilterText() {
    switch (selectedFilter) {
      case 'delivered':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return '';
    }
  }

  bool _shouldShowDateHeader(List<QueryDocumentSnapshot> orders, int index) {
    if (index == 0) return true;
    
    final currentOrder = orders[index].data() as Map<String, dynamic>;
    final previousOrder = orders[index - 1].data() as Map<String, dynamic>;
    
    final currentDate = (currentOrder['createdAt'] as Timestamp?)?.toDate();
    final previousDate = (previousOrder['createdAt'] as Timestamp?)?.toDate();
    
    if (currentDate == null || previousDate == null) return false;
    
    return currentDate.day != previousDate.day ||
           currentDate.month != previousDate.month ||
           currentDate.year != previousDate.year;
  }

  // دالة آمنة لتنسيق التاريخ مع معالجة الأخطاء
  String _formatDateHeader(Map<String, dynamic> orderData) {
    final date = (orderData['createdAt'] as Timestamp?)?.toDate();
    if (date == null) return 'تاريخ غير محدد';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDate = DateTime(date.year, date.month, date.day);
    
    if (orderDate == today) {
      return 'اليوم';
    } else if (orderDate == yesterday) {
      return 'الأمس';
    } else {
      // استخدام تنسيق آمن مع معالجة الأخطاء
      try {
        return DateFormat('EEEE، dd MMMM yyyy', 'ar').format(date);
      } catch (e) {
        // في حالة الخطأ، استخدم تنسيق بسيط
        try {
          return DateFormat('dd/MM/yyyy').format(date);
        } catch (e2) {
          return '${date.day}/${date.month}/${date.year}';
        }
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      locale: const Locale('ar'),
      helpText: 'اختر نطاق التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      fieldStartHintText: 'تاريخ البداية',
      fieldEndHintText: 'تاريخ النهاية',
    );
    
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }
}

class HistoryOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const HistoryOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String orderId = order['orderId'] ?? 'غير محدد';
    final String status = order['status'] ?? 'غير محدد';
    final String customerName = order['customerName'] ?? 'عميل غير محدد';
    final double earnings = (order['deliveryEarnings'] ?? order['deliveryFee'] ?? 0.0).toDouble();
    final double totalAmount = (order['totalAmount'] ?? 0.0).toDouble();
    final String address = order['address'] ?? 'عنوان غير محدد';
    
    final bool isDelivered = status == 'delivered';
    final Color statusColor = isDelivered ? Colors.green : Colors.red;
    final IconData statusIcon = isDelivered ? Icons.check_circle : Icons.cancel;
    final String statusText = isDelivered ? 'تم التوصيل' : 'ملغي';

    final completionTime = isDelivered 
        ? (order['deliveredAt'] as Timestamp?)?.toDate()
        : (order['cancelledAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryOrderDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'طلب #$orderId',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isDelivered && earnings > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${earnings.toStringAsFixed(0)} د.ج',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'العميل: $customerName',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(fontFamily: 'Cairo', color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    'المبلغ: ${totalAmount.toStringAsFixed(0)} د.ج',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              
              if (completionTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${isDelivered ? 'تم التوصيل' : 'تم الإلغاء'}: ${_formatTime(completionTime)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: statusColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // دالة آمنة لتنسيق الوقت
  String _formatTime(DateTime time) {
    try {
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// lib/delivery/delivery_orders_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'delivery_order_details.dart'; // استيراد شاشة التفاصيل

class DeliveryOrdersTab extends StatefulWidget {
  const DeliveryOrdersTab({super.key});

  @override
  State<DeliveryOrdersTab> createState() => _DeliveryOrdersTabState();
}

class _DeliveryOrdersTabState extends State<DeliveryOrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color deliveryColor = const Color(0xFFFF6B35);
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // تم إزالة دالة إنشاء البيانات التجريبية
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الطلبات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: deliveryColor,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'طلبات جديدة'),
            Tab(text: 'قيد التوصيل'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // إعادة تحميل البيانات
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // المحتوى الأول: طلبات جديدة حقيقية
          _buildOrdersList(context, orderType: 'new'),
          // المحتوى الثاني: طلبات قيد التوصيل حقيقية
          _buildOrdersList(context, orderType: 'in_progress'),
        ],
      ),
    );
  }

  // ودجت لبناء قائمة الطلبات الحقيقية من Firestore
  Widget _buildOrdersList(BuildContext context, {required String orderType}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    Query query;
    if (orderType == 'new') {
      // الطلبات الجديدة (لم يتم قبولها بعد) - بيانات حقيقية فقط
      query = FirebaseFirestore.instance
          .collection('delivery_orders')
          .where('status', isEqualTo: 'new');
    } else {
      // الطلبات قيد التوصيل للمستخدم الحالي - بيانات حقيقية فقط
      query = FirebaseFirestore.instance
          .collection('delivery_orders')
          .where('deliveryId', isEqualTo: currentUser?.uid ?? '')
          .where('status', isEqualTo: 'in_progress');
    }

    // محاولة إضافة ترتيب إذا كان متاحاً
    try {
      query = query.orderBy('createdAt', descending: true);
    } catch (e) {
      // في حالة عدم وجود فهرس، استمر بدون ترتيب
      print('لا يمكن ترتيب البيانات: $e');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
                Text(
                  'حدث خطأ في تحميل الطلبات',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'تأكد من الاتصال بالإنترنت',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey[500]),
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
                Icon(
                  orderType == 'new' ? Icons.inbox : Icons.local_shipping_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  orderType == 'new' 
                      ? 'لا توجد طلبات جديدة حالياً'
                      : 'لا توجد طلبات قيد التوصيل',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  orderType == 'new'
                      ? 'ستظهر الطلبات الجديدة هنا عند توفرها من العملاء'
                      : 'اقبل طلباً جديداً من التبويب الأول لبدء التوصيل',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                if (orderType == 'new') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: deliveryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: deliveryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: deliveryColor, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'نصيحة: تأكد من تفعيل الإشعارات لتلقي تنبيهات فورية عند وصول طلبات جديدة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: deliveryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final orderData = {'id': orderDoc.id, ...orderDoc.data() as Map<String, dynamic>};
              
              return OrderCard(
                order: orderData,
                isNewOrder: orderType == 'new',
                onOrderUpdated: () {
                  setState(() {}); // إعادة تحميل البيانات بعد التحديث
                },
              );
            },
          ),
        );
      },
    );
  }
}

// بطاقة الطلب المحسنة - تعرض البيانات الحقيقية فقط
class OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool isNewOrder;
  final VoidCallback onOrderUpdated;

  const OrderCard({
    super.key,
    required this.order,
    required this.isNewOrder,
    required this.onOrderUpdated,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool isAccepting = false;
  final Color deliveryColor = const Color(0xFFFF6B35);

  // دالة قبول الطلب مع تحديث البيانات الحقيقية
  Future<void> _acceptOrder() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorMessage('يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() => isAccepting = true);

    try {
      // تحديث حالة الطلب في قاعدة البيانات
      await FirebaseFirestore.instance
          .collection('delivery_orders')
          .doc(widget.order['id'])
          .update({
        'status': 'in_progress',
        'deliveryId': currentUser.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم قبول الطلب بنجاح! يمكنك الآن بدء التوصيل'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(
              label: 'عرض التفاصيل',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryOrderDetailsScreen(order: widget.order),
                  ),
                );
              },
            ),
          ),
        );
        widget.onOrderUpdated(); // إشعار الصفحة الأب بالتحديث
      }
    } catch (e) {
      _showErrorMessage('خطأ في قبول الطلب: $e');
    } finally {
      if (mounted) {
        setState(() => isAccepting = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = widget.order['orderId'] ?? 'غير محدد';
    final String address = widget.order['address'] ?? 'عنوان غير محدد';
    final String distance = widget.order['distance'] ?? 'غير محدد';
    final String customerName = widget.order['customerName'] ?? 'عميل غير محدد';
    final String customerPhone = widget.order['customerPhone'] ?? '';
    final double totalAmount = (widget.order['totalAmount'] ?? 0.0).toDouble();
    final int estimatedTime = widget.order['estimatedDeliveryTime'] ?? 30;
    final String paymentMethod = widget.order['paymentMethod'] ?? 'cash';

    // تحديد نص طريقة الدفع
    String paymentText = paymentMethod == 'cash' ? 'دفع عند الاستلام' : 'دفع إلكتروني';
    Color paymentColor = paymentMethod == 'cash' ? Colors.green : Colors.blue;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // الانتقال إلى شاشة تفاصيل الطلب عند النقر
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryOrderDetailsScreen(order: widget.order),
            ),
          );
          
          // إذا تم تحديث الطلب، أعد تحميل البيانات
          if (result == true) {
            widget.onOrderUpdated();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة مع رقم الطلب والمبلغ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'طلب #$orderId',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: deliveryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${totalAmount.toStringAsFixed(0)} د.ج',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: deliveryColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // معلومات العميل
              Row(
                children: [
                  Icon(Icons.person, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'العميل: $customerName',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (customerPhone.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        // يمكن إضافة وظيفة الاتصال هنا
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.phone, color: Colors.green, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
              
              const Divider(height: 16),
              
              // العنوان
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // المسافة والوقت المتوقع
              Row(
                children: [
                  Icon(Icons.directions_car_filled_outlined, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    distance,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$estimatedTime دقيقة',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // طريقة الدفع
              Row(
                children: [
                  Icon(
                    paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                    color: paymentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paymentText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: paymentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // زر قبول الطلب (للطلبات الجديدة فقط)
              if (widget.isNewOrder) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAccepting ? null : _acceptOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deliveryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: isAccepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'قبول الطلب',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

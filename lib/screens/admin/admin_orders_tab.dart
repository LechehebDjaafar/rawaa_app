import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  String _selectedStatus = 'الكل';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = Color.fromARGB(255, 89, 138, 243); 
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // إحصائيات الطلبات
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildOrderStatCard(
                    'طلبات جديدة',
                    'جديد',
                    primaryColor,
                    Icons.new_releases,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderStatCard(
                    'قيد التنفيذ',
                    'قيد التنفيذ',
                    alertColor,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderStatCard(
                    'مكتملة',
                    'تم التسليم',
                    secondaryColor,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),
          
          // شريط البحث والفلترة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // حقل البحث
                TextField(
                  onChanged: (value) {
                    setState(() {
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طلب أو عميل...',
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                
                // فلترة حسب الحالة
                Row(
                  children: [
                    const Text(
                      'حالة الطلب:',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: ['الكل', 'جديد', 'قيد التنفيذ', 'تم التسليم', 'ملغي'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // قائمة الطلبات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final orders = snapshot.data!.docs;
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    final orderId = orders[index].id;
                    
                    return OrderCard(
                      order: order,
                      orderId: orderId,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      alertColor: alertColor,
                      onStatusUpdate: (newStatus) => _updateOrderStatus(orderId, newStatus),
                      onDelete: () => _deleteOrder(orderId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderStatCard(String title, String status, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            StreamBuilder<QuerySnapshot>(
              stream: _ordersCollection.where('status', isEqualTo: status).snapshots(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.hasData ? snapshot.data!.docs.length.toString() : '0',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Cairo',
                  ),
                );
              },
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Stream<QuerySnapshot> _getFilteredOrdersStream() {
    Query query = _ordersCollection.orderBy('createdAt', descending: true);
    
    // فلترة حسب الحالة
    if (_selectedStatus != 'الكل') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    return query.snapshots();
  }
  
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteOrder(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _ordersCollection.doc(orderId).delete();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الطلب بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String orderId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color alertColor;
  final Function(String) onStatusUpdate;
  final VoidCallback onDelete;

  const OrderCard({
    super.key,
    required this.order,
    required this.orderId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.alertColor,
    required this.onStatusUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String status = order['status'] ?? 'جديد';
    final double totalAmount = (order['totalAmount'] ?? 0).toDouble();
    final List<dynamic> items = order['items'] ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text(
          'طلب من ${order['customer'] ?? 'زبون'}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المبلغ: ${totalAmount.toStringAsFixed(2)} دج',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'عدد المنتجات: ${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تفاصيل العميل
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل العميل:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('الاسم: ${order['customer'] ?? 'غير محدد'}', 
                           style: const TextStyle(fontFamily: 'Cairo')),
                      if (order['customerPhone'] != null)
                        Text('الهاتف: ${order['customerPhone']}', 
                             style: const TextStyle(fontFamily: 'Cairo')),
                      if (order['deliveryAddress'] != null)
                        Text('عنوان التوصيل: ${order['deliveryAddress']}', 
                             style: const TextStyle(fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // عرض المنتجات في الطلب
                const Text(
                  'المنتجات:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...List.generate(
                  items.length,
                  (itemIndex) {
                    final item = items[itemIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'] ?? 'منتج',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'الكمية: ${item['quantity']} × ${item['price']} دج',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item['subtotal']} دج',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const Divider(),
                
                // المجموع الكلي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المجموع الكلي:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} دج',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // أزرار تغيير الحالة
                if (status != 'تم التسليم' && status != 'ملغي')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (status == 'جديد')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('بدء التنفيذ', style: TextStyle(fontFamily: 'Cairo')),
                          onPressed: () => onStatusUpdate('قيد التنفيذ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: alertColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      if (status == 'قيد التنفيذ')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('تم التسليم', style: TextStyle(fontFamily: 'Cairo')),
                          onPressed: () => onStatusUpdate('تم التسليم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('إلغاء الطلب', style: TextStyle(fontFamily: 'Cairo')),
                        onPressed: () => onStatusUpdate('ملغي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
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
      case 'ملغي':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({super.key});

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> with SingleTickerProviderStateMixin {
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
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
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // التحقق من وجود مجموعة الطلبات وإنشائها إذا لم تكن موجودة
    _ensureOrdersCollectionExists().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود مجموعة الطلبات وإنشائها إذا لم تكن موجودة
  Future<void> _ensureOrdersCollectionExists() async {
    try {
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await _ordersCollection.limit(1).get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة الطلبات لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await _ordersCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة الطلبات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // عرض تفاصيل الطلب
  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تفاصيل الطلب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: secondaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              // معلومات العميل
              _buildDetailItem(
                icon: Icons.person,
                title: 'العميل',
                value: order['customer'] ?? 'غير معروف',
              ),
              const SizedBox(height: 12),
              
              // معلومات المنتج
              _buildDetailItem(
                icon: Icons.shopping_bag,
                title: 'المنتج',
                value: order['product'] ?? 'غير محدد',
              ),
              const SizedBox(height: 12),
              
              // حالة الطلب
              _buildDetailItem(
                icon: Icons.info_outline,
                title: 'الحالة',
                value: order['status'] ?? 'غير محدد',
                valueColor: _getStatusColor(order['status'] ?? ''),
              ),
              const SizedBox(height: 12),
              
              // تاريخ الطلب
              _buildDetailItem(
                icon: Icons.calendar_today,
                title: 'تاريخ الطلب',
                value: order['createdAt'] != null
                    ? _formatTimestamp(order['createdAt'])
                    : 'غير محدد',
              ),
              const SizedBox(height: 12),
              
              // السعر
              _buildDetailItem(
                icon: Icons.attach_money,
                title: 'السعر',
                value: order['price'] != null
                    ? '${order['price']} دج'
                    : 'غير محدد',
              ),
              
              const Spacer(),
              
              // أزرار تغيير الحالة
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(orderId, 'قيد التنفيذ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'قيد التنفيذ',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(orderId, 'تم التسليم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تم التسليم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تحديث حالة الطلب
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى: $newStatus'),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}';
  }

  // بناء عنصر تفاصيل
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: secondaryColor, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: _ordersCollection.snapshots(),
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
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد طلبات حالياً',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ستظهر الطلبات الجديدة هنا',
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
                  
                  final orders = snapshot.data!.docs;
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    color: primaryColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index].data() as Map<String, dynamic>;
                        final orderId = orders[index].id;
                        
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order['status'] ?? ''),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'العميل: ${order['customer'] ?? 'غير معروف'}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'المنتج: ${order['product'] ?? 'غير محدد'}\nالحالة: ${order['status'] ?? 'غير محدد'}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () => _showOrderDetails(order, orderId),
                            ),
                            onTap: () => _showOrderDetails(order, orderId),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  // الحصول على لون حالة الطلب
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

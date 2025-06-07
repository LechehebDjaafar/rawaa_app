// تحديث seller_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'seller_home_tab.dart';
import 'seller_products_tab.dart';
import 'seller_orders_tab.dart';
import 'seller_messages_tab.dart';
import 'seller_profile_tab.dart';
import 'seller_notifications_screen.dart'; // إضافة شاشة الإشعارات

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ألوان متناسقة مع مشروع الري والهيدروليك
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color.fromARGB(255, 78, 94, 243); // أخضر داكن
  final Color accentColor = const Color(0xFF64B5F6); // أزرق فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح

  final List<Widget> _tabs = [
    const SellerHomeTab(),
    const SellerProductsTab(),
    const SellerOrdersTab(),
    const SellerMessagesTab(),
    const SellerProfileTab(),
  ];

  final List<String> _titles = [
    'لوحة التحكم',
    'منتجاتي',
    'الطلبات',
    'الرسائل',
    'الملف الشخصي',
  ];

  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.inventory_outlined,
    Icons.receipt_long_outlined,
    Icons.message_outlined,
    Icons.person_outline,
  ];

  final List<IconData> _selectedIcons = [
    Icons.dashboard,
    Icons.inventory,
    Icons.receipt_long,
    Icons.message,
    Icons.person,
  ];

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.reset();
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward();
    }
  }

  // دالة للانتقال إلى صفحة الطلبات
  void _navigateToOrders() {
    setState(() {
      _selectedIndex = 2; // فهرس تبويب الطلبات
    });
    _animationController.reset();
    _animationController.forward();
  }

  // دالة لعرض تفاصيل الطلب
  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس النافذة
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
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات العميل
                      _buildDetailSection(
                        'معلومات العميل',
                        Icons.person,
                        [
                          _buildDetailRow('اسم العميل:', order['customer'] ?? 'غير معروف'),
                          _buildDetailRow('رقم الهاتف:', order['customerPhone'] ?? 'غير محدد'),
                          _buildDetailRow('العنوان:', order['customerAddress'] ?? 'غير محدد'),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // تفاصيل الطلب
                      _buildDetailSection(
                        'تفاصيل الطلب',
                        Icons.info,
                        [
                          _buildDetailRow('حالة الطلب:', order['status'] ?? 'غير محدد'),
                          _buildDetailRow('تاريخ الطلب:', _formatTimestamp(order['createdAt'])),
                          _buildDetailRow('المبلغ الإجمالي:', '${order['totalAmount']} د.ج'),
                          _buildDetailRow('طريقة الدفع:', _getPaymentMethodText(order['paymentMethod'])),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // معلومات التوصيل (إن وجدت)
                      if (order['needsDelivery'] == true) ...[
                        _buildDetailSection(
                          'معلومات التوصيل',
                          Icons.delivery_dining,
                          [
                            _buildDetailRow('عنوان التوصيل:', order['deliveryAddress'] ?? 'غير محدد'),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // المنتجات المطلوبة
                      _buildDetailSection(
                        'المنتجات المطلوبة',
                        Icons.shopping_bag,
                        _buildItemsList(order['items']),
                      ),
                      
                      // ملاحظات إضافية
                      if (order['notes'] != null && order['notes'].isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(
                          'ملاحظات',
                          Icons.note,
                          [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                order['notes'],
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // أزرار العمليات
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(orderId, 'قيد التنفيذ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('قيد التنفيذ', style: TextStyle(fontFamily: 'Cairo')),
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
                      ),
                      child: const Text('تم التسليم', style: TextStyle(fontFamily: 'Cairo')),
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

  // بناء قسم التفاصيل
  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  // بناء صف التفاصيل
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء قائمة المنتجات
  List<Widget> _buildItemsList(dynamic items) {
    if (items == null || items is! List) {
      return [
        Text(
          'لا توجد تفاصيل للمنتجات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ];
    }

    return (items as List).map<Widget>((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'منتج غير محدد',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'الكمية: ${item['quantity'] ?? 0} × ${item['price'] ?? 0} د.ج',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${((item['quantity'] ?? 0) * (item['price'] ?? 0))} د.ج',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // تحديث حالة الطلب
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى: $newStatus'),
          backgroundColor: secondaryColor,
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
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'غير محدد';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // الحصول على نص طريقة الدفع
  String _getPaymentMethodText(String? paymentMethod) {
    switch (paymentMethod) {
      case 'cash':
        return 'دفع عند الاستلام';
      case 'electronic':
        return 'دفع إلكتروني';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final isVerySmallScreen = screenHeight < 500;
        
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: isVerySmallScreen ? 16 : 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: primaryColor,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            actions: [
              // زر الإشعارات مع عداد الإشعارات غير المقروءة
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      size: isVerySmallScreen ? 20 : 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SellerNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  // عداد الإشعارات غير المقروءة
                  Positioned(
                    right: 8,
                    top: 8,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('seller_notifications')
                          .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                          .where('isRead', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }
                        
                        final unreadCount = snapshot.data!.docs.length;
                        
                        return Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: isVerySmallScreen ? 14 : 16,
                            minHeight: isVerySmallScreen ? 14 : 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _selectedIndex == 0 
                ? SellerHomeTabWithCallbacks(
                    onOrderTap: _showOrderDetails,
                    onViewAllOrdersTap: _navigateToOrders,
                  )
                : _tabs[_selectedIndex],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showUnselectedLabels: true,
              selectedLabelStyle: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: isVerySmallScreen ? 10 : 12,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 9 : 11,
              ),
              onTap: _onItemTapped,
              items: List.generate(
                _titles.length,
                (index) => BottomNavigationBarItem(
                  icon: Icon(
                    _selectedIndex == index ? _selectedIcons[index] : _icons[index],
                    size: isVerySmallScreen ? 20 : 24,
                  ),
                  label: _titles[index],
                  tooltip: _titles[index],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// كلاس محدث لـ SellerHomeTab مع callbacks
class SellerHomeTabWithCallbacks extends StatelessWidget {
  final Function(Map<String, dynamic>, String) onOrderTap;
  final VoidCallback onViewAllOrdersTap;

  const SellerHomeTabWithCallbacks({
    super.key,
    required this.onOrderTap,
    required this.onViewAllOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    // هنا تضع محتوى SellerHomeTab مع إضافة callbacks للطلبات
    // يجب تمرير onOrderTap و onViewAllOrdersTap إلى العناصر المناسبة
    return const SellerHomeTab(); // مؤقتاً، يجب تحديث SellerHomeTab لدعم callbacks
  }
}

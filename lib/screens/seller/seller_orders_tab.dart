import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({super.key});

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> with SingleTickerProviderStateMixin {
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  
  // إضافة الفلترة الصحيحة - الحصول على معرف البائع الحالي
  final String? _currentSellerId = FirebaseAuth.instance.currentUser?.uid;
  
  String _selectedFilter = 'الكل';

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor =  const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFFFF8A65);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    // تم حذف استدعاء _ensureOrdersCollectionExists() لتجنب إنشاء طلبات تجريبية
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // عرض تفاصيل الطلب - محسن ومرن
  void _showOrderDetails(Map<String, dynamic> order, String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenWidth < 600;
          final isVerySmallScreen = screenHeight < 500;
          
          return Container(
            height: screenHeight * (isVerySmallScreen ? 0.9 : 0.8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
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
                          fontSize: isVerySmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: secondaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: isVerySmallScreen ? 20 : 24,
                        ),
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
                          SizedBox(height: isVerySmallScreen ? 12 : 16),
                          
                          // معلومات العميل
                          _buildSectionHeader('معلومات العميل', isVerySmallScreen),
                          SizedBox(height: isVerySmallScreen ? 8 : 12),
                          _buildDetailCard([
                            _buildDetailItem(
                              icon: Icons.person,
                              title: 'اسم العميل',
                              value: order['customer'] ?? 'غير معروف',
                              isVerySmallScreen: isVerySmallScreen,
                            ),
                            _buildDetailItem(
                              icon: Icons.phone,
                              title: 'رقم الهاتف',
                              value: order['customerPhone'] ?? 'غير محدد',
                              isVerySmallScreen: isVerySmallScreen,
                            ),
                            _buildDetailItem(
                              icon: Icons.location_on,
                              title: 'العنوان',
                              value: order['customerAddress'] ?? 'غير محدد',
                              isVerySmallScreen: isVerySmallScreen,
                            ),
                          ], isVerySmallScreen),
                          
                          SizedBox(height: isVerySmallScreen ? 16 : 20),
                          
                          // تفاصيل الطلب
                          _buildSectionHeader('تفاصيل الطلب', isVerySmallScreen),
                          SizedBox(height: isVerySmallScreen ? 8 : 12),
                          _buildDetailCard([
                            _buildDetailItem(
                              icon: Icons.info_outline,
                              title: 'حالة الطلب',
                              value: order['status'] ?? 'غير محدد',
                              valueColor: _getStatusColor(order['status'] ?? ''),
                              isVerySmallScreen: isVerySmallScreen,
                            ),
                            _buildDetailItem(
                              icon: Icons.calendar_today,
                              title: 'تاريخ الطلب',
                              value: order['createdAt'] != null
                                  ? _formatTimestamp(order['createdAt'])
                                  : 'غير محدد',
                              isVerySmallScreen: isVerySmallScreen,
                            ),
                            _buildDetailItem(
                              icon: Icons.attach_money,
                              title: 'المبلغ الإجمالي',
                              value: order['totalAmount'] != null
                                  ? '${order['totalAmount']} د.ج'
                                  : 'غير محدد',
                              valueColor: primaryColor,
                              isVerySmallScreen: isVerySmallScreen,
                            ),
                          ], isVerySmallScreen),
                          
                          SizedBox(height: isVerySmallScreen ? 16 : 20),
                          
                          // المنتجات المطلوبة
                          _buildSectionHeader('المنتجات المطلوبة', isVerySmallScreen),
                          SizedBox(height: isVerySmallScreen ? 8 : 12),
                          _buildItemsList(order['items'], isVerySmallScreen),
                          
                          // ملاحظات إضافية
                          if (order['notes'] != null && order['notes'].isNotEmpty) ...[
                            SizedBox(height: isVerySmallScreen ? 16 : 20),
                            _buildSectionHeader('ملاحظات', isVerySmallScreen),
                            SizedBox(height: isVerySmallScreen ? 8 : 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                order['notes'],
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 13 : 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                          
                          SizedBox(height: isVerySmallScreen ? 20 : 24),
                        ],
                      ),
                    ),
                  ),
                  
                  // أزرار تغيير الحالة - مرنة
                  if (isSmallScreen)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 40 : 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(orderId, 'قيد التنفيذ'),
                            icon: Icon(
                              Icons.hourglass_empty,
                              size: isVerySmallScreen ? 16 : 18,
                            ),
                            label: Text(
                              'قيد التنفيذ',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: isVerySmallScreen ? 14 : 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 8 : 12),
                        SizedBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 40 : 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(orderId, 'تم التسليم'),
                            icon: Icon(
                              Icons.check_circle,
                              size: isVerySmallScreen ? 16 : 18,
                            ),
                            label: Text(
                              'تم التسليم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: isVerySmallScreen ? 14 : 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: isVerySmallScreen ? 40 : 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateOrderStatus(orderId, 'قيد التنفيذ'),
                              icon: Icon(
                                Icons.hourglass_empty,
                                size: isVerySmallScreen ? 16 : 18,
                              ),
                              label: Text(
                                'قيد التنفيذ',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: isVerySmallScreen ? 14 : 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isVerySmallScreen ? 8 : 12),
                        Expanded(
                          child: SizedBox(
                            height: isVerySmallScreen ? 40 : 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateOrderStatus(orderId, 'تم التسليم'),
                              icon: Icon(
                                Icons.check_circle,
                                size: isVerySmallScreen ? 16 : 18,
                              ),
                              label: Text(
                                'تم التسليم',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: isVerySmallScreen ? 14 : 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // بناء رأس القسم
  Widget _buildSectionHeader(String title, bool isVerySmallScreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isVerySmallScreen ? 16 : 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Cairo',
        color: primaryColor,
      ),
    );
  }

  // بناء بطاقة التفاصيل
  Widget _buildDetailCard(List<Widget> children, bool isVerySmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
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
        children: children,
      ),
    );
  }

  // بناء قائمة المنتجات
  Widget _buildItemsList(dynamic items, bool isVerySmallScreen) {
    if (items == null || items is! List) {
      return Container(
        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'لا توجد تفاصيل للمنتجات',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isVerySmallScreen ? 13 : 15,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Column(
      children: (items as List).map<Widget>((item) {
        return Container(
          margin: EdgeInsets.only(bottom: isVerySmallScreen ? 8 : 12),
          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: primaryColor,
                size: isVerySmallScreen ? 18 : 22,
              ),
              SizedBox(width: isVerySmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'منتج غير محدد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: isVerySmallScreen ? 13 : 15,
                      ),
                    ),
                    SizedBox(height: isVerySmallScreen ? 2 : 4),
                    Text(
                      'الكمية: ${item['quantity'] ?? 0} × ${item['price'] ?? 0} د.ج',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 11 : 13,
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
                  fontSize: isVerySmallScreen ? 13 : 15,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    return '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // بناء عنصر تفاصيل - محسن
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required bool isVerySmallScreen,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isVerySmallScreen ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: secondaryColor,
            size: isVerySmallScreen ? 18 : 22,
          ),
          SizedBox(width: isVerySmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 2 : 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود معرف البائع
    if (_currentSellerId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
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
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenHeight < 500;
        
        return Scaffold(
          backgroundColor: backgroundColor,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // شريط الفلترة
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Row(
                    children: [
                      Text(
                        'فلترة الطلبات:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: isVerySmallScreen ? 14 : 16,
                        ),
                      ),
                      SizedBox(width: isVerySmallScreen ? 8 : 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: ['الكل', 'جديد', 'قيد التنفيذ', 'تم التسليم']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedFilter = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
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

                      // هنا ستظهر رسالة "لا توجد طلبات" إذا لم توجد طلبات حقيقية
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: isVerySmallScreen ? 60 : 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: isVerySmallScreen ? 12 : 16),
                              Text(
                                'لا توجد طلبات حالياً',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: isVerySmallScreen ? 6 : 8),
                              Text(
                                'ستظهر الطلبات الجديدة هنا',
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

                      final orders = snapshot.data!.docs;
                      
                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        color: primaryColor,
                        child: ListView.separated(
                          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
                          itemBuilder: (context, index) {
                            final order = orders[index].data() as Map<String, dynamic>;
                            final orderId = orders[index].id;
                            
                            return _buildOrderCard(order, orderId, isVerySmallScreen);
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

  // بناء بطاقة الطلب - محسنة ومرنة
  Widget _buildOrderCard(Map<String, dynamic> order, String orderId, bool isVerySmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order, orderId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(order['status'] ?? ''),
                    radius: isVerySmallScreen ? 16 : 20,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                      size: isVerySmallScreen ? 16 : 20,
                    ),
                  ),
                  SizedBox(width: isVerySmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['customer'] ?? 'غير معروف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: isVerySmallScreen ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 2 : 4),
                        Text(
                          order['status'] ?? 'غير محدد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isVerySmallScreen ? 12 : 14,
                            color: _getStatusColor(order['status'] ?? ''),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: isVerySmallScreen ? 14 : 18,
                  ),
                ],
              ),
              
              SizedBox(height: isVerySmallScreen ? 8 : 12),
              
              // تفاصيل إضافية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المبلغ: ${order['totalAmount']?.toString() ?? '0'} د.ج',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (order['createdAt'] != null)
                    Text(
                      _formatTimestamp(order['createdAt']),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 10 : 12,
                        color: Colors.grey[600],
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

  // الحصول على ستريم الطلبات المفلترة مع إضافة فلترة sellerId
  Stream<QuerySnapshot> _getFilteredOrdersStream() {
    if (_currentSellerId == null) {
      return const Stream.empty();
    }
    
    Query query = _ordersCollection
        .where('sellerId', isEqualTo: _currentSellerId!) // إضافة الفلترة الأساسية
        .orderBy('createdAt', descending: true);
    
    if (_selectedFilter != 'الكل') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }
    
    return query.snapshots();
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

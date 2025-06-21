import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() => _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState extends State<SellerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final CollectionReference _notificationsCollection =
      FirebaseFirestore.instance.collection('seller_notifications');
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  
  // تحسين: التحقق من وجود المستخدم قبل الحصول على UID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  String _selectedFilter = 'الكل';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // متغير للتحكم في Stream
  late Stream<QuerySnapshot> _notificationsStream;
  bool _isInitialized = false;

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
    
    // تهيئة البيانات بالترتيب الصحيح - بدون إنشاء إشعارات تجريبية
    _initializeData();
  }

  // تهيئة البيانات مع التحقق من وجود المستخدم - بدون إشعارات تجريبية
  Future<void> _initializeData() async {
    // التحقق من وجود المستخدم أولاً
    if (_currentUserId == null) {
      setState(() {
        _isInitialized = true;
      });
      return;
    }
    
    try {
      // تهيئة Stream مباشرة بدون إنشاء إشعارات تجريبية
      _notificationsStream = _notificationsCollection
          .where('sellerId', isEqualTo: _currentUserId!)
          .orderBy('createdAt', descending: true)
          .snapshots();
      
      setState(() {
        _isInitialized = true;
      });
      
      _animationController.forward();
      _setupNotificationListener();
    } catch (e) {
      print('خطأ في تهيئة البيانات: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // إعداد مستمع الإشعارات للطلبات الجديدة
  void _setupNotificationListener() {
    if (_currentUserId == null) return;
    
    _ordersCollection
        .where('sellerId', isEqualTo: _currentUserId!)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _createOrderNotification(change.doc.data() as Map<String, dynamic>, change.doc.id);
        }
      }
    });
  }

  // إنشاء إشعار للطلب الجديد
  Future<void> _createOrderNotification(Map<String, dynamic> orderData, String orderId) async {
    if (_currentUserId == null) return;
    
    try {
      await _notificationsCollection.add({
        'sellerId': _currentUserId!,
        'title': 'طلب جديد!',
        'body': 'لديك طلب جديد من ${orderData['customer'] ?? 'زبون'} بقيمة ${orderData['totalAmount'] ?? 0} د.ج',
        'type': 'new_order',
        'priority': 'high',
        'isRead': false,
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'orderId': orderId,
          'customerName': orderData['customer'],
          'amount': orderData['totalAmount'],
        },
      });
      
      _showLocalNotification(
        'طلب جديد!',
        'لديك طلب جديد من ${orderData['customer'] ?? 'زبون'} بقيمة ${orderData['totalAmount'] ?? 0} د.ج'
      );
    } catch (e) {
      print('خطأ في إنشاء إشعار الطلب: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // عرض الإشعار المحلي
  void _showLocalNotification(String title, String body) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            Text(
              body,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            // فتح شاشة الإشعارات أو التفاصيل
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من وجود المستخدم
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
        ),
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
        final screenHeight = constraints.maxHeight;
        final isVerySmallScreen = screenHeight < 500;
        
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'الإشعارات',
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
              IconButton(
                icon: Icon(
                  Icons.mark_email_read,
                  size: isVerySmallScreen ? 20 : 24,
                ),
                onPressed: _markAllAsRead,
                tooltip: 'تحديد الكل كمقروء',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_sweep,
                  size: isVerySmallScreen ? 20 : 24,
                ),
                onPressed: _showClearAllDialog,
                tooltip: 'حذف الكل',
              ),
            ],
          ),
          body: !_isInitialized
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // شريط الفلترة والإحصائيات
                      Container(
                        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                        child: Column(
                          children: [
                            // إحصائيات سريعة
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'الكل',
                                    Icons.notifications,
                                    primaryColor,
                                    isVerySmallScreen,
                                    _getNotificationCount(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'غير مقروءة',
                                    Icons.mark_email_unread,
                                    alertColor,
                                    isVerySmallScreen,
                                    _getUnreadNotificationCount(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'طلبات',
                                    Icons.shopping_cart,
                                    secondaryColor,
                                    isVerySmallScreen,
                                    _getOrderNotificationCount(),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: isVerySmallScreen ? 12 : 16),
                            
                            // فلترة الإشعارات
                            Row(
                              children: [
                                Text(
                                  'فلترة:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                      items: [
                                        'الكل',
                                        'غير مقروءة',
                                        'مقروءة',
                                        'طلبات جديدة',
                                        'رسائل',
                                        'مدفوعات',
                                        'تنبيهات المخزون',
                                        'تقييمات'
                                      ].map((String value) {
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
                          ],
                        ),
                      ),
                      
                      // قائمة الإشعارات
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getFilteredNotificationsStream(),
                          builder: (context, snapshot) {
                            // معالجة محسنة لحالات الاتصال
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                                      'حدث خطأ في تحميل الإشعارات',
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
                            
                            // هنا ستظهر رسالة "لا توجد إشعارات" إذا لم توجد إشعارات حقيقية
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: isVerySmallScreen ? 60 : 80,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                                    Text(
                                      'لا توجد إشعارات',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: isVerySmallScreen ? 16 : 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 6 : 8),
                                    Text(
                                      'ستظهر الإشعارات الجديدة هنا',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: isVerySmallScreen ? 12 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            final notifications = snapshot.data!.docs;
                            
                            return RefreshIndicator(
                              onRefresh: () async {
                                // لا نحتاج لاستدعاء setState هنا لأن StreamBuilder سيتحدث تلقائيًا
                              },
                              color: primaryColor,
                              child: ListView.separated(
                                padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                                itemCount: notifications.length,
                                separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
                                itemBuilder: (context, index) {
                                  final notification = notifications[index].data() as Map<String, dynamic>;
                                  final notificationId = notifications[index].id;
                                  
                                  return NotificationCard(
                                    notification: notification,
                                    notificationId: notificationId,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    accentColor: accentColor,
                                    alertColor: alertColor,
                                    isVerySmallScreen: isVerySmallScreen,
                                    onTap: () => _markAsRead(notificationId),
                                    onDelete: () => _deleteNotification(notificationId),
                                  );
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

  // باقي الدوال المساعدة...
  Widget _buildStatCard(String title, IconData icon, Color color, bool isVerySmallScreen, Widget countWidget) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
        child: Column(
          children: [
            Icon(icon, size: isVerySmallScreen ? 16 : 20, color: color),
            SizedBox(height: isVerySmallScreen ? 2 : 4),
            countWidget,
            Text(
              title,
              style: TextStyle(
                fontSize: isVerySmallScreen ? 8 : 10,
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

  Widget _getNotificationCount() {
    if (_currentUserId == null) return const Text('0');
    
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsCollection
          .where('sellerId', isEqualTo: _currentUserId!)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontFamily: 'Cairo',
          ),
        );
      },
    );
  }

  Widget _getUnreadNotificationCount() {
    if (_currentUserId == null) return const Text('0');
    
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsCollection
          .where('sellerId', isEqualTo: _currentUserId!)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: alertColor,
            fontFamily: 'Cairo',
          ),
        );
      },
    );
  }

  Widget _getOrderNotificationCount() {
    if (_currentUserId == null) return const Text('0');
    
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsCollection
          .where('sellerId', isEqualTo: _currentUserId!)
          .where('type', isEqualTo: 'new_order')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
            fontFamily: 'Cairo',
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredNotificationsStream() {
    if (_currentUserId == null) {
      // إرجاع stream فارغ إذا لم يكن هناك مستخدم
      return const Stream.empty();
    }
    
    Query query = _notificationsCollection
        .where('sellerId', isEqualTo: _currentUserId!)
        .orderBy('createdAt', descending: true);
    
    switch (_selectedFilter) {
      case 'غير مقروءة':
        query = query.where('isRead', isEqualTo: false);
        break;
      case 'مقروءة':
        query = query.where('isRead', isEqualTo: true);
        break;
      case 'طلبات جديدة':
        query = query.where('type', isEqualTo: 'new_order');
        break;
      case 'رسائل':
        query = query.where('type', isEqualTo: 'message');
        break;
      case 'مدفوعات':
        query = query.where('type', isEqualTo: 'payment');
        break;
      case 'تنبيهات المخزون':
        query = query.where('type', isEqualTo: 'stock_alert');
        break;
      case 'تقييمات':
        query = query.where('type', isEqualTo: 'review');
        break;
    }
    
    return query.snapshots();
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('خطأ في تحديث حالة القراءة: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;
    
    try {
      final query = await _notificationsCollection
          .where('sellerId', isEqualTo: _currentUserId!)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in query.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد جميع الإشعارات كمقروءة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الإشعار'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllNotifications();
            },
            child: const Text('حذف الكل', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    if (_currentUserId == null) return;
    
    try {
      final query = await _notificationsCollection
          .where('sellerId', isEqualTo: _currentUserId!)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف جميع الإشعارات'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// بطاقة الإشعار للبائعين - محسنة
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String notificationId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color alertColor;
  final bool isVerySmallScreen;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.notificationId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.alertColor,
    required this.isVerySmallScreen,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? 'general';
    final String priority = notification['priority'] ?? 'normal';
    
    return Card(
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس الإشعار
              Row(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: isVerySmallScreen ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification['title'] ?? 'إشعار',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 14 : 16,
                        color: isRead ? Colors.grey[700] : Colors.black87,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: isVerySmallScreen ? 8 : 10,
                      height: isVerySmallScreen ? 8 : 10,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: isVerySmallScreen ? 6 : 8),
              
              // محتوى الإشعار
              if (notification['body'] != null && notification['body'].isNotEmpty)
                Text(
                  notification['body'],
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 12 : 14,
                    color: isRead ? Colors.grey[600] : Colors.grey[800],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              
              SizedBox(height: isVerySmallScreen ? 8 : 12),
              
              // تفاصيل الإشعار
              Row(
                children: [
                  if (priority == 'high')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 6 : 8,
                        vertical: isVerySmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'مهم',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isVerySmallScreen ? 10 : 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (priority == 'high') const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 6 : 8,
                      vertical: isVerySmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTypeText(type),
                      style: TextStyle(
                        color: _getTypeColor(type),
                        fontSize: isVerySmallScreen ? 10 : 12,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(notification['createdAt']),
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 10 : 12,
                      color: Colors.grey[500],
                      fontFamily: 'Cairo',
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'message':
        return Icons.message;
      case 'payment':
        return Icons.payment;
      case 'stock_alert':
        return Icons.warning;
      case 'review':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'new_order':
        return secondaryColor;
      case 'message':
        return primaryColor;
      case 'payment':
        return accentColor;
      case 'stock_alert':
        return alertColor;
      case 'review':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'new_order':
        return 'طلب جديد';
      case 'message':
        return 'رسالة';
      case 'payment':
        return 'دفع';
      case 'stock_alert':
        return 'تنبيه مخزون';
      case 'review':
        return 'تقييم';
      default:
        return 'عام';
    }
  }

  String _formatDate(dynamic timestamp) {
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
}

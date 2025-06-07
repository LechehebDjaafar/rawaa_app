import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> 
    with SingleTickerProviderStateMixin {
  final CollectionReference _notificationsCollection = 
      FirebaseFirestore.instance.collection('customer_notifications');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String _selectedFilter = 'الكل';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);
  
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
    _ensureNotificationsCollectionExists();
    _createSampleNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // إنشاء مجموعة الإشعارات تلقائياً
  Future<void> _ensureNotificationsCollectionExists() async {
    try {
      final snapshot = await _notificationsCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة إشعارات الزبائن لأول مرة');
        DocumentReference tempDoc = await _notificationsCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في إنشاء مجموعة الإشعارات: $e');
    }
  }

  // إنشاء إشعارات تجريبية مناسبة للزبائن
  Future<void> _createSampleNotifications() async {
    if (_currentUserId == 'guest') return;
    
    final sampleNotifications = [
      {
        'title': 'مرحباً بك في RAWAA!',
        'body': 'نرحب بك في تطبيق RAWAA لمعدات الري والهيدروليك. استكشف منتجاتنا المتنوعة واحصل على أفضل العروض',
        'type': 'welcome',
        'priority': 'normal',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'عرض خاص - خصم 25%',
        'body': 'خصم 25% على جميع أنظمة الري بالتنقيط والمضخات الغاطسة لفترة محدودة حتى نهاية الشهر',
        'type': 'offer',
        'priority': 'high',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'تم تأكيد طلبك',
        'body': 'تم تأكيد طلبك رقم #1234 بقيمة 15,500 دج وسيتم التوصيل خلال 3-5 أيام عمل',
        'type': 'order_confirmed',
        'priority': 'high',
        'isRead': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'منتجات جديدة في المتجر',
        'body': 'تم إضافة مضخات مياه جديدة عالية الكفاءة ومعدات ري ذكية إلى متجرنا. اكتشف الآن!',
        'type': 'new_products',
        'priority': 'normal',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'تذكير الصيانة الدورية',
        'body': 'حان وقت الصيانة الدورية لنظام الري الخاص بك. احجز موعد الصيانة الآن للحصول على خدمة مجانية',
        'type': 'maintenance',
        'priority': 'medium',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'دورة تدريبية جديدة',
        'body': 'دورة تدريبية متخصصة في تركيب وصيانة أنظمة الري الحديثة. سجل الآن واحصل على شهادة معتمدة',
        'type': 'training',
        'priority': 'normal',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    // التحقق من وجود إشعارات مسبقة لتجنب التكرار
    final existingNotifications = await _notificationsCollection
        .where('customerId', isEqualTo: _currentUserId)
        .get();
    
    if (existingNotifications.docs.isEmpty) {
      for (var notification in sampleNotifications) {
        notification['customerId'] = _currentUserId;
        await _notificationsCollection.add(notification);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
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
          body: FadeTransition(
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
                              'عروض',
                              Icons.local_offer,
                              secondaryColor,
                              isVerySmallScreen,
                              _getOfferNotificationCount(),
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
                                  'عروض',
                                  'طلبات',
                                  'منتجات جديدة',
                                  'دورات',
                                  'صيانة'
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        );
                      }
                      
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
                      
                      return ListView.separated(
                        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
                        itemBuilder: (context, index) {
                          final notification = notifications[index].data() as Map<String, dynamic>;
                          final notificationId = notifications[index].id;
                          
                          return CustomerNotificationCard(
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
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsCollection
          .where('customerId', isEqualTo: _currentUserId)
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
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsCollection
          .where('customerId', isEqualTo: _currentUserId)
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
  
  Widget _getOfferNotificationCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsCollection
          .where('customerId', isEqualTo: _currentUserId)
          .where('type', isEqualTo: 'offer')
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
    Query query = _notificationsCollection
        .where('customerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true);
    
    switch (_selectedFilter) {
      case 'غير مقروءة':
        query = query.where('isRead', isEqualTo: false);
        break;
      case 'مقروءة':
        query = query.where('isRead', isEqualTo: true);
        break;
      case 'عروض':
        query = query.where('type', isEqualTo: 'offer');
        break;
      case 'طلبات':
        query = query.where('type', whereIn: ['order_confirmed', 'order_shipped', 'order_delivered']);
        break;
      case 'منتجات جديدة':
        query = query.where('type', isEqualTo: 'new_products');
        break;
      case 'دورات':
        query = query.where('type', isEqualTo: 'training');
        break;
      case 'صيانة':
        query = query.where('type', isEqualTo: 'maintenance');
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
    try {
      final query = await _notificationsCollection
          .where('customerId', isEqualTo: _currentUserId)
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد جميع الإشعارات كمقروءة'),
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
  
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الإشعار'),
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
    try {
      final query = await _notificationsCollection
          .where('customerId', isEqualTo: _currentUserId)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف جميع الإشعارات'),
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
}

// بطاقة الإشعار للزبائن
class CustomerNotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String notificationId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color alertColor;
  final bool isVerySmallScreen;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerNotificationCard({
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
      case 'welcome':
        return Icons.waving_hand;
      case 'offer':
        return Icons.local_offer;
      case 'order_confirmed':
      case 'order_shipped':
      case 'order_delivered':
        return Icons.shopping_bag;
      case 'new_products':
        return Icons.new_releases;
      case 'training':
        return Icons.school;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.notifications;
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'welcome':
        return primaryColor;
      case 'offer':
        return alertColor;
      case 'order_confirmed':
      case 'order_shipped':
      case 'order_delivered':
        return secondaryColor;
      case 'new_products':
        return accentColor;
      case 'training':
        return Colors.purple;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  String _getTypeText(String type) {
    switch (type) {
      case 'welcome':
        return 'ترحيب';
      case 'offer':
        return 'عرض خاص';
      case 'order_confirmed':
        return 'تأكيد طلب';
      case 'order_shipped':
        return 'شحن طلب';
      case 'order_delivered':
        return 'تسليم طلب';
      case 'new_products':
        return 'منتجات جديدة';
      case 'training':
        return 'دورة تدريبية';
      case 'maintenance':
        return 'صيانة';
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

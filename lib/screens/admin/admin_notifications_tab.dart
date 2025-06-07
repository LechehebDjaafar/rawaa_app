import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({super.key});

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');
  String _selectedFilter = 'الكل';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenHeight < 600;
        final isVerySmallScreen = screenHeight < 500;
        
        return Container(
          color: backgroundColor,
          child: Column(
            children: [
              // شريط الفلترة وإنشاء إشعار جديد
              Container(
                padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                child: Column(
                  children: [
                    // زر إنشاء إشعار جديد
                    SizedBox(
                      width: double.infinity,
                      height: isVerySmallScreen ? 40 : 45,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add, size: isVerySmallScreen ? 18 : 20),
                        label: Text(
                          'إنشاء إشعار جديد',
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
                        onPressed: () => _showCreateNotificationDialog(context, isVerySmallScreen),
                      ),
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
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            isExpanded: true,
                            items: ['الكل', 'غير مقروءة', 'مقروءة', 'مهمة'].map((String value) {
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
                        
                        return NotificationCard(
                          notification: notification,
                          notificationId: notificationId,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          accentColor: accentColor,
                          alertColor: alertColor,
                          isVerySmallScreen: isVerySmallScreen,
                          onDelete: () => _deleteNotification(notificationId),
                          onMarkAsRead: () => _markAsRead(notificationId),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Stream<QuerySnapshot> _getFilteredNotificationsStream() {
    Query query = _notificationsCollection.orderBy('createdAt', descending: true);
    
    switch (_selectedFilter) {
      case 'غير مقروءة':
        query = query.where('isRead', isEqualTo: false);
        break;
      case 'مقروءة':
        query = query.where('isRead', isEqualTo: true);
        break;
      case 'مهمة':
        query = query.where('priority', isEqualTo: 'عالية');
        break;
    }
    
    return query.snapshots();
  }
  
  void _showCreateNotificationDialog(BuildContext context, bool isVerySmallScreen) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedPriority = 'متوسطة';
    String selectedType = 'عام';
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'إنشاء إشعار جديد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isVerySmallScreen ? 16 : 18,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان الإشعار',
                      labelStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 12 : 14,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 12 : 16),
                  
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'محتوى الإشعار',
                      labelStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 12 : 14,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 12 : 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'الأولوية',
                            labelStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 12 : 14,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: ['منخفضة', 'متوسطة', 'عالية'].map((String value) {
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
                              selectedPriority = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: InputDecoration(
                            labelText: 'النوع',
                            labelStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 12 : 14,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: ['عام', 'طلب جديد', 'تحديث', 'تحذير'].map((String value) {
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
                              selectedType = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
              ),
              onPressed: isLoading ? null : () async {
                if (titleController.text.isEmpty || messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() {
                  isLoading = true;
                });
                
                try {
                  await _notificationsCollection.add({
                    'title': titleController.text,
                    'message': messageController.text,
                    'priority': selectedPriority,
                    'type': selectedType,
                    'isRead': false,
                    'createdAt': FieldValue.serverTimestamp(),
                    'createdBy': FirebaseAuth.instance.currentUser?.uid,
                  });
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إنشاء الإشعار بنجاح'),
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
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: isLoading
                  ? SizedBox(
                      width: isVerySmallScreen ? 16 : 20,
                      height: isVerySmallScreen ? 16 : 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'إنشاء',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 12 : 14,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الإشعار بنجاح'),
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
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String notificationId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color alertColor;
  final bool isVerySmallScreen;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.notificationId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.alertColor,
    required this.isVerySmallScreen,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] ?? false;
    final String priority = notification['priority'] ?? 'متوسطة';
    final String type = notification['type'] ?? 'عام';
    
    return Card(
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: () {
          if (!isRead) {
            onMarkAsRead();
          }
        },
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
                    color: _getPriorityColor(priority),
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
                ],
              ),
              
              SizedBox(height: isVerySmallScreen ? 6 : 8),
              
              // محتوى الإشعار
              Text(
                notification['message'] ?? '',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 12 : 14,
                  color: isRead ? Colors.grey[600] : Colors.grey[800],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: isVerySmallScreen ? 8 : 12),
              
              // تفاصيل الإشعار وإجراءات
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 6 : 8,
                      vertical: isVerySmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: _getPriorityColor(priority),
                        fontSize: isVerySmallScreen ? 10 : 12,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 6 : 8,
                      vertical: isVerySmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: accentColor,
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
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      } else if (value == 'mark_read' && !isRead) {
                        onMarkAsRead();
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read),
                              SizedBox(width: 8),
                              Text('تحديد كمقروء', style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
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
      case 'طلب جديد':
        return Icons.shopping_cart;
      case 'تحديث':
        return Icons.update;
      case 'تحذير':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'عالية':
        return Colors.red;
      case 'متوسطة':
        return Colors.orange;
      case 'منخفضة':
        return Colors.green;
      default:
        return Colors.grey;
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class SellerMessagesTab extends StatefulWidget {
  const SellerMessagesTab({super.key});

  @override
  State<SellerMessagesTab> createState() => _SellerMessagesTabState();
}

class _SellerMessagesTabState extends State<SellerMessagesTab> with SingleTickerProviderStateMixin {
  final CollectionReference _messagesCollection = FirebaseFirestore.instance.collection('conversations');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'seller_id';
  bool _isLoading = true;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor =  const Color.fromARGB(255, 78, 94, 243); // أخضر داكن
  final Color accentColor = const Color(0xFF64B5F6); // أزرق فاتح
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
    
    // التحقق من وجود مجموعة المحادثات وإنشائها إذا لم تكن موجودة
    _ensureMessagesCollectionExists().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود مجموعة المحادثات وإنشائها إذا لم تكن موجودة
  Future<void> _ensureMessagesCollectionExists() async {
    try {
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await _messagesCollection.limit(1).get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة المحادثات لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await _messagesCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة المحادثات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // فتح صفحة المحادثة
  void _openConversation(String conversationId, String customerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          customerName: customerName,
          sellerId: _currentUserId,
        ),
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'الرسائل',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: secondaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _messagesCollection
                          .where('participants', arrayContains: _currentUserId)
                          .orderBy('lastMessageTime', descending: true)
                          .snapshots(),
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
                                  Icons.chat_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا توجد رسائل حالياً',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'ستظهر هنا المحادثات مع الزبائن',
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
                        
                        final conversations = snapshot.data!.docs;
                        
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final conversation = conversations[index].data() as Map<String, dynamic>;
                            final conversationId = conversations[index].id;
                            
                            // استخراج معرف الزبون
                            final participants = conversation['participants'] as List<dynamic>;
                            final customerId = participants.firstWhere((id) => id != _currentUserId, orElse: () => '');
                            
                            return FutureBuilder<DocumentSnapshot>(
                              future: _usersCollection.doc(customerId).get(),
                              builder: (context, userSnapshot) {
                                String customerName = 'زبون';
                                String customerInitial = 'ز';
                                
                                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                  customerName = userData['name'] ?? 'زبون';
                                  customerInitial = customerName.isNotEmpty ? customerName[0] : 'ز';
                                }
                                
                                return Card(
                                  elevation: 2,
                                  shadowColor: Colors.black12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: _getRandomColor(customerName),
                                      radius: 24,
                                      child: Text(
                                        customerInitial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            customerName,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (conversation['lastMessageTime'] != null)
                                          Text(
                                            _formatTimestamp(conversation['lastMessageTime']),
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            conversation['lastMessage'] ?? '',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              color: conversation['unreadCount'] > 0 ? Colors.black87 : Colors.grey[600],
                                              fontWeight: conversation['unreadCount'] > 0 ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (conversation['unreadCount'] > 0)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              conversation['unreadCount'].toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () => _openConversation(conversationId, customerName),
                                  ),
                                );
                              },
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
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'الأمس';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  // الحصول على لون عشوائي ولكن ثابت لنفس الاسم
  Color _getRandomColor(String name) {
    final List<Color> colors = [
      const Color(0xFF1976D2), // أزرق
      const Color(0xFF2F5233), // أخضر
      const Color(0xFFFF8A65), // برتقالي
      const Color(0xFF9C27B0), // أرجواني
      const Color(0xFF795548), // بني
      const Color(0xFF607D8B), // رمادي أزرق
    ];
    
    final int hash = name.hashCode;
    final int index = hash.abs() % colors.length;
    return colors[index];
  }
}

// شاشة المحادثة
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String customerName;
  final String sellerId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.customerName,
    required this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _conversationsCollection = FirebaseFirestore.instance.collection('conversations');
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  
  @override
  void initState() {
    super.initState();
    // تحديث عدد الرسائل غير المقروءة إلى صفر
    _markAsRead();
  }
  
  // تحديث عدد الرسائل غير المقروءة
  Future<void> _markAsRead() async {
    try {
      await _conversationsCollection.doc(widget.conversationId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('خطأ في تحديث عدد الرسائل غير المقروءة: $e');
    }
  }
  
  // إرسال رسالة جديدة
  Future<void> _sendMessage() async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    try {
      // الحصول على مرجع المحادثة
      final DocumentReference conversationRef = _conversationsCollection.doc(widget.conversationId);
      
      // الحصول على مرجع مجموعة الرسائل داخل المحادثة
      final CollectionReference messagesRef = conversationRef.collection('messages');
      
      // إضافة الرسالة الجديدة
      await messagesRef.add({
        'text': messageText,
        'senderId': widget.sellerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // تحديث آخر رسالة ووقتها في المحادثة
      await conversationRef.update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': widget.sellerId,
      });
      
      // مسح حقل الإدخال
      _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
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
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // منطقة الرسائل
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _conversationsCollection
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد رسائل بعد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ابدأ المحادثة الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final messages = snapshot.data!.docs;
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isSentByMe = message['senderId'] == widget.sellerId;
                    
                    return Align(
                      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSentByMe ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isSentByMe ? const Radius.circular(0) : null,
                            bottomLeft: !isSentByMe ? const Radius.circular(0) : null,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isSentByMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['timestamp'] != null
                                  ? _formatMessageTime(message['timestamp'])
                                  : '',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: isSentByMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // منطقة إدخال الرسالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تنسيق وقت الرسالة
  String _formatMessageTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

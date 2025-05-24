import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumTab extends StatefulWidget {
  const ForumTab({super.key});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> with SingleTickerProviderStateMixin {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _conversationsCollection = FirebaseFirestore.instance.collection('conversations');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isLoading = true;
  String _searchQuery = '';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ
  
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
    
    // التحقق من وجود مجموعة المستخدمين وإنشائها إذا لم تكن موجودة
    _ensureCollectionsExist().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود المجموعات الأساسية وإنشائها إذا لم تكن موجودة
  Future<void> _ensureCollectionsExist() async {
    try {
      // التحقق من وجود مجموعة المستخدمين
      final usersSnapshot = await _usersCollection.limit(1).get();
      
      if (usersSnapshot.docs.isEmpty) {
        print('إنشاء مجموعة المستخدمين لأول مرة');
        
        DocumentReference tempDoc = await _usersCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await tempDoc.delete();
      }
      
      // التحقق من وجود مجموعة المحادثات
      final conversationsSnapshot = await _conversationsCollection.limit(1).get();
      
      if (conversationsSnapshot.docs.isEmpty) {
        print('إنشاء مجموعة المحادثات لأول مرة');
        
        DocumentReference tempDoc = await _conversationsCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود المجموعات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // شريط البحث
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث عن بائع...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  
                  // قائمة البائعين
                  Expanded(
                    child: _buildSellersList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSellersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersCollection
          .where('role', isEqualTo: 'seller')
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
                  Icons.store_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا يوجد بائعين متاحين حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        
        final sellers = snapshot.data!.docs;
        
        // فلترة البائعين حسب البحث
        final filteredSellers = _searchQuery.isEmpty
            ? sellers
            : sellers.where((doc) {
                final seller = doc.data() as Map<String, dynamic>;
                final name = seller['name'] ?? '';
                final username = seller['username'] ?? '';
                final serviceType = seller['serviceType'] ?? '';
                
                return name.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                       username.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                       serviceType.toString().toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();
        
        if (filteredSellers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد نتائج مطابقة للبحث',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredSellers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final seller = filteredSellers[index].data() as Map<String, dynamic>;
            final sellerId = filteredSellers[index].id;
            
            return SellerCard(
              sellerId: sellerId,
              name: seller['name'] ?? 'بائع',
              username: seller['username'] ?? '',
              serviceType: seller['serviceType'] ?? 'غير محدد',
              rating: (seller['rating'] ?? 0).toDouble(),
              imageUrl: seller['profileImage'],
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              accentColor: accentColor,
              currentUserId: _currentUserId,
            );
          },
        );
      },
    );
  }
}

class SellerCard extends StatelessWidget {
  final String sellerId;
  final String name;
  final String username;
  final String serviceType;
  final double rating;
  final String? imageUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String currentUserId;

  const SellerCard({
    super.key,
    required this.sellerId,
    required this.name,
    required this.username,
    required this.serviceType,
    required this.rating,
    this.imageUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showSellerDetails(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة البائع
              CircleAvatar(
                radius: 30,
                backgroundColor: accentColor.withOpacity(0.2),
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? Icon(
                        Icons.person,
                        color: accentColor,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // معلومات البائع
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo',
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'نوع الخدمة: $serviceType',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // زر المراسلة
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text(
                          'مراسلة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _startChat(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عرض تفاصيل البائع
  void _showSellerDetails(BuildContext context) {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'معلومات البائع',
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
            
            // معلومات البائع
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: accentColor.withOpacity(0.2),
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? Icon(
                        Icons.person,
                        color: accentColor,
                        size: 50,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            if (username.isNotEmpty)
              Center(
                child: Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // معلومات إضافية
            _buildInfoItem(
              icon: Icons.category_outlined,
              title: 'نوع الخدمة',
              value: serviceType,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 16),
            
            // يمكن إضافة المزيد من المعلومات هنا
            
            const Spacer(),
            
            // زر المراسلة
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text(
                  'مراسلة البائع',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _startChat(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بدء محادثة مع البائع
  void _startChat(BuildContext context) {
    if (currentUserId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // التحقق من وجود محادثة سابقة
    FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get()
        .then((snapshot) {
      String? conversationId;
      
      // البحث عن محادثة موجودة بين المستخدم الحالي والبائع
      for (var doc in snapshot.docs) {
        final conversation = doc.data();
        final participants = conversation['participants'] as List<dynamic>;
        
        if (participants.contains(sellerId)) {
          conversationId = doc.id;
          break;
        }
      }
      
      if (conversationId != null) {
        // فتح المحادثة الموجودة
        _openChatScreen(context, conversationId);
      } else {
        // إنشاء محادثة جديدة
        FirebaseFirestore.instance.collection('conversations').add({
          'participants': [currentUserId, sellerId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        }).then((docRef) {
          _openChatScreen(context, docRef.id);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // فتح شاشة المحادثة
  void _openChatScreen(BuildContext context, String conversationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          sellerName: name,
          sellerId: sellerId,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  // بناء عنصر معلومات
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String sellerName;
  final String sellerId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.sellerName,
    required this.sellerId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
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
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
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
      final DocumentReference conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId);
      
      // الحصول على مرجع مجموعة الرسائل داخل المحادثة
      final CollectionReference messagesRef = conversationRef.collection('messages');
      
      // إضافة الرسالة الجديدة
      await messagesRef.add({
        'text': messageText,
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // تحديث آخر رسالة ووقتها في المحادثة
      await conversationRef.update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': widget.currentUserId,
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
          widget.sellerName,
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
              stream: FirebaseFirestore.instance
                  .collection('conversations')
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
                    final isSentByMe = message['senderId'] == widget.currentUserId;
                    
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

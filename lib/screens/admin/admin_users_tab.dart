import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  String _searchQuery = '';
  String _selectedUserType = 'الكل';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // شريط البحث والفلترة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // حقل البحث
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مستخدم...',
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
                
                // فلترة نوع المستخدم
                Row(
                  children: [
                    const Text(
                      'نوع المستخدم:',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedUserType,
                        isExpanded: true,
                        items: ['الكل', 'customer', 'seller'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value == 'customer' ? 'زبون' : value == 'seller' ? 'بائع' : value,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedUserType = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // قائمة المستخدمين
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredUsersStream(),
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
                        Icon(Icons.people_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد مستخدمون',
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
                
                final users = snapshot.data!.docs;
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    
                    return UserCard(
                      user: user,
                      userId: userId,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      accentColor: accentColor,
                      onUserAction: (action) => _handleUserAction(action, userId, user),
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
  
  Stream<QuerySnapshot> _getFilteredUsersStream() {
    Query query = _usersCollection;
    
    // فلترة حسب نوع المستخدم
    if (_selectedUserType != 'الكل') {
      query = query.where('role', isEqualTo: _selectedUserType);
    }
    
    return query.snapshots();
  }
  
  void _handleUserAction(String action, String userId, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        _showUserDetails(userId, user);
        break;
      case 'edit':
        _showEditUserDialog(userId, user);
        break;
      case 'delete':
        _showDeleteConfirmation(userId);
        break;
      case 'toggle_status':
        _toggleUserStatus(userId, user);
        break;
    }
  }
  
  void _showUserDetails(String userId, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل المستخدم', style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الاسم', user['name'] ?? 'غير محدد'),
              _buildDetailRow('البريد الإلكتروني', user['email'] ?? 'غير محدد'),
              _buildDetailRow('رقم الهاتف', user['phone'] ?? 'غير محدد'),
              _buildDetailRow('العنوان', user['address'] ?? 'غير محدد'),
              _buildDetailRow('نوع الحساب', user['role'] ?? 'غير محدد'),
              _buildDetailRow('الحالة', user['isActive'] == true ? 'نشط' : 'محظور'),
              if (user['role'] == 'seller') ...[
                const Divider(),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('products')
                      .where('sellerId', isEqualTo: userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildDetailRow('عدد المنتجات', snapshot.data!.docs.length.toString());
                    }
                    return _buildDetailRow('عدد المنتجات', 'جاري التحميل...');
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditUserDialog(String userId, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final addressController = TextEditingController(text: user['address'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المستخدم', style: TextStyle(fontFamily: 'Cairo')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: TextStyle(fontFamily: 'Cairo'),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _usersCollection.doc(userId).update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تعديل المستخدم بنجاح'),
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
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذا المستخدم؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _usersCollection.doc(userId).delete();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المستخدم بنجاح'),
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
  
  void _toggleUserStatus(String userId, Map<String, dynamic> user) async {
    try {
      final bool currentStatus = user['isActive'] ?? true;
      await _usersCollection.doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'تم حظر المستخدم' : 'تم إلغاء حظر المستخدم'),
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

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Function(String) onUserAction;

  const UserCard({
    super.key,
    required this.user,
    required this.userId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.onUserAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = user['isActive'] ?? true;
    final String userType = user['role'] ?? 'customer';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: userType == 'seller' ? secondaryColor : primaryColor,
          child: Icon(
            userType == 'seller' ? Icons.store : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          user['name'] ?? 'مستخدم',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? 'لا يوجد بريد إلكتروني',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: userType == 'seller' ? secondaryColor : primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userType == 'seller' ? 'بائع' : 'زبون',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'محظور',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onUserAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('عرض التفاصيل', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(isActive ? Icons.block : Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'حظر المستخدم' : 'إلغاء الحظر',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
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
      ),
    );
  }
}

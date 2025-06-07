// تحديث admin_dashboard.dart لإضافة الصفحات الجديدة
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_users_tab.dart';
import 'admin_courses_tab.dart';
import 'admin_products_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_analytics_tab.dart';
import 'admin_notifications_tab.dart'; // إضافة الإشعارات
import 'admin_profile_tab.dart'; // إضافة الملف الشخصي

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _tabs = [
    const AdminAnalyticsTab(),
    const AdminUsersTab(),
    const AdminProductsTab(),
    const AdminCoursesTab(),
    const AdminOrdersTab(),
    const AdminNotificationsTab(), // إضافة صفحة الإشعارات
    const AdminProfileTab(), // إضافة صفحة الملف الشخصي
  ];

  final List<String> _titles = [
    'الإحصائيات',
    'المستخدمون',
    'المنتجات',
    'الدورات',
    'الطلبات',
    'الإشعارات', // إضافة عنوان الإشعارات
    'الملف الشخصي', // إضافة عنوان الملف الشخصي
  ];
  
  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.supervisor_account_outlined,
    Icons.inventory_outlined,
    Icons.school_outlined,
    Icons.receipt_long_outlined,
    Icons.notifications_outlined, // إضافة أيقونة الإشعارات
    Icons.person_outlined, // إضافة أيقونة الملف الشخصي
  ];
  
  final List<IconData> _selectedIcons = [
    Icons.dashboard,
    Icons.supervisor_account,
    Icons.inventory,
    Icons.school,
    Icons.receipt_long,
    Icons.notifications, // إضافة أيقونة الإشعارات المحددة
    Icons.person, // إضافة أيقونة الملف الشخصي المحددة
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
    
    _ensureCollectionsExist().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  Future<void> _ensureCollectionsExist() async {
    try {
      final List<String> requiredCollections = [
        'users',
        'products',
        'trainings',
        'orders',
        'sales',
        'notifications', // إضافة مجموعة الإشعارات
      ];
      
      for (String collection in requiredCollections) {
        await _ensureCollectionExists(collection);
      }
      
      print('تم التحقق من جميع المجموعات الأساسية بنجاح');
    } catch (e) {
      print('حدث خطأ أثناء التحقق من المجموعات: $e');
    }
  }
  
  Future<void> _ensureCollectionExists(String collectionName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة $collectionName لأول مرة');
        
        DocumentReference tempDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .add({
              'temp': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
        
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة $collectionName: $e');
    }
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
            backgroundColor: secondaryColor,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _tabs[_selectedIndex],
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

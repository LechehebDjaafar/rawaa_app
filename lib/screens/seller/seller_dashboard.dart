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
  final Color secondaryColor =  const Color.fromARGB(255, 78, 94, 243); // أخضر داكن
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

import 'package:flutter/material.dart';
import 'seller_home_tab.dart';
import 'seller_products_tab.dart';
import 'seller_orders_tab.dart';
import 'seller_messages_tab.dart';

import 'seller_profile_tab.dart';
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // ألوان متناسقة مع مشروع الري والهيدروليك
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF64B5F6); // أزرق فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  
  final List _tabs = [
    const SellerHomeTab(),
    const SellerProductsTab(),
    const SellerOrdersTab(),
    const SellerMessagesTab(),
    const SellerProfileTab(),
  ];

  final List _titles = [
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // إضافة وظيفة الإشعارات هنا
            },
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
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
          ),
          onTap: _onItemTapped,
          items: List.generate(
            _titles.length,
            (index) => BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == index ? _selectedIcons[index] : _icons[index],
              ),
              label: _titles[index],
              tooltip: _titles[index],
            ),
          ),
        ),
      ),
    );
  }
}

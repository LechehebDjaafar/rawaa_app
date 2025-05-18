import 'package:flutter/material.dart';
import 'seller_home_tab.dart';
import 'seller_products_tab.dart';
import 'seller_orders_tab.dart';
import 'seller_messages_tab.dart';
import 'seller_reviews_tab.dart';
import 'seller_profile_tab.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    SellerHomeTab(),
    SellerProductsTab(),
    SellerOrdersTab(),
    SellerMessagesTab(),
    SellerReviewsTab(),
    SellerProfileTab(),
  ];

  final List<String> _titles = [
    'لوحة التحكم',
    'منتجاتي',
    'الطلبات',
    'الرسائل',
    'التقييمات',
    'الملف الشخصي',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF2F5233),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2F5233),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'منتجاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'الرسائل'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'التقييمات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}

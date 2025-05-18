import 'package:flutter/material.dart';
import 'admin_users_tab.dart';
import 'admin_courses_tab.dart';
import 'admin_products_tab.dart';
import 'admin_ads_tab.dart';
import 'admin_subscriptions_tab.dart';
import 'admin_competitions_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    AdminUsersTab(),
    AdminCoursesTab(),
    AdminProductsTab(),
    AdminAdsTab(),
    AdminSubscriptionsTab(),
    AdminCompetitionsTab(),

  ];

  final List<String> _titles = [
    'المستخدمون',
    'الدورات',
    'المنتجات',
    'الإعلانات',
    'الاشتراكات',
    'المسابقات',

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2C3E50),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.supervisor_account), label: 'المستخدمون'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'الدورات'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'الإعلانات'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: 'الاشتراكات'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'المسابقات'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'المنتدى'),
        ],
      ),
    );
  }
}

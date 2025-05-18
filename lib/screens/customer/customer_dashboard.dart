import 'package:flutter/material.dart';
import 'products_tab.dart';
import 'cart_tab.dart';
import 'favorites_tab.dart';
import 'training_tab.dart';
import 'forum_tab.dart';
import 'profile_tab.dart';
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    ProductsTab(),
    TrainingTab(),
    FavoritesTab(),
    CartTab(),
    ForumTab(),
    ProfileTab(),
  ];

  final List<String> _titles = [
    'المنتجات',
    'الدورات التكوينية',
    'المفضلة',
    'عربة الشراء',
    'منتدى النقاش',
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
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'منتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'دورات'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'مفضلة'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'السلة'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'منتدى'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'), 
        ],
      ),
    );
  }
}

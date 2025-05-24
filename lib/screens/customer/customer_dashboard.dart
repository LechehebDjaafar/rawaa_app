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

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color.fromARGB(255, 89, 138, 243); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ
  
  final List _tabs = [
    const ProductsTab(),
    const TrainingTab(),
    const FavoritesTab(),
    const CartTab(),
    const ForumTab(),
    const ProfileTab(),
  ];

  final List _titles = [
    'المنتجات',
    'الدورات التكوينية',
    'المفضلة',
    'عربة الشراء',
    'منتدى النقاش',
    'الملف الشخصي',
  ];
  
  final List<IconData> _icons = [
    Icons.storefront_outlined,
    Icons.school_outlined,
    Icons.favorite_outline,
    Icons.shopping_cart_outlined,
    Icons.forum_outlined,
    Icons.person_outline,
  ];
  
  final List<IconData> _selectedIcons = [
    Icons.storefront,
    Icons.school,
    Icons.favorite,
    Icons.shopping_cart,
    Icons.forum,
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
        backgroundColor: secondaryColor,
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
              label: _titles[index].split(' ')[0],
              tooltip: _titles[index],
            ),
          ),
        ),
      ),
    );
  }
}

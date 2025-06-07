import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'products_tab.dart';
import 'cart_tab.dart';
import 'favorites_tab.dart';
import 'training_tab.dart';
import 'forum_tab.dart';
import 'profile_tab.dart';
import 'customer_notifications_screen.dart'; // إضافة شاشة الإشعارات

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color.fromARGB(255, 78, 94, 243); // أخضر داكن - تصحيح اللون
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ

  final List<Widget> _tabs = [
    const ProductsTab(),
    const TrainingTab(),
    const FavoritesTab(),
    const CartTab(),
    const ForumTab(),
    const ProfileTab(),
  ];

  final List<String> _titles = [
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
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
                          builder: (context) => const CustomerNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  // عداد الإشعارات غير المقروءة
                  if (_currentUserId != 'guest')
                    Positioned(
                      right: 8,
                      top: 8,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('customer_notifications')
                            .where('customerId', isEqualTo: _currentUserId)
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
                              color: alertColor,
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
                                fontFamily: 'Cairo',
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
                  label: _titles[index].split(' ')[0],
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

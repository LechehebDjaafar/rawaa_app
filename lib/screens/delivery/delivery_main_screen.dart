// lib/delivery/delivery_main_screen.dart
import 'package:flutter/material.dart';
// قم باستيراد ملفات التبويبات التي سننشئها الآن
import 'delivery_dashboard_tab.dart'; 
import 'delivery_orders_tab.dart';
import 'delivery_history_tab.dart';
import 'delivery_profile_tab.dart';


class DeliveryMainScreen extends StatefulWidget {
  const DeliveryMainScreen({super.key});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DeliveryDashboardTab(),
    DeliveryOrdersTab(),
    DeliveryHistoryTab(),
    DeliveryProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الأرشيف'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'ملفي'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // مهم لظهور كل الأيقونات
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rawaa_app/screens/admin/admin_dashboard.dart';
import 'package:rawaa_app/screens/customer/certificates_tab.dart';
import 'package:rawaa_app/screens/customer/customer_dashboard.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';
import 'package:rawaa_app/screens/customer/training_details.dart';
import 'package:rawaa_app/screens/seller/seller_dashboard.dart';
import 'firebase_options.dart';

// استيراد الشاشات
import 'features/splash/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/select_account_type_screen.dart';
import 'features/auth/screens/register_customer_screen.dart';
import 'features/auth/screens/register_seller_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // التحقق من حالة تسجيل الدخول
  final prefs = await SharedPreferences.getInstance();
  final String? userType = prefs.getString('user_type');
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  
  runApp(MyApp(isLoggedIn: isLoggedIn, userType: userType));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userType;
  
  const MyApp({super.key, required this.isLoggedIn, this.userType});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rawaa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // تحديد الشاشة الأولى بناءً على حالة تسجيل الدخول
      initialRoute: _getInitialRoute(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/select_account_type': (context) => const SelectAccountTypeScreen(),
        '/register_customer': (context) => const RegisterCustomerScreen(),
        '/register_seller': (context) => const RegisterSellerScreen(),
        '/customer_dashboard': (context) => const CustomerDashboard(),
        '/seller_dashboard': (context) => const SellerDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/product_details': (context) => const ProductDetails(productId: '',),
        '/training_details': (context) => const TrainingDetails(),
        '/certificates': (context) => const CertificatesTab(),
      },
    );
  }
  
  // تحديد الشاشة الأولى بناءً على حالة تسجيل الدخول ونوع المستخدم
  String _getInitialRoute() {
    if (isLoggedIn) {
      switch (userType) {
        case 'seller':
          return '/seller_dashboard';
        case 'customer':
          return '/customer_dashboard';
        case 'admin':
          return '/admin_dashboard';
        default:
          return '/onboarding';
      }
    } else {
      return '/onboarding';
    }
  }
}

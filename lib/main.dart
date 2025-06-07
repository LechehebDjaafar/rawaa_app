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

// استيراد شاشات المصادقة
import 'features/splash/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/select_account_type_screen.dart';
import 'features/auth/screens/register_customer_screen.dart';
import 'features/auth/screens/register_seller_screen.dart';

// استيراد شاشات عمال التوصيل الجديدة
import 'features/auth/screens/delivery_register_screen.dart';
import 'screens/delivery/delivery_main_screen.dart';
import 'screens/delivery/delivery_order_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('خطأ في تهيئة Firebase: $e');
  }
  
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
        // ألوان التطبيق المحدثة
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1976D2), // أزرق مائي
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        fontFamily: 'Cairo',
        
        // تصميم AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        // تصميم الأزرار
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // تصميم البطاقات
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        
        // تصميم حقول الإدخال
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        
        // تصميم BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF1976D2),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontFamily: 'Cairo'),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      
      // تحديد الشاشة الأولى بناءً على حالة تسجيل الدخول
      initialRoute: _getInitialRoute(),
      
      // جميع المسارات في التطبيق
      routes: {
        // شاشات البداية والمصادقة
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/select_account_type': (context) => const SelectAccountTypeScreen(),
        
        // شاشات التسجيل
        '/register_customer': (context) => const RegisterCustomerScreen(),
        '/register_seller': (context) => const RegisterSellerScreen(),
        '/register_delivery': (context) => const DeliveryRegisterScreen(), // جديد
        
        // لوحات التحكم الرئيسية
        '/customer_dashboard': (context) => const CustomerDashboard(),
        '/seller_dashboard': (context) => const SellerDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/delivery_main': (context) => const DeliveryMainScreen(), // جديد
        
        // شاشات تفاصيل المنتجات والدورات
        '/product_details': (context) => const ProductDetails(productId: ''),
        '/training_details': (context) => TrainingDetails(
          trainingId: '', 
          training: const {},
        ),
        '/certificates': (context) => const CertificatesTab(),
        
        // شاشات عمال التوصيل
        '/delivery_order_details': (context) => const DeliveryOrderDetailsScreen(order: {},), // جديد
      },
      
      // معالج المسارات غير المعروفة
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('صفحة غير موجودة'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'عذراً، الصفحة المطلوبة غير موجودة',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // تحديد الشاشة الأولى بناءً على حالة تسجيل الدخول ونوع المستخدم
  String _getInitialRoute() {
    if (isLoggedIn && userType != null) {
      switch (userType) {
        case 'seller':
          return '/seller_dashboard';
        case 'customer':
          return '/customer_dashboard';
        case 'admin':
          return '/admin_dashboard';
        case 'delivery': // جديد
          return '/delivery_main';
        default:
          // في حالة وجود نوع مستخدم غير معروف، ارجع للبداية
          return '/onboarding';
      }
    } else {
      // المستخدم غير مسجل دخول
      return '/onboarding';
    }
  }
}

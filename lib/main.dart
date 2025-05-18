import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rawaa_app/screens/admin/admin_dashboard.dart';
import 'package:rawaa_app/screens/customer/certificates_tab.dart';
import 'package:rawaa_app/screens/customer/customer_dashboard.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';
import 'package:rawaa_app/screens/customer/training_details.dart';
import 'package:rawaa_app/screens/seller/seller_dashboard.dart';
import 'firebase_options.dart';

// استيراد الشاشات الجديدة
import 'features/splash/welcome_screen1.dart';
import 'features/splash/welcome_screen2.dart';
import 'features/splash/welcome_screen3.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/select_account_type_screen.dart';
import 'features/auth/screens/register_customer_screen.dart';
import 'features/auth/screens/register_seller_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rawaa App Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/welcome1',
      routes: {
        '/welcome1': (context) => const WelcomeScreen1(),
        '/welcome2': (context) => const WelcomeScreen2(),
        '/welcome3': (context) => const WelcomeScreen3(),
        '/login': (context) => const LoginScreen(),
        '/select_account_type': (context) => const SelectAccountTypeScreen(),
        '/register_customer': (context) => const RegisterCustomerScreen(),
        '/register_seller': (context) => const RegisterSellerScreen(),
        '/customer_dashboard': (context) => const CustomerDashboard(),
        '/seller_dashboard': (context) => const SellerDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/product_details': (context) => const ProductDetails(),
        '/training_details': (context) => const TrainingDetails(),
        '/certificates': (context) => const CertificatesTab(),
      },

    );
  }
}

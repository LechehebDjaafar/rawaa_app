import 'package:flutter/material.dart';

class SelectAccountTypeScreen extends StatelessWidget {
  const SelectAccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ألوان متناسقة مع مشروع الري والهيدروليك
    final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
    final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
    final Color deliveryColor = const Color(0xFFFF6B35); // برتقالي للتوصيل
    final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'اختيار نوع الحساب',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 600;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (isSmallScreen ? 32 : 48),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // عنوان الصفحة
                      Text(
                        'مرحبًا بك في تطبيق RAWAA',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        'اختر نوع الحساب الذي تريد إنشاءه',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[700],
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 30 : 40),
                      
                      // بطاقة حساب الزبون
                      _buildAccountTypeCard(
                        context: context,
                        title: 'حساب زبون',
                        subtitle: 'تسوق واستفد من الخدمات والدورات التدريبية',
                        icon: Icons.person,
                        color: primaryColor,
                        route: '/register_customer',
                        isSmallScreen: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // بطاقة حساب البائع
                      _buildAccountTypeCard(
                        context: context,
                        title: 'حساب بائع',
                        subtitle: 'أضف منتجاتك وخدماتك وابدأ البيع',
                        icon: Icons.store,
                        color: secondaryColor,
                        route: '/register_seller',
                        isSmallScreen: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // بطاقة حساب عامل التوصيل (جديد)
                      _buildAccountTypeCard(
                        context: context,
                        title: 'حساب عامل توصيل',
                        subtitle: 'انضم إلى فريق التوصيل واربح المال',
                        icon: Icons.delivery_dining,
                        color: deliveryColor,
                        route: '/register_delivery',
                        isSmallScreen: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      
                      // زر العودة لتسجيل الدخول
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_new,
                              size: isSmallScreen ? 14 : 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'لديك حساب بالفعل؟ تسجيل الدخول',
                              style: TextStyle(
                                color: primaryColor,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 13 : 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // دالة لإنشاء بطاقة نوع الحساب مع تحسينات للشاشات الصغيرة
  Widget _buildAccountTypeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 32 : 40,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(
                    icon,
                    size: isSmallScreen ? 32 : 40,
                    color: color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, route),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'اختيار',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

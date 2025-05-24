import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  // بيانات صفحات الترحيب
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'مرحبًا بك في تطبيق RAWAA',
      'description': 'منصة متكاملة لخدمات الري والهيدروليك في الجزائر',
      'icon': Icons.water_drop_rounded,
      'color1': const Color(0xFF1976D2),
      'color2': const Color(0xFF64B5F6),
    },
    {
      'title': 'تسوق بسهولة',
      'description': 'اكتشف منتجات الري والهيدروليك وقم بالشراء بكل سهولة',
      'icon': Icons.shopping_cart_rounded,
      'color1': const Color(0xFF2F5233),
      'color2': const Color(0xFF4CAF50),
    },
    {
      'title': 'تعلم واكتسب المهارات',
      'description': 'دورات تدريبية متخصصة في مجال الري والهيدروليك',
      'icon': Icons.school_rounded,
      'color1': const Color(0xFFFF8A65),
      'color2': const Color(0xFFFFAB91),
    },
  ];

  // مؤشرات الصفحات
  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  // تصميم المؤشر
  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // تخزين حالة عرض شاشة الترحيب
  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // صفحات الترحيب
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _onboardingData[index]['color1'],
                      _onboardingData[index]['color2'],
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // شعار اللوغو الخاص بك في الأعلى
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            // إذا لم يتم العثور على الصورة، عرض أيقونة بديلة
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.water_drop_rounded,
                              size: 60,
                              color: _onboardingData[index]['color1'],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // أيقونة بدلاً من الصورة
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _onboardingData[index]['icon'],
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // عنوان الترحيب
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _onboardingData[index]['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // وصف الترحيب
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _onboardingData[index]['description'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // زر تخطي في الأعلى
          Positioned(
            top: 50,
            right: 20,
            child: _currentPage != _numPages - 1
                ? TextButton(
                    onPressed: () async {
                      await _markOnboardingComplete();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
          
          // مؤشرات الصفحات والأزرار في الأسفل
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageIndicator(),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage == _numPages - 1) {
                          await _markOnboardingComplete();
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _onboardingData[_currentPage]['color1'],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == _numPages - 1 ? 'ابدأ الآن' : 'التالي',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

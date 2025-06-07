import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // الحصول على معلومات الشاشة
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenHeight < 600;
          final isVerySmallScreen = screenHeight < 500;
          
          return Stack(
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
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: isVerySmallScreen ? 10 : 20,
                        ),
                        child: Column(
                          children: [
                            // مساحة علوية مرنة
                            Flexible(
                              flex: isSmallScreen ? 1 : 2,
                              child: Container(),
                            ),
                            
                            // شعار اللوغو
                            Container(
                              width: isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120),
                              height: isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120),
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
                                  width: isVerySmallScreen ? 50 : (isSmallScreen ? 65 : 80),
                                  height: isVerySmallScreen ? 50 : (isSmallScreen ? 65 : 80),
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.water_drop_rounded,
                                    size: isVerySmallScreen ? 40 : (isSmallScreen ? 50 : 60),
                                    color: _onboardingData[index]['color1'],
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                            
                            // أيقونة الصفحة
                            Container(
                              width: isVerySmallScreen ? 100 : (isSmallScreen ? 120 : 150),
                              height: isVerySmallScreen ? 100 : (isSmallScreen ? 120 : 150),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _onboardingData[index]['icon'],
                                size: isVerySmallScreen ? 50 : (isSmallScreen ? 60 : 80),
                                color: Colors.white,
                              ),
                            ),
                            
                            SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                            
                            // عنوان الترحيب
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _onboardingData[index]['title'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isVerySmallScreen ? 10 : 16),
                            
                            // وصف الترحيب
                            Flexible(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                                child: Text(
                                  _onboardingData[index]['description'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                                    fontFamily: 'Cairo',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            
                            // مساحة سفلية مرنة
                            Flexible(
                              flex: isSmallScreen ? 1 : 2,
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // زر تخطي في الأعلى
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: _currentPage != _numPages - 1
                    ? SafeArea(
                        child: TextButton(
                          onPressed: () async {
                            await _markOnboardingComplete();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          child: Text(
                            'تخطي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallScreen ? 14 : 16,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
              
              // مؤشرات الصفحات والأزرار في الأسفل
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: isVerySmallScreen ? 15 : 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // مؤشرات الصفحات
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildPageIndicator(),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 20 : 30),
                        
                        // زر التالي/ابدأ الآن
                        SizedBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 45 : 50,
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
                              elevation: 5,
                              shadowColor: Colors.black.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: FittedBox(
                              child: Text(
                                _currentPage == _numPages - 1 ? 'ابدأ الآن' : 'التالي',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 16 : 18,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

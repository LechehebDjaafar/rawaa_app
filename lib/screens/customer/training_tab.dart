import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rawaa_app/screens/customer/training_details.dart';

class TrainingTab extends StatefulWidget {
  const TrainingTab({super.key});

  @override
  State<TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<TrainingTab> with SingleTickerProviderStateMixin {
  final CollectionReference _trainingsCollection = FirebaseFirestore.instance.collection('trainings');
  bool _isLoading = true;
  String _selectedFilter = 'الكل';

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _ensureTrainingsCollectionExists().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود مجموعة الدورات وإنشائها إذا لم تكن موجودة
  Future<void> _ensureTrainingsCollectionExists() async {
    try {
      final snapshot = await _trainingsCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة الدورات لأول مرة');
        DocumentReference tempDoc = await _trainingsCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await tempDoc.delete();
        
        // إضافة دورات تجريبية
        await _createSampleTrainings();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة الدورات: $e');
    }
  }

  // إنشاء دورات تجريبية
  Future<void> _createSampleTrainings() async {
    final sampleTrainings = [
      {
        'title': 'دورة صيانة مضخات الري',
        'description': 'تعلم أساسيات صيانة المضخات مع شهادة معتمدة. الدورة تشمل دروس نظرية وتطبيقية مباشرة مع مدربين محترفين.',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'time': '10:00',
        'duration': '4 ساعات',
        'level': 'مبتدئ',
        'price': 0.0,
        'videoUrls': [
          'https://example.com/video1.mp4',
          'https://example.com/video2.mp4',
          'https://example.com/video3.mp4',
        ],
        'examQuestions': [
          {
            'question': 'ما هي الخطوة الأولى في صيانة المضخة؟',
            'options': ['فصل الكهرباء', 'تنظيف المضخة', 'فحص الزيت', 'تشغيل المضخة'],
            'correctAnswer': 0,
          },
          {
            'question': 'كم مرة يجب تغيير زيت المضخة؟',
            'options': ['كل شهر', 'كل 3 أشهر', 'كل 6 أشهر', 'كل سنة'],
            'correctAnswer': 2,
          },
        ],
        'passingScore': 70,
        'registeredUsers': [],
        'completedUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'دورة تركيب أنظمة الري بالتنقيط',
        'description': 'دورة شاملة لتعلم تركيب وصيانة أنظمة الري بالتنقيط الحديثة مع التطبيق العملي.',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'time': '14:00',
        'duration': '6 ساعات',
        'level': 'متوسط',
        'price': 150.0,
        'videoUrls': [
          'https://example.com/drip1.mp4',
          'https://example.com/drip2.mp4',
          'https://example.com/drip3.mp4',
          'https://example.com/drip4.mp4',
        ],
        'examQuestions': [
          {
            'question': 'ما هو الضغط المناسب لنظام الري بالتنقيط؟',
            'options': ['1-2 بار', '3-4 بار', '5-6 بار', '7-8 بار'],
            'correctAnswer': 0,
          },
          {
            'question': 'ما هي فائدة الفلاتر في نظام الري؟',
            'options': ['توفير المياه', 'منع انسداد النقاطات', 'زيادة الضغط', 'تقليل التكلفة'],
            'correctAnswer': 1,
          },
        ],
        'passingScore': 75,
        'registeredUsers': [],
        'completedUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'دورة الزراعة المائية للمبتدئين',
        'description': 'تعلم أساسيات الزراعة المائية وكيفية إنشاء نظام زراعي مائي منزلي بسيط وفعال.',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 21))),
        'time': '16:00',
        'duration': '3 ساعات',
        'level': 'مبتدئ',
        'price': 100.0,
        'videoUrls': [
          'https://example.com/hydro1.mp4',
          'https://example.com/hydro2.mp4',
        ],
        'examQuestions': [
          {
            'question': 'ما هي الزراعة المائية؟',
            'options': ['زراعة في الماء فقط', 'زراعة بدون تربة', 'زراعة تحت الماء', 'زراعة بالمياه المالحة'],
            'correctAnswer': 1,
          },
        ],
        'passingScore': 60,
        'registeredUsers': [],
        'completedUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var training in sampleTrainings) {
      await _trainingsCollection.add(training);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenHeight < 500;
        
        return Container(
          color: backgroundColor,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // شريط الفلترة - مرن
                      _buildFilterBar(isVerySmallScreen),
                      
                      // قائمة الدورات - مرنة
                      Expanded(
                        child: _buildTrainingsList(isVerySmallScreen, isSmallScreen),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // بناء شريط الفلترة
  Widget _buildFilterBar(bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      child: Row(
        children: [
          Text(
            'فلترة الدورات:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: isVerySmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(width: isVerySmallScreen ? 8 : 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: const SizedBox(),
                items: ['الكل', 'مبتدئ', 'متوسط', 'متقدم', 'مجاني', 'مدفوع']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 12 : 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء قائمة الدورات المرنة
  Widget _buildTrainingsList(bool isVerySmallScreen, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredTrainingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isVerySmallScreen ? 50 : 60,
                  color: Colors.red[300],
                ),
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 14 : 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: isVerySmallScreen ? 60 : 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                Text(
                  'لا توجد دورات متاحة حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 6 : 8),
                Text(
                  'سيتم إضافة دورات تكوينية قريباً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 12 : 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final trainings = snapshot.data!.docs;
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: primaryColor,
          child: ListView.separated(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            itemCount: trainings.length,
            separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 12 : 16),
            itemBuilder: (context, index) {
              final training = trainings[index].data() as Map<String, dynamic>;
              final trainingId = trainings[index].id;
              
              return TrainingCard(
                trainingId: trainingId,
                training: training,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accentColor: accentColor,
                alertColor: alertColor,
                isVerySmallScreen: isVerySmallScreen,
                isSmallScreen: isSmallScreen,
              );
            },
          ),
        );
      },
    );
  }

  // الحصول على ستريم الدورات المفلترة
  Stream<QuerySnapshot> _getFilteredTrainingsStream() {
    Query query = _trainingsCollection.orderBy('date', descending: false);
    
    switch (_selectedFilter) {
      case 'مبتدئ':
        query = query.where('level', isEqualTo: 'مبتدئ');
        break;
      case 'متوسط':
        query = query.where('level', isEqualTo: 'متوسط');
        break;
      case 'متقدم':
        query = query.where('level', isEqualTo: 'متقدم');
        break;
      case 'مجاني':
        query = query.where('price', isEqualTo: 0.0);
        break;
      case 'مدفوع':
        query = query.where('price', isGreaterThan: 0.0);
        break;
    }
    
    return query.snapshots();
  }

  // تنسيق التاريخ
  String _formatDate(dynamic date) {
    if (date == null) return 'غير محدد';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}

// بطاقة الدورة المحسنة والمرنة
class TrainingCard extends StatelessWidget {
  final String trainingId;
  final Map<String, dynamic> training;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color alertColor;
  final bool isVerySmallScreen;
  final bool isSmallScreen;

  const TrainingCard({
    super.key,
    required this.trainingId,
    required this.training,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.alertColor,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isRegistered = training['registeredUsers'] != null &&
        (training['registeredUsers'] as List).contains(userId);
    final isCompleted = training['completedUsers'] != null &&
        (training['completedUsers'] as List).contains(userId);
    final price = training['price'] ?? 0.0;
    final isFree = price == 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingDetails(
                trainingId: trainingId,
                training: training,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;
            final imageHeight = isVerySmallScreen ? 100.0 : 120.0;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الدورة مع شارة السعر
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: isVerySmallScreen ? 40 : 50,
                          color: accentColor,
                        ),
                      ),
                      
                      // شارة السعر
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 6 : 8,
                            vertical: isVerySmallScreen ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isFree ? Colors.green : primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isFree ? 'مجاني' : '${price.toInt()} دج',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                      
                      // شارة المستوى
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallScreen ? 6 : 8,
                            vertical: isVerySmallScreen ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(training['level'] ?? 'مبتدئ'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            training['level'] ?? 'مبتدئ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // معلومات الدورة
                Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان الدورة
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: primaryColor,
                            size: isVerySmallScreen ? 18 : 20,
                          ),
                          SizedBox(width: isVerySmallScreen ? 6 : 8),
                          Expanded(
                            child: Text(
                              training['title'] ?? 'دورة تكوينية',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      
                      // وصف الدورة
                      Text(
                        training['description'] ?? 'لا يوجد وصف',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 11 : 13,
                          color: Colors.grey[700],
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 8 : 12),
                      
                      // تفاصيل الدورة
                      Wrap(
                        spacing: isVerySmallScreen ? 8 : 12,
                        runSpacing: isVerySmallScreen ? 4 : 6,
                        children: [
                          _buildInfoChip(
                            Icons.calendar_today,
                            _formatDate(training['date']),
                            isVerySmallScreen,
                          ),
                          _buildInfoChip(
                            Icons.access_time,
                            training['time'] ?? '00:00',
                            isVerySmallScreen,
                          ),
                          _buildInfoChip(
                            Icons.timer,
                            training['duration'] ?? '1 ساعة',
                            isVerySmallScreen,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                      
                      // أزرار التفاعل
                      _buildActionButtons(context, isRegistered, isCompleted),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // بناء شريحة المعلومات
  Widget _buildInfoChip(IconData icon, String text, bool isVerySmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isVerySmallScreen ? 12 : 14,
          color: secondaryColor,
        ),
        SizedBox(width: isVerySmallScreen ? 2 : 4),
        Text(
          text,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 9 : 11,
            fontFamily: 'Cairo',
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  // بناء أزرار التفاعل
  Widget _buildActionButtons(BuildContext context, bool isRegistered, bool isCompleted) {
    if (isCompleted) {
      return Container(
        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.green,
              size: isVerySmallScreen ? 16 : 20,
            ),
            SizedBox(width: isVerySmallScreen ? 6 : 8),
            Expanded(
              child: Text(
                'تم إكمال الدورة بنجاح',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: isVerySmallScreen ? 11 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isRegistered) {
      return Container(
        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_user,
              color: accentColor,
              size: isVerySmallScreen ? 16 : 20,
            ),
            SizedBox(width: isVerySmallScreen ? 6 : 8),
            Expanded(
              child: Text(
                'أنت مسجل في هذه الدورة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontSize: isVerySmallScreen ? 11 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: isVerySmallScreen ? 32 : 40,
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.how_to_reg,
          size: isVerySmallScreen ? 14 : 16,
        ),
        label: Text(
          'سجل الآن',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: isVerySmallScreen ? 11 : 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: alertColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          _registerForTraining(context, trainingId);
        },
      ),
    );
  }

  // الحصول على لون المستوى
  Color _getLevelColor(String level) {
    switch (level) {
      case 'مبتدئ':
        return Colors.green;
      case 'متوسط':
        return Colors.orange;
      case 'متقدم':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // تنسيق التاريخ
  String _formatDate(dynamic date) {
    if (date == null) return 'غير محدد';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  // تسجيل في الدورة
  void _registerForTraining(BuildContext context, String trainingId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FirebaseFirestore.instance.collection('trainings').doc(trainingId).update({
      'registeredUsers': FieldValue.arrayUnion([userId]),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التسجيل في الدورة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainingDetails(
            trainingId: trainingId,
            training: training,
          ),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}

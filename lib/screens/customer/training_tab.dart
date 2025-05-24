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
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
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
    
    // التحقق من وجود مجموعة الدورات وإنشائها إذا لم تكن موجودة
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
      // محاولة الحصول على وثيقة واحدة للتحقق من وجود المجموعة
      final snapshot = await _trainingsCollection.limit(1).get();
      
      // إذا لم تكن المجموعة موجودة، سنضيف وثيقة مؤقتة ثم نحذفها
      if (snapshot.docs.isEmpty) {
        print('إنشاء مجموعة الدورات لأول مرة');
        
        // إضافة وثيقة مؤقتة
        DocumentReference tempDoc = await _trainingsCollection.add({
          'temp': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // حذف الوثيقة المؤقتة
        await tempDoc.delete();
      }
    } catch (e) {
      print('خطأ في التحقق من وجود مجموعة الدورات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTrainingsList(),
            ),
    );
  }

  Widget _buildTrainingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _trainingsCollection.orderBy('date', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
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
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد دورات متاحة حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم إضافة دورات تكوينية قريباً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
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
            padding: const EdgeInsets.all(16),
            itemCount: trainings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final training = trainings[index].data() as Map<String, dynamic>;
              final trainingId = trainings[index].id;
              
              return TrainingCard(
                trainingId: trainingId,
                title: training['title'] ?? 'دورة تكوينية',
                description: training['description'] ?? 'لا يوجد وصف',
                date: _formatDate(training['date']),
                time: training['time'] ?? '00:00',
                isRegistered: training['registeredUsers'] != null && 
                    (training['registeredUsers'] as List<dynamic>).contains(FirebaseAuth.instance.currentUser?.uid),
                imageUrl: training['imageUrl'],
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accentColor: accentColor,
                alertColor: alertColor,
              );
            },
          ),
        );
      },
    );
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

class TrainingCard extends StatelessWidget {
  final String trainingId;
  final String title;
  final String description;
  final String date;
  final String time;
  final bool isRegistered;
  final String? imageUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color alertColor;

  const TrainingCard({
    super.key,
    required this.trainingId,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.isRegistered,
    this.imageUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.alertColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingDetails(
                // trainingId: trainingId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الدورة
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    width: double.infinity,
                    color: accentColor.withOpacity(0.2),
                    child: Icon(
                      Icons.school_outlined,
                      size: 60,
                      color: accentColor,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 60,
                  color: accentColor,
                ),
              ),
            
            // معلومات الدورة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isRegistered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.how_to_reg),
                        label: const Text(
                          'سجل الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: alertColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _registerForTraining(context, trainingId);
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user, color: accentColor),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'أنت مسجل في هذه الدورة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            // trainingId: trainingId,
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

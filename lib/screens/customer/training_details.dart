import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TrainingDetails extends StatefulWidget {
  final String trainingId;
  final Map<String, dynamic> training;

  const TrainingDetails({
    super.key,
    required this.trainingId,
    required this.training,
  });

  @override
  State<TrainingDetails> createState() => _TrainingDetailsState();
}

class _TrainingDetailsState extends State<TrainingDetails> with TickerProviderStateMixin {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isRegistered = false;
  bool _isCompleted = false;
  bool _hasPassedExam = false;
  int _currentVideoIndex = 0;
  List<bool> _watchedVideos = [];
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor =  const Color.fromARGB(255, 78, 94, 243);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  // متغيرات للأنيميشن
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkUserStatus();
    _initializeWatchedVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // التحقق من حالة المستخدم
  void _checkUserStatus() {
    final registeredUsers = widget.training['registeredUsers'] as List? ?? [];
    final completedUsers = widget.training['completedUsers'] as List? ?? [];
    
    setState(() {
      _isRegistered = registeredUsers.contains(_currentUserId);
      _isCompleted = completedUsers.contains(_currentUserId);
    });
  }

  // تهيئة قائمة الفيديوهات المشاهدة
  void _initializeWatchedVideos() {
    final videoUrls = widget.training['videoUrls'] as List? ?? [];
    setState(() {
      _watchedVideos = List.filled(videoUrls.length, false);
    });
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
              'تفاصيل الدورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 16 : 18,
              ),
            ),
            backgroundColor: secondaryColor,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
              tabs: const [
                Tab(text: 'نظرة عامة'),
                Tab(text: 'الفيديوهات'),
                Tab(text: 'الاختبار'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(isVerySmallScreen, isSmallScreen),
              _buildVideosTab(isVerySmallScreen, isSmallScreen),
              _buildExamTab(isVerySmallScreen, isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  // تبويب النظرة العامة
  Widget _buildOverviewTab(bool isVerySmallScreen, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة الدورة
          Container(
            height: isVerySmallScreen ? 150 : 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accentColor.withOpacity(0.2),
            ),
            child: Icon(
              Icons.school_outlined,
              size: isVerySmallScreen ? 60 : 80,
              color: accentColor,
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // اسم الدورة
          Text(
            widget.training['title'] ?? 'دورة تكوينية',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 6 : 8),
          
          // تفاصيل الدورة
          Wrap(
            spacing: isVerySmallScreen ? 8 : 16,
            runSpacing: isVerySmallScreen ? 4 : 8,
            children: [
              _buildDetailChip(
                Icons.calendar_today,
                _formatDate(widget.training['date']),
                isVerySmallScreen,
              ),
              _buildDetailChip(
                Icons.access_time,
                widget.training['time'] ?? '00:00',
                isVerySmallScreen,
              ),
              _buildDetailChip(
                Icons.timer,
                widget.training['duration'] ?? '1 ساعة',
                isVerySmallScreen,
              ),
              _buildDetailChip(
                Icons.signal_cellular_alt,
                widget.training['level'] ?? 'مبتدئ',
                isVerySmallScreen,
              ),
            ],
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // وصف الدورة
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وصف الدورة',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 6 : 8),
                Text(
                  widget.training['description'] ?? 'لا يوجد وصف متاح',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 12 : 14,
                    fontFamily: 'Cairo',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // معلومات إضافية
          _buildInfoCard(
            'معلومات الدورة',
            [
              _buildInfoRow(
                Icons.attach_money,
                'السعر',
                widget.training['price'] == 0.0 ? 'مجاني' : '${widget.training['price']} دج',
                isVerySmallScreen,
              ),
              _buildInfoRow(
                Icons.video_library,
                'عدد الفيديوهات',
                '${(widget.training['videoUrls'] as List?)?.length ?? 0} فيديو',
                isVerySmallScreen,
              ),
              _buildInfoRow(
                Icons.quiz,
                'درجة النجاح',
                '${widget.training['passingScore'] ?? 70}%',
                isVerySmallScreen,
              ),
            ],
            isVerySmallScreen,
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : 24),
          
          // أزرار التفاعل
          _buildActionButtons(isVerySmallScreen),
        ],
      ),
    );
  }

  // تبويب الفيديوهات
  Widget _buildVideosTab(bool isVerySmallScreen, bool isSmallScreen) {
    if (!_isRegistered) {
      return _buildNotRegisteredMessage(isVerySmallScreen);
    }

    final videoUrls = widget.training['videoUrls'] as List? ?? [];
    
    if (videoUrls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: isVerySmallScreen ? 60 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Text(
              'لا توجد فيديوهات متاحة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      itemCount: videoUrls.length,
      separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
      itemBuilder: (context, index) {
        return _buildVideoCard(
          index,
          videoUrls[index],
          isVerySmallScreen,
        );
      },
    );
  }

  // تبويب الاختبار
  Widget _buildExamTab(bool isVerySmallScreen, bool isSmallScreen) {
    if (!_isRegistered) {
      return _buildNotRegisteredMessage(isVerySmallScreen);
    }

    final examQuestions = widget.training['examQuestions'] as List? ?? [];
    
    if (examQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: isVerySmallScreen ? 60 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Text(
              'لا يوجد اختبار لهذه الدورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الاختبار
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات الاختبار',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 6 : 8),
                Text(
                  'عدد الأسئلة: ${examQuestions.length}',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 12 : 14,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'درجة النجاح: ${widget.training['passingScore'] ?? 70}%',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 12 : 14,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (_hasPassedExam)
                  Padding(
                    padding: EdgeInsets.only(top: isVerySmallScreen ? 6 : 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: isVerySmallScreen ? 16 : 20,
                        ),
                        SizedBox(width: isVerySmallScreen ? 4 : 8),
                        Text(
                          'لقد نجحت في الاختبار!',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 12 : 14,
                            fontFamily: 'Cairo',
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : 24),
          
          // زر بدء الاختبار
          SizedBox(
            width: double.infinity,
            height: isVerySmallScreen ? 40 : 48,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.quiz,
                size: isVerySmallScreen ? 16 : 20,
              ),
              label: Text(
                _hasPassedExam ? 'إعادة الاختبار' : 'بدء الاختبار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: isVerySmallScreen ? 14 : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasPassedExam ? accentColor : alertColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _startExam(examQuestions, isVerySmallScreen),
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة الفيديو
  Widget _buildVideoCard(int index, String videoUrl, bool isVerySmallScreen) {
    final isWatched = _watchedVideos[index];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
        leading: CircleAvatar(
          backgroundColor: isWatched ? Colors.green : primaryColor,
          radius: isVerySmallScreen ? 16 : 20,
          child: Icon(
            isWatched ? Icons.check : Icons.play_arrow,
            color: Colors.white,
            size: isVerySmallScreen ? 16 : 20,
          ),
        ),
        title: Text(
          'الفيديو ${index + 1}',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: isVerySmallScreen ? 12 : 14,
          ),
        ),
        subtitle: Text(
          isWatched ? 'تم المشاهدة' : 'لم يتم المشاهدة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isVerySmallScreen ? 10 : 12,
            color: isWatched ? Colors.green : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.play_circle_outline,
          color: primaryColor,
          size: isVerySmallScreen ? 20 : 24,
        ),
        onTap: () => _playVideo(index, videoUrl),
      ),
    );
  }

  // بناء رسالة عدم التسجيل
  Widget _buildNotRegisteredMessage(bool isVerySmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: isVerySmallScreen ? 60 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Text(
              'يجب التسجيل في الدورة أولاً',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isVerySmallScreen ? 6 : 8),
            Text(
              'سجل في الدورة للوصول إلى المحتوى',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 12 : 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // بناء شريحة التفاصيل
  Widget _buildDetailChip(IconData icon, String text, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : 12,
        vertical: isVerySmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isVerySmallScreen ? 14 : 16,
            color: secondaryColor,
          ),
          SizedBox(width: isVerySmallScreen ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isVerySmallScreen ? 10 : 12,
              fontFamily: 'Cairo',
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة المعلومات
  Widget _buildInfoCard(String title, List<Widget> children, bool isVerySmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isVerySmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: primaryColor,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 8 : 12),
          ...children,
        ],
      ),
    );
  }

  // بناء صف المعلومات
  Widget _buildInfoRow(IconData icon, String label, String value, bool isVerySmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isVerySmallScreen ? 6 : 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: isVerySmallScreen ? 16 : 18,
            color: secondaryColor,
          ),
          SizedBox(width: isVerySmallScreen ? 6 : 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 12 : 14,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isVerySmallScreen ? 12 : 14,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء أزرار التفاعل
  Widget _buildActionButtons(bool isVerySmallScreen) {
    if (_isCompleted) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
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
              size: isVerySmallScreen ? 20 : 24,
            ),
            SizedBox(width: isVerySmallScreen ? 8 : 12),
            Expanded(
              child: Text(
                'تهانينا! لقد أكملت الدورة بنجاح',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: isVerySmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isRegistered) {
      return SizedBox(
        width: double.infinity,
        height: isVerySmallScreen ? 40 : 48,
        child: ElevatedButton.icon(
          icon: Icon(
            Icons.how_to_reg,
            size: isVerySmallScreen ? 16 : 20,
          ),
          label: Text(
            'سجل في الدورة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: isVerySmallScreen ? 14 : 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: alertColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _registerForTraining,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
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
            size: isVerySmallScreen ? 20 : 24,
          ),
          SizedBox(width: isVerySmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              'أنت مسجل في هذه الدورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontSize: isVerySmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تشغيل الفيديو
  void _playVideo(int index, String videoUrl) async {
    try {
      final Uri url = Uri.parse(videoUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // تحديث حالة المشاهدة
        setState(() {
          _watchedVideos[index] = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل مشاهدة الفيديو'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw 'Could not launch $videoUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تشغيل الفيديو: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // بدء الاختبار
  void _startExam(List examQuestions, bool isVerySmallScreen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamScreen(
          trainingId: widget.trainingId,
          questions: examQuestions,
          passingScore: widget.training['passingScore'] ?? 70,
          onExamCompleted: (bool passed, int score) {
            setState(() {
              _hasPassedExam = passed;
              if (passed) {
                _isCompleted = true;
                _updateTrainingCompletion();
              }
            });
          },
        ),
      ),
    );
  }

  // تسجيل في الدورة
  void _registerForTraining() {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FirebaseFirestore.instance
        .collection('trainings')
        .doc(widget.trainingId)
        .update({
      'registeredUsers': FieldValue.arrayUnion([_currentUserId]),
    }).then((_) {
      setState(() {
        _isRegistered = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التسجيل في الدورة بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
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

  // تحديث إكمال الدورة
  void _updateTrainingCompletion() {
    FirebaseFirestore.instance
        .collection('trainings')
        .doc(widget.trainingId)
        .update({
      'completedUsers': FieldValue.arrayUnion([_currentUserId]),
    });
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
}

// شاشة الاختبار
class ExamScreen extends StatefulWidget {
  final String trainingId;
  final List questions;
  final int passingScore;
  final Function(bool passed, int score) onExamCompleted;

  const ExamScreen({
    super.key,
    required this.trainingId,
    required this.questions,
    required this.passingScore,
    required this.onExamCompleted,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  bool _isCompleted = false;
  int _score = 0;

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color alertColor = const Color(0xFFFF8A65);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(widget.questions.length, null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmallScreen = constraints.maxHeight < 500;
        
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              'اختبار الدورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 16 : 18,
              ),
            ),
            backgroundColor: secondaryColor,
            elevation: 0,
          ),
          body: _isCompleted ? _buildResultsScreen(isVerySmallScreen) : _buildExamScreen(isVerySmallScreen),
        );
      },
    );
  }

  // شاشة الاختبار
  Widget _buildExamScreen(bool isVerySmallScreen) {
    final question = widget.questions[_currentQuestionIndex];
    
    return Padding(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط التقدم
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : 20),
          
          // رقم السؤال
          Text(
            'السؤال ${_currentQuestionIndex + 1} من ${widget.questions.length}',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 14 : 16,
              fontFamily: 'Cairo',
              color: Colors.grey[600],
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          // نص السؤال
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              question['question'] ?? '',
              style: TextStyle(
                fontSize: isVerySmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : 20),
          
          // خيارات الإجابة
          Expanded(
            child: ListView.separated(
              itemCount: (question['options'] as List).length,
              separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
              itemBuilder: (context, index) {
                final option = question['options'][index];
                final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isVerySmallScreen ? 20 : 24,
                          height: isVerySmallScreen ? 20 : 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: isVerySmallScreen ? 12 : 16,
                                )
                              : null,
                        ),
                        SizedBox(width: isVerySmallScreen ? 12 : 16),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 14 : 16,
                              fontFamily: 'Cairo',
                              color: isSelected ? primaryColor : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : 20),
          
          // أزرار التنقل
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'السابق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              
              if (_currentQuestionIndex > 0) SizedBox(width: isVerySmallScreen ? 12 : 16),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedAnswers[_currentQuestionIndex] != null
                      ? () {
                          if (_currentQuestionIndex < widget.questions.length - 1) {
                            setState(() {
                              _currentQuestionIndex++;
                            });
                          } else {
                            _submitExam();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentQuestionIndex < widget.questions.length - 1 ? 'التالي' : 'إنهاء الاختبار',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // شاشة النتائج
  Widget _buildResultsScreen(bool isVerySmallScreen) {
    final percentage = (_score / widget.questions.length * 100).round();
    final passed = percentage >= widget.passingScore;
    
    return Padding(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: isVerySmallScreen ? 80 : 100,
            color: passed ? Colors.green : Colors.red,
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : 20),
          
          Text(
            passed ? 'تهانينا!' : 'للأسف لم تنجح',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 24 : 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: passed ? Colors.green : Colors.red,
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          
          Text(
            'نتيجتك: $_score من ${widget.questions.length} ($percentage%)',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 18 : 20,
              fontFamily: 'Cairo',
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 8 : 12),
          
          Text(
            'درجة النجاح المطلوبة: ${widget.passingScore}%',
            style: TextStyle(
              fontSize: isVerySmallScreen ? 14 : 16,
              fontFamily: 'Cairo',
              color: Colors.grey[600],
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 24 : 32),
          
          if (passed)
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                'لقد اجتزت الاختبار بنجاح! يمكنك الآن الحصول على شهادة إتمام الدورة.',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 14 : 16,
                  fontFamily: 'Cairo',
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          SizedBox(height: isVerySmallScreen ? 20 : 24),
          
          Row(
            children: [
              if (!passed)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex = 0;
                        _selectedAnswers = List.filled(widget.questions.length, null);
                        _isCompleted = false;
                        _score = 0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              
              if (!passed) SizedBox(width: isVerySmallScreen ? 12 : 16),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onExamCompleted(passed, percentage);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: passed ? Colors.green : primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'العودة للدورة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تقديم الاختبار
  void _submitExam() {
    int correctAnswers = 0;
    
    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final correctAnswer = question['correctAnswer'];
      final selectedAnswer = _selectedAnswers[i];
      
      if (selectedAnswer == correctAnswer) {
        correctAnswers++;
      }
    }
    
    setState(() {
      _score = correctAnswers;
      _isCompleted = true;
    });
  }
}

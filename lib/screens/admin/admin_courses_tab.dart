import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCoursesTab extends StatefulWidget {
  const AdminCoursesTab({super.key});

  @override
  State<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

class _AdminCoursesTabState extends State<AdminCoursesTab> {
  final CollectionReference _trainingsCollection = FirebaseFirestore.instance.collection('trainings');
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // إحصائيات الدورات
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'إجمالي الدورات',
                    StreamBuilder<QuerySnapshot>(
                      stream: _trainingsCollection.snapshots(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.hasData ? snapshot.data!.docs.length.toString() : '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Cairo',
                          ),
                        );
                      },
                    ),
                    Icons.school,
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'الدورات النشطة',
                    StreamBuilder<QuerySnapshot>(
                      stream: _trainingsCollection
                          .where('date', isGreaterThan: Timestamp.now())
                          .snapshots(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.hasData ? snapshot.data!.docs.length.toString() : '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                            fontFamily: 'Cairo',
                          ),
                        );
                      },
                    ),
                    Icons.play_circle,
                    secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // زر إضافة دورة جديدة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة دورة تكوينية جديدة',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _showAddCourseDialog(context);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // قائمة الدورات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _trainingsCollection.orderBy('date', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد دورات تكوينية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final courses = snapshot.data!.docs;
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = courses[index].data() as Map<String, dynamic>;
                    final courseId = courses[index].id;
                    
                    return CourseCard(
                      course: course,
                      courseId: courseId,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      accentColor: accentColor,
                      alertColor: alertColor,
                      onEdit: () => _showEditCourseDialog(context, courseId, course),
                      onDelete: () => _showDeleteConfirmation(context, courseId),
                      onViewParticipants: () => _showParticipants(context, courseId, course),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, Widget valueWidget, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            valueWidget,
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddCourseDialog(BuildContext context) {
    _showCourseDialog(context, isEdit: false);
  }
  
  void _showEditCourseDialog(BuildContext context, String courseId, Map<String, dynamic> courseData) {
    _showCourseDialog(context, isEdit: true, courseId: courseId, courseData: courseData);
  }
  
  void _showCourseDialog(BuildContext context, {
    required bool isEdit,
    String? courseId,
    Map<String, dynamic>? courseData,
  }) {
    final titleController = TextEditingController(text: courseData?['title'] ?? '');
    final descriptionController = TextEditingController(text: courseData?['description'] ?? '');
    final timeController = TextEditingController(text: courseData?['time'] ?? '');
    final durationController = TextEditingController(text: courseData?['duration'] ?? '');
    final priceController = TextEditingController(text: courseData?['price']?.toString() ?? '');
    final meetLinkController = TextEditingController(text: courseData?['meetLink'] ?? '');
    final meetPasswordController = TextEditingController(text: courseData?['meetPassword'] ?? '');
    
    DateTime selectedDate = courseData?['date'] != null 
        ? (courseData!['date'] as Timestamp).toDate()
        : DateTime.now();
    String selectedLevel = courseData?['level'] ?? 'مبتدئ';
    File? imageFile;
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEdit ? 'تعديل الدورة' : 'إضافة دورة جديدة',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // عنوان الدورة
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الدورة *',
                      labelStyle: TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),
                  
                  // وصف الدورة
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'وصف الدورة *',
                      labelStyle: TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),
                  
                  // المدة والوقت
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          decoration: const InputDecoration(
                            labelText: 'المدة (ساعات)',
                            labelStyle: TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          decoration: const InputDecoration(
                            labelText: 'وقت البداية',
                            labelStyle: TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(),
                            hintText: '10:00',
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // السعر والمستوى
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'السعر (دج)',
                            labelStyle: TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontFamily: 'Cairo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedLevel,
                          decoration: const InputDecoration(
                            labelText: 'المستوى',
                            labelStyle: TextStyle(fontFamily: 'Cairo'),
                            border: OutlineInputBorder(),
                          ),
                          items: ['مبتدئ', 'متوسط', 'متقدم'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedLevel = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // تاريخ الدورة
                  ListTile(
                    title: const Text('تاريخ الدورة *', style: TextStyle(fontFamily: 'Cairo')),
                    subtitle: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // رابط Google Meet
                  TextField(
                    controller: meetLinkController,
                    decoration: const InputDecoration(
                      labelText: 'رابط Google Meet *',
                      labelStyle: TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(),
                      hintText: 'https://meet.google.com/xxx-xxxx-xxx',
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),
                  
                  // كلمة مرور الاجتماع
                  TextField(
                    controller: meetPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور الاجتماع (اختيارية)',
                      labelStyle: TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),
                  
                  // اختيار صورة
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(
                      imageFile != null ? 'تم اختيار الصورة' : 'اختيار صورة للدورة',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
                      
                      if (pickedImage != null) {
                        setState(() {
                          imageFile = File(pickedImage.path);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
              ),
              onPressed: isLoading ? null : () async {
                if (titleController.text.isEmpty || 
                    descriptionController.text.isEmpty ||
                    meetLinkController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة (*)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setState(() {
                  isLoading = true;
                });
                
                try {
                  String? imageUrl;
                  
                  // رفع الصورة إذا تم اختيارها
                  if (imageFile != null) {
                    final String fileName = 'training_${DateTime.now().millisecondsSinceEpoch}';
                    final Reference storageRef = FirebaseStorage.instance.ref().child('training_images/$fileName');
                    final UploadTask uploadTask = storageRef.putFile(imageFile!);
                    final TaskSnapshot snapshot = await uploadTask;
                    imageUrl = await snapshot.ref.getDownloadURL();
                  }
                  
                  final Map<String, dynamic> courseData = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'time': timeController.text,
                    'duration': durationController.text,
                    'price': double.tryParse(priceController.text) ?? 0,
                    'level': selectedLevel,
                    'date': Timestamp.fromDate(selectedDate),
                    'meetLink': meetLinkController.text,
                    'meetPassword': meetPasswordController.text,
                    'registeredUsers': [],
                    'maxParticipants': 50, // حد أقصى افتراضي
                    'isActive': true,
                  };
                  
                  if (imageUrl != null) {
                    courseData['imageUrl'] = imageUrl;
                  }
                  
                  if (isEdit && courseId != null) {
                    courseData['updatedAt'] = FieldValue.serverTimestamp();
                    await _trainingsCollection.doc(courseId).update(courseData);
                  } else {
                    courseData['createdAt'] = FieldValue.serverTimestamp();
                    await _trainingsCollection.add(courseData);
                  }
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'تم تعديل الدورة بنجاح' : 'تمت إضافة الدورة بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEdit ? 'تعديل' : 'إضافة',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذه الدورة؟ سيتم حذف جميع التسجيلات المرتبطة بها.', 
                           style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _trainingsCollection.doc(courseId).delete();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الدورة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
  
  void _showParticipants(BuildContext context, String courseId, Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('المشتركون في ${course['title']}', style: const TextStyle(fontFamily: 'Cairo')),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getParticipantsDetails(course['registeredUsers'] ?? []),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('لا يوجد مشتركون في هذه الدورة', style: TextStyle(fontFamily: 'Cairo')),
                );
              }
              
              final participants = snapshot.data!;
              
              return Column(
                children: [
                  Text(
                    'عدد المشتركين: ${participants.length}',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: accentColor,
                            child: Text(
                              participant['name']?.isNotEmpty == true 
                                  ? participant['name'][0] 
                                  : 'م',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            participant['name'] ?? 'مستخدم',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          subtitle: Text(
                            participant['email'] ?? '',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
  
  Future<List<Map<String, dynamic>>> _getParticipantsDetails(List<dynamic> userIds) async {
    List<Map<String, dynamic>> participants = [];
    
    for (String userId in userIds) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          participants.add(userDoc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        print('خطأ في جلب بيانات المستخدم $userId: $e');
      }
    }
    
    return participants;
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final String courseId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color alertColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewParticipants;

  const CourseCard({
    super.key,
    required this.course,
    required this.courseId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.alertColor,
    required this.onEdit,
    required this.onDelete,
    required this.onViewParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime courseDate = course['date'] != null 
        ? (course['date'] as Timestamp).toDate()
        : DateTime.now();
    final bool isPastCourse = courseDate.isBefore(DateTime.now());
    final int participantsCount = (course['registeredUsers'] as List<dynamic>?)?.length ?? 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? 'دورة تكوينية',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['level'] ?? 'مبتدئ',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPastCourse ? Colors.grey : secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPastCourse ? 'منتهية' : 'نشطة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // معلومات الدورة
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.calendar_today, _formatDate(courseDate)),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.access_time, course['time'] ?? '00:00'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.schedule, '${course['duration'] ?? '0'} ساعة'),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.monetization_on, '${course['price'] ?? '0'} دج'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.people, '$participantsCount مشترك'),
                ),
                if (course['meetLink'] != null)
                  Expanded(
                    child: InkWell(
                      onTap: () => _launchMeetLink(course['meetLink']),
                      child: _buildInfoItem(Icons.video_call, 'رابط الاجتماع', isClickable: true),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // وصف الدورة
            Text(
              course['description'] ?? 'لا يوجد وصف',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('المشتركون', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    onPressed: onViewParticipants,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text, {bool isClickable = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isClickable ? primaryColor : Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: isClickable ? primaryColor : Colors.grey[700],
              decoration: isClickable ? TextDecoration.underline : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  void _launchMeetLink(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}

import 'package:flutter/material.dart';

class AdminCoursesTab extends StatelessWidget {
  const AdminCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // بيانات تجريبية
    final courses = [
      {'title': 'دورة صيانة مضخات', 'trainer': 'م. أحمد', 'status': 'نشطة'},
      {'title': 'دورة الري الذكي', 'trainer': 'م. ليلى', 'status': 'مغلقة'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('إضافة دورة جديدة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2980B9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddCourseDialog(),
            );
          },
        ),
        const SizedBox(height: 16),
        ...courses.map((course) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.school, color: Color(0xFF2980B9)),
            title: Text(course['title']!, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            subtitle: Text('المدرب: ${course['trainer']} - الحالة: ${course['status']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // تعديل الدورة
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // حذف الدورة
                  },
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class AddCourseDialog extends StatelessWidget {
  const AddCourseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة دورة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(decoration: const InputDecoration(labelText: 'عنوان الدورة')),
          TextField(decoration: const InputDecoration(labelText: 'اسم المدرب')),
          TextField(decoration: const InputDecoration(labelText: 'الوصف')),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('إلغاء'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('إضافة'),
          onPressed: () {
            // منطق إضافة الدورة
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

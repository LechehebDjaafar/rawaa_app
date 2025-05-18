import 'package:flutter/material.dart';

class AdminForumTab extends StatelessWidget {
  const AdminForumTab({super.key});

  @override
  Widget build(BuildContext context) {
    // بيانات مواضيع تجريبية
    final topics = [
      {'title': 'أفضل طرق صيانة الأنابيب', 'author': 'م. ليلى'},
      {'title': 'كيف أختار مضخة مناسبة؟', 'author': 'م. أحمد'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final topic = topics[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.forum, color: Color(0xFF2C3E50)),
            title: Text(topic['title']!, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            subtitle: Text('بواسطة: ${topic['author']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // منطق تعديل الموضوع
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // منطق حذف الموضوع
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

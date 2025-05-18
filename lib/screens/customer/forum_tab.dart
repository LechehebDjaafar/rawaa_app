import 'package:flutter/material.dart';

class ForumTab extends StatelessWidget {
  const ForumTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة المواضيع (تجريبية)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ForumPostCard(
          title: 'كيف أختار مضخة مناسبة؟',
          author: 'م. أحمد',
          replies: 5,
        ),
        const SizedBox(height: 12),
        ForumPostCard(
          title: 'أفضل طرق صيانة الأنابيب',
          author: 'م. ليلى',
          replies: 2,
        ),
      ],
    );
  }
}

class ForumPostCard extends StatelessWidget {
  final String title;
  final String author;
  final int replies;

  const ForumPostCard({
    super.key,
    required this.title,
    required this.author,
    required this.replies,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.forum, color: Color(0xFF2C3E50)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        subtitle: Text('بواسطة: $author'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.reply, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text('$replies'),
          ],
        ),
        onTap: () {
          // الانتقال لتفاصيل الموضوع/النقاش
        },
      ),
    );
  }
}

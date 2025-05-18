import 'package:flutter/material.dart';

class SellerMessagesTab extends StatelessWidget {
  const SellerMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة رسائل تجريبية
    final messages = [
      {'from': 'أحمد', 'lastMessage': 'هل المنتج متوفر؟'},
      {'from': 'سارة', 'lastMessage': 'متى يصل الطلب؟'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final msg = messages[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2F5233),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(msg['from']!, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            subtitle: Text(msg['lastMessage']!, style: const TextStyle(fontFamily: 'Cairo')),
            trailing: Icon(Icons.chat, color: Colors.blue.shade700),
            onTap: () {
              // فتح المحادثة
            },
          ),
        );
      },
    );
  }
}

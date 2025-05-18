import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAdsTab extends StatelessWidget {
  const AdminAdsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ads').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد إعلانات'));
        }

        final ads = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة إعلان جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddAdDialog(),
                );
              },
            ),
            const SizedBox(height: 16),
            ...ads.map((adDoc) {
              final ad = adDoc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: Color(0xFFE74C3C)),
                  title: Text(ad['title'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  subtitle: Text('تاريخ النشر: ${ad['date'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      adDoc.reference.delete();
                    },
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class AddAdDialog extends StatefulWidget {
  const AddAdDialog({super.key});

  @override
  State<AddAdDialog> createState() => _AddAdDialogState();
}

class _AddAdDialogState extends State<AddAdDialog> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة إعلان جديد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان الإعلان')),
          TextField(controller: contentController, decoration: const InputDecoration(labelText: 'محتوى الإعلان')),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('إلغاء'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('إضافة'),
          onPressed: () async {
            await FirebaseFirestore.instance.collection('ads').add({
              'title': titleController.text,
              'content': contentController.text,
              'date': DateTime.now().toString().substring(0, 10),
            });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

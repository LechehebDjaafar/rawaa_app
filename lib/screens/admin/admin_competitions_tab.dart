import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCompetitionsTab extends StatelessWidget {
  const AdminCompetitionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('competitions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد مسابقات'));
        }

        final competitions = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة مسابقة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2980B9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddCompetitionDialog(),
                );
              },
            ),
            const SizedBox(height: 16),
            ...competitions.map((compDoc) {
              final comp = compDoc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Color(0xFF2980B9)),
                  title: Text(comp['title'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  subtitle: Text('تاريخ المسابقة: ${comp['date'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      compDoc.reference.delete();
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

class AddCompetitionDialog extends StatefulWidget {
  const AddCompetitionDialog({super.key});

  @override
  State<AddCompetitionDialog> createState() => _AddCompetitionDialogState();
}

class _AddCompetitionDialogState extends State<AddCompetitionDialog> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مسابقة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان المسابقة')),
          TextField(controller: descController, decoration: const InputDecoration(labelText: 'وصف المسابقة')),
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
            await FirebaseFirestore.instance.collection('competitions').add({
              'title': titleController.text,
              'description': descController.text,
              'date': DateTime.now().toString().substring(0, 10),
            });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

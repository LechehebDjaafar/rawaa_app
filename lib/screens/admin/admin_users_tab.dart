import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمون'));
        }

        final users = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الاسم')),
              DataColumn(label: Text('الدور')),
              DataColumn(label: Text('البريد')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: users.map((doc) {
              final user = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(user['name'] ?? '')),
                DataCell(Text(user['role'] ?? '')),
                DataCell(Text(user['email'] ?? '')),
                DataCell(Text(user['status'] ?? 'نشط')),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        // مثال: تفعيل المستخدم
                        doc.reference.update({'status': 'نشط'});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.block, color: Colors.red),
                      onPressed: () {
                        // مثال: تعطيل المستخدم
                        doc.reference.update({'status': 'معلق'});
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}

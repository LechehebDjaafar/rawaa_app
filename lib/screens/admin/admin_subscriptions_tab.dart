import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSubscriptionsTab extends StatelessWidget {
  const AdminSubscriptionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subscriptions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد اشتراكات'));
        }

        final subscriptions = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('المشترك')),
              DataColumn(label: Text('الباقة')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('البريد')),
              DataColumn(label: Text('الهاتف')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: subscriptions.map((doc) {
              final sub = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(sub['name'] ?? '')),
                DataCell(Text(sub['plan'] ?? '')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sub['status'] == 'نشط' ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sub['status'] ?? '',
                      style: TextStyle(
                        color: sub['status'] == 'نشط' ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(sub['email'] ?? '')),
                DataCell(Text(sub['phone'] ?? '')),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'تفعيل الاشتراك',
                      onPressed: () {
                        doc.reference.update({'status': 'نشط'});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'إلغاء الاشتراك',
                      onPressed: () {
                        doc.reference.update({'status': 'منتهي'});
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductsTab extends StatelessWidget {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد منتجات'));
        }

        final products = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('المنتج')),
              DataColumn(label: Text('الفئة')),
              DataColumn(label: Text('السعر')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: products.map((doc) {
              final product = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(product['name'] ?? '')),
                DataCell(Text(product['category'] ?? '')),
                DataCell(Text(product['price']?.toString() ?? '')),
                DataCell(Text(product['status'] ?? 'متوفر')),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // منطق تعديل المنتج (يمكنك فتح Dialog للتعديل)
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        doc.reference.delete();
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

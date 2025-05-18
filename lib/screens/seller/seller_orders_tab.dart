import 'package:flutter/material.dart';

class SellerOrdersTab extends StatelessWidget {
  const SellerOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة طلبات تجريبية
    final orders = [
      {'customer': 'أحمد', 'product': 'مضخة مياه', 'status': 'جديد'},
      {'customer': 'سارة', 'product': 'أنبوب ري', 'status': 'قيد التنفيذ'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFF2F5233)),
            title: Text('العميل: ${order['customer']}', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            subtitle: Text('المنتج: ${order['product']}\nالحالة: ${order['status']}', style: const TextStyle(fontFamily: 'Cairo')),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onPressed: () {
                // تفاصيل الطلب أو تغيير الحالة
              },
            ),
          ),
        );
      },
    );
  }
}

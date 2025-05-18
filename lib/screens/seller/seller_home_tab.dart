import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerHomeTab extends StatelessWidget {
  const SellerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Color(0xFFF5F7FA),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إحصائيات المبيعات',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1976D2))),
                const SizedBox(height: 16),
                // مثال على ربط رسم بياني حقيقي من فايربيز
                SizedBox(
                  height: 120,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sales')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      // هنا يمكنك رسم رسم بياني فعلي باستخدام fl_chart أو غيرها
                      return Text('عرض رسم بياني حقيقي هنا');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: const [
            Expanded(
                child: _StatusCard(
                    icon: Icons.receipt_long,
                    color: Color(0xFF1976D2),
                    title: 'طلبات جديدة',
                    value: '5')), // اربطها ببيانات حقيقية بنفس الطريقة
            SizedBox(width: 12),
            Expanded(
                child: _StatusCard(
                    icon: Icons.star,
                    color: Color(0xFFFFC107),
                    title: 'تقييمات',
                    value: '4.8')),
            SizedBox(width: 12),
            Expanded(
                child: _StatusCard(
                    icon: Icons.message,
                    color: Color(0xFF43A047),
                    title: 'رسائل',
                    value: '2')),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}

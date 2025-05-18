import 'package:flutter/material.dart';

class SellerReviewsTab extends StatelessWidget {
  const SellerReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة تقييمات تجريبية
    final reviews = [
      {'customer': 'أحمد', 'rating': 5, 'comment': 'منتج ممتاز!'},
      {'customer': 'سارة', 'rating': 4, 'comment': 'خدمة جيدة.'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  review['rating'] as int,
                  (i) => const Icon(Icons.star, color: Colors.amber, size: 16),
                ),
              ),
            ),
            title: Text("djjafar", style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            subtitle: Text("waw", style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      },
    );
  }
}

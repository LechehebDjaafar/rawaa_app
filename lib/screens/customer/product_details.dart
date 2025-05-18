import 'package:flutter/material.dart';

class ProductDetails extends StatelessWidget {
  const ProductDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('تفاصيل المنتج', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF2F5233),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // صورة المنتج
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
              image: const DecorationImage(
                image: AssetImage('assets/images/sample_product.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // اسم المنتج والسعر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('اسم المنتج', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              Text('2500 دج', style: TextStyle(fontSize: 20, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // الفئة والتقييم
          Row(
            children: const [
              Icon(Icons.category, color: Colors.grey, size: 20),
              SizedBox(width: 4),
              Text('مضخات', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(width: 16),
              Icon(Icons.star, color: Colors.amber, size: 20),
              Text('4.5', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // وصف المنتج
          const Text(
            'وصف المنتج: مضخة مياه عالية الجودة مناسبة للري الزراعي، مقاومة للصدأ وسهلة التركيب.',
            style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 16),
          // أزرار
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('أضف للسلة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5233),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // إضافة للسلة
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.red, size: 32),
                onPressed: () {
                  // إضافة للمفضلة
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // التقييمات
          const Text('آراء العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          ReviewCard(
            reviewer: 'محمد',
            rating: 5,
            comment: 'منتج ممتاز وسعر مناسب!',
          ),
          ReviewCard(
            reviewer: 'سارة',
            rating: 4,
            comment: 'جودة جيدة لكن التوصيل تأخر قليلاً.',
          ),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String reviewer;
  final int rating;
  final String comment;

  const ReviewCard({
    super.key,
    required this.reviewer,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(reviewer[0], style: const TextStyle(color: Color(0xFF2F5233))),
        ),
        title: Row(
          children: [
            Text(reviewer, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(width: 8),
            Row(
              children: List.generate(
                rating,
                (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
              ),
            ),
          ],
        ),
        subtitle: Text(comment, style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }
}

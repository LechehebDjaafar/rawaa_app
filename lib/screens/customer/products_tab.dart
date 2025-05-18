import 'package:flutter/material.dart';
import 'package:rawaa_app/screens/customer/product_details.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث والفلاتر
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_alt, color: Color(0xFF2C3E50)),
                onPressed: () {
                  // فتح نافذة الفلاتر (الولاية، السعر، النوع...)
                },
              ),
            ],
          ),
        ),
        // شبكة المنتجات
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: 8, // عدد المنتجات التجريبي
            itemBuilder: (context, index) => ProductCard(),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // الانتقال لتفاصيل المنتج
            Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ProductDetails()),
  );

        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: const DecorationImage(
                  image: AssetImage('assets/images/sample_product.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  const SizedBox(height: 4),
                  const Text('الفئة: مضخات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('4.5', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2500 دج', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F5233))),
                      IconButton(
                        icon: Icon(Icons.favorite_border, color: Colors.red.shade400),
                        onPressed: () {
                          // إضافة للمفضلة
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F5233),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        // إضافة للسلة
                      },
                      child: const Text('أضف للسلة', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

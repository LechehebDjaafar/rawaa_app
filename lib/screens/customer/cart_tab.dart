import 'package:flutter/material.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة المنتجات في السلة (تجريبية)
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => CartItemCard(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المجموع: 7500 دج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F5233))),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('الدفع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F5233),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  // منطق الدفع
                  
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CartItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('assets/images/sample_product.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: const Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        subtitle: const Text('الكمية: 2\nالسعر: 2500 دج'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // منطق إزالة من السلة
          },
        ),
      ),
    );
  }
}

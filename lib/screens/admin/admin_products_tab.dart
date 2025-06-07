import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  String _selectedStatus = 'الكل';
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = Color.fromARGB(255, 89, 138, 243); 
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color alertColor = const Color(0xFFFF8A65);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // شريط البحث والفلترة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // حقل البحث
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    hintStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                
                // فلاتر
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: const Text('الفئة', style: TextStyle(fontFamily: 'Cairo')),
                        isExpanded: true,
                        items: ['الكل', 'إلكترونيات', 'ملابس', 'كتب', 'رياضة'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        hint: const Text('الحالة', style: TextStyle(fontFamily: 'Cairo')),
                        isExpanded: true,
                        items: ['الكل', 'معتمد', 'في انتظار الموافقة', 'مرفوض'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontFamily: 'Cairo')),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // قائمة المنتجات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final products = snapshot.data!.docs;
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;
                    
                    return ProductCard(
                      product: product,
                      productId: productId,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      onProductAction: (action) => _handleProductAction(action, productId, product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleProductAction(String action, String productId, Map<String, dynamic> product) {
    switch (action) {
      case 'approve':
        _updateProductStatus(productId, 'معتمد');
        break;
      case 'reject':
        _updateProductStatus(productId, 'مرفوض');
        break;
      case 'delete':
        _showDeleteConfirmation(productId);
        break;
    }
  }
  
  void _updateProductStatus(String productId, String status) async {
    try {
      await _productsCollection.doc(productId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة المنتج إلى: $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showDeleteConfirmation(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _productsCollection.doc(productId).delete();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المنتج بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final Color primaryColor;
  final Color secondaryColor;
  final Function(String) onProductAction;

  const ProductCard({
    super.key,
    required this.product,
    required this.productId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onProductAction,
  });

  @override
  Widget build(BuildContext context) {
    final String status = product['status'] ?? 'في انتظار الموافقة';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // صورة المنتج
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: product['imageUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(product['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product['imageUrl'] == null
                  ? const Icon(Icons.image_outlined, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // معلومات المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'منتج',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'السعر: ${product['price']?.toString() ?? '0'} دج',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المخزون: ${product['stock']?.toString() ?? '0'}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // أزرار الإجراءات
            Column(
              children: [
                if (status == 'في انتظار الموافقة') ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => onProductAction('approve'),
                    tooltip: 'موافقة',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => onProductAction('reject'),
                    tooltip: 'رفض',
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onProductAction('delete'),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'معتمد':
        return Colors.green;
      case 'في انتظار الموافقة':
        return Colors.orange;
      case 'مرفوض':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

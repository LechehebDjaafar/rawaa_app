import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> with SingleTickerProviderStateMixin {
  final CollectionReference _cartCollection = FirebaseFirestore.instance.collection('cart');
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  final CollectionReference _salesCollection = FirebaseFirestore.instance.collection('sales');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isInitializing = true; // تغيير من _isLoading إلى _isInitializing للتوضيح
  double _totalAmount = 0;
  
  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2); // أزرق مائي
  final Color secondaryColor = const Color(0xFF2F5233); // أخضر داكن
  final Color accentColor = const Color(0xFF4ECDC4); // تركواز فاتح
  final Color backgroundColor = const Color(0xFFF5F7FA); // رمادي فاتح
  final Color alertColor = const Color(0xFFFF8A65); // برتقالي دافئ
  
  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // إضافة متغير للتحكم في Stream
  late Stream<QuerySnapshot> _cartStream;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // التحقق من وجود المجموعات وإنشائها إذا لم تكن موجودة
    _ensureCollectionsExist().then((_) {
      // تهيئة Stream مرة واحدة فقط
      _cartStream = _cartCollection
          .where('userId', isEqualTo: _currentUserId)
          .snapshots();
          
      setState(() {
        _isInitializing = false;
      });
      _animationController.forward();
    });
  }

  // دالة للتحقق من وجود المجموعات وإنشائها إذا لم تكن موجودة
  Future<void> _ensureCollectionsExist() async {
    try {
      // قائمة المجموعات المطلوبة
      final collections = [
        _cartCollection,
        _ordersCollection,
        _salesCollection
      ];
      
      // التحقق من كل مجموعة
      for (var collection in collections) {
        final snapshot = await collection.limit(1).get();
        
        if (snapshot.docs.isEmpty) {
          print('إنشاء مجموعة ${collection.path} لأول مرة');
          
          DocumentReference tempDoc = await collection.add({
            'temp': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          await tempDoc.delete();
        }
      }
    } catch (e) {
      print('خطأ في التحقق من وجود المجموعات: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: _isInitializing
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCartContent(),
            ),
    );
  }

  Widget _buildCartContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _cartStream, // استخدام المتغير بدلاً من إنشاء stream جديد في كل مرة
      builder: (context, snapshot) {
        // تعامل أفضل مع حالات الاتصال
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'السلة فارغة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أضف منتجات إلى السلة لتظهر هنا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('تصفح المنتجات', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // الانتقال إلى صفحة المنتجات (التاب الأول)
                    DefaultTabController.of(context)?.animateTo(0);
                  },
                ),
              ],
            ),
          );
        }
        
        final cartItems = snapshot.data!.docs;
        
        // حساب المجموع الكلي بشكل منفصل لتجنب إعادة البناء المتكررة
        _calculateTotalAmount(cartItems);
        
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // لا نحتاج لاستدعاء setState هنا لأن StreamBuilder سيتحدث تلقائيًا
                },
                color: primaryColor,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index].data() as Map<String, dynamic>;
                    final cartItemId = cartItems[index].id;
                    final productId = cartItem['productId'] as String;
                    final quantity = cartItem['quantity'] as int;
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: _productsCollection.doc(productId).get(),
                      builder: (context, productSnapshot) {
                        // تحسين التعامل مع حالات FutureBuilder
                        if (productSnapshot.connectionState == ConnectionState.waiting) {
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 16),
                                  Text('جاري تحميل معلومات المنتج...'),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              title: const Text('منتج غير متوفر'),
                              subtitle: const Text('تم حذف هذا المنتج أو تغييره'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                                onPressed: () => _removeFromCart(cartItemId),
                              ),
                            ),
                          );
                        }
                        
                        final product = productSnapshot.data!.data() as Map<String, dynamic>;
                        final price = (product['price'] ?? 0).toDouble();
                        
                        return CartItemCard(
                          product: product,
                          quantity: quantity,
                          cartItemId: cartItemId,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          onQuantityChanged: (newQuantity) {
                            _updateCartItemQuantity(cartItemId, newQuantity);
                          },
                          onRemove: () {
                            _showRemoveConfirmation(context, cartItemId);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع: ${_totalAmount.toStringAsFixed(2)} دج',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: secondaryColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      'الدفع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: cartItems.isEmpty ? null : () {
                      _showCheckoutConfirmation(context, cartItems);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // حساب المجموع الكلي - تحسين الأداء باستخدام Future.wait
  Future<void> _calculateTotalAmount(List<QueryDocumentSnapshot> cartItems) async {
    try {
      double total = 0;
      
      // جمع كل طلبات الحصول على المنتجات في قائمة واحدة
      final futures = cartItems.map((item) {
        final cartItem = item.data() as Map<String, dynamic>;
        final productId = cartItem['productId'] as String;
        final quantity = cartItem['quantity'] as int;
        
        return _productsCollection.doc(productId).get().then((productDoc) {
          if (productDoc.exists) {
            final product = productDoc.data() as Map<String, dynamic>;
            final price = (product['price'] ?? 0).toDouble();
            return price * quantity;
          }
          return 0.0;
        }).catchError((e) {
          print('خطأ في حساب السعر للمنتج $productId: $e');
          return 0.0;
        });
      });
      
      // انتظار جميع الطلبات معًا
      final results = await Future.wait(futures);
      
      // جمع النتائج
      for (var price in results) {
        total += price;
      }
      
      // تحديث المجموع فقط إذا كان هناك تغيير
      if (_totalAmount != total) {
        setState(() {
          _totalAmount = total;
        });
      }
    } catch (e) {
      print('خطأ في حساب المجموع الكلي: $e');
    }
  }

  // تحديث كمية المنتج في السلة
  Future<void> _updateCartItemQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeFromCart(cartItemId);
      return;
    }
    
    try {
      await _cartCollection.doc(cartItemId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحديث الكمية: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // إزالة منتج من السلة
  Future<void> _removeFromCart(String cartItemId) async {
    try {
      await _cartCollection.doc(cartItemId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إزالة المنتج من السلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // عرض نافذة تأكيد الإزالة
  void _showRemoveConfirmation(BuildContext context, String cartItemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الإزالة', style: TextStyle(fontFamily: 'Cairo')),
          content: const Text('هل أنت متأكد من إزالة هذا المنتج من السلة؟', style: TextStyle(fontFamily: 'Cairo')),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey[700], fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromCart(cartItemId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('إزالة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
  }

  // عرض نافذة تأكيد الطلب
  void _showCheckoutConfirmation(BuildContext context, List<QueryDocumentSnapshot> cartItems) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الطلب', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هل أنت متأكد من إتمام عملية الشراء؟', style: TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 12),
              Text(
                'المجموع: ${_totalAmount.toStringAsFixed(2)} دج',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey[700], fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToCheckout(cartItems);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('تأكيد الطلب', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
  }

  // إتمام عملية الشراء
  Future<void> _proceedToCheckout(List<QueryDocumentSnapshot> cartItems) async {
    try {
      // إنشاء طلب جديد
      final orderItems = [];
      
      // جمع معلومات المنتجات في الطلب
      for (var item in cartItems) {
        final cartItem = item.data() as Map<String, dynamic>;
        final productId = cartItem['productId'] as String;
        final quantity = cartItem['quantity'] as int;
        
        final productDoc = await _productsCollection.doc(productId).get();
        if (productDoc.exists) {
          final product = productDoc.data() as Map<String, dynamic>;
          final price = (product['price'] ?? 0).toDouble();
          
          orderItems.add({
            'productId': productId,
            'productName': product['name'] ?? 'منتج',
            'quantity': quantity,
            'price': price,
            'subtotal': price * quantity,
          });
        }
      }
      
      // إضافة الطلب إلى مجموعة الطلبات
      final orderRef = await _ordersCollection.add({
        'customerId': _currentUserId,
        'customer': await _getUserName(),
        'items': orderItems,
        'totalAmount': _totalAmount,
        'status': 'جديد',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // إضافة إلى إحصائيات المبيعات
      await _salesCollection.add({
        'orderId': orderRef.id,
        'customerId': _currentUserId,
        'amount': _totalAmount,
        'date': FieldValue.serverTimestamp(),
      });
      
      // حذف جميع العناصر من السلة
      for (var item in cartItems) {
        await _cartCollection.doc(item.id).delete();
      }
      
      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إتمام الطلب بنجاح، شكراً لك!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إتمام الطلب: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // الحصول على اسم المستخدم
  Future<String> _getUserName() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'زبون';
      }
      return 'زبون';
    } catch (e) {
      print('خطأ في جلب اسم المستخدم: $e');
      return 'زبون';
    }
  }
}

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final String cartItemId;
  final Color primaryColor;
  final Color secondaryColor;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.cartItemId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final price = (product['price'] ?? 0).toDouble();
    final totalPrice = price * quantity;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  ? Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    )
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
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'السعر: ${price.toStringAsFixed(2)} دج',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المجموع: ${totalPrice.toStringAsFixed(2)} دج',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // التحكم في الكمية
                  Row(
                    children: [
                      const Text(
                        'الكمية:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                onQuantityChanged(quantity - 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                onQuantityChanged(quantity + 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // زر الحذف
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// lib/customer/cart_tab.dart
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
  final CollectionReference _deliveryOrdersCollection = FirebaseFirestore.instance.collection('delivery_orders');
  final CollectionReference _salesCollection = FirebaseFirestore.instance.collection('sales');
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  bool _isInitializing = true;
  double _totalAmount = 0;

  // ألوان التطبيق
  final Color primaryColor = const Color(0xFF1976D2);
  final Color secondaryColor = const Color(0xFF2F5233);
  final Color deliveryColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // متغيرات للأنيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Stream<QuerySnapshot> _cartStream;

  @override
  void initState() {
    super.initState();

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

    _ensureCollectionsExist().then((_) {
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
      final collections = [
        _cartCollection,
        _ordersCollection,
        _deliveryOrdersCollection,
        _salesCollection
      ];

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenHeight < 500;
        
        return Container(
          color: backgroundColor,
          child: _isInitializing
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCartContent(
                    isSmallScreen: isSmallScreen,
                    isVerySmallScreen: isVerySmallScreen,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCartContent({
    required bool isSmallScreen,
    required bool isVerySmallScreen,
    required double screenWidth,
    required double screenHeight,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _cartStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: isVerySmallScreen ? 50 : 60, color: Colors.red[300]),
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isVerySmallScreen ? 14 : 16,
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
            child: Padding(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: isVerySmallScreen ? 60 : 80, color: Colors.grey[400]),
                  SizedBox(height: isVerySmallScreen ? 12 : 16),
                  Text(
                    'السلة فارغة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 6 : 8),
                  Text(
                    'أضف منتجات إلى السلة لتظهر هنا',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isVerySmallScreen ? 20 : 24),
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 200,
                    height: isVerySmallScreen ? 40 : 48,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.shopping_bag_outlined, size: isVerySmallScreen ? 18 : 20),
                      label: Text(
                        'تصفح المنتجات',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: isVerySmallScreen ? 14 : 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        DefaultTabController.of(context)?.animateTo(0);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final cartItems = snapshot.data!.docs;
        _calculateTotalAmount(cartItems);

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {},
                color: primaryColor,
                child: ListView.separated(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => SizedBox(height: isVerySmallScreen ? 8 : 12),
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index].data() as Map<String, dynamic>;
                    final cartItemId = cartItems[index].id;
                    final productId = cartItem['productId'] as String;
                    final quantity = cartItem['quantity'] as int;

                    return FutureBuilder<DocumentSnapshot>(
                      future: _productsCollection.doc(productId).get(),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.connectionState == ConnectionState.waiting) {
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: isVerySmallScreen ? 16 : 24,
                                    height: isVerySmallScreen ? 16 : 24,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: isVerySmallScreen ? 12 : 16),
                                  Text(
                                    'جاري تحميل معلومات المنتج...',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: isVerySmallScreen ? 12 : 14,
                                    ),
                                  ),
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
                              title: Text(
                                'منتج غير متوفر',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 14 : 16,
                                ),
                              ),
                              subtitle: Text(
                                'تم حذف هذا المنتج أو تغييره',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade400,
                                  size: isVerySmallScreen ? 20 : 24,
                                ),
                                onPressed: () => _removeFromCart(cartItemId),
                              ),
                            ),
                          );
                        }

                        final product = productSnapshot.data!.data() as Map<String, dynamic>;

                        return CartItemCard(
                          product: product,
                          quantity: quantity,
                          cartItemId: cartItemId,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          isVerySmallScreen: isVerySmallScreen,
                          isSmallScreen: isSmallScreen,
                          onQuantityChanged: (newQuantity) {
                            _updateCartItemQuantity(cartItemId, newQuantity);
                          },
                          onRemove: () {
                            _showRemoveConfirmation(context, cartItemId, isVerySmallScreen);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            // شريط المجموع والدفع
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
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
              child: isSmallScreen
                  ? Column(
                      children: [
                        Text(
                          'المجموع: ${_totalAmount.toStringAsFixed(2)} د.ج',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: secondaryColor,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 8 : 12),
                        SizedBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 40 : 48,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.payment, size: isVerySmallScreen ? 18 : 20),
                            label: Text(
                              'الدفع',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: isVerySmallScreen ? 14 : 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: cartItems.isEmpty ? null : () {
                              _showPaymentOptionsDialog(context, cartItems, isVerySmallScreen);
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المجموع: ${_totalAmount.toStringAsFixed(2)} د.ج',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: secondaryColor,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.payment, size: isVerySmallScreen ? 18 : 20),
                          label: Text(
                            'الدفع',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: isVerySmallScreen ? 14 : 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 16 : 24,
                              vertical: isVerySmallScreen ? 8 : 12,
                            ),
                          ),
                          onPressed: cartItems.isEmpty ? null : () {
                            _showPaymentOptionsDialog(context, cartItems, isVerySmallScreen);
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

  // نافذة خيارات الدفع والتوصيل الجديدة
  void _showPaymentOptionsDialog(BuildContext context, List<QueryDocumentSnapshot> cartItems, bool isVerySmallScreen) {
    String selectedPaymentMethod = 'cash'; // cash أو electronic
    bool needsDelivery = false;
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'خيارات الدفع والتوصيل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عرض المجموع
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المجموع الكلي:',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_totalAmount.toStringAsFixed(2)} د.ج',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // خيارات طريقة الدفع
                    Text(
                      'طريقة الدفع:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.money, color: Colors.green, size: isVerySmallScreen ? 18 : 20),
                          const SizedBox(width: 8),
                          Text(
                            'دفع عند الاستلام',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                      value: 'cash',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                      dense: true,
                    ),
                    
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue, size: isVerySmallScreen ? 18 : 20),
                          const SizedBox(width: 8),
                          Text(
                            'دفع إلكتروني',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                      value: 'electronic',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                      dense: true,
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // خيار التوصيل
                    CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(Icons.delivery_dining, color: deliveryColor, size: isVerySmallScreen ? 18 : 20),
                          const SizedBox(width: 8),
                          Text(
                            'أحتاج إلى توصيل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: isVerySmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      value: needsDelivery,
                      onChanged: (value) {
                        setDialogState(() {
                          needsDelivery = value ?? false;
                        });
                      },
                      activeColor: deliveryColor,
                      dense: true,
                    ),
                    
                    // حقل العنوان (يظهر فقط عند اختيار التوصيل)
                    if (needsDelivery) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'عنوان التوصيل',
                          labelStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isVerySmallScreen ? 12 : 14,
                          ),
                          hintText: 'أدخل عنوانك الكامل للتوصيل',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isVerySmallScreen ? 10 : 12,
                          ),
                          prefixIcon: Icon(Icons.location_on, color: deliveryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: deliveryColor),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: isVerySmallScreen ? 12 : 14,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: deliveryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'رسوم التوصيل: 200 د.ج',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: isVerySmallScreen ? 10 : 12,
                            color: deliveryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // التحقق من العنوان إذا كان التوصيل مطلوباً
                    if (needsDelivery && addressController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى إدخال عنوان التوصيل'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop();
                    _proceedToCheckout(
                      cartItems, 
                      selectedPaymentMethod, 
                      needsDelivery, 
                      addressController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'تأكيد الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // إتمام عملية الشراء مع الخيارات الجديدة
  Future<void> _proceedToCheckout(
    List<QueryDocumentSnapshot> cartItems, 
    String paymentMethod, 
    bool needsDelivery, 
    String deliveryAddress,
  ) async {
    try {
      // إنشاء طلب جديد
      final orderItems = <Map<String, dynamic>>[];
      double deliveryFee = needsDelivery ? 200.0 : 0.0;
      double finalTotal = _totalAmount + deliveryFee;

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

      // إضافة الطلب إلى مجموعة الطلبات العادية
      final orderRef = await _ordersCollection.add({
        'customerId': _currentUserId,
        'customer': await _getUserName(),
        'items': orderItems,
        'subtotal': _totalAmount,
        'deliveryFee': deliveryFee,
        'totalAmount': finalTotal,
        'paymentMethod': paymentMethod,
        'needsDelivery': needsDelivery,
        'deliveryAddress': needsDelivery ? deliveryAddress : null,
        'status': needsDelivery ? 'في انتظار التوصيل' : 'جديد',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // إذا كان التوصيل مطلوباً، أضف الطلب إلى قاعدة بيانات التوصيل
      if (needsDelivery) {
        await _deliveryOrdersCollection.add({
          'orderId': orderRef.id,
          'customerId': _currentUserId,
          'customerName': await _getUserName(),
          'customerPhone': await _getUserPhone(),
          'status': 'new', // جديد، في انتظار قبول عامل التوصيل
          'address': deliveryAddress,
          'items': orderItems.map((item) => item['productName']).toList(),
          'totalAmount': finalTotal,
          'deliveryFee': deliveryFee,
          'paymentMethod': paymentMethod,
          'createdAt': FieldValue.serverTimestamp(),
          'estimatedDeliveryTime': 30, // 30 دقيقة افتراضياً
          'distance': 'سيتم تحديده', // سيتم تحديده لاحقاً
        });
      }

      // إضافة إلى إحصائيات المبيعات
      await _salesCollection.add({
        'orderId': orderRef.id,
        'customerId': _currentUserId,
        'amount': finalTotal,
        'paymentMethod': paymentMethod,
        'hasDelivery': needsDelivery,
        'date': FieldValue.serverTimestamp(),
      });

      // حذف جميع العناصر من السلة
      for (var item in cartItems) {
        await _cartCollection.doc(item.id).delete();
      }

      // عرض رسالة نجاح
      String successMessage = needsDelivery 
          ? 'تم إتمام الطلب بنجاح! سيتم التواصل معك قريباً لتأكيد التوصيل.'
          : 'تم إتمام الطلب بنجاح، شكراً لك!';
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // حساب المجموع الكلي
  Future<void> _calculateTotalAmount(List<QueryDocumentSnapshot> cartItems) async {
    try {
      double total = 0;
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

      final results = await Future.wait(futures);
      for (var price in results) {
        total += price;
      }

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
  void _showRemoveConfirmation(BuildContext context, String cartItemId, bool isVerySmallScreen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تأكيد الإزالة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isVerySmallScreen ? 16 : 18,
            ),
          ),
          content: Text(
            'هل أنت متأكد من إزالة هذا المنتج من السلة؟',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isVerySmallScreen ? 14 : 16,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
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
              child: Text(
                'إزالة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  // الحصول على رقم هاتف المستخدم
  Future<String> _getUserPhone() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['phone'] ?? 'غير محدد';
      }
      return 'غير محدد';
    } catch (e) {
      print('خطأ في جلب رقم الهاتف: $e');
      return 'غير محدد';
    }
  }
}

// بطاقة عنصر السلة (نفس الكود السابق)
class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final String cartItemId;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.cartItemId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
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
        padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isSmallScreen) {
              return _buildCompactLayout(price, totalPrice);
            } else {
              return _buildExpandedLayout(price, totalPrice);
            }
          },
        ),
      ),
    );
  }

  // تخطيط مضغوط للشاشات الصغيرة
  Widget _buildCompactLayout(double price, double totalPrice) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Container(
              width: isVerySmallScreen ? 60 : 70,
              height: isVerySmallScreen ? 60 : 70,
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
                      size: isVerySmallScreen ? 24 : 30,
                      color: Colors.grey[400],
                    )
                  : null,
            ),

            SizedBox(width: isVerySmallScreen ? 8 : 12),

            // معلومات المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'منتج',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: isVerySmallScreen ? 12 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isVerySmallScreen ? 2 : 4),
                  Text(
                    'السعر: ${price.toStringAsFixed(2)} د.ج',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey[700],
                      fontSize: isVerySmallScreen ? 10 : 12,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 2 : 4),
                  Text(
                    'المجموع: ${totalPrice.toStringAsFixed(2)} د.ج',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      fontSize: isVerySmallScreen ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),

            // زر الحذف
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: isVerySmallScreen ? 18 : 20,
              ),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        SizedBox(height: isVerySmallScreen ? 8 : 12),

        // التحكم في الكمية
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الكمية:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isVerySmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      onQuantityChanged(quantity - 1);
                    },
                    child: Container(
                      padding: EdgeInsets.all(isVerySmallScreen ? 4 : 6),
                      child: Icon(
                        Icons.remove,
                        size: isVerySmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen ? 8 : 12,
                      vertical: isVerySmallScreen ? 4 : 6,
                    ),
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: isVerySmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      onQuantityChanged(quantity + 1);
                    },
                    child: Container(
                      padding: EdgeInsets.all(isVerySmallScreen ? 4 : 6),
                      child: Icon(
                        Icons.add,
                        size: isVerySmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // تخطيط موسع للشاشات الكبيرة
  Widget _buildExpandedLayout(double price, double totalPrice) {
    return Row(
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
                'السعر: ${price.toStringAsFixed(2)} د.ج',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'المجموع: ${totalPrice.toStringAsFixed(2)} د.ج',
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
    );
  }
}

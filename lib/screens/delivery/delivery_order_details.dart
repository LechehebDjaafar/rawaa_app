// lib/delivery/delivery_order_details.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  
  const DeliveryOrderDetailsScreen({super.key, required this.order});

  @override
  State<DeliveryOrderDetailsScreen> createState() => _DeliveryOrderDetailsScreenState();
}

class _DeliveryOrderDetailsScreenState extends State<DeliveryOrderDetailsScreen> {
  final Color deliveryColor = const Color(0xFFFF6B35);
  bool isUpdating = false;
  Map<String, dynamic> currentOrder = {};

  @override
  void initState() {
    super.initState();
    currentOrder = Map.from(widget.order);
    _loadLatestOrderData();
  }

  // تحميل أحدث بيانات الطلب من قاعدة البيانات
  Future<void> _loadLatestOrderData() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('delivery_orders')
          .doc(widget.order['id'])
          .get();

      if (orderDoc.exists && mounted) {
        setState(() {
          currentOrder = {'id': orderDoc.id, ...orderDoc.data()!};
        });
      }
    } catch (e) {
      print('خطأ في تحميل بيانات الطلب: $e');
    }
  }

  // دالة لتحديث حالة الطلب إلى "تم التوصيل"
  Future<void> _markAsDelivered() async {
    setState(() => isUpdating = true);
    
    try {
      final updateData = {
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      };

      // إضافة أرباح التوصيل إذا لم تكن موجودة
      if (currentOrder['deliveryEarnings'] == null) {
        updateData['deliveryEarnings'] = currentOrder['deliveryFee'] ?? 200.0;
      }

      // تحديث حالة الطلب في Firestore
      await FirebaseFirestore.instance
          .collection('delivery_orders')
          .doc(currentOrder['id'])
          .update(updateData);

      // تحديث البيانات المحلية
      setState(() {
        currentOrder['status'] = 'delivered';
        currentOrder['deliveredAt'] = Timestamp.now();
        if (currentOrder['deliveryEarnings'] == null) {
          currentOrder['deliveryEarnings'] = currentOrder['deliveryFee'] ?? 200.0;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تأكيد توصيل الطلب بنجاح! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(
              label: 'عرض الأرباح',
              textColor: Colors.white,
              onPressed: () {
                _showEarningsDialog();
              },
            ),
          ),
        );
        
        // العودة إلى الصفحة السابقة بعد تأخير قصير
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الطلب: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  // عرض نافذة الأرباح
  void _showEarningsDialog() {
    final earnings = currentOrder['deliveryEarnings'] ?? currentOrder['deliveryFee'] ?? 200.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.green),
            const SizedBox(width: 8),
            const Text('أرباحك من هذا الطلب', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${earnings.toStringAsFixed(0)} د.ج',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            const Text('تهانينا! تم إضافة المبلغ إلى رصيدك', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ممتاز', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // دالة لفتح تطبيق الهاتف للاتصال
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorMessage('لا يمكن فتح تطبيق الهاتف');
      }
    } catch (e) {
      _showErrorMessage('خطأ في فتح تطبيق الهاتف: $e');
    }
  }

  // دالة لفتح خرائط جوجل مع العنوان
  Future<void> _openInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorMessage('لا يمكن فتح خرائط جوجل');
      }
    } catch (e) {
      _showErrorMessage('خطأ في فتح الخريطة: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = currentOrder['orderId'] ?? 'غير محدد';
    final String customerName = currentOrder['customerName'] ?? 'عميل غير محدد';
    final String customerPhone = currentOrder['customerPhone'] ?? '';
    final String deliveryAddress = currentOrder['address'] ?? 'عنوان غير محدد';
    final List<dynamic> items = currentOrder['items'] ?? [];
    final double totalAmount = (currentOrder['totalAmount'] ?? 0.0).toDouble();
    final double deliveryFee = (currentOrder['deliveryFee'] ?? 200.0).toDouble();
    final String status = currentOrder['status'] ?? 'pending';
    final int estimatedTime = currentOrder['estimatedDeliveryTime'] ?? 30;
    final String paymentMethod = currentOrder['paymentMethod'] ?? 'cash';
    final String distance = currentOrder['distance'] ?? 'غير محدد';

    // تحديد نصوص وألوان الحالة
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'delivered':
        statusText = 'تم التوصيل بنجاح ✅';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusText = 'قيد التوصيل 🚚';
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'pending':
      case 'new':
        statusText = 'في انتظار البدء ⏳';
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      default:
        statusText = 'حالة غير معروفة';
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('طلب #$orderId', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: deliveryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLatestOrderData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLatestOrderData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حالة الطلب المحسنة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    if (status == 'in_progress' || status == 'pending') ...[
                      const SizedBox(height: 8),
                      Text(
                        'الوقت المتوقع: $estimatedTime دقيقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: statusColor,
                        ),
                      ),
                    ],
                    if (status == 'delivered' && currentOrder['deliveredAt'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'تم التوصيل: ${_formatTimestamp(currentOrder['deliveredAt'])}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // معلومات العميل
              _buildSectionCard(
                title: 'معلومات العميل',
                icon: Icons.person_pin,
                children: [
                  _buildDetailRow('اسم العميل:', customerName),
                  if (customerPhone.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('رقم الهاتف:', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.grey[700])),
                        Row(
                          children: [
                            Text(customerPhone, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                                onPressed: () => _makePhoneCall(customerPhone),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // قسم عنوان التوصيل
              _buildSectionCard(
                title: 'عنوان التوصيل',
                icon: Icons.location_on,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      deliveryAddress,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, height: 1.5),
                    ),
                  ),
                  if (distance != 'غير محدد') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: deliveryColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'المسافة: $distance',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: deliveryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ العنوان', style: TextStyle(fontFamily: 'Cairo')),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: deliveryAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ العنوان إلى الحافظة!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('فتح الخريطة', style: TextStyle(fontFamily: 'Cairo')),
                          onPressed: () => _openInMaps(deliveryAddress),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // معلومات الطلب
              _buildSectionCard(
                title: 'معلومات الطلب',
                icon: Icons.info_outline,
                children: [
                  _buildDetailRow('طريقة الدفع:', _getPaymentMethodText(paymentMethod)),
                  _buildDetailRow('رسوم التوصيل:', '${deliveryFee.toStringAsFixed(0)} د.ج'),
                  if (currentOrder['createdAt'] != null)
                    _buildDetailRow('تاريخ الطلب:', _formatTimestamp(currentOrder['createdAt'])),
                ],
              ),

              const SizedBox(height: 16),

              // قسم محتويات الطلب
              _buildSectionCard(
                title: 'محتويات الطلب (${items.length} عنصر)',
                icon: Icons.shopping_bag,
                children: [
                  if (items.isEmpty)
                    const Text(
                      'لا توجد تفاصيل للمنتجات',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.grey),
                    )
                  else
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: deliveryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.toString(),
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const Divider(height: 24),
                  _buildDetailRow('المبلغ الإجمالي:', '${totalAmount.toStringAsFixed(0)} د.ج', isTotal: true),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (status == 'pending' || status == 'in_progress') && status != 'delivered' 
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isUpdating ? null : _markAsDelivered,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                child: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'تأكيد استلام الطلب ✅',
                        style: TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
              ),
            )
          : null,
    );
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'غير محدد';
    }
    
    return '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // الحصول على نص طريقة الدفع
  String _getPaymentMethodText(String? paymentMethod) {
    switch (paymentMethod) {
      case 'cash':
        return 'دفع عند الاستلام 💰';
      case 'electronic':
        return 'دفع إلكتروني 💳';
      default:
        return 'غير محدد';
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: deliveryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

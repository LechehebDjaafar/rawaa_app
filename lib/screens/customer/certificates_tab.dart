import 'package:flutter/material.dart';

class CertificatesTab extends StatelessWidget {
  const CertificatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة الشهادات (تجريبية)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CertificateCard(
          title: 'دورة صيانة مضخات الري',
          date: '2024-07-10',
          certificateUrl: 'https://example.com/certificate1.pdf',
        ),
        CertificateCard(
          title: 'دورة التحكم في أنظمة الري الذكي',
          date: '2024-07-15',
          certificateUrl: 'https://example.com/certificate2.pdf',
        ),
      ],
    );
  }
}

class CertificateCard extends StatelessWidget {
  final String title;
  final String date;
  final String certificateUrl;

  const CertificateCard({
    super.key,
    required this.title,
    required this.date,
    required this.certificateUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.verified, color: Colors.amber.shade700, size: 36),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        subtitle: Text('تاريخ الدورة: $date'),
        trailing: IconButton(
          icon: const Icon(Icons.download, color: Color(0xFF2980B9)),
          onPressed: () {
            // تحميل الشهادة
            
          },
        ),
      ),
    );
  }
}

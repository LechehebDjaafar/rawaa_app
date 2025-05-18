import 'package:flutter/material.dart';

class TrainingDetails extends StatelessWidget {
  const TrainingDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title:
            const Text('تفاصيل الدورة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF2980B9),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // صورة الدورة
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.blue[100],
              image: const DecorationImage(
                image: AssetImage('assets/images/sample_training.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // اسم الدورة والتاريخ
          const Text('دورة صيانة مضخات الري',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              SizedBox(width: 4),
              Text('2024-07-10',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(width: 16),
              Icon(Icons.access_time, size: 18, color: Colors.grey),
              SizedBox(width: 4),
              Text('10:00', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          // وصف الدورة
          const Text(
            'تعلم أساسيات صيانة المضخات مع شهادة معتمدة. الدورة تشمل دروس نظرية وتطبيقية مباشرة مع مدربين محترفين.',
            style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 16),
          // مؤقت الدورة
          Row(
            children: [
              Icon(Icons.timer, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('المؤقت: 00:10:23',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          // زر التسجيل أو الشهادة
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.how_to_reg),
                label: const Text('سجل في الدورة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2980B9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                onPressed: () {
                  // منطق التسجيل في الدورة
                },
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.verified, color: Colors.amber),
                label: const Text('تحميل الشهادة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade800,
                  side: BorderSide(color: Colors.amber.shade200),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
                onPressed: () {
                  // تحميل الشهادة بعد إتمام الدورة
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

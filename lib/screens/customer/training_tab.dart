import 'package:flutter/material.dart';
import 'package:rawaa_app/screens/customer/training_details.dart';

class TrainingTab extends StatelessWidget {
  const TrainingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TrainingCard(
          title: 'دورة صيانة مضخات الري',
          description: 'تعلم أساسيات صيانة المضخات مع شهادة معتمدة.',
          date: '2024-07-10',
          time: '10:00',
          isRegistered: false,
        ),
        const SizedBox(height: 16),
        TrainingCard(
          title: 'دورة التحكم في أنظمة الري الذكي',
          description: 'دورة متقدمة حول أنظمة الري الذكي.',
          date: '2024-07-15',
          time: '14:00',
          isRegistered: true,
        ),
      ],
    );
  }
}

class TrainingCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String time;
  final bool isRegistered;

  const TrainingCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.isRegistered,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.blue.shade700, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54, fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(date, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(time, style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isRegistered)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('سجل الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrainingDetails()),
                  );
                },

                  ),
                if (isRegistered)
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      const Text('المؤقت: 00:10:23',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Icon(Icons.verified, color: Colors.amber.shade700),
                      const Text('شهادة متاحة بعد الدورة'),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vomi/views/main/facility_models.dart';

class FacilityDetailScreen extends StatelessWidget {
  final Facility facility;

  const FacilityDetailScreen({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시설 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              facility.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              facility.address,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              facility.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (facility.phone != null) ...[
              const SizedBox(height: 14),
              _InfoRow(label: '전화', value: facility.phone!),
            ],
            if (facility.hours != null) ...[
              const SizedBox(height: 6),
              _InfoRow(label: '운영시간', value: facility.hours!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

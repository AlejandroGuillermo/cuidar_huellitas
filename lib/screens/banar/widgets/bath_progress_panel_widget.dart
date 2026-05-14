import 'package:flutter/material.dart';

class BathProgressPanelWidget extends StatelessWidget {
  final Size size;
  final int soapProgress;
  final int scrubProgress;
  final int rinseProgress;
  final int towelProgress;

  const BathProgressPanelWidget({
    super.key,
    required this.size,
    required this.soapProgress,
    required this.scrubProgress,
    required this.rinseProgress,
    required this.towelProgress,
  });

  @override
  Widget build(BuildContext context) {
    final panelWidth = (size.width * 0.34).clamp(142.0, 186.0);
    return Container(
      width: panelWidth,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BathProgressRow(
            label: 'Jabon',
            value: soapProgress,
            color: const Color(0xFFE78CF4),
          ),
          const SizedBox(height: 8),
          _BathProgressRow(
            label: 'Sin Suciedad',
            value: scrubProgress,
            color: const Color(0xFFD48A4E),
          ),
          const SizedBox(height: 8),
          _BathProgressRow(
            label: 'Enjuague',
            value: rinseProgress,
            color: const Color(0xFF7BCDF5),
          ),
          const SizedBox(height: 8),
          _BathProgressRow(
            label: 'Secado',
            value: towelProgress,
            color: const Color(0xFFF0DA7A),
          ),
        ],
      ),
    );
  }
}

class _BathProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _BathProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF58717D),
                ),
              ),
            ),
            Text(
              '$value%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF58717D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: const Color(0xFFE6EDF2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 100).clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

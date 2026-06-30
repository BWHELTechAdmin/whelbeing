import 'package:flutter/material.dart';

import '../utils/validators.dart';

/// Live checklist of password strength requirements.
///
/// Uses [ValueListenableBuilder] so each row updates as the user types
/// without rebuilding the parent widget tree.
class PasswordRequirementsChecklist extends StatelessWidget {
  const PasswordRequirementsChecklist({
    super.key,
    required this.controller,
    required this.vw,
    required this.vh,
  });

  final TextEditingController controller;
  final double vw;
  final double vh;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final p = value.text;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.5 * vw),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2520)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password requirements',
                style: TextStyle(
                  fontSize: 2.8 * vw,
                  color: const Color(0xFF5A4A3A),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 1.2 * vh),
              for (final (i, req)
                  in Validators.passwordRequirements.indexed) ...[
                if (i > 0) SizedBox(height: 0.7 * vh),
                _RequirementRow(
                  met: req.isMet(p),
                  label: req.label,
                  vw: vw,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.met,
    required this.label,
    required this.vw,
  });

  final bool met;
  final String label;
  final double vw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 4.0 * vw,
          color: met ? const Color(0xFFC9A96E) : const Color(0xFF3A3028),
        ),
        SizedBox(width: 2.0 * vw),
        Text(
          label,
          style: TextStyle(
            fontSize: 3.2 * vw,
            color: met ? const Color(0xFFE8DCC8) : const Color(0xFF4A4038),
          ),
        ),
      ],
    );
  }
}
